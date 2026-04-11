import '../../../models/profile.dart';
import 'message.dart';

class ConversationSummary {
  final String id;
  final List<Profile> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;

  const ConversationSummary({
    required this.id,
    required this.participants,
    required this.unreadCount,
    this.lastMessage,
    this.updatedAt,
  });
}

class ConversationThread {
  final String id;
  final List<Profile> participants;
  final List<Message> messages;

  const ConversationThread({
    required this.id,
    required this.participants,
    required this.messages,
  });
}
