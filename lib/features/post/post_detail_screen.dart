import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/responsive.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../widgets/user_avatar.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  List<Comment> _comments = [];
  bool _loading = true;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final postData = await Supabase.instance.client
          .from('posts')
          .select('*, author:profiles!user_id(*), category:categories!category_id(name)')
          .eq('id', widget.postId)
          .single();

      final commentsData = await Supabase.instance.client
          .from('comments')
          .select('*, author:profiles!user_id(*)')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      setState(() {
        _post = Post.fromJson(postData);
        _comments = commentsData.map((j) => Comment.fromJson(j)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eraro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      context.push('/ensaluti');
      return;
    }

    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.from('comments').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'content': content,
      });
      _commentController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eraro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Afiŝo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Afiŝo ne trovita'))
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ResponsiveLayout.detailMaxWidth,
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              16,
                              horizontalPadding,
                              16,
                            ),
                            children: [
                              _PostBody(post: _post!),
                              const Divider(height: 32),
                              Text(
                                '${_comments.length} komentoj',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withAlpha(150),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._comments.map((c) => _CommentTile(comment: c)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: colorScheme.surface,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ResponsiveLayout.detailMaxWidth,
                          ),
                          child: Container(
                            padding: EdgeInsets.only(
                              left: horizontalPadding,
                              right: horizontalPadding,
                              top: 12,
                              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              border: Border(
                                top: BorderSide(
                                  color: colorScheme.outline,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Skribu komenton…',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    maxLines: null,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _submitComment(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _submitting ? null : _submitComment,
                                  icon: _submitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PostBody extends StatelessWidget {
  final Post post;
  const _PostBody({required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                radius: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author?.name ?? 'Anonima',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '@${author?.username ?? '?'}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(120),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(post.content, style: const TextStyle(fontSize: 17, height: 1.5)),
        const SizedBox(height: 12),
        Text(
          timeago.format(post.createdAt, locale: 'es'),
          style: TextStyle(
            color: colorScheme.onSurface.withAlpha(120),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.favorite_border, size: 18, color: colorScheme.onSurface.withAlpha(120)),
            const SizedBox(width: 4),
            Text(
              '${post.likesCount}',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
            ),
            const SizedBox(width: 16),
            Icon(Icons.chat_bubble_outline, size: 18, color: colorScheme.onSurface.withAlpha(120)),
            const SizedBox(width: 4),
            Text(
              '${post.commentsCount}',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final author = comment.author;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
              radius: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author?.name ?? 'Anonima',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'es'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
