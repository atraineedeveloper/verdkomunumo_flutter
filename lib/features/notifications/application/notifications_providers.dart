import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/supabase_notifications_repository.dart';
import '../domain/notifications_repository.dart';
import 'notifications_controller.dart';
import 'notifications_state.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseNotificationsRepository(client);
});

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return NotificationsController(repository, userId);
});
