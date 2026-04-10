import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/notifications/application/notification_preferences_providers.dart';
import '../features/notifications/application/notification_preferences_state.dart';
import '../features/notifications/application/push_registration_providers.dart';

class PushNotificationBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const PushNotificationBootstrap({super.key, required this.child});

  @override
  ConsumerState<PushNotificationBootstrap> createState() =>
      _PushNotificationBootstrapState();
}

class _PushNotificationBootstrapState
    extends ConsumerState<PushNotificationBootstrap> {
  ProviderSubscription<String?>? _userSubscription;
  ProviderSubscription<NotificationPreferencesState>? _preferencesSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _syncInProgress = false;

  @override
  void initState() {
    super.initState();

    _userSubscription = ref.listenManual<String?>(currentUserIdProvider, (
      previous,
      next,
    ) {
      if (previous != null && previous != next) {
        unawaited(
          ref
              .read(pushRegistrationCoordinatorProvider)
              .disableForUser(previous),
        );
      }
      unawaited(_syncRegistration());
    }, fireImmediately: true);

    _preferencesSubscription = ref.listenManual<NotificationPreferencesState>(
      notificationPreferencesControllerProvider,
      (previous, next) => unawaited(_syncRegistration()),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startTokenRefreshListener());
      unawaited(_syncRegistration());
    });
  }

  @override
  void dispose() {
    _userSubscription?.close();
    _preferencesSubscription?.close();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startTokenRefreshListener() async {
    final stream = await ref
        .read(pushRegistrationCoordinatorProvider)
        .tokenRefreshStream();

    _tokenRefreshSubscription = stream.listen((_) {
      unawaited(_syncRegistration());
    });
  }

  Future<void> _syncRegistration() async {
    if (_syncInProgress) return;

    _syncInProgress = true;
    try {
      final userId = ref.read(currentUserIdProvider);
      final state = ref.read(notificationPreferencesControllerProvider);
      final coordinator = ref.read(pushRegistrationCoordinatorProvider);

      if (userId == null || state.isLoading) {
        return;
      }

      if (!state.preferences.enabled) {
        await coordinator.disableForUser(userId);
        return;
      }

      await coordinator.syncForUser(userId);
    } finally {
      _syncInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
