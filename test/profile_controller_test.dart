import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/error/app_failure.dart';
import 'package:verdkomunumo_flutter/features/profile/application/profile_controller.dart';
import 'package:verdkomunumo_flutter/features/profile/domain/profile_repository.dart';
import 'package:verdkomunumo_flutter/models/post.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  group('ProfileController', () {
    test('load populates profile state', () async {
      final profile = _profile(followersCount: 4);
      final controller = ProfileController(
        _FakeProfileRepository(
          viewData: ProfileViewData(
            profile: profile,
            posts: [_post(id: 'post-1')],
            isFollowing: false,
          ),
        ),
        profile.username,
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.profile?.username, profile.username);
      expect(controller.state.posts, hasLength(1));
      expect(controller.state.errorMessage, isNull);
    });

    test('toggleFollow updates following state and follower count', () async {
      final profile = _profile(followersCount: 4);
      final controller = ProfileController(
        _FakeProfileRepository(
          viewData: ProfileViewData(
            profile: profile,
            posts: const [],
            isFollowing: false,
          ),
          toggleFollowResult: true,
        ),
        profile.username,
      );

      await Future<void>.delayed(Duration.zero);
      await controller.toggleFollow();

      expect(controller.state.isFollowing, isTrue);
      expect(controller.state.profile?.followersCount, 5);
      expect(controller.state.errorMessage, isNull);
    });

    test('toggleFollow surfaces AppFailure messages', () async {
      final profile = _profile(followersCount: 4);
      final controller = ProfileController(
        _FakeProfileRepository(
          viewData: ProfileViewData(
            profile: profile,
            posts: const [],
            isFollowing: false,
          ),
          toggleFollowError: const AppFailure('Could not follow user'),
        ),
        profile.username,
      );

      await Future<void>.delayed(Duration.zero);
      await controller.toggleFollow();

      expect(controller.state.isFollowing, isFalse);
      expect(controller.state.errorMessage, 'Could not follow user');
    });
  });
}

class _FakeProfileRepository implements ProfileRepository {
  final ProfileViewData viewData;
  final bool toggleFollowResult;
  final AppFailure? toggleFollowError;

  _FakeProfileRepository({
    required this.viewData,
    this.toggleFollowResult = false,
    this.toggleFollowError,
  });

  @override
  Future<ProfileViewData> fetchProfile(String username) async => viewData;

  @override
  Future<bool> toggleFollow({
    required String profileId,
    required bool isFollowing,
  }) async {
    if (toggleFollowError != null) {
      throw toggleFollowError!;
    }

    return toggleFollowResult;
  }
}

Profile _profile({required int followersCount}) {
  return Profile(
    id: 'profile-1',
    username: 'lina',
    role: 'user',
    followersCount: followersCount,
    followingCount: 3,
    postsCount: 2,
    createdAt: DateTime(2026, 1, 1),
  );
}

Post _post({required String id}) {
  return Post(
    id: id,
    authorId: 'profile-1',
    content: 'Saluton',
    imageUrls: const [],
    likesCount: 0,
    commentsCount: 0,
    isEdited: false,
    createdAt: DateTime(2026, 1, 1),
  );
}
