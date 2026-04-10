import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/notifications/notification_permission_status.dart';
import 'package:verdkomunumo_flutter/core/notifications/notification_platform_service.dart';
import 'package:verdkomunumo_flutter/features/notifications/application/notification_preferences_controller.dart';
import 'package:verdkomunumo_flutter/features/notifications/domain/notification_preferences.dart';
import 'package:verdkomunumo_flutter/features/notifications/domain/notification_preferences_repository.dart';

void main() {
  group('NotificationPreferencesController', () {
    test('load hydrates preferences and permission status', () async {
      final controller = NotificationPreferencesController(
        _FakeNotificationPreferencesRepository(
          storedPreferences: NotificationPreferences.defaults().copyWith(
            enabled: true,
            mentionsEnabled: false,
          ),
        ),
        _FakeNotificationPlatformService(
          permissionStatus: NotificationPermissionStatus.granted,
        ),
        'user-1',
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.preferences.enabled, isTrue);
      expect(controller.state.preferences.mentionsEnabled, isFalse);
      expect(
        controller.state.permissionStatus,
        NotificationPermissionStatus.granted,
      );
    });

    test('toggleNotifications requests permission before enabling', () async {
      final platform = _FakeNotificationPlatformService(
        permissionStatus: NotificationPermissionStatus.notDetermined,
        requestedPermissionStatus: NotificationPermissionStatus.granted,
      );
      final controller = NotificationPreferencesController(
        _FakeNotificationPreferencesRepository(),
        platform,
        'user-1',
      );

      await Future<void>.delayed(Duration.zero);
      await controller.toggleNotifications(true);

      expect(platform.requestPermissionCalls, 1);
      expect(controller.state.preferences.enabled, isTrue);
      expect(
        controller.state.permissionStatus,
        NotificationPermissionStatus.granted,
      );
    });

    test(
      'toggleNotifications keeps disabled state when permission is denied',
      () async {
        final controller = NotificationPreferencesController(
          _FakeNotificationPreferencesRepository(),
          _FakeNotificationPlatformService(
            permissionStatus: NotificationPermissionStatus.denied,
            requestedPermissionStatus: NotificationPermissionStatus.denied,
          ),
          'user-1',
        );

        await Future<void>.delayed(Duration.zero);
        await controller.toggleNotifications(true);

        expect(controller.state.preferences.enabled, isFalse);
        expect(
          controller.state.permissionStatus,
          NotificationPermissionStatus.denied,
        );
        expect(controller.state.errorMessage, isNotNull);
      },
    );

    test('updateChannels persists per-type preferences', () async {
      final controller = NotificationPreferencesController(
        _FakeNotificationPreferencesRepository(
          storedPreferences: NotificationPreferences.defaults().copyWith(
            enabled: true,
          ),
        ),
        _FakeNotificationPlatformService(
          permissionStatus: NotificationPermissionStatus.granted,
        ),
        'user-1',
      );

      await Future<void>.delayed(Duration.zero);
      await controller.updateChannels(
        likesEnabled: false,
        followsEnabled: false,
        messagesEnabled: false,
      );

      expect(controller.state.preferences.likesEnabled, isFalse);
      expect(controller.state.preferences.followsEnabled, isFalse);
      expect(controller.state.preferences.commentsEnabled, isTrue);
      expect(controller.state.preferences.messagesEnabled, isFalse);
    });
  });
}

class _FakeNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  NotificationPreferences storedPreferences;

  _FakeNotificationPreferencesRepository({
    NotificationPreferences? storedPreferences,
  }) : storedPreferences =
           storedPreferences ?? NotificationPreferences.defaults();

  @override
  Future<NotificationPreferences> load(String userId) async =>
      storedPreferences;

  @override
  Future<NotificationPreferences> save(
    String userId,
    NotificationPreferences preferences,
  ) async {
    storedPreferences = preferences;
    return storedPreferences;
  }
}

class _FakeNotificationPlatformService extends NotificationPlatformService {
  NotificationPermissionStatus permissionStatus;
  final NotificationPermissionStatus requestedPermissionStatus;
  int requestPermissionCalls = 0;

  _FakeNotificationPlatformService({
    required this.permissionStatus,
    NotificationPermissionStatus? requestedPermissionStatus,
  }) : requestedPermissionStatus =
           requestedPermissionStatus ?? permissionStatus;

  @override
  bool get isSupported => true;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestPermissionCalls += 1;
    permissionStatus = requestedPermissionStatus;
    return permissionStatus;
  }
}
