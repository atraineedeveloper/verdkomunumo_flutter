import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/post.dart';
import '../../../models/profile.dart';
import '../domain/search_repository.dart';

class SupabaseSearchRepository implements SearchRepository {
  final SupabaseClient _client;

  const SupabaseSearchRepository(this._client);

  @override
  Future<SearchResults> search(String query) async {
    final postsData = await _client
        .from('posts')
        .select(
          '*, author:profiles!user_id(*), category:categories!category_id(name)',
        )
        .eq('is_deleted', false)
        .ilike('content', '%$query%')
        .order('created_at', ascending: false)
        .limit(30);

    final usersData = await _client
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(20);

    return SearchResults(
      posts: postsData.map((json) => Post.fromJson(json)).toList(),
      users: usersData.map((json) => Profile.fromJson(json)).toList(),
    );
  }
}
