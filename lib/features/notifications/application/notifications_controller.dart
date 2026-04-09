import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  final String? _userId;

  NotificationsController(this._repository, this._userId)
      : super(NotificationsState.initial()) {
    load();
  }

  Future<void> load() async {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, notifications: const []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications = await _repository.fetchNotifications(_userId);
      final hasUnread = notifications.any((notification) => !notification.isRead);

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        errorMessage: null,
      );

      if (hasUnread) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          markAllAsRead();
        });
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ne eblis sxargi la sciigojn.',
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null ||
        state.isMarkingRead ||
        state.notifications.every((notification) => notification.isRead)) {
      return;
    }

    state = state.copyWith(isMarkingRead: true);
    try {
      await _repository.markAllAsRead(_userId);
      state = state.copyWith(
        isMarkingRead: false,
        notifications: state.notifications
            .map(
              (notification) => notification.isRead
                  ? notification
                  : notification.copyWith(isRead: true),
            )
            .toList(),
      );
    } catch (_) {
      state = state.copyWith(
        isMarkingRead: false,
        errorMessage: 'Ne eblis marki la sciigojn kiel legitaj.',
      );
    }
  }
}
