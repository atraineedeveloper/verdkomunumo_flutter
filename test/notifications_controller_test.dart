import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/features/notifications/application/notifications_controller.dart';
import 'package:verdkomunumo_flutter/features/notifications/domain/notifications_repository.dart';
import 'package:verdkomunumo_flutter/models/notification.dart';

void main() {
  group('NotificationsController', () {
    late FakeNotificationsRepository repository;
    const userId = 'user-1';

    setUp(() {
      repository = FakeNotificationsRepository();
    });

    test('initial state is correct', () {
      final controller = NotificationsController(repository, userId);
      expect(controller.state.isLoading, isTrue);
      expect(controller.state.notifications, isEmpty);
      expect(controller.state.errorMessage, isNull);
    });

    test('load success updates state correctly', () async {
      final notifications = [
        createNotification(id: '1', isRead: true),
        createNotification(id: '2', isRead: true),
      ];
      repository.notifications = notifications;

      final controller = NotificationsController(repository, userId);
      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.notifications, notifications);
      expect(controller.state.errorMessage, isNull);
    });

    test('load failure sets error message', () async {
      repository.shouldThrowFetch = true;

      final controller = NotificationsController(repository, userId);
      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, 'Ne eblis ŝargi la sciigojn.');
    });

    test('load with null user clears notifications', () async {
      final controller = NotificationsController(repository, null);
      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.notifications, isEmpty);
      expect(controller.state.errorMessage, isNull);
    });

    test('markAllAsRead success updates notifications state', () async {
      final notifications = [
        createNotification(id: '1', isRead: false),
        createNotification(id: '2', isRead: false),
      ];
      repository.notifications = notifications;

      final controller = NotificationsController(repository, userId);
      await controller.load();

      await controller.markAllAsRead();

      expect(controller.state.notifications.every((n) => n.isRead), isTrue);
      expect(controller.state.errorMessage, isNull);
      expect(repository.markAllAsReadCalls, greaterThan(0));
    });

    test('markAllAsRead failure sets error message', () async {
      final notifications = [createNotification(id: '1', isRead: false)];
      repository.notifications = notifications;
      repository.shouldThrowMarkRead = true;

      final controller = NotificationsController(repository, userId);
      await controller.load();

      await controller.markAllAsRead();

      expect(
        controller.state.errorMessage,
        'Ne eblis marki la sciigojn kiel legitajn.',
      );
    });

    testWidgets('load automatically triggers markAllAsRead if unread exists', (
      tester,
    ) async {
      final notifications = [createNotification(id: '1', isRead: false)];
      repository.notifications = notifications;

      final controller = NotificationsController(repository, userId);

      await controller.load();

      // Flush the post frame callbacks
      await tester.pump();

      expect(repository.markAllAsReadCalls, greaterThan(0));
    });
  });
}

class FakeNotificationsRepository implements NotificationsRepository {
  List<AppNotification> notifications = [];
  bool shouldThrowFetch = false;
  bool shouldThrowMarkRead = false;
  int markAllAsReadCalls = 0;

  @override
  Future<List<AppNotification>> fetchNotifications(String userId) async {
    if (shouldThrowFetch) {
      throw Exception('Fetch error');
    }
    return notifications;
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    markAllAsReadCalls++;
    if (shouldThrowMarkRead) {
      throw Exception('Mark read error');
    }
  }
}

AppNotification createNotification({required String id, bool isRead = false}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    type: 'like',
    isRead: isRead,
    createdAt: DateTime.now(),
  );
}
