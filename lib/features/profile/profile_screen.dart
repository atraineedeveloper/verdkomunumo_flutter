import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_routes.dart';
import '../../core/error/app_failure.dart';
import '../../core/presence/presence_providers.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';
import '../auth/application/auth_providers.dart';
import '../feed/widgets/post_card.dart';
import 'application/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider(username));
    final controller =
        ref.read(profileControllerProvider(username).notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(currentUserIdProvider);
    final onlineIds = ref.watch(presenceControllerProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final isOwnProfile =
        state.profile != null && currentUserId == state.profile!.id;
    final isOnline =
        state.profile != null && onlineIds.contains(state.profile!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.profile?.username ?? username,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: () => context.go(AppRoutes.settings),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : state.profile == null
          ? Center(
              child: Text(
                state.errorMessage ?? 'Profilo ne trovita',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(140),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                // ── Profile header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveLayout.contentMaxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: _ProfileHeader(
                          profile: state.profile!,
                          isFollowing: state.isFollowing,
                          isOwnProfile: isOwnProfile,
                          isOnline: isOnline,
                          followLoading: state.isFollowLoading,
                          onFollowTap: () async {
                            if (!ref
                                .read(authStateNotifierProvider)
                                .isAuthenticated) {
                              context.push(AppRoutes.login);
                              return;
                            }
                            try {
                              await controller.toggleFollow();
                            } on AppFailure catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error.message),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Divider + post count ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1,
                        color: colorScheme.outline.withAlpha(80),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          4,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: ResponsiveLayout.contentMaxWidth,
                            ),
                            child: Text(
                              '${state.posts.length} afiŝoj',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Posts list ────────────────────────────────────────────────
                if (state.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.article_outlined,
                                size: 28,
                                color: colorScheme.onSurface.withAlpha(80),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ankoraŭ ne estas afiŝoj',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withAlpha(140),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ResponsiveLayout.contentMaxWidth,
                          ),
                          child: PostCard(
                            key: ValueKey(state.posts[index].id),
                            post: state.posts[index],
                          ),
                        ),
                      ),
                      childCount: state.posts.length,
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Profile profile;
  final bool isFollowing;
  final bool isOwnProfile;
  final bool isOnline;
  final bool followLoading;
  final VoidCallback onFollowTap;

  const _ProfileHeader({
    required this.profile,
    required this.isFollowing,
    required this.isOwnProfile,
    required this.isOnline,
    required this.followLoading,
    required this.onFollowTap,
  });

  String get _levelLabel {
    switch (profile.esperantoLevel) {
      case 'progresanto':
        return 'Progresanto';
      case 'flua':
        return 'Flua';
      default:
        return 'Komencanto';
    }
  }

  Color _levelColor(BuildContext context) {
    switch (profile.esperantoLevel) {
      case 'flua':
        return const Color(0xFF22C55E);
      case 'progresanto':
        return const Color(0xFF3B82F6);
      default:
        return Theme.of(context).colorScheme.onSurface.withAlpha(120);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar row ─────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with presence
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glow ring for online
                  if (isOnline)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withAlpha(80),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  UserAvatar(
                    avatarUrl: profile.avatarUrl,
                    username: profile.username,
                    radius: 44,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),

              // Stats: following | followers | posts
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      count: profile.postsCount,
                      label: 'Afiŝoj',
                    ),
                    _StatColumn(
                      count: profile.followersCount,
                      label: 'Sekvantoj',
                    ),
                    _StatColumn(
                      count: profile.followingCount,
                      label: 'Sekvitaj',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Name + username ────────────────────────────────────────────────
          Text(
            profile.name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '@${profile.username}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withAlpha(140),
              fontSize: 13,
            ),
          ),

          // ── Level badge ────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _levelColor(context).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _levelColor(context).withAlpha(60),
                  ),
                ),
                child: Text(
                  _levelLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: _levelColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // ── Bio ────────────────────────────────────────────────────────────
          if (profile.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio!,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
                color: colorScheme.onSurface.withAlpha(220),
              ),
            ),
          ],

          // ── Action button ──────────────────────────────────────────────────
          if (!isOwnProfile) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: isFollowing
                  ? OutlinedButton(
                      onPressed: followLoading ? null : onFollowTap,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: followLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Malsekvu',
                              style: textTheme.labelLarge?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                    )
                  : ElevatedButton(
                      onPressed: followLoading ? null : onFollowTap,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: followLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CupertinoActivityIndicator(
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Sekvu',
                              style: textTheme.labelLarge?.copyWith(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stat column ────────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final int count;
  final String label;

  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          _formatCount(count),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(140),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
