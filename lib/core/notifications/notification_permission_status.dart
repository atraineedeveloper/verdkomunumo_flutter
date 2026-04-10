enum NotificationPermissionStatus {
  unsupported,
  notDetermined,
  denied,
  granted,
}

NotificationPermissionStatus notificationPermissionStatusFromValue(
  String? value,
) {
  switch (value) {
    case 'granted':
      return NotificationPermissionStatus.granted;
    case 'denied':
      return NotificationPermissionStatus.denied;
    case 'notDetermined':
      return NotificationPermissionStatus.notDetermined;
    default:
      return NotificationPermissionStatus.unsupported;
  }
}
