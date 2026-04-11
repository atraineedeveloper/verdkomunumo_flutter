import 'profile.dart';

class Post {
  final String id;
  final String authorId;
  final String content;
  final String? categoryId;
  final String? categoryName;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final bool isEdited;
  final DateTime createdAt;
  final Profile? author;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.categoryId,
    this.categoryName,
    required this.imageUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.isEdited,
    required this.createdAt,
    this.author,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final authorJson =
        (json['author'] ?? json['profiles']) as Map<String, dynamic>?;
    final categoryJson =
        (json['category'] ?? json['categories']) as Map<String, dynamic>?;

    return Post(
      id: (json['id'] ?? '').toString(),
      authorId: (json['user_id'] ?? json['author_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      categoryId: json['category_id']?.toString(),
      categoryName: categoryJson?['name'] as String?,
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      author: authorJson != null ? Profile.fromJson(authorJson) : null,
    );
  }
}
