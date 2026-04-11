import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../../../models/post.dart';
import '../domain/feed_category.dart';
import '../domain/feed_filter.dart';
import '../domain/feed_repository.dart';

class SupabaseFeedRepository implements FeedRepository {
  final SupabaseClient _client;

  const SupabaseFeedRepository(this._client);

  @override
  Future<List<FeedCategory>> fetchCategories() async {
    try {
      final data = await _client
          .from('categories')
          .select('id, name, icon')
          .order('sort_order', ascending: true);

      return data
          .map(
            (json) => FeedCategory(
              id: (json['id'] ?? '').toString(),
              name: (json['name'] ?? 'Kategorio').toString(),
              iconKey: json['icon']?.toString(),
            ),
          )
          .toList();
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load categories right now.',
      );
      throw FeedFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<FeedPage> fetchPosts({
    required FeedFilter filter,
    required String? selectedCategoryId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final followingIds = await _loadFollowingIds(filter);
      if (filter == FeedFilter.following && followingIds.isEmpty) {
        return const FeedPage(posts: [], hasMore: false);
      }

      var query = _client
          .from('posts')
          .select(
            '*, author:profiles!user_id(*), category:categories!category_id(name)',
          )
          .eq('is_deleted', false);

      if (selectedCategoryId != null) {
        query = query.eq('category_id', selectedCategoryId);
      }

      if (followingIds.isNotEmpty) {
        query = query.inFilter('user_id', followingIds);
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;
      final data = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final posts = data.map((json) => Post.fromJson(json)).toList();
      return FeedPage(posts: posts, hasMore: posts.length == pageSize);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load the feed right now.',
      );
      throw FeedFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> createPost({
    required String content,
    required String? categoryId,
    String? imagePath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PostCreationFailure(
        'You must be signed in to create a post.',
      );
    }

    try {
      final imageUrls = <String>[];
      if (imagePath != null && imagePath.isNotEmpty) {
        final extension = _fileExtension(imagePath);
        final objectPath = _buildImagePath(userId, extension);
        final file = File(imagePath);

        await _client.storage.from('post-images').upload(
              objectPath,
              file,
              fileOptions: FileOptions(
                upsert: false,
                contentType: _contentTypeFor(extension),
              ),
            );

        final publicUrl =
            _client.storage.from('post-images').getPublicUrl(objectPath);
        imageUrls.add(publicUrl);
      }

      await _client.from('posts').insert({
        'user_id': userId,
        'content': content,
        'category_id': categoryId,
        'image_urls': imageUrls,
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to create the post right now.',
      );
      throw PostCreationFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  String _fileExtension(String path) {
    final segments = path.split('.');
    if (segments.length < 2) return '';
    return segments.last.toLowerCase();
  }

  String? _contentTypeFor(String extension) {
    if (extension.isEmpty) return null;
    switch (extension) {
      case 'jpg':
        return 'image/jpeg';
      case 'jpeg':
      case 'png':
      case 'webp':
        return 'image/$extension';
      default:
        return null;
    }
  }

  String _buildImagePath(String userId, String extension) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = Random().nextInt(999999);
    final ext = extension.isEmpty ? '' : '.$extension';
    return '$userId/$stamp-$randomSuffix$ext';
  }

  Future<List<String>> _loadFollowingIds(FeedFilter filter) async {
    if (filter != FeedFilter.following) {
      return const [];
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final follows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    return follows.map((row) => row['following_id'] as String).toList();
  }
}

class FeedFailure extends AppFailure {
  const FeedFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}

class PostCreationFailure extends FeedFailure {
  const PostCreationFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
