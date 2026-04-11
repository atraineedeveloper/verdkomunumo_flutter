import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../app/routing/app_routes.dart';
import '../../core/error/app_failure.dart';
import '../../core/responsive.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../widgets/user_avatar.dart';
import '../auth/application/auth_providers.dart';
import '../reports/application/reports_providers.dart';
import '../reports/domain/report_reason.dart';
import 'application/post_detail_providers.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  Comment? _replyTo;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    try {
      await ref
          .read(postDetailControllerProvider(widget.postId).notifier)
          .submitComment(_commentController.text, parentId: _replyTo?.id);
      _commentController.clear();
      setState(() => _replyTo = null);
    } on AppFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _startReply(Comment comment) {
    setState(() => _replyTo = comment);
  }

  void _cancelReply() {
    setState(() => _replyTo = null);
  }

  Future<void> _openEditPostSheet(String initialContent) async {
    final controller = TextEditingController(text: initialContent);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Redakti afiŝon',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ĝisdatigu la afiŝon...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(
                          postDetailControllerProvider(widget.postId).notifier,
                        )
                        .updatePost(controller.text);
                    if (!mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Konservi'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _openEditCommentSheet({
    required String commentId,
    required String initialContent,
  }) async {
    final controller = TextEditingController(text: initialContent);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Redakti komenton',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ĝisdatigu la komenton...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(
                          postDetailControllerProvider(widget.postId).notifier,
                        )
                        .updateComment(
                          commentId: commentId,
                          content: controller.text,
                        );
                    if (!mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Konservi'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _confirmDeletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Forigi afiŝon?'),
          content: const Text('Ĉi tio kaŝos la afiŝon por ĉiuj uzantoj.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nuligi'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Forigi'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    await ref
        .read(postDetailControllerProvider(widget.postId).notifier)
        .deletePost();
    if (!mounted) return;
    context.go(AppRoutes.feed);
  }

  Future<void> _confirmDeleteComment(String commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Forigi komenton?'),
          content: const Text('Ĉi tio kaŝos la komenton por ĉiuj uzantoj.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nuligi'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Forigi'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    await ref
        .read(postDetailControllerProvider(widget.postId).notifier)
        .deleteComment(commentId);
  }

  Future<void> _openReportSheet({
    required bool isPost,
    required String targetId,
  }) async {
    final isLoggedIn = ref.read(authStateNotifierProvider).isAuthenticated;
    if (!isLoggedIn) {
      if (!mounted) return;
      context.push(AppRoutes.login);
      return;
    }

    final reasonOptions = reportReasons;
    final detailsController = TextEditingController();
    var selectedReason = reasonOptions.first.value;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isSubmitting = ref.watch(reportsControllerProvider).isLoading;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPost ? 'Raporti afiŝon' : 'Raporti komenton',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    items: reasonOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedReason = value);
                    },
                    decoration: const InputDecoration(labelText: 'Kialo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Detaloj (laŭvole)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              try {
                                final controller = ref.read(
                                  reportsControllerProvider.notifier,
                                );
                                if (isPost) {
                                  await controller.submitPostReport(
                                    postId: targetId,
                                    reason: selectedReason,
                                    details: detailsController.text,
                                  );
                                } else {
                                  await controller.submitCommentReport(
                                    commentId: targetId,
                                    reason: selectedReason,
                                    details: detailsController.text,
                                  );
                                }
                                if (!mounted) return;
                                Navigator.of(sheetContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Raporto sendita.'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              } on AppFailure catch (error) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error.message),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Sendi raporton'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    detailsController.dispose();
  }

  List<Widget> _buildCommentThread(
    List<Comment> comments,
    String? currentUserId,
  ) {
    final topLevel = comments.where((comment) => comment.parentId == null);
    final repliesByParent = <String, List<Comment>>{};
    for (final comment in comments) {
      final parentId = comment.parentId;
      if (parentId == null) continue;
      repliesByParent.putIfAbsent(parentId, () => []).add(comment);
    }

    final widgets = <Widget>[];
    for (final comment in topLevel) {
      widgets.add(
        _CommentTile(
          comment: comment,
          currentUserId: currentUserId,
          onReport: () => _openReportSheet(isPost: false, targetId: comment.id),
          onEdit: () => _openEditCommentSheet(
            commentId: comment.id,
            initialContent: comment.content,
          ),
          onDelete: () => _confirmDeleteComment(comment.id),
          onReply: () => _startReply(comment),
        ),
      );

      final replies = repliesByParent[comment.id] ?? const [];
      for (final reply in replies) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: _CommentTile(
              comment: reply,
              currentUserId: currentUserId,
              onReport: () =>
                  _openReportSheet(isPost: false, targetId: reply.id),
              onEdit: () => _openEditCommentSheet(
                commentId: reply.id,
                initialContent: reply.content,
              ),
              onDelete: () => _confirmDeleteComment(reply.id),
              onReply: () => _startReply(comment),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  // SECTION: builders

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailControllerProvider(widget.postId));
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
    final currentUserId = ref.watch(currentUserIdProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Afiŝo')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.post == null
          ? Center(child: Text(state.errorMessage ?? 'Afiŝo ne trovita'))
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
                          _PostBody(
                            post: state.post!,
                            currentUserId: currentUserId,
                            onEdit: () =>
                                _openEditPostSheet(state.post!.content),
                            onDelete: _confirmDeletePost,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _openReportSheet(
                                isPost: true,
                                targetId: state.post!.id,
                              ),
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('Raporti'),
                            ),
                          ),
                          const Divider(height: 32),
                          Text(
                            '${state.comments.length} komentoj',
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(150),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildCommentThread(state.comments, currentUserId),
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
                        child: isLoggedIn
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_replyTo != null)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Respondi al @${_replyTo!.author?.username ?? 'uzanto'}',
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withAlpha(150),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _cancelReply,
                                            icon: const Icon(Icons.close),
                                            tooltip: 'Nuligi',
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentController,
                                          decoration: InputDecoration(
                                            hintText: 'Skribu komenton...',
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          maxLines: null,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _submitComment(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filled(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : _submitComment,
                                        icon: state.isSubmitting
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
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
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ensalutu por komenti en ĉi tiu afiŝo.',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withAlpha(
                                          150,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.login),
                                    child: const Text('Ensalutu'),
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
  final String? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostBody({
    required this.post,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

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
                  context.push('${AppRoutes.profilePrefix}/${author.username}');
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
            const Spacer(),
            if (currentUserId != null && currentUserId == post.authorId)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Redakti')),
                  PopupMenuItem(value: 'delete', child: Text('Forigi')),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(post.content, style: const TextStyle(fontSize: 17, height: 1.5)),
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: post.imageUrls.first,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 180,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              timeago.format(post.createdAt, locale: 'es'),
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(120),
                fontSize: 13,
              ),
            ),
            if (post.isEdited) ...[
              const SizedBox(width: 8),
              Text(
                'Redaktita',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(120),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.favorite_border,
              size: 18,
              color: colorScheme.onSurface.withAlpha(120),
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likesCount}',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: colorScheme.onSurface.withAlpha(120),
            ),
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
  final String? currentUserId;
  final VoidCallback onReport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.onReport,
    required this.onEdit,
    required this.onDelete,
    required this.onReply,
  });

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
                context.push('${AppRoutes.profilePrefix}/${author.username}');
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'es'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    if (comment.isEdited) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Redaktita',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (currentUserId != null &&
                        currentUserId == comment.authorId)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Redakti')),
                          PopupMenuItem(value: 'delete', child: Text('Forigi')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onReply,
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Respondi'),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Raporti'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
