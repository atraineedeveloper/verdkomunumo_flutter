import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/analytics/analytics_service.dart';
import 'package:verdkomunumo_flutter/features/community_chat/application/community_chat_controller.dart';
import 'package:verdkomunumo_flutter/features/community_chat/domain/community_chat_repository.dart';
import 'package:verdkomunumo_flutter/features/community_chat/domain/community_message.dart';

void main() {
  group('CommunityChatController', () {
    test('load populates messages', () async {
      final controller = CommunityChatController(
        _FakeCommunityChatRepository(),
        const AnalyticsService.disabled(),
      );

      await controller.load(limit: 10);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.messages, hasLength(1));
    });

    test('sendMessage delegates to repository', () async {
      final repository = _FakeCommunityChatRepository();
      final controller = CommunityChatController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.sendMessage('Saluton');

      expect(repository.sendCalls, 1);
      expect(repository.lastContent, 'Saluton');
    });
  });
}

class _FakeCommunityChatRepository implements CommunityChatRepository {
  int sendCalls = 0;
  String? lastContent;
  final _controller = StreamController<CommunityMessage>.broadcast();

  @override
  Future<List<CommunityMessage>> fetchMessages({required int limit}) async {
    return [
      CommunityMessage(
        id: 'm1',
        userId: 'u1',
        content: 'Saluton',
        isDeleted: false,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Stream<CommunityMessage> streamMessages() => _controller.stream;

  @override
  Future<void> sendMessage({
    required String content,
    required String clientNonce,
  }) async {
    sendCalls += 1;
    lastContent = content;
  }
}
