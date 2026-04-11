import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/features/post_interactions/application/post_interaction_controller.dart';
import 'package:verdkomunumo_flutter/features/post_interactions/domain/post_interactions_repository.dart';

void main() {
  group('PostInteractionController', () {
    test('initial state sets likes count and isLiked defaults to false', () {
      final repository = _FakePostInteractionsRepository();
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      expect(controller.state.likesCount, 5);
      expect(controller.state.isLiked, isFalse);
      expect(controller.state.isLoading, isFalse);
    });

    test('loads liked state on initialization if userId is provided', () async {
      final repository = _FakePostInteractionsRepository(initialIsLiked: true);
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLiked, isTrue);
      expect(repository.isPostLikedCalls, 1);
    });

    test('does not load liked state if userId is null', () async {
      final repository = _FakePostInteractionsRepository();
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: null,
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLiked, isFalse);
      expect(repository.isPostLikedCalls, 0);
    });

    test('swallows error if loading liked state fails', () async {
      final repository = _FakePostInteractionsRepository(
        shouldThrowOnIsLiked: true,
      );
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLiked, isFalse);
      expect(repository.isPostLikedCalls, 1);
    });

    test('toggleLike does nothing if userId is null', () async {
      final repository = _FakePostInteractionsRepository();
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: null,
        initialLikesCount: 5,
      );

      final result = await controller.toggleLike();

      expect(result, isFalse);
      expect(repository.likeCalls, 0);
      expect(repository.unlikeCalls, 0);
    });

    test('toggleLike does nothing if already loading', () async {
      final repository = _FakePostInteractionsRepository(delay: const Duration(milliseconds: 100));
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      // Start first toggle, it will set isLoading to true
      final future1 = controller.toggleLike();

      // Start second toggle while first is still running
      final result2 = await controller.toggleLike();

      expect(result2, isFalse);

      await future1;
      expect(repository.likeCalls, 1); // Only called once
    });

    test('toggleLike optimistically increments likes and calls likePost', () async {
      final repository = _FakePostInteractionsRepository();
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero); // Wait for initial load

      final future = controller.toggleLike();

      // Verify optimistic update
      expect(controller.state.isLoading, isTrue);
      expect(controller.state.isLiked, isTrue);
      expect(controller.state.likesCount, 6);

      final result = await future;

      expect(result, isTrue);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isLiked, isTrue);
      expect(controller.state.likesCount, 6);
      expect(repository.likeCalls, 1);
    });

    test('toggleLike optimistically decrements likes and calls unlikePost', () async {
      final repository = _FakePostInteractionsRepository(initialIsLiked: true);
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero); // Wait for initial load
      expect(controller.state.isLiked, isTrue);

      final future = controller.toggleLike();

      // Verify optimistic update
      expect(controller.state.isLoading, isTrue);
      expect(controller.state.isLiked, isFalse);
      expect(controller.state.likesCount, 4);

      final result = await future;

      expect(result, isTrue);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isLiked, isFalse);
      expect(controller.state.likesCount, 4);
      expect(repository.unlikeCalls, 1);
    });

    test('toggleLike rolls back state if likePost fails', () async {
      final repository = _FakePostInteractionsRepository(shouldThrowOnLike: true);
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero); // Wait for initial load

      final result = await controller.toggleLike();

      expect(result, isFalse);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isLiked, isFalse); // Rolled back
      expect(controller.state.likesCount, 5); // Rolled back
      expect(repository.likeCalls, 1);
    });

    test('toggleLike rolls back state if unlikePost fails', () async {
      final repository = _FakePostInteractionsRepository(
        initialIsLiked: true,
        shouldThrowOnUnlike: true,
      );
      final controller = PostInteractionController(
        repository: repository,
        postId: 'post-1',
        userId: 'user-1',
        initialLikesCount: 5,
      );

      await Future<void>.delayed(Duration.zero); // Wait for initial load
      expect(controller.state.isLiked, isTrue);

      final result = await controller.toggleLike();

      expect(result, isFalse);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isLiked, isTrue); // Rolled back
      expect(controller.state.likesCount, 5); // Rolled back
      expect(repository.unlikeCalls, 1);
    });
  });
}

class _FakePostInteractionsRepository implements PostInteractionsRepository {
  final bool initialIsLiked;
  final bool shouldThrowOnIsLiked;
  final bool shouldThrowOnLike;
  final bool shouldThrowOnUnlike;
  final Duration delay;

  int isPostLikedCalls = 0;
  int likeCalls = 0;
  int unlikeCalls = 0;

  _FakePostInteractionsRepository({
    this.initialIsLiked = false,
    this.shouldThrowOnIsLiked = false,
    this.shouldThrowOnLike = false,
    this.shouldThrowOnUnlike = false,
    this.delay = Duration.zero,
  });

  @override
  Future<bool> isPostLiked({required String postId, required String userId}) async {
    isPostLikedCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowOnIsLiked) throw Exception('Failed to check like status');
    return initialIsLiked;
  }

  @override
  Future<void> likePost({required String postId, required String userId}) async {
    likeCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowOnLike) throw Exception('Failed to like post');
  }

  @override
  Future<void> unlikePost({required String postId, required String userId}) async {
    unlikeCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowOnUnlike) throw Exception('Failed to unlike post');
  }
}
