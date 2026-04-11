import '../../../models/profile.dart';

class CommunityMessage {
  final String id;
  final String userId;
  final Profile? author;
  final String content;
  final String? clientNonce;
  final bool isDeleted;
  final DateTime createdAt;

  const CommunityMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.isDeleted,
    required this.createdAt,
    this.clientNonce,
    this.author,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return CommunityMessage(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      clientNonce: json['client_nonce']?.toString(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: authorJson == null ? null : Profile.fromJson(authorJson),
    );
  }
}
