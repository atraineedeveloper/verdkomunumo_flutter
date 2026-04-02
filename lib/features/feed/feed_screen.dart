import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/responsive.dart';
import '../../models/post.dart';
import '../../widgets/esperanto_star.dart';
import 'widgets/post_card.dart';
import 'widgets/compose_post_sheet.dart';

class _Category {
  final String id;
  final String name;
  final IconData icon;
  const _Category({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  List<_Category> _categories = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _filter = 'all'; // 'all' | 'following'
  String? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  int _requestId = 0;

  static IconData _iconForCategory(String? name) {
    switch ((name ?? '').toLowerCase()) {
      case 'ĝenerala':
        return Icons.forum_outlined;
      case 'lernado':
        return Icons.school_outlined;
      case 'kulturo':
        return Icons.palette_outlined;
      case 'novaĵoj':
        return Icons.newspaper_outlined;
      case 'teknologio':
        return Icons.memory_outlined;
      case 'vojaĝoj':
        return Icons.flight_takeoff_outlined;
      case 'helpo':
        return Icons.help_outline;
      case 'ludoj':
        return Icons.sports_esports_outlined;
      default:
        return Icons.label_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await Supabase.instance.client
          .from('categories')
          .select('id, name, icon')
          .order('sort_order', ascending: true);
      if (!mounted) return;
      setState(() {
        _categories = data
            .map((j) => _Category(
                  id: (j['id'] ?? '').toString(),
                  name: (j['name'] ?? 'Kategorio').toString(),
                  icon: _iconForCategory(j['name']?.toString()),
                ))
            .toList();
      });
    } catch (_) {}
  }

  Future<List<String>?> _loadFollowingIds(String? userId) async {
    if (_filter != 'following' || userId == null) return null;

    final follows = await Supabase.instance.client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    return follows.map((f) => f['following_id'] as String).toList();
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _buildPostsQuery({
    List<String>? followingIds,
  }) {
    var query = Supabase.instance.client
        .from('posts')
        .select('*, author:profiles!user_id(*), category:categories!category_id(name)')
        .eq('is_deleted', false);

    if (_selectedCategoryId != null) {
      query = query.eq('category_id', _selectedCategoryId!);
    }

    if (followingIds != null) {
      query = query.inFilter('user_id', followingIds);
    }

    return query;
  }

  Future<List<Post>> _fetchPostPage({
    required int page,
    required List<String>? followingIds,
  }) async {
    final from = page * _pageSize;
    final to = from + _pageSize - 1;
    final data = await _buildPostsQuery(followingIds: followingIds)
        .order('created_at', ascending: false)
        .range(from, to);

    return data.map((j) => Post.fromJson(j)).toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    final requestId = ++_requestId;

    if (refresh) {
      setState(() {
        _posts = [];
        _page = 0;
        _hasMore = true;
        _loading = true;
        _loadingMore = false;
      });
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final followingIds = await _loadFollowingIds(userId);

      if (followingIds != null && followingIds.isEmpty) {
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _posts = [];
          _page = 0;
          _loading = false;
          _loadingMore = false;
          _hasMore = false;
        });
        return;
      }

      final posts = await _fetchPostPage(
        page: 0,
        followingIds: followingIds,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _posts = posts;
        _page = 1;
        _hasMore = posts.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eraro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final requestId = _requestId;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final followingIds = await _loadFollowingIds(userId);

      if (followingIds != null && followingIds.isEmpty) {
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _loadingMore = false;
          _hasMore = false;
        });
        return;
      }

      final morePosts = await _fetchPostPage(
        page: _page,
        followingIds: followingIds,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _posts.addAll(morePosts);
        _page++;
        _hasMore = morePosts.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _loadingMore = false);
    }
  }

  void _setFilter(String filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _loadPosts(refresh: true);
  }

  void _setCategory(String? id) {
    if (_selectedCategoryId == id) {
      setState(() => _selectedCategoryId = null);
    } else {
      setState(() => _selectedCategoryId = id);
    }
    _loadPosts(refresh: true);
  }

