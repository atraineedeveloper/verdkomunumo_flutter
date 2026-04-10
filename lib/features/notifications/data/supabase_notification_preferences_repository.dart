import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_preferences_repository.dart';

class SupabaseNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  final SupabaseClient _client;

  const SupabaseNotificationPreferencesRepository(this._client);

  @override
  Future<NotificationPreferences> load(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('''
            push_notifications_enabled,
            push_notify_like,
            push_notify_comment,
            push_notify_follow,
            push_notify_message,
            push_notify_mention,
            push_notify_category_approved,
            push_notify_category_rejected
            ''')
          .eq('id', userId)
          .single();

      return NotificationPreferences(
        enabled: data['push_notifications_enabled'] as bool? ?? true,
        likesEnabled: data['push_notify_like'] as bool? ?? false,
        commentsEnabled: data['push_notify_comment'] as bool? ?? true,
        followsEnabled: data['push_notify_follow'] as bool? ?? false,
        mentionsEnabled: data['push_notify_mention'] as bool? ?? true,
        messagesEnabled: data['push_notify_message'] as bool? ?? true,
        categoryApprovedEnabled:
            data['push_notify_category_approved'] as bool? ?? false,
        categoryRejectedEnabled:
            data['push_notify_category_rejected'] as bool? ?? false,
      );
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load notification preferences right now.',
      );
      throw NotificationPreferencesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<NotificationPreferences> save(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _client
          .from('profiles')
          .update({
            'push_notifications_enabled': preferences.enabled,
            'push_notify_like': preferences.likesEnabled,
            'push_notify_comment': preferences.commentsEnabled,
            'push_notify_follow': preferences.followsEnabled,
            'push_notify_message': preferences.messagesEnabled,
            'push_notify_mention': preferences.mentionsEnabled,
            'push_notify_category_approved':
                preferences.categoryApprovedEnabled,
            'push_notify_category_rejected':
                preferences.categoryRejectedEnabled,
          })
          .eq('id', userId);

      return preferences;
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to save notification preferences right now.',
      );
      throw NotificationPreferencesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class NotificationPreferencesFailure extends AppFailure {
  const NotificationPreferencesFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
