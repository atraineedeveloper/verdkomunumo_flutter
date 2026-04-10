import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_routes.dart';
import '../../core/responsive.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';
import '../feed/widgets/post_card.dart';
import 'application/search_providers.dart';

enum _SearchTab { posts, users }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _searchDebounce;

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
      ref.read(searchControllerProvider.notifier).clear();
      return;
    }

    if (value.trim().length < 2) {
      ref.read(searchControllerProvider.notifier).search(value);
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(searchControllerProvider.notifier).search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
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
              hintText: 'Serĉu afiŝojn aŭ uzantojn...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchControllerProvider.notifier).clear();
                        setState(() {});
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              setState(() {});
              _scheduleSearch(value);
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _searchDebounce?.cancel();
              ref.read(searchControllerProvider.notifier).search(value);
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
              text: state.query.isNotEmpty
                  ? 'Afiŝoj (${state.posts.length})'
                  : 'Afiŝoj',
            ),
            Tab(
              text: state.query.isNotEmpty
                  ? 'Uzantoj (${state.users.length})'
                  : 'Uzantoj',
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.query.isEmpty
          ? const _EmptySearch()
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
                      state.posts.isEmpty
                          ? _NoResults(
                              query: state.query,
                              type: _SearchTab.posts,
                            )
                          : ListView.builder(
                              itemCount: state.posts.length,
                              itemBuilder: (_, index) => PostCard(
                                key: ValueKey(state.posts[index].id),
                                post: state.posts[index],
                              ),
                            ),
                      state.users.isEmpty
                          ? _NoResults(
                              query: state.query,
                              type: _SearchTab.users,
                            )
                          : ListView.builder(
                              itemCount: state.users.length,
                              itemBuilder: (_, index) =>
                                  _UserTile(profile: state.users[index]),
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
  const _EmptySearch();

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
      onTap: () =>
          context.push('${AppRoutes.profilePrefix}/${profile.username}'),
    );
  }
}
