import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../../../models/comment.dart';
import '../../../models/post.dart';
import '../domain/post_detail_repository.dart';

class SupabasePostDetailRepository implements PostDetailRepository {
  final SupabaseClient _client;

  const SupabasePostDetailRepository(this._client);

  @override
  Future<PostDetailData> fetchPostDetail(String postId) async {
    try {
      final postData = await _client
          .from('posts')
          .select(
            '*, author:profiles!user_id(*), category:categories!category_id(name)',
          )
          .eq('id', postId)
          .single();

      final commentsData = await _client
          .from('comments')
          .select('*, author:profiles!user_id(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return PostDetailData(
        post: Post.fromJson(postData),
        comments: commentsData.map((json) => Comment.fromJson(json)).toList(),
      );
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load the post right now.',
      );
      throw PostDetailFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> createComment({
    required String postId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PostCommentFailure(
        'You must be signed in to comment on a post.',
      );
    }

    try {
      await _client.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content.trim(),
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to send the comment right now.',
      );
      throw PostCommentFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class PostDetailFailure extends AppFailure {
  const PostDetailFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}

class PostCommentFailure extends PostDetailFailure {
  const PostCommentFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
