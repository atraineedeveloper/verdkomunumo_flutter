import '../../../core/notifications/notification_permission_status.dart';
import '../domain/notification_preferences.dart';

class NotificationPreferencesState {
  final NotificationPreferences preferences;
  final NotificationPermissionStatus permissionStatus;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const NotificationPreferencesState({
    required this.preferences,
    required this.permissionStatus,
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
  });

  factory NotificationPreferencesState.initial() {
    return NotificationPreferencesState(
      preferences: NotificationPreferences.defaults(),
      permissionStatus: NotificationPermissionStatus.unsupported,
      isLoading: true,
      isSaving: false,
      errorMessage: null,
    );
  }

  bool get notificationsAvailable =>
      permissionStatus != NotificationPermissionStatus.unsupported;

  bool get canManageChannels => preferences.enabled;

  NotificationPreferencesState copyWith({
    NotificationPreferences? preferences,
    NotificationPermissionStatus? permissionStatus,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _sentinel,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
