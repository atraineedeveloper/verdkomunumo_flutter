import '../../../models/post.dart';
import '../domain/feed_category.dart';
import '../domain/feed_filter.dart';

class FeedState {
  final List<Post> posts;
  final List<FeedCategory> categories;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final FeedFilter filter;
  final String? selectedCategoryId;
  final String? errorMessage;
  final bool initialized;
  final int page;

  const FeedState({
    required this.posts,
    required this.categories,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.hasMore,
    required this.filter,
    required this.selectedCategoryId,
    required this.errorMessage,
    required this.initialized,
    required this.page,
  });

  factory FeedState.initial() {
    return const FeedState(
      posts: [],
      categories: [],
      isLoadingInitial: true,
      isLoadingMore: false,
      hasMore: true,
      filter: FeedFilter.all,
      selectedCategoryId: null,
      errorMessage: null,
      initialized: false,
      page: 0,
    );
  }

  FeedState copyWith({
    List<Post>? posts,
    List<FeedCategory>? categories,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    FeedFilter? filter,
    Object? selectedCategoryId = _sentinel,
    Object? errorMessage = _sentinel,
    bool? initialized,
    int? page,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      categories: categories ?? this.categories,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      selectedCategoryId: identical(selectedCategoryId, _sentinel)
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      initialized: initialized ?? this.initialized,
      page: page ?? this.page,
    );
  }
}

const _sentinel = Object();
