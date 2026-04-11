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
          .eq('is_deleted', false)
          .single();

      final commentsData = await _client
          .from('comments')
          .select('*, author:profiles!user_id(*)')
          .eq('post_id', postId)
          .eq('is_deleted', false)
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
    String? parentId,
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
        if (parentId != null) 'parent_id': parentId,
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

  @override
  Future<void> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      await _client.from('posts').update({
        'content': content.trim(),
        'is_edited': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', postId);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to update the post right now.',
      );
      throw PostDetailFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> deletePost({required String postId}) async {
    try {
      await _client.from('posts').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', postId);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to delete the post right now.',
      );
      throw PostDetailFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _client.from('comments').update({
        'content': content.trim(),
        'is_edited': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', commentId);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to update the comment right now.',
      );
      throw PostDetailFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> deleteComment({required String commentId}) async {
    try {
      await _client.from('comments').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', commentId);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to delete the comment right now.',
      );
      throw PostDetailFailure(
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
