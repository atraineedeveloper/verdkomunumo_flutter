import '../../../models/profile.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final Profile? sender;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'] as Map<String, dynamic>?;
    return Message(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      sender: senderJson == null ? null : Profile.fromJson(senderJson),
      content: (json['content'] ?? '').toString(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
