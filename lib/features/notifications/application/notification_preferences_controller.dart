import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_permission_status.dart';
import '../../../core/notifications/notification_platform_service.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_preferences_repository.dart';
import 'notification_preferences_state.dart';

class NotificationPreferencesController
    extends StateNotifier<NotificationPreferencesState> {
  final NotificationPreferencesRepository _repository;
  final NotificationPlatformService _platformService;
  final String? _userId;

  NotificationPreferencesController(
    this._repository,
    this._platformService,
    this._userId,
  ) : super(NotificationPreferencesState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final permissionStatus = await _platformService.getPermissionStatus();
      if (_userId == null) {
        state = state.copyWith(
          preferences: NotificationPreferences.defaults().copyWith(
            enabled: false,
          ),
          permissionStatus: permissionStatus,
          isLoading: false,
          errorMessage: null,
        );
        return;
      }

      final preferences = await _repository.load(_userId);
      state = state.copyWith(
        preferences: preferences,
        permissionStatus: permissionStatus,
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ne eblis ŝargi la sciigajn preferojn.',
      );
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      if (_userId == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Necesas ensaluti por administri sciigojn.',
        );
        return;
      }

      var permissionStatus = await _platformService.getPermissionStatus();

      if (enabled &&
          permissionStatus != NotificationPermissionStatus.granted &&
          permissionStatus != NotificationPermissionStatus.unsupported) {
        permissionStatus = await _platformService.requestPermission();
      }

      final effectiveEnabled =
          enabled &&
          (permissionStatus == NotificationPermissionStatus.granted ||
              permissionStatus == NotificationPermissionStatus.unsupported);

      final nextPreferences = state.preferences.copyWith(
        enabled: effectiveEnabled,
      );
      final savedPreferences = await _repository.save(_userId, nextPreferences);

      state = state.copyWith(
        preferences: savedPreferences,
        permissionStatus: permissionStatus,
        isSaving: false,
        errorMessage: enabled && !effectiveEnabled
            ? 'La sistemo ankoraŭ ne permesas sciigojn por ĉi tiu aplikaĵo.'
            : null,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Ne eblis ĝisdatigi la sciigajn preferojn.',
      );
    }
  }

  Future<void> updateChannels({
    bool? likesEnabled,
    bool? commentsEnabled,
    bool? followsEnabled,
    bool? mentionsEnabled,
    bool? messagesEnabled,
    bool? categoryApprovedEnabled,
    bool? categoryRejectedEnabled,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      if (_userId == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Necesas ensaluti por administri sciigojn.',
        );
        return;
      }

      final nextPreferences = state.preferences.copyWith(
        likesEnabled: likesEnabled,
        commentsEnabled: commentsEnabled,
        followsEnabled: followsEnabled,
        mentionsEnabled: mentionsEnabled,
        messagesEnabled: messagesEnabled,
        categoryApprovedEnabled: categoryApprovedEnabled,
        categoryRejectedEnabled: categoryRejectedEnabled,
      );
      final savedPreferences = await _repository.save(_userId, nextPreferences);
      state = state.copyWith(
        preferences: savedPreferences,
        isSaving: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Ne eblis ĝisdatigi la sciigajn preferojn.',
      );
    }
  }

  Future<void> openSystemSettings() async {
    await _platformService.openSystemSettings();
  }
}
