class NotificationPreferences {
  final bool enabled;
  final bool likesEnabled;
  final bool commentsEnabled;
  final bool followsEnabled;
  final bool mentionsEnabled;
  final bool messagesEnabled;
  final bool categoryApprovedEnabled;
  final bool categoryRejectedEnabled;

  const NotificationPreferences({
    required this.enabled,
    required this.likesEnabled,
    required this.commentsEnabled,
    required this.followsEnabled,
    required this.mentionsEnabled,
    required this.messagesEnabled,
    required this.categoryApprovedEnabled,
    required this.categoryRejectedEnabled,
  });

  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      enabled: true,
      likesEnabled: false,
      commentsEnabled: true,
      followsEnabled: false,
      mentionsEnabled: true,
      messagesEnabled: true,
      categoryApprovedEnabled: false,
      categoryRejectedEnabled: false,
    );
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? likesEnabled,
    bool? commentsEnabled,
    bool? followsEnabled,
    bool? mentionsEnabled,
    bool? messagesEnabled,
    bool? categoryApprovedEnabled,
    bool? categoryRejectedEnabled,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      likesEnabled: likesEnabled ?? this.likesEnabled,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      followsEnabled: followsEnabled ?? this.followsEnabled,
      mentionsEnabled: mentionsEnabled ?? this.mentionsEnabled,
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      categoryApprovedEnabled:
          categoryApprovedEnabled ?? this.categoryApprovedEnabled,
      categoryRejectedEnabled:
          categoryRejectedEnabled ?? this.categoryRejectedEnabled,
    );
  }
}
