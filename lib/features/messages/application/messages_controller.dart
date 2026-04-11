import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/error/app_failure.dart';
import '../../../models/profile.dart';
import '../domain/messages_repository.dart';
import 'messages_state.dart';

class MessagesController extends StateNotifier<MessagesState> {
  final MessagesRepository _repository;
  final AnalyticsService _analytics;

  MessagesController(this._repository, this._analytics)
    : super(MessagesState.initial());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final conversations = await _repository.fetchConversations();
      state = state.copyWith(
        isLoading: false,
        conversations: conversations,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ŝargi mesaĝojn.',
        ),
      );
    }
  }

  Future<void> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      state = state.copyWith(
        searchQuery: trimmed,
        searchResults: const [],
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(
      searchQuery: trimmed,
      isSearching: true,
      errorMessage: null,
    );

    try {
      final results = await _repository.searchUsers(trimmed);
      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (error) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis serĉi uzantojn.',
        ),
      );
    }
  }

  Future<String?> startConversation(Profile profile) async {
    state = state.copyWith(isStarting: true, errorMessage: null);

    try {
      final conversationId = await _repository.startConversationWithUser(
        profile.id,
      );
      await _analytics.logConversationStarted();
      await load();
      state = state.copyWith(isStarting: false);
      return conversationId;
    } catch (error) {
      state = state.copyWith(
        isStarting: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis komenci konversacion.',
        ),
      );
      rethrow;
    }
  }
}
