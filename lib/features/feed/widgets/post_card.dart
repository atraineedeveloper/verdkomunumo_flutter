import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/routing/app_routes.dart';
import '../../../core/presence/presence_providers.dart';
import '../../../models/post.dart';
import '../../../widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../../post_interactions/application/post_interactions_providers.dart';

class PostCard extends ConsumerWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = post.author;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final args = PostInteractionArgs(
      postId: post.id,
      initialLikesCount: post.likesCount,
    );
    final interactionState = ref.watch(postInteractionControllerProvider(args));
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
    final onlineIds = ref.watch(presenceControllerProvider);
    final isOnline = author != null && onlineIds.contains(author.id);

    Future<void> handleToggleLike() async {
      if (!isLoggedIn) {
        context.go(AppRoutes.login);
        return;
      }
      final success = await ref
          .read(postInteractionControllerProvider(args).notifier)
          .toggleLike();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ne eblis ĝisdatigi la ŝaton.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    return InkWell(
      onTap: () => context.push('${AppRoutes.postDetailPrefix}/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column: avatar ──────────────────────────────────────────
            GestureDetector(
              onTap: () {
                if (author != null) {
                  context.push(
                    '${AppRoutes.profilePrefix}/${author.username}',
                  );
                }
              },
              child: _AvatarWithPresence(
                avatarUrl: author?.avatarUrl,
                username: author?.username ?? '?',
                radius: 22,
                isOnline: isOnline,
              ),
            ),
            const SizedBox(width: 12),

            // ── Right column: all content ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: name · @username · time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            if (author != null) {
                              context.push(
                                '${AppRoutes.profilePrefix}/${author.username}',
                              );
                            }
                          },
                          child: Text(
                            author?.name ?? 'Anonima',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (author?.username != null) ...[
                        const SizedBox(width: 5),
                        Text(
                          '@${author!.username}',
                          style: textTheme.bodySmall?.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        timeago.format(post.createdAt, locale: 'es'),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),

                  // Category tag (if any)
                  if (post.categoryName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.categoryName!,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppThemeColors.primary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  // Content
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Image
                  if (post.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        maxHeightDiskCache: 600,
                        placeholder: (_, _) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.onSurface.withAlpha(60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Action row
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ActionBtn(
                        icon: interactionState.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        count: interactionState.likesCount,
                        activeColor: const Color(0xFFF43F5E),
                        isActive: interactionState.isLiked,
                        onTap: handleToggleLike,
                        loading: interactionState.isLoading,
                      ),
                      const SizedBox(width: 20),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        count: post.commentsCount,
                        onTap: () => context.push(
                          '${AppRoutes.postDetailPrefix}/${post.id}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color? activeColor;
  final bool isActive;
  final VoidCallback onTap;
  final bool loading;

  const _ActionBtn({
    required this.icon,
    required this.count,
    required this.onTap,
    this.activeColor,
    this.isActive = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withAlpha(100);
    final color = isActive ? (activeColor ?? muted) : muted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(icon, size: 18, color: color),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Avatar with presence dot ───────────────────────────────────────────────────

class _AvatarWithPresence extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;
  final bool isOnline;

  const _AvatarWithPresence({
    required this.avatarUrl,
    required this.username,
    required this.radius,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(avatarUrl: avatarUrl, username: username, radius: radius),
        if (isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Color helper ──────────────────────────────────────────────────────────────

class AppThemeColors {
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}
