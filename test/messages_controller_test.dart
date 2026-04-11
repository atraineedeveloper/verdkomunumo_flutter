import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/analytics/analytics_service.dart';
import 'package:verdkomunumo_flutter/features/messages/application/messages_controller.dart';
import 'package:verdkomunumo_flutter/features/messages/application/messages_state.dart';
import 'package:verdkomunumo_flutter/features/messages/domain/conversation.dart';
import 'package:verdkomunumo_flutter/features/messages/domain/messages_repository.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  group('MessagesController', () {
    test('load populates conversations', () async {
      final controller = MessagesController(
        _FakeMessagesRepository(
          conversations: [
            ConversationSummary(
              id: 'c1',
              participants: [_profile()],
              unreadCount: 0,
            ),
          ],
        ),
        const AnalyticsService.disabled(),
      );

      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.errorMessage, isNull);
    });

    test('searchUsers updates search results', () async {
      final controller = MessagesController(
        _FakeMessagesRepository(
          searchResults: [_profile(id: 'user-2', username: 'lina')],
        ),
        const AnalyticsService.disabled(),
      );

      await controller.searchUsers('li');

      expect(controller.state.isSearching, isFalse);
      expect(controller.state.searchResults, hasLength(1));
    });

    test('startConversation returns id and refreshes list', () async {
      final repository = _FakeMessagesRepository(
        conversations: const [],
        startConversationId: 'c1',
      );
      final controller = MessagesController(
        repository,
        const AnalyticsService.disabled(),
      );

      final conversationId = await controller.startConversation(_profile());

      expect(conversationId, 'c1');
      expect(controller.state.isStarting, isFalse);
    });
  });
}

class _FakeMessagesRepository implements MessagesRepository {
  final List<ConversationSummary> conversations;
  final List<Profile> searchResults;
  final String startConversationId;

  _FakeMessagesRepository({
    this.conversations = const [],
    this.searchResults = const [],
    this.startConversationId = 'conv-1',
  });

  @override
  Future<List<ConversationSummary>> fetchConversations() async {
    return conversations;
  }

  @override
  Future<ConversationThread> fetchConversation(String conversationId) async {
    return ConversationThread(
      id: conversationId,
      participants: [],
      messages: [],
    );
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {}

  @override
  Future<String> startConversationWithUser(String targetUserId) async {
    return startConversationId;
  }

  @override
  Future<List<Profile>> searchUsers(String query) async {
    return searchResults;
  }
}

Profile _profile({String id = 'user-1', String username = 'ada'}) {
  return Profile(
    id: id,
    username: username,
    displayName: 'Ada',
    bio: null,
    avatarUrl: null,
    esperantoLevel: 'komencanto',
    role: 'user',
    followersCount: 0,
    followingCount: 0,
    postsCount: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}
