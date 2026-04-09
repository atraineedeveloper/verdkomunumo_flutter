import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/post.dart';
import '../../../models/profile.dart';
import '../domain/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  const SupabaseProfileRepository(this._client);

  @override
  Future<ProfileViewData> fetchProfile(String username) async {
    final profileData = await _client
        .from('profiles')
        .select()
        .eq('username', username)
        .single();

    final profile = Profile.fromJson(profileData);

    final postsData = await _client
        .from('posts')
        .select('*, author:profiles!user_id(*), category:categories!category_id(name)')
        .eq('user_id', profile.id)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(30);

    final currentUserId = _client.auth.currentUser?.id;
    var isFollowing = false;

    if (currentUserId != null && currentUserId != profile.id) {
      final followData = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', profile.id)
          .maybeSingle();
      isFollowing = followData != null;
    }

    return ProfileViewData(
      profile: profile,
      posts: postsData.map((json) => Post.fromJson(json)).toList(),
      isFollowing: isFollowing,
    );
  }

  @override
  Future<bool> toggleFollow({
    required String profileId,
    required bool isFollowing,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw const ProfileActionFailure('You must be signed in to follow users.');
    }

    if (isFollowing) {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', profileId);
      return false;
    }

    await _client.from('follows').insert({
      'follower_id': currentUserId,
      'following_id': profileId,
    });
    return true;
  }
}

class ProfileActionFailure implements Exception {
  final String message;

  const ProfileActionFailure(this.message);

  @override
  String toString() => message;
}