  Future<void> _openCompose() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      context.push('/ensaluti');
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ComposePostSheet(categories: _categories
          .map((c) => {'id': c.id, 'name': c.name})
          .toList()),
    );
    _loadPosts(refresh: true);
  }

  Widget _buildFeedList(double contentMaxWidth, double horizontalPadding) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: _posts.isEmpty
              ? _EmptyState(
                  filter: _filter,
                  hasCategory: _selectedCategoryId != null,
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _posts.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return PostCard(
                      key: ValueKey(_posts[index].id),
                      post: _posts[index],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildLandscapePanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    _Category? selectedCategory;
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        selectedCategory = category;
        break;
      }
    }

    return SizedBox(
      width: 280,
      child: ListView(
        padding: const EdgeInsets.only(top: 16, right: 24, bottom: 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Komunumo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filter == 'following'
                        ? 'Vi vidas afiŝojn de sekvataj uzantoj.'
                        : 'Vi vidas la plej freŝajn afiŝojn de la komunumo.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(150),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedCategory != null)
                    Chip(
                      avatar: Icon(selectedCategory.icon, size: 16),
                      label: Text(selectedCategory.name),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoggedIn
                          ? _openCompose
                          : () => context.push('/ensaluti'),
                      icon: Icon(isLoggedIn ? Icons.edit_outlined : Icons.login),
                      label: Text(isLoggedIn ? 'Nova afiŝo' : 'Ensalutu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategorioj',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategoryId == cat.id;
                        return FilterChip(
                          selected: selected,
                          onSelected: (_) => _setCategory(cat.id),
                          avatar: Icon(
                            cat.icon,
                            size: 16,
                            color: selected
                                ? Colors.black
                                : colorScheme.onSurface,
                          ),
                          label: Text(
                            cat.name,
                            style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : colorScheme.onSurface,
                            ),
                          ),
                          selectedColor: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          checkmarkColor: Colors.black,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.isMobile(context)
        ? ResponsiveLayout.contentMaxWidth
        : ResponsiveLayout.wideContentMaxWidth;
    final useLandscapePanels = ResponsiveLayout.useLandscapePanels(context);

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveContent(
          maxWidth: contentMaxWidth,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              EsperantoStar(size: 22, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Verdkomunumo'),
            ],
          ),
        ),
        actions: [
          if (!isLoggedIn)
            TextButton(
              onPressed: () => context.push('/ensaluti'),
              child: const Text('Ensalutu'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_categories.isNotEmpty ? 104 : 56),
          child: ResponsiveContent(
            maxWidth: contentMaxWidth,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    _FilterTab(
                      label: 'Ĉiuj afiŝoj',
                      selected: _filter == 'all',
                      onTap: () => _setFilter('all'),
                    ),
                    _FilterTab(
                      label: 'Sekvataj',
                      selected: _filter == 'following',
                      onTap: () {
                        if (!isLoggedIn) {
                          context.push('/ensaluti');
                        } else {
                          _setFilter('following');
                        }
                      },
                    ),
                  ],
                ),
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _categories.map((cat) {
                        final selected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.black
                                    : colorScheme.onSurface,
                              ),
                            ),
                            avatar: Icon(
                              cat.icon,
                              size: 16,
                              color: selected
                                  ? Colors.black
                                  : colorScheme.onSurface,
                            ),
                            selected: selected,
                            onSelected: (_) => _setCategory(cat.id),
                            selectedColor: colorScheme.primary,
                            checkmarkColor: Colors.black,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            side: BorderSide(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : useLandscapePanels
              ? Row(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadPosts(refresh: true),
                        child: _buildFeedList(contentMaxWidth, horizontalPadding),
                      ),
                    ),
                    _buildLandscapePanel(context),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () => _loadPosts(refresh: true),
                  child: _buildFeedList(contentMaxWidth, horizontalPadding),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        tooltip: 'Nova afiŝo',
        child: const Icon(Icons.edit_outlined),
      ),
      floatingActionButtonLocation: ResponsiveLayout.isMobile(context)
          ? FloatingActionButtonLocation.endDocked
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? primary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(150),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  final bool hasCategory;
  const _EmptyState({required this.filter, required this.hasCategory});

  @override
  Widget build(BuildContext context) {
    final message = hasCategory
        ? 'Neniu afiŝo en tiu ĉi kategorio'
        : filter == 'following'
            ? 'Sekvu uzantojn por vidi iliajn afiŝojn'
            : 'Ankoraŭ ne estas afiŝoj';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasCategory
                  ? Icons.category_outlined
                  : filter == 'following'
                      ? Icons.people_outline
                      : Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
