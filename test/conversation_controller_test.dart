import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/analytics/analytics_service.dart';
import 'package:verdkomunumo_flutter/features/messages/application/conversation_controller.dart';
import 'package:verdkomunumo_flutter/features/messages/domain/conversation.dart';
import 'package:verdkomunumo_flutter/features/messages/domain/messages_repository.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  group('ConversationController', () {
    test('load populates conversation', () async {
      final controller = ConversationController(
        _FakeMessagesRepository(),
        const AnalyticsService.disabled(),
        'c1',
        'current-user-id',
      );

      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.conversation?.id, 'c1');
      expect(controller.state.errorMessage, isNull);
    });

    test('sendMessage triggers repository', () async {
      final repository = _FakeMessagesRepository();
      final controller = ConversationController(
        repository,
        const AnalyticsService.disabled(),
        'c1',
        'current-user-id',
      );

      await controller.sendMessage('Saluton');

      expect(repository.sendCalls, 1);
      expect(repository.lastContent, 'Saluton');
    });
  });
}

class _FakeMessagesRepository implements MessagesRepository {
  int sendCalls = 0;
  String? lastContent;

  @override
  Future<List<ConversationSummary>> fetchConversations() async {
    return const [];
  }

  @override
  Future<ConversationThread> fetchConversation(String conversationId) async {
    return ConversationThread(
      id: conversationId,
      participants: [_profile()],
      messages: const [],
    );
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    sendCalls += 1;
    lastContent = content;
  }

  @override
  Future<String> startConversationWithUser(String targetUserId) async {
    return 'c1';
  }

  @override
  Future<List<Profile>> searchUsers(String query) async {
    return const [];
  }
}

Profile _profile() {
  return Profile(
    id: 'user-2',
    username: 'lina',
    displayName: 'Lina',
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
