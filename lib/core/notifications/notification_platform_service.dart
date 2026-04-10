import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_permission_status.dart';

class NotificationPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'verdkomunumo/notifications',
  );

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (!isSupported) return NotificationPermissionStatus.unsupported;

    final value = await _channel.invokeMethod<String>('getPermissionStatus');
    return notificationPermissionStatusFromValue(value);
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    if (!isSupported) return NotificationPermissionStatus.unsupported;

    final value = await _channel.invokeMethod<String>('requestPermission');
    return notificationPermissionStatusFromValue(value);
  }

  Future<void> openSystemSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openSystemSettings');
  }
}
