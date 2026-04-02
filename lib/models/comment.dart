import 'profile.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final Profile? author;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    this.author,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    final authorJson =
        (json['author'] ?? json['profiles']) as Map<String, dynamic>?;
    return Comment(
      id: (json['id'] ?? '').toString(),
      postId: (json['post_id'] ?? '').toString(),
      authorId: (json['user_id'] ?? json['author_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      author: authorJson != null ? Profile.fromJson(authorJson) : null,
    );
  }
}
