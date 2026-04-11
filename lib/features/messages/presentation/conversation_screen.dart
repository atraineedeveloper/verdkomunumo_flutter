import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/routing/app_routes.dart';
import '../../../core/presence/presence_providers.dart';
import '../../../models/profile.dart';
import '../../../widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../application/messages_providers.dart';
import '../domain/message.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(conversationControllerProvider(widget.conversationId).notifier)
            ..load(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Profile? _otherParticipant(
    List<Profile> participants,
    String? currentUserId,
  ) {
    if (participants.isEmpty) return null;
    if (currentUserId == null) return participants.first;
    return participants.firstWhere(
      (profile) => profile.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  Future<void> _sendMessage() async {
    final controller = ref.read(
      conversationControllerProvider(widget.conversationId).notifier,
    );
    try {
      await controller.sendMessage(_messageController.text);
      _messageController.clear();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      conversationControllerProvider(widget.conversationId),
    );
    final currentUserId = ref.watch(currentUserIdProvider);
    final onlineIds = ref.watch(presenceControllerProvider);
    final conversation = state.conversation;
    final other = conversation == null
        ? null
        : _otherParticipant(conversation.participants, currentUserId);
    final isOnline = other != null && onlineIds.contains(other.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.messages),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(other?.name ?? 'Konversacio'),
            if (isOnline) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversation == null
                    ? Center(
                        child: Text(
                          state.errorMessage ?? 'Konversacio ne trovita',
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: conversation.messages.length,
                        itemBuilder: (_, index) {
                          final message = conversation.messages[index];
                          final isOwn = message.senderId == currentUserId;
                          return _MessageBubble(message: message, isOwn: isOwn);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Skribu mesaĝon...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: state.isSending ? null : _sendMessage,
                    icon: state.isSending
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;

  const _MessageBubble({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor =
        isOwn ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isOwn ? Colors.white : colorScheme.onSurface;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwn && message.sender != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    avatarUrl: message.sender!.avatarUrl,
                    username: message.sender!.username,
                    radius: 10,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.sender!.name,
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ],
              ),
            if (!isOwn && message.sender != null) const SizedBox(height: 6),
            Text(
              message.content,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(message.createdAt, locale: 'es'),
              style: TextStyle(
                color: textColor.withAlpha(170),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
