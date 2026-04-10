import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_platform_service.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/supabase_notification_preferences_repository.dart';
import '../domain/notification_preferences_repository.dart';
import 'notification_preferences_controller.dart';
import 'notification_preferences_state.dart';

final notificationPlatformServiceProvider =
    Provider<NotificationPlatformService>((ref) {
      return NotificationPlatformService();
    });

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return SupabaseNotificationPreferencesRepository(client);
    });

final notificationPreferencesControllerProvider =
    StateNotifierProvider<
      NotificationPreferencesController,
      NotificationPreferencesState
    >((ref) {
      final repository = ref.watch(notificationPreferencesRepositoryProvider);
      final platformService = ref.watch(notificationPlatformServiceProvider);
      final userId = ref.watch(currentUserIdProvider);
      return NotificationPreferencesController(
        repository,
        platformService,
        userId,
      );
    });
