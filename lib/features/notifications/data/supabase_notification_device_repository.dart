import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../../../core/notifications/push_token_registration.dart';
import '../domain/notification_device_repository.dart';

class SupabaseNotificationDeviceRepository
    implements NotificationDeviceRepository {
  final SupabaseClient _client;

  const SupabaseNotificationDeviceRepository(this._client);

  @override
  Future<void> upsertDevice({
    required String userId,
    required PushTokenRegistration registration,
  }) async {
    try {
      await _client.from('notification_devices').upsert({
        'user_id': userId,
        'platform': registration.platform,
        'push_provider': registration.pushProvider,
        'token': registration.token,
        'locale': registration.locale,
        'timezone': registration.timezone,
        'is_enabled': true,
        'revoked_at': null,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'push_provider,token');
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to register the push device right now.',
      );
      throw NotificationDeviceFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> disableDevice({
    required String userId,
    required String pushProvider,
    required String token,
  }) async {
    try {
      await _client
          .from('notification_devices')
          .update({
            'is_enabled': false,
            'revoked_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('push_provider', pushProvider)
          .eq('token', token);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to disable the push device right now.',
      );
      throw NotificationDeviceFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class NotificationDeviceFailure extends AppFailure {
  const NotificationDeviceFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
