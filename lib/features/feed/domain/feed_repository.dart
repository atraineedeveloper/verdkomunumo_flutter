import '../../../models/post.dart';
import 'feed_category.dart';
import 'feed_filter.dart';

class FeedPage {
  final List<Post> posts;
  final bool hasMore;

  const FeedPage({required this.posts, required this.hasMore});
}

abstract class FeedRepository {
  Future<List<FeedCategory>> fetchCategories();

  Future<FeedPage> fetchPosts({
    required FeedFilter filter,
    required String? selectedCategoryId,
    required int page,
    required int pageSize,
  });

  Future<void> createPost({
    required String content,
    required String? categoryId,
    String? imagePath,
  });
}
