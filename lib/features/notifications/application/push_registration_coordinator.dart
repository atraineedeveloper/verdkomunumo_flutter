import '../../../core/notifications/push_token_service.dart';
import '../domain/notification_device_repository.dart';

class PushRegistrationCoordinator {
  final PushTokenService _pushTokenService;
  final NotificationDeviceRepository _deviceRepository;

  const PushRegistrationCoordinator(
    this._pushTokenService,
    this._deviceRepository,
  );

  Future<void> syncForUser(String userId) async {
    final registration = await _pushTokenService.getCurrentRegistration();
    if (registration == null) return;

    await _deviceRepository.upsertDevice(
      userId: userId,
      registration: registration,
    );
  }

  Future<void> disableForUser(String userId) async {
    final registration = await _pushTokenService.getCurrentRegistration();
    if (registration == null) return;

    await _deviceRepository.disableDevice(
      userId: userId,
      pushProvider: registration.pushProvider,
      token: registration.token,
    );
  }

  Future<Stream<String>> tokenRefreshStream() {
    return _pushTokenService.tokenRefreshStream();
  }
}
