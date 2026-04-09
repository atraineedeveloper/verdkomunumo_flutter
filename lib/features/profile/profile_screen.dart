import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_routes.dart';
import '../../core/responsive.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';
import '../auth/application/auth_providers.dart';
import '../feed/widgets/post_card.dart';
import 'application/profile_providers.dart';
import 'data/supabase_profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider(username));
    final controller = ref.read(profileControllerProvider(username).notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(currentUserIdProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final isOwnProfile =
        state.profile != null && currentUserId == state.profile!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.profile?.username ?? username),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go(AppRoutes.settings),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.profile == null
              ? Center(
                  child: Text(state.errorMessage ?? 'Profilo ne trovita'),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: ResponsiveLayout.contentMaxWidth,
                            ),
                            child: _ProfileHeader(
                              profile: state.profile!,
                              isFollowing: state.isFollowing,
                              isOwnProfile: isOwnProfile,
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
                                } on ProfileActionFailure catch (error) {
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          8,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: ResponsiveLayout.contentMaxWidth,
                            ),
                            child: Text(
                              '${state.posts.length} afisxoj',
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(150),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state.posts.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: ResponsiveLayout.contentMaxWidth,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Ankorau ne estas afisxoj',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Center(
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
                          ),
                          childCount: state.posts.length,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Profile profile;
  final bool isFollowing;
  final bool isOwnProfile;
  final bool followLoading;
  final VoidCallback onFollowTap;

  const _ProfileHeader({
    required this.profile,
    required this.isFollowing,
    required this.isOwnProfile,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                avatarUrl: profile.avatarUrl,
                username: profile.username,
                radius: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  runAlignment: WrapAlignment.center,
                  children: [
                    if (!isOwnProfile)
                      OutlinedButton(
                        onPressed: followLoading ? null : onFollowTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFollowing
                              ? colorScheme.onSurface
                              : colorScheme.primary,
                          side: BorderSide(
                            color: isFollowing
                                ? colorScheme.outline
                                : colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: followLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isFollowing ? 'Malsekvu' : 'Sekvu'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${profile.username}',
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(150),
              fontSize: 14,
            ),
          ),
          if (profile.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(profile.bio!, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
          const SizedBox(height: 10),
          Chip(
            label: Text(_levelLabel, style: const TextStyle(fontSize: 12)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _StatItem(count: profile.followingCount, label: 'Sekvitaj'),
              _StatItem(count: profile.followersCount, label: 'Sekvantoj'),
              _StatItem(count: profile.postsCount, label: 'Afisxoj'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
