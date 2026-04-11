import '../../../models/profile.dart';
import 'conversation.dart';

abstract class MessagesRepository {
  Future<List<ConversationSummary>> fetchConversations();

  Future<ConversationThread> fetchConversation(String conversationId);

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  });

  Future<String> startConversationWithUser(String targetUserId);

  Future<List<Profile>> searchUsers(String query);
}
