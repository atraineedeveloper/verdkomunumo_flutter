import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_routes.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/suggestions/presentation/suggestion_sheet.dart';
import '../../widgets/esperanto_star.dart';
import 'application/feed_providers.dart';
import 'application/feed_state.dart';
import 'domain/feed_category.dart';
import 'domain/feed_filter.dart';
import 'widgets/compose_post_sheet.dart';
import 'widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(feedControllerProvider.notifier).initialize(),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openCompose(List<FeedCategory> categories) async {
    final isLoggedIn = ref.read(authStateNotifierProvider).isAuthenticated;
    if (!isLoggedIn) {
      context.push(AppRoutes.login);
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ComposePostSheet(categories: categories),
    );
  }

  Future<void> _openSuggestionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SuggestionSheet(),
    );
  }

  Widget _buildFeedList(FeedState state, VoidCallback onRetry) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.isMobile(context)
        ? ResponsiveLayout.contentMaxWidth
        : ResponsiveLayout.wideContentMaxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: state.posts.isEmpty
              ? _EmptyState(
                  filter: state.filter,
                  hasCategory: state.selectedCategoryId != null,
                  errorMessage: state.errorMessage,
                  onRetry: onRetry,
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.posts.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    return PostCard(
                      key: ValueKey(state.posts[index].id),
                      post: state.posts[index],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildLandscapePanel(
    BuildContext context,
    FeedState state,
    bool isLoggedIn,
  ) {
    final selectedCategory = state.categories
        .where((cat) => cat.id == state.selectedCategoryId)
        .firstOrNull;

    return SizedBox(
      width: 260,
      child: ListView(
        padding: const EdgeInsets.only(top: 16, right: 20, bottom: 24),
        children: [
          _SideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Komunumo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  state.filter == FeedFilter.following
                      ? 'Afiŝoj de sekvataj uzantoj.'
                      : 'La plej freŝaj afiŝoj de la komunumo.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.4),
                ),
                if (selectedCategory != null) ...[
                  const SizedBox(height: 10),
                  _CategoryPill(
                    category: selectedCategory,
                    selected: true,
                    onTap: () => ref
                        .read(feedControllerProvider.notifier)
                        .toggleCategory(selectedCategory.id),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoggedIn
                        ? () => _openCompose(state.categories)
                        : () => context.push(AppRoutes.login),
                    icon: Icon(
                      isLoggedIn ? Icons.edit_rounded : Icons.login_rounded,
                      size: 16,
                    ),
                    label: Text(isLoggedIn ? 'Nova afiŝo' : 'Ensalutu'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openSuggestionSheet,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                    label: const Text('Sugesti kategorion'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SideCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategorioj',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.categories.map((cat) {
                      final selected = state.selectedCategoryId == cat.id;
                      return _CategoryPill(
                        category: cat,
                        selected: selected,
                        onTap: () => ref
                            .read(feedControllerProvider.notifier)
                            .toggleCategory(cat.id),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
    final colorScheme = Theme.of(context).colorScheme;
    final useLandscapePanels = ResponsiveLayout.useLandscapePanels(context);

    final hasCategoryBar = state.categories.isNotEmpty && !useLandscapePanels;
    final appBarBottomHeight = isLoggedIn
        ? (hasCategoryBar ? 96.0 : 52.0)
        : (hasCategoryBar ? 96.0 : 52.0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: EsperantoStar(size: 16, color: Colors.black),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Verdkomunumo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('Ensalutu'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _openSuggestionSheet,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 22),
                tooltip: 'Sugesti kategorion',
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(appBarBottomHeight),
          child: Column(
            children: [
              // ── Filter pill toggle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _PillFilterToggle(
                  showFollowing: isLoggedIn,
                  selected: state.filter,
                  onSelect: (filter) => ref
                      .read(feedControllerProvider.notifier)
                      .setFilter(filter),
                ),
              ),
              // ── Category pills ──────────────────────────────────────────────
              if (hasCategoryBar)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    children: state.categories.map((cat) {
                      final selected = state.selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _CategoryPill(
                          category: cat,
                          selected: selected,
                          onTap: () => ref
                              .read(feedControllerProvider.notifier)
                              .toggleCategory(cat.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Divider(height: 1, color: colorScheme.outline.withAlpha(80)),
            ],
          ),
        ),
      ),
      body: state.isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : useLandscapePanels
          ? Row(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: () =>
                        ref.read(feedControllerProvider.notifier).refresh(),
                    child: _buildFeedList(
                      state,
                      () => ref.read(feedControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: colorScheme.outline.withAlpha(80),
                ),
                _buildLandscapePanel(context, state, isLoggedIn),
              ],
            )
          : RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
              child: _buildFeedList(
                state,
                () => ref.read(feedControllerProvider.notifier).refresh(),
              ),
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 60,
        ),
        child: FloatingActionButton(
          heroTag: 'compose-fab',
          onPressed: () => _openCompose(state.categories),
          tooltip: 'Nova afiŝo',
          child: const Icon(Icons.edit_rounded, size: 22),
        ),
      ),
    );
  }
}

// ── Pill filter toggle ─────────────────────────────────────────────────────────

class _PillFilterToggle extends StatelessWidget {
  final bool showFollowing;
  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelect;

  const _PillFilterToggle({
    required this.showFollowing,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _PillTab(
            label: 'Ĉiuj afiŝoj',
            selected: selected == FeedFilter.all,
            onTap: () => onSelect(FeedFilter.all),
            isDark: isDark,
          ),
          if (showFollowing)
            _PillTab(
              label: 'Sekvataj',
              selected: selected == FeedFilter.following,
              onTap: () => onSelect(FeedFilter.following),
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? colorScheme.surface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withAlpha(130),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category pill ──────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final FeedCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppTheme.primaryGreen
                : colorScheme.outline.withAlpha(isDark ? 80 : 120),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForCategory(category),
              size: 13,
              color: selected
                  ? Colors.black
                  : colorScheme.onSurface.withAlpha(160),
            ),
            const SizedBox(width: 5),
            Text(
              category.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? Colors.black
                    : colorScheme.onSurface.withAlpha(200),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Landscape side card ────────────────────────────────────────────────────────

class _SideCard extends StatelessWidget {
  final Widget child;

  const _SideCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withAlpha(120)),
      ),
      child: child,
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final FeedFilter filter;
  final bool hasCategory;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.filter,
    required this.hasCategory,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final icon = hasCategory
        ? Icons.filter_list_rounded
        : filter == FeedFilter.following
        ? Icons.people_outline_rounded
        : Icons.article_outlined;

    final message =
        errorMessage ??
        (hasCategory
            ? 'Neniu afiŝo en tiu ĉi kategorio'
            : filter == FeedFilter.following
            ? 'Sekvu uzantojn por vidi iliajn afiŝojn'
            : 'Ankoraŭ ne estas afiŝoj');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                icon,
                size: 32,
                color: colorScheme.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(140),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Reprovi')),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

IconData _iconForCategory(FeedCategory category) {
  switch (category.name.toLowerCase()) {
    case 'ĝenerala':
    case 'gxenerala':
      return Icons.forum_outlined;
    case 'lernado':
      return Icons.school_outlined;
    case 'kulturo':
      return Icons.palette_outlined;
    case 'novaĵoj':
    case 'novajxoj':
      return Icons.newspaper_outlined;
    case 'teknologio':
      return Icons.memory_outlined;
    case 'vojaĝoj':
    case 'vojagxoj':
      return Icons.flight_takeoff_outlined;
    case 'helpo':
      return Icons.help_outline;
    case 'ludoj':
      return Icons.sports_esports_outlined;
    default:
      return Icons.label_outline;
  }
}
