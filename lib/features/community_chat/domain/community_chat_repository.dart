import 'community_message.dart';

abstract class CommunityChatRepository {
  Future<List<CommunityMessage>> fetchMessages({required int limit});

  Stream<CommunityMessage> streamMessages();

  Future<void> sendMessage({
    required String content,
    required String clientNonce,
  });
}
