import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/error/app_failure.dart';
import 'package:verdkomunumo_flutter/features/post/application/post_detail_controller.dart';
import 'package:verdkomunumo_flutter/features/post/data/supabase_post_detail_repository.dart';
import 'package:verdkomunumo_flutter/features/post/domain/post_detail_repository.dart';
import 'package:verdkomunumo_flutter/models/comment.dart';
import 'package:verdkomunumo_flutter/models/post.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  group('PostDetailController', () {
    test('load populates post and comments', () async {
      final controller = PostDetailController(
        _FakePostDetailRepository(
          data: PostDetailData(
            post: _post(),
            comments: [_comment(id: 'comment-1')],
          ),
        ),
        'post-1',
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.post?.id, 'post-1');
      expect(controller.state.comments, hasLength(1));
      expect(controller.state.errorMessage, isNull);
    });

    test('load surfaces repository failures', () async {
      final controller = PostDetailController(
        _FakePostDetailRepository(
          loadError: const AppFailure('Could not load post'),
        ),
        'post-1',
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.post, isNull);
      expect(controller.state.comments, isEmpty);
      expect(controller.state.errorMessage, 'Could not load post');
    });

    test('submitComment ignores blank content', () async {
      final repository = _FakePostDetailRepository(
        data: PostDetailData(post: _post(), comments: const []),
      );
      final controller = PostDetailController(repository, 'post-1');

      await Future<void>.delayed(Duration.zero);
      await controller.submitComment('   ');

      expect(repository.createCommentCalls, isEmpty);
      expect(repository.fetchCalls, 1);
      expect(controller.state.isSubmitting, isFalse);
    });

    test('submitComment creates a comment and reloads the detail', () async {
      final repository = _FakePostDetailRepository(
        data: PostDetailData(
          post: _post(),
          comments: [_comment(id: 'comment-1')],
        ),
      );
      final controller = PostDetailController(repository, 'post-1');

      await Future<void>.delayed(Duration.zero);
      await controller.submitComment('Nova komento');

      expect(repository.createCommentCalls, hasLength(1));
      expect(repository.fetchCalls, 2);
      expect(controller.state.comments, hasLength(1));
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test(
      'submitComment stores the failure message for generic errors',
      () async {
        final repository = _FakePostDetailRepository(
          data: PostDetailData(post: _post(), comments: const []),
          createCommentError: const AppFailure('Could not send comment'),
        );
        final controller = PostDetailController(repository, 'post-1');

        await Future<void>.delayed(Duration.zero);
        await controller.submitComment('Nova komento');

        expect(controller.state.isSubmitting, isFalse);
        expect(controller.state.errorMessage, 'Could not send comment');
      },
    );

    test(
      'submitComment rethrows PostCommentFailure and resets submitting',
      () async {
        final repository = _FakePostDetailRepository(
          data: PostDetailData(post: _post(), comments: const []),
          createCommentError: const PostCommentFailure('Comment blocked'),
        );
        final controller = PostDetailController(repository, 'post-1');

        await Future<void>.delayed(Duration.zero);

        await expectLater(
          () => controller.submitComment('Nova komento'),
          throwsA(isA<PostCommentFailure>()),
        );

        expect(controller.state.isSubmitting, isFalse);
      },
    );
  });
}

class _FakePostDetailRepository implements PostDetailRepository {
  final PostDetailData? data;
  final Object? loadError;
  final Object? createCommentError;
  final List<_CreateCommentCall> createCommentCalls = [];
  int fetchCalls = 0;

  _FakePostDetailRepository({
    this.data,
    this.loadError,
    this.createCommentError,
  });

  @override
  Future<void> createComment({
    required String postId,
    required String content,
  }) async {
    createCommentCalls.add(
      _CreateCommentCall(postId: postId, content: content),
    );

    if (createCommentError != null) {
      throw createCommentError!;
    }
  }

  @override
  Future<PostDetailData> fetchPostDetail(String postId) async {
    fetchCalls += 1;

    if (loadError != null) {
      throw loadError!;
    }

    return data ?? PostDetailData(post: _post(), comments: const []);
  }
}

class _CreateCommentCall {
  final String postId;
  final String content;

  const _CreateCommentCall({required this.postId, required this.content});
}

Profile _profile() {
  return Profile(
    id: 'user-1',
    username: 'lina',
    displayName: 'Lina',
    role: 'user',
    followersCount: 3,
    followingCount: 2,
    postsCount: 1,
    createdAt: DateTime(2026, 1, 1),
  );
}

Post _post() {
  return Post(
    id: 'post-1',
    authorId: 'user-1',
    content: 'Saluton',
    imageUrls: const [],
    likesCount: 2,
    commentsCount: 1,
    isEdited: false,
    createdAt: DateTime(2026, 1, 1),
    author: _profile(),
  );
}

Comment _comment({required String id}) {
  return Comment(
    id: id,
    postId: 'post-1',
    authorId: 'user-1',
    content: 'Bonega afiŝo',
    likesCount: 0,
    createdAt: DateTime(2026, 1, 1),
    author: _profile(),
  );
}
