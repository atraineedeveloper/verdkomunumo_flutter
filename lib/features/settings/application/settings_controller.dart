import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../models/profile.dart';
import '../domain/settings_repository.dart';
import 'settings_state.dart';

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final String? _userId;

  SettingsController(this._repository, this._userId)
    : super(SettingsState.initial()) {
    load();
  }

  Future<void> load() async {
    if (_userId == null) {
      state = state.copyWith(
        isLoading: false,
        profile: null,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.fetchCurrentProfile(_userId);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ŝargi la profilon.',
        ),
      );
    }
  }

  Future<void> saveProfile({
    required Profile profile,
    required String? displayName,
    required String? bio,
    required String esperantoLevel,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updatedProfile = await _repository.updateProfile(
        profile: profile,
        displayName: displayName,
        bio: bio,
        esperantoLevel: esperantoLevel,
      );
      state = state.copyWith(
        profile: updatedProfile,
        isSaving: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis konservi la profilon.',
        ),
      );
      rethrow;
    }
  }
}
