import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/routing/app_routes.dart';
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
    final args = PostInteractionArgs(
      postId: post.id,
      initialLikesCount: post.likesCount,
    );
    final interactionState = ref.watch(postInteractionControllerProvider(args));
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;

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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outline, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (author != null) {
                      context.push(
                        '${AppRoutes.profilePrefix}/${author.username}',
                      );
                    }
                  },
                  child: UserAvatar(
                    avatarUrl: author?.avatarUrl,
                    username: author?.username ?? '?',
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              author?.name ?? 'Anonima',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '@${author?.username ?? '?'}',
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(120),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        timeago.format(post.createdAt, locale: 'es'),
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(120),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.categoryName != null)
                  Chip(
                    label: Text(post.categoryName!),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  maxHeightDiskCache: 600,
                  placeholder: (_, _) => Container(
                    height: 200,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 120,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: interactionState.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  count: interactionState.likesCount,
                  color: interactionState.isLiked ? Colors.redAccent : null,
                  onTap: handleToggleLike,
                  loading: interactionState.isLoading,
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: post.commentsCount,
                  onTap: () =>
                      context.push('${AppRoutes.postDetailPrefix}/${post.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color? color;
  final VoidCallback onTap;
  final bool loading;

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onTap,
    this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withAlpha(120);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color ?? muted,
                  ),
                )
              : Icon(icon, size: 20, color: color ?? muted),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: color ?? muted, fontSize: 13)),
        ],
      ),
    );
  }
}
