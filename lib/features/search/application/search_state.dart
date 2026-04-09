import '../../../models/post.dart';
import '../../../models/profile.dart';

class SearchState {
  final List<Post> posts;
  final List<Profile> users;
  final bool isLoading;
  final String query;
  final String? errorMessage;

  const SearchState({
    required this.posts,
    required this.users,
    required this.isLoading,
    required this.query,
    required this.errorMessage,
  });

  factory SearchState.initial() {
    return const SearchState(
      posts: [],
      users: [],
      isLoading: false,
      query: '',
      errorMessage: null,
    );
  }

  SearchState copyWith({
    List<Post>? posts,
    List<Profile>? users,
    bool? isLoading,
    String? query,
    Object? errorMessage = _sentinel,
  }) {
    return SearchState(
      posts: posts ?? this.posts,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
