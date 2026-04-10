import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/error/app_failure.dart';
import 'package:verdkomunumo_flutter/features/settings/application/settings_controller.dart';
import 'package:verdkomunumo_flutter/features/settings/domain/settings_repository.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  group('SettingsController', () {
    test('load populates the current profile', () async {
      final profile = _profile();
      final controller = SettingsController(
        _FakeSettingsRepository(currentProfile: profile),
        profile.id,
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.profile?.username, profile.username);
      expect(controller.state.errorMessage, isNull);
    });

    test('load surfaces repository failures', () async {
      final controller = SettingsController(
        _FakeSettingsRepository(
          loadError: const AppFailure('Could not load profile'),
        ),
        'user-1',
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.profile, isNull);
      expect(controller.state.errorMessage, 'Could not load profile');
    });

    test('saveProfile updates state after a successful save', () async {
      final profile = _profile();
      final updatedProfile = _profile(
        displayName: 'Nova Nomo',
        bio: 'Nova bio',
        esperantoLevel: 'flua',
      );
      final repository = _FakeSettingsRepository(
        currentProfile: profile,
        updatedProfile: updatedProfile,
      );
      final controller = SettingsController(repository, profile.id);

      await Future<void>.delayed(Duration.zero);
      await controller.saveProfile(
        profile: profile,
        displayName: 'Nova Nomo',
        bio: 'Nova bio',
        esperantoLevel: 'flua',
      );

      expect(controller.state.isSaving, isFalse);
      expect(controller.state.profile?.displayName, 'Nova Nomo');
      expect(controller.state.profile?.bio, 'Nova bio');
      expect(controller.state.profile?.esperantoLevel, 'flua');
      expect(controller.state.errorMessage, isNull);
      expect(repository.updateCalls, hasLength(1));
    });

    test(
      'saveProfile keeps state consistent and rethrows on failure',
      () async {
        final profile = _profile(displayName: 'Malnova');
        final controller = SettingsController(
          _FakeSettingsRepository(
            currentProfile: profile,
            saveError: const AppFailure('Could not save profile'),
          ),
          profile.id,
        );

        await Future<void>.delayed(Duration.zero);

        await expectLater(
          () => controller.saveProfile(
            profile: profile,
            displayName: 'Nova',
            bio: 'Bio',
            esperantoLevel: 'progresanto',
          ),
          throwsA(isA<AppFailure>()),
        );

        expect(controller.state.isSaving, isFalse);
        expect(controller.state.profile?.displayName, 'Malnova');
        expect(controller.state.errorMessage, 'Could not save profile');
      },
    );
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  final Profile? currentProfile;
  final Profile? updatedProfile;
  final AppFailure? loadError;
  final AppFailure? saveError;
  final List<_UpdateProfileCall> updateCalls = [];

  _FakeSettingsRepository({
    this.currentProfile,
    this.updatedProfile,
    this.loadError,
    this.saveError,
  });

  @override
  Future<Profile?> fetchCurrentProfile(String userId) async {
    if (loadError != null) {
      throw loadError!;
    }
    return currentProfile;
  }

  @override
  Future<Profile> updateProfile({
    required Profile profile,
    required String? displayName,
    required String? bio,
    required String esperantoLevel,
  }) async {
    updateCalls.add(
      _UpdateProfileCall(
        profile: profile,
        displayName: displayName,
        bio: bio,
        esperantoLevel: esperantoLevel,
      ),
    );

    if (saveError != null) {
      throw saveError!;
    }

    return updatedProfile ??
        _profile(
          displayName: displayName,
          bio: bio,
          esperantoLevel: esperantoLevel,
        );
  }
}

class _UpdateProfileCall {
  final Profile profile;
  final String? displayName;
  final String? bio;
  final String esperantoLevel;

  const _UpdateProfileCall({
    required this.profile,
    required this.displayName,
    required this.bio,
    required this.esperantoLevel,
  });
}

Profile _profile({
  String? displayName = 'Lina',
  String? bio = 'Saluton',
  String? esperantoLevel = 'komencanto',
}) {
  return Profile(
    id: 'user-1',
    username: 'lina',
    displayName: displayName,
    bio: bio,
    avatarUrl: null,
    esperantoLevel: esperantoLevel,
    role: 'user',
    followersCount: 3,
    followingCount: 2,
    postsCount: 1,
    createdAt: DateTime(2026, 1, 1),
  );
}
