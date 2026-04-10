import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/error/app_failure.dart';
import 'package:verdkomunumo_flutter/features/feed/application/feed_controller.dart';
import 'package:verdkomunumo_flutter/features/feed/domain/feed_category.dart';
import 'package:verdkomunumo_flutter/features/feed/domain/feed_filter.dart';
import 'package:verdkomunumo_flutter/features/feed/domain/feed_repository.dart';
import 'package:verdkomunumo_flutter/models/post.dart';

void main() {
  group('FeedController', () {
    test('initialize loads categories and first page', () async {
      final repository = _FakeFeedRepository(
        categories: const [FeedCategory(id: 'general', name: 'General')],
        feedPage: FeedPage(posts: [_post(id: 'post-1')], hasMore: true),
      );
      final controller = FeedController(repository);

      await controller.initialize();

      expect(controller.state.categories, hasLength(1));
      expect(controller.state.posts, hasLength(1));
      expect(controller.state.initialized, isTrue);
      expect(controller.state.errorMessage, isNull);
      expect(repository.fetchPostsCalls.single.filter, FeedFilter.all);
    });

    test('refresh surfaces AppFailure messages', () async {
      final controller = FeedController(
        _FakeFeedRepository(
          categories: const [],
          feedError: const AppFailure('Feed unavailable'),
        ),
      );

      await controller.refresh();

      expect(controller.state.isLoadingInitial, isFalse);
      expect(controller.state.errorMessage, 'Feed unavailable');
    });
  });
}

class _FakeFeedRepository implements FeedRepository {
  final List<FeedCategory> categories;
  final FeedPage? feedPage;
  final AppFailure? feedError;
  final List<_FetchPostsCall> fetchPostsCalls = [];

  _FakeFeedRepository({
    required this.categories,
    this.feedPage,
    this.feedError,
  });

  @override
  Future<void> createPost({
    required String content,
    required String? categoryId,
  }) async {}

  @override
  Future<List<FeedCategory>> fetchCategories() async => categories;

  @override
  Future<FeedPage> fetchPosts({
    required FeedFilter filter,
    required String? selectedCategoryId,
    required int page,
    required int pageSize,
  }) async {
    fetchPostsCalls.add(
      _FetchPostsCall(
        filter: filter,
        selectedCategoryId: selectedCategoryId,
        page: page,
        pageSize: pageSize,
      ),
    );

    if (feedError != null) {
      throw feedError!;
    }

    return feedPage ?? const FeedPage(posts: [], hasMore: false);
  }
}

class _FetchPostsCall {
  final FeedFilter filter;
  final String? selectedCategoryId;
  final int page;
  final int pageSize;

  const _FetchPostsCall({
    required this.filter,
    required this.selectedCategoryId,
    required this.page,
    required this.pageSize,
  });
}

Post _post({required String id}) {
  return Post(
    id: id,
    authorId: 'author-1',
    content: 'Saluton',
    imageUrls: const [],
    likesCount: 0,
    commentsCount: 0,
    isEdited: false,
    createdAt: DateTime(2026, 1, 1),
  );
}
