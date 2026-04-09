import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/comment.dart';
import '../../../models/post.dart';
import '../domain/post_detail_repository.dart';

class SupabasePostDetailRepository implements PostDetailRepository {
  final SupabaseClient _client;

  const SupabasePostDetailRepository(this._client);

  @override
  Future<PostDetailData> fetchPostDetail(String postId) async {
    final postData = await _client
        .from('posts')
        .select('*, author:profiles!user_id(*), category:categories!category_id(name)')
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

    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content.trim(),
    });
  }
}

class PostCommentFailure implements Exception {
  final String message;

  const PostCommentFailure(this.message);

  @override
  String toString() => message;
}
