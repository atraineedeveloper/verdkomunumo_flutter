class Profile {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? esperantoLevel;
  final String role;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.esperantoLevel,
    required this.role,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.createdAt,
  });

  String get name => displayName?.isNotEmpty == true ? displayName! : username;

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: (json['id'] ?? '').toString(),
    username: (json['username'] ?? json['display_name'] ?? 'anonima')
        .toString(),
    displayName: json['display_name'] as String?,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    esperantoLevel: json['esperanto_level'] as String?,
    role: json['role'] as String? ?? 'user',
    followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
    followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
    postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
    createdAt: _parseDate(json['created_at']),
  );
}
