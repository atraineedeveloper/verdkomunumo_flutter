import '../../../models/post.dart';
import '../../../models/profile.dart';

class ProfileViewData {
  final Profile profile;
  final List<Post> posts;
  final bool isFollowing;

  const ProfileViewData({
    required this.profile,
    required this.posts,
    required this.isFollowing,
  });
}

abstract class ProfileRepository {
  Future<ProfileViewData> fetchProfile(String username);

  Future<bool> toggleFollow({
    required String profileId,
    required bool isFollowing,
  });
}
