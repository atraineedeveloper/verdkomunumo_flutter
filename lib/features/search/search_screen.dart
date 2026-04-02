import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/responsive.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';
import '../feed/widgets/post_card.dart';

enum _SearchTab { posts, users }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Post> _posts = [];
  List<Profile> _users = [];
  bool _loading = false;
  String _query = '';
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();

    if (value.isEmpty) {
      _search(value);
      return;
    }

    if (value.trim().length < 2) {
      setState(() {
        _query = value.trim();
        _loading = false;
        _posts = [];
        _users = [];
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _search(value),
    );
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    final requestId = ++_searchRequestId;
    if (query.isEmpty) {
      setState(() {
        _posts = [];
        _users = [];
        _query = '';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _query = query;
    });

    try {
      final postsData = await Supabase.instance.client
          .from('posts')
          .select('*, author:profiles!user_id(*), category:categories!category_id(name)')
          .eq('is_deleted', false)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(30);

      final usersData = await Supabase.instance.client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _posts = postsData.map((j) => Post.fromJson(j)).toList();
        _users = usersData.map((j) => Profile.fromJson(j)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ne eblis ŝargi la serĉrezultojn.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: ResponsiveContent(
          maxWidth: ResponsiveLayout.contentMaxWidth,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Serĉu afiŝojn aŭ uzantojn…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) {
              setState(() {});
              _scheduleSearch(v);
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _searchDebounce?.cancel();
              _search(value);
            },
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withAlpha(150),
          indicatorColor: colorScheme.primary,
          tabs: [
            Tab(
              text: _query.isNotEmpty
                  ? 'Afiŝoj (${_posts.length})'
                  : 'Afiŝoj',
            ),
            Tab(
              text: _query.isNotEmpty
                  ? 'Uzantoj (${_users.length})'
                  : 'Uzantoj',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
              ? _EmptySearch()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ResponsiveLayout.contentMaxWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _posts.isEmpty
                              ? _NoResults(query: _query, type: _SearchTab.posts)
                              : ListView.builder(
                                  itemCount: _posts.length,
                                  itemBuilder: (_, i) => PostCard(
                                    key: ValueKey(_posts[i].id),
                                    post: _posts[i],
                                  ),
                                ),
                          _users.isEmpty
                              ? _NoResults(query: _query, type: _SearchTab.users)
                              : ListView.builder(
                                  itemCount: _users.length,
                                  itemBuilder: (_, i) =>
                                      _UserTile(profile: _users[i]),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
            ),
            const SizedBox(height: 16),
            Text(
              'Serĉu afiŝojn aŭ uzantojn',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final _SearchTab type;
  const _NoResults({required this.query, required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Neniu ${type == _SearchTab.posts ? 'afiŝo' : 'uzanto'} trovita por "$query"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Profile profile;
  const _UserTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: UserAvatar(
        avatarUrl: profile.avatarUrl,
        username: profile.username,
        radius: 24,
      ),
      title: Text(
        profile.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '@${profile.username}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontSize: 13,
        ),
      ),
      trailing: Text(
        '${profile.followersCount} sekvantoj',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
      onTap: () => context.push('/profilo/${profile.username}'),
    );
  }
}
