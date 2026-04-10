import 'notification_preferences.dart';

abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> load(String userId);

  Future<NotificationPreferences> save(
    String userId,
    NotificationPreferences preferences,
  );
}
