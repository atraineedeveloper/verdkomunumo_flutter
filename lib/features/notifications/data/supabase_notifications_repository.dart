import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/notification.dart';
import '../domain/notifications_repository.dart';

class SupabaseNotificationsRepository implements NotificationsRepository {
  final SupabaseClient _client;

  const SupabaseNotificationsRepository(this._client);

  @override
  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select('*, actor:profiles!actor_id(id, username, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
