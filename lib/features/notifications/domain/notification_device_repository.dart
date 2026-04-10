import '../../../core/notifications/push_token_registration.dart';

abstract class NotificationDeviceRepository {
  Future<void> upsertDevice({
    required String userId,
    required PushTokenRegistration registration,
  });

  Future<void> disableDevice({
    required String userId,
    required String pushProvider,
    required String token,
  });
}
