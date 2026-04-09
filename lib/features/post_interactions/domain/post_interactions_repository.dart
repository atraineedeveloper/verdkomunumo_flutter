abstract class PostInteractionsRepository {
  Future<bool> isPostLiked({
    required String postId,
    required String userId,
  });

  Future<void> likePost({
    required String postId,
    required String userId,
  });

  Future<void> unlikePost({
    required String postId,
    required String userId,
  });
}
