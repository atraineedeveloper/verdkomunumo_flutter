import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';
import 'profile_state.dart';

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final String _username;

  ProfileController(this._repository, this._username)
      : super(ProfileState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.fetchProfile(_username);
      state = state.copyWith(
        isLoading: false,
        profile: result.profile,
        posts: result.posts,
        isFollowing: result.isFollowing,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        profile: null,
        posts: const [],
        errorMessage: 'Ne eblis sxargi la profilon.',
      );
    }
  }

  Future<void> toggleFollow() async {
    final profile = state.profile;
    if (profile == null || state.isFollowLoading) return;

    state = state.copyWith(isFollowLoading: true);
    try {
      final isFollowing = await _repository.toggleFollow(
        profileId: profile.id,
        isFollowing: state.isFollowing,
      );
      state = state.copyWith(
        isFollowLoading: false,
        isFollowing: isFollowing,
        profile: _updatedProfile(profile, isFollowing),
      );
    } on ProfileActionFailure catch (error) {
      state = state.copyWith(
        isFollowLoading: false,
        errorMessage: error.message,
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        isFollowLoading: false,
        errorMessage: 'Ne eblis sxangxi la sekvadon.',
      );
    }
  }

  Profile _updatedProfile(Profile profile, bool isFollowing) {
    final followersCount = isFollowing
        ? profile.followersCount + 1
        : (profile.followersCount - 1).clamp(0, 1 << 31);

    return Profile(
      id: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      esperantoLevel: profile.esperantoLevel,
      role: profile.role,
      followersCount: followersCount,
      followingCount: profile.followingCount,
      postsCount: profile.postsCount,
      createdAt: profile.createdAt,
    );
  }
}
