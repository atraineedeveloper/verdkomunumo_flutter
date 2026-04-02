import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/post.dart';
import '../../../widgets/user_avatar.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likesCount;
  bool _liked = false;
  bool _likeLoading = false;

  @override
  void initState() {
    super.initState();
    _syncFromPost();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likesCount != widget.post.likesCount) {
      _syncFromPost();
    }
  }

  void _syncFromPost() {
    _likesCount = widget.post.likesCount;
    _liked = false;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final postId = widget.post.id;
    final result = await Supabase.instance.client
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();
    if (mounted && widget.post.id == postId) {
      setState(() => _liked = result != null);
    }
  }

  Future<void> _toggleLike() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      context.go('/ensaluti');
      return;
    }
    if (_likeLoading) return;
    final previousLiked = _liked;
    final previousLikesCount = _likesCount;
    setState(() => _likeLoading = true);

    try {
      if (_liked) {
        setState(() {
          _liked = false;
          _likesCount = (_likesCount - 1).clamp(0, 1 << 31);
        });
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', widget.post.id);
      } else {
        setState(() {
          _liked = true;
          _likesCount++;
        });
        await Supabase.instance.client.from('likes').insert({
          'user_id': userId,
          'post_id': widget.post.id,
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = previousLiked;
          _likesCount = previousLikesCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ne eblis ĝisdatigi la ŝaton.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.push('/afisxo/${post.id}'),
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
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (author != null) {
                      context.push('/profilo/${author.username}');
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
            // Content
            Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4)),
            // Images
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
            // Actions
            Row(
              children: [
                _ActionButton(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  count: _likesCount,
                  color: _liked ? Colors.redAccent : null,
                  onTap: _toggleLike,
                  loading: _likeLoading,
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: post.commentsCount,
                  onTap: () => context.push('/afisxo/${post.id}'),
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
          Text(
            '$count',
            style: TextStyle(color: color ?? muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
