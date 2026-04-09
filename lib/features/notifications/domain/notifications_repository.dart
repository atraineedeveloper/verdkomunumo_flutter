import '../../../models/notification.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> fetchNotifications(String userId);

  Future<void> markAllAsRead(String userId);
}
