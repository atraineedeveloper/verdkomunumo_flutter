import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_routes.dart';
import '../../core/responsive.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ComposePostSheet(categories: categories),
    );
  }

  Future<void> _openSuggestionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SuggestionSheet(),
    );
  }

  Widget _buildFeedList(
    FeedState state,
    double contentMaxWidth,
    double horizontalPadding,
    VoidCallback onRetry,
  ) {
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
                  itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
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
    final colorScheme = Theme.of(context).colorScheme;
    FeedCategory? selectedCategory;
    for (final category in state.categories) {
      if (category.id == state.selectedCategoryId) {
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
                    state.filter == FeedFilter.following
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
                      avatar: Icon(
                        _iconForCategory(selectedCategory),
                        size: 16,
                      ),
                      label: Text(selectedCategory.name),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoggedIn
                          ? () => _openCompose(state.categories)
                          : () => context.push(AppRoutes.login),
                      icon: Icon(
                        isLoggedIn ? Icons.edit_outlined : Icons.login,
                      ),
                      label: Text(isLoggedIn ? 'Nova afiŝo' : 'Ensalutu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.categories.isNotEmpty) ...[
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
                      children: state.categories.map((category) {
                        final selected =
                            state.selectedCategoryId == category.id;
                        return FilterChip(
                          selected: selected,
                          onSelected: (_) => ref
                              .read(feedControllerProvider.notifier)
                              .toggleCategory(category.id),
                          avatar: Icon(
                            _iconForCategory(category),
                            size: 16,
                            color: selected
                                ? Colors.black
                                : colorScheme.onSurface,
                          ),
                          label: Text(
                            category.name,
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
    final state = ref.watch(feedControllerProvider);
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
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
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Ensalutu'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            state.categories.isNotEmpty ? 104 : 56,
          ),
          child: ResponsiveContent(
            maxWidth: contentMaxWidth,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    _FilterTab(
                      label: 'Ĉiuj afiŝoj',
                      selected: state.filter == FeedFilter.all,
                      onTap: () => ref
                          .read(feedControllerProvider.notifier)
                          .setFilter(FeedFilter.all),
                    ),
                    if (isLoggedIn)
                      _FilterTab(
                        label: 'Sekvataj',
                        selected: state.filter == FeedFilter.following,
                        onTap: () {
                          ref
                              .read(feedControllerProvider.notifier)
                              .setFilter(FeedFilter.following);
                        },
                      ),
                  ],
                ),
                if (state.categories.isNotEmpty)
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: state.categories.map((category) {
                        final selected =
                            state.selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.black
                                    : colorScheme.onSurface,
                              ),
                            ),
                            avatar: Icon(
                              _iconForCategory(category),
                              size: 16,
                              color: selected
                                  ? Colors.black
                                  : colorScheme.onSurface,
                            ),
                            selected: selected,
                            onSelected: (_) => ref
                                .read(feedControllerProvider.notifier)
                                .toggleCategory(category.id),
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
      body: state.isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : useLandscapePanels
          ? Row(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        ref.read(feedControllerProvider.notifier).refresh(),
                    child: _buildFeedList(
                      state,
                      contentMaxWidth,
                      horizontalPadding,
                      () => ref.read(feedControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
                _buildLandscapePanel(context, state, isLoggedIn),
              ],
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
              child: _buildFeedList(
                state,
                contentMaxWidth,
                horizontalPadding,
                () => ref.read(feedControllerProvider.notifier).refresh(),
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'suggestion-fab',
            onPressed: _openSuggestionSheet,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Sugesto'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'compose-fab',
            onPressed: () => _openCompose(state.categories),
            tooltip: 'Nova afiŝo',
            child: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      floatingActionButtonLocation: ResponsiveLayout.isMobile(context)
          ? FloatingActionButtonLocation.endDocked
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

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
    final message = errorMessage ??
        (hasCategory
            ? 'Neniu afiŝo en tiu ĉi kategorio'
            : filter == FeedFilter.following
                ? 'Sekvu uzantojn por vidi iliajn afiŝojn'
                : 'Ankoraŭ ne estas afiŝoj');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasCategory
                  ? Icons.category_outlined
                  : filter == FeedFilter.following
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
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontSize: 16,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reprovi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
