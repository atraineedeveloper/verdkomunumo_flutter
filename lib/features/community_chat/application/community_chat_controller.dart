import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/error/app_failure.dart';
import '../domain/community_chat_repository.dart';
import '../domain/community_message.dart';
import 'community_chat_state.dart';

class CommunityChatController extends StateNotifier<CommunityChatState> {
  final CommunityChatRepository _repository;
  final AnalyticsService _analytics;
  StreamSubscription<CommunityMessage>? _subscription;

  CommunityChatController(this._repository, this._analytics)
    : super(CommunityChatState.initial());

  Future<void> load({int limit = 50}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final messages = await _repository.fetchMessages(limit: limit);
      state = state.copyWith(isLoading: false, messages: messages);
      _listenRealtime();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ŝargi la komunumon.',
        ),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (state.isSending) return;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(isSending: true, errorMessage: null);
    try {
      final nonce =
          '${DateTime.now().millisecondsSinceEpoch}-${trimmed.hashCode}';
      await _repository.sendMessage(content: trimmed, clientNonce: nonce);
      await _analytics.logCommunityMessageSent();
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

  void _listenRealtime() {
    _subscription?.cancel();
    _subscription = _repository.streamMessages().listen((message) {
      final existing = state.messages;
      if (existing.any((item) => item.id == message.id)) return;
      state = state.copyWith(messages: [...existing, message]);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
