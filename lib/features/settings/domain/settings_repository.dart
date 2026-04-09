import '../../../models/profile.dart';

abstract class SettingsRepository {
  Future<Profile?> fetchCurrentProfile(String userId);

  Future<Profile> updateProfile({
    required Profile profile,
    required String? displayName,
    required String? bio,
    required String esperantoLevel,
  });
}
