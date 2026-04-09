import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/post_interactions_repository.dart';

class SupabasePostInteractionsRepository implements PostInteractionsRepository {
  final SupabaseClient _client;

  const SupabasePostInteractionsRepository(this._client);

  @override
  Future<bool> isPostLiked({
    required String postId,
    required String userId,
  }) async {
    final result = await _client
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();
    return result != null;
  }

  @override
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    await _client.from('likes').insert({
      'user_id': userId,
      'post_id': postId,
    });
  }

  @override
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    await _client
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);
  }
}
