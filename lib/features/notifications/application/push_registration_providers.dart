import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/push_token_service.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_notification_device_repository.dart';
import '../domain/notification_device_repository.dart';
import 'push_registration_coordinator.dart';

final pushTokenServiceProvider = Provider<PushTokenService>((ref) {
  return PushTokenService();
});

final notificationDeviceRepositoryProvider =
    Provider<NotificationDeviceRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return SupabaseNotificationDeviceRepository(client);
    });

final pushRegistrationCoordinatorProvider =
    Provider<PushRegistrationCoordinator>((ref) {
      final pushTokenService = ref.watch(pushTokenServiceProvider);
      final deviceRepository = ref.watch(notificationDeviceRepositoryProvider);
      return PushRegistrationCoordinator(pushTokenService, deviceRepository);
    });
