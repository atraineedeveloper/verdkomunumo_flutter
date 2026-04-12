import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/error/app_failure.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/messages_repository.dart';
import 'conversation_state.dart';

class ConversationController extends StateNotifier<ConversationState> {
  final MessagesRepository _repository;
  final AnalyticsService _analytics;
  final String conversationId;
  final String? _currentUserId;

  ConversationController(
    this._repository,
    this._analytics,
    this.conversationId,
    this._currentUserId,
  ) : super(ConversationState.initial());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final conversation = await _repository.fetchConversation(conversationId);
      state = state.copyWith(
        isLoading: false,
        conversation: conversation,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ŝargi la konversacion.',
        ),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (state.isSending) return;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(isSending: true, errorMessage: null);
    final optimistic = _buildOptimisticMessage(trimmed);
    if (optimistic != null && state.conversation != null) {
      final messages = [...state.conversation!.messages, optimistic];
      state = state.copyWith(
        conversation: ConversationThread(
          id: state.conversation!.id,
          participants: state.conversation!.participants,
          messages: messages,
        ),
      );
    }
    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        content: trimmed,
      );
      await _analytics.logMessageSent();
      await load();
      state = state.copyWith(isSending: false);
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis sendi la mesaĝon.',
        ),
      );
      rethrow;
    }
  }

  Message? _buildOptimisticMessage(String content) {
    final userId = _currentUserId;
    if (userId == null) return null;
    return Message(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: userId,
      sender: null,
      content: content,
      isRead: true,
      createdAt: DateTime.now(),
    );
  }
}
