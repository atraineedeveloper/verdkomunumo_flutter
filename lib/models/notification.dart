class AppNotification {
  final String id;
  final String userId;
  final String type; // like | comment | follow | mention
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String? postId;
  final String? postContent;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.actorId,
    this.actorUsername,
    this.actorAvatarUrl,
    this.postId,
    this.postContent,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      actorId: actor?['id'] as String?,
      actorUsername: actor?['username'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      postId: json['post_id'] as String?,
      postContent: json['post_content'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get message {
    switch (type) {
      case 'like':
        return '${actorUsername ?? 'Iu'} ŝatis vian afiŝon';
      case 'comment':
        return '${actorUsername ?? 'Iu'} komentis vian afiŝon';
      case 'follow':
        return '${actorUsername ?? 'Iu'} eksekvatas vin';
      case 'mention':
        return '${actorUsername ?? 'Iu'} menciis vin en afiŝo';
      default:
        return 'Nova sciigo';
    }
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? actorId,
    String? actorUsername,
    String? actorAvatarUrl,
    String? postId,
    String? postContent,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      actorUsername: actorUsername ?? this.actorUsername,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      postId: postId ?? this.postId,
      postContent: postContent ?? this.postContent,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
