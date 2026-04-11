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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    try {
      await ref
          .read(postDetailControllerProvider(widget.postId).notifier)
          .submitComment(_commentController.text);
      _commentController.clear();
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
            final isSubmitting =
                ref.watch(reportsControllerProvider).isLoading;

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
                    decoration: const InputDecoration(
                      labelText: 'Kialo',
                    ),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailControllerProvider(widget.postId));
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
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
                              _PostBody(post: state.post!),
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
                              ...state.comments.map(
                                (comment) => _CommentTile(
                                  comment: comment,
                                  onReport: () => _openReportSheet(
                                    isPost: false,
                                    targetId: comment.id,
                                  ),
                                ),
                              ),
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
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 12,
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
                                ? Row(
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
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Ensalutu por komenti en ĉi tiu afiŝo.',
                                          style: TextStyle(
                                            color:
                                                colorScheme.onSurface.withAlpha(
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
  final VoidCallback onReport;

  const _CommentTile({required this.comment, required this.onReport});

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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Raporti'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
