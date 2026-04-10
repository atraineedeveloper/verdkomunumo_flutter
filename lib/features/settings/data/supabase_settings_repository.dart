import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../../../models/profile.dart';
import '../domain/settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseClient _client;

  const SupabaseSettingsRepository(this._client);

  @override
  Future<Profile?> fetchCurrentProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load the profile right now.',
      );
      throw SettingsFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<Profile> updateProfile({
    required Profile profile,
    required String? displayName,
    required String? bio,
    required String esperantoLevel,
  }) async {
    final normalizedDisplayName = displayName?.trim();
    final normalizedBio = bio?.trim();

    try {
      await _client
          .from('profiles')
          .update({
            'display_name': normalizedDisplayName,
            'bio': normalizedBio,
            'esperanto_level': esperantoLevel,
          })
          .eq('id', profile.id);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to save the profile right now.',
      );
      throw SettingsFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }

    return Profile(
      id: profile.id,
      username: profile.username,
      displayName: normalizedDisplayName,
      bio: normalizedBio,
      avatarUrl: profile.avatarUrl,
      esperantoLevel: esperantoLevel,
      role: profile.role,
      followersCount: profile.followersCount,
      followingCount: profile.followingCount,
      postsCount: profile.postsCount,
      createdAt: profile.createdAt,
    );
  }
}

class SettingsFailure extends AppFailure {
  const SettingsFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
