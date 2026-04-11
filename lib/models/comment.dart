import 'profile.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String? parentId;
  final String content;
  final int likesCount;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Profile? author;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentId,
    required this.content,
    required this.likesCount,
    required this.isEdited,
    required this.createdAt,
    this.updatedAt,
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
      parentId: json['parent_id']?.toString(),
      content: (json['content'] ?? '').toString(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : _parseDate(json['updated_at']),
      author: authorJson != null ? Profile.fromJson(authorJson) : null,
    );
  }
}
