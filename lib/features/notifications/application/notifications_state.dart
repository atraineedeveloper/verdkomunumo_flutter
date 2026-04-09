import '../../../models/notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isMarkingRead;
  final String? errorMessage;

  const NotificationsState({
    required this.notifications,
    required this.isLoading,
    required this.isMarkingRead,
    required this.errorMessage,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      notifications: [],
      isLoading: true,
      isMarkingRead: false,
      errorMessage: null,
    );
  }

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isMarkingRead,
    Object? errorMessage = _sentinel,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isMarkingRead: isMarkingRead ?? this.isMarkingRead,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
