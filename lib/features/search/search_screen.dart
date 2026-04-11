import 'dart:async';

import 'package:flutter/cupertino.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Serĉu afiŝojn aŭ uzantojn...',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: colorScheme.onSurface.withAlpha(120),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref.read(searchControllerProvider.notifier).clear();
                        setState(() {});
                      },
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
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
            ],
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : state.query.isEmpty
          ? _EmptySearch(horizontalPadding: horizontalPadding)
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

// ── User tile ─────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final Profile profile;

  const _UserTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () =>
          context.push('${AppRoutes.profilePrefix}/${profile.username}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withAlpha(60),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: profile.avatarUrl,
              username: profile.username,
              radius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '@${profile.username}',
                    style: textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${profile.followersCount}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'sekvantoj',
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.onSurface.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final double horizontalPadding;

  const _EmptySearch({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 32,
                color: colorScheme.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Serĉu afiŝojn aŭ uzantojn',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tajpu almenaŭ 2 signojn por komenci',
              style: textTheme.bodySmall,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                type == _SearchTab.posts
                    ? Icons.article_outlined
                    : Icons.person_search_outlined,
                size: 32,
                color: colorScheme.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Neniu ${type == _SearchTab.posts ? 'afiŝo' : 'uzanto'} trovita',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 4),
            Text('por "$query"', style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
