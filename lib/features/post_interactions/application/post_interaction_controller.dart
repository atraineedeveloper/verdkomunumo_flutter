import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/post_interactions_repository.dart';
import 'post_interaction_state.dart';

class PostInteractionController extends StateNotifier<PostInteractionState> {
  final PostInteractionsRepository _repository;
  final String _postId;
  final String? _userId;

  PostInteractionController({
    required PostInteractionsRepository repository,
    required String postId,
    required String? userId,
    required int initialLikesCount,
  }) : _repository = repository,
       _postId = postId,
       _userId = userId,
       super(PostInteractionState.initial(initialLikesCount)) {
    _loadLikedState();
  }

  Future<void> _loadLikedState() async {
    if (_userId == null) return;

    try {
      final isLiked = await _repository.isPostLiked(
        postId: _postId,
        userId: _userId,
      );
      state = state.copyWith(isLiked: isLiked);
    } catch (_) {
      // Keep the UI usable even if the remote like lookup fails.
    }
  }

  Future<bool> toggleLike() async {
    final userId = _userId;
    if (userId == null || state.isLoading) return false;

    final previousState = state;
    state = state.copyWith(
      isLoading: true,
      isLiked: !state.isLiked,
      likesCount: state.isLiked
          ? (state.likesCount - 1).clamp(0, 1 << 31)
          : state.likesCount + 1,
    );

    try {
      if (previousState.isLiked) {
        await _repository.unlikePost(postId: _postId, userId: userId);
      } else {
        await _repository.likePost(postId: _postId, userId: userId);
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (_) {
      state = previousState.copyWith(isLoading: false);
      return false;
    }
  }
}
