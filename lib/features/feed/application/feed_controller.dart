import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_filter.dart';
import '../domain/feed_repository.dart';
import 'feed_state.dart';

class FeedController extends StateNotifier<FeedState> {
  final FeedRepository _repository;
  static const int pageSize = 20;

  FeedController(this._repository) : super(FeedState.initial());

  Future<void> initialize() async {
    if (state.initialized) return;
    await Future.wait([
      _loadCategories(),
      refresh(),
    ]);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoadingInitial: true,
      isLoadingMore: false,
      hasMore: true,
      page: 0,
      posts: [],
      errorMessage: null,
    );

    try {
      final result = await _repository.fetchPosts(
        filter: state.filter,
        selectedCategoryId: state.selectedCategoryId,
        page: 0,
        pageSize: pageSize,
      );

      state = state.copyWith(
        posts: result.posts,
        hasMore: result.hasMore,
        isLoadingInitial: false,
        initialized: true,
        page: 1,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingInitial: false,
        initialized: true,
        errorMessage: 'Ne eblis sxargi la feed-on.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.fetchPosts(
        filter: state.filter,
        selectedCategoryId: state.selectedCategoryId,
        page: state.page,
        pageSize: pageSize,
      );

      state = state.copyWith(
        posts: [...state.posts, ...result.posts],
        page: state.page + 1,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> setFilter(FeedFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    await refresh();
  }

  Future<void> toggleCategory(String id) async {
    final nextId = state.selectedCategoryId == id ? null : id;
    state = state.copyWith(selectedCategoryId: nextId);
    await refresh();
  }

  Future<void> createPost({
    required String content,
    required String? categoryId,
  }) async {
    await _repository.createPost(content: content, categoryId: categoryId);
    await refresh();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.fetchCategories();
      state = state.copyWith(categories: categories);
    } catch (_) {
      state = state.copyWith(categories: const []);
    }
  }
}
