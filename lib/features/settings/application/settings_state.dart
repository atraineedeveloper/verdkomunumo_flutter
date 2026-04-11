import '../../../models/profile.dart';

class SettingsState {
  final Profile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const SettingsState({
    required this.profile,
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      profile: null,
      isLoading: true,
      isSaving: false,
      errorMessage: null,
    );
  }

  SettingsState copyWith({
    Object? profile = _sentinel,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _sentinel,
  }) {
    return SettingsState(
      profile: identical(profile, _sentinel)
          ? this.profile
          : profile as Profile?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
