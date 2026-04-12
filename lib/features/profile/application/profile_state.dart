import '../../../models/post.dart';
import '../../../models/profile.dart';

class ProfileState {
  final bool isLoading;
  final bool isFollowLoading;
  final Profile? profile;
  final List<Post> posts;
  final bool isFollowing;
  final String? errorMessage;

  const ProfileState({
    required this.isLoading,
    required this.isFollowLoading,
    required this.profile,
    required this.posts,
    required this.isFollowing,
    required this.errorMessage,
  });

  factory ProfileState.initial() {
    return const ProfileState(
      isLoading: true,
      isFollowLoading: false,
      profile: null,
      posts: [],
      isFollowing: false,
      errorMessage: null,
    );
  }

  ProfileState copyWith({
    bool? isLoading,
    bool? isFollowLoading,
    Object? profile = _sentinel,
    List<Post>? posts,
    bool? isFollowing,
    Object? errorMessage = _sentinel,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isFollowLoading: isFollowLoading ?? this.isFollowLoading,
      profile: identical(profile, _sentinel)
          ? this.profile
          : profile as Profile?,
      posts: posts ?? this.posts,
      isFollowing: isFollowing ?? this.isFollowing,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
