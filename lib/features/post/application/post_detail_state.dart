import '../../../models/comment.dart';
import '../../../models/post.dart';

class PostDetailState {
  final Post? post;
  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const PostDetailState({
    required this.post,
    required this.comments,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  factory PostDetailState.initial() {
    return const PostDetailState(
      post: null,
      comments: [],
      isLoading: true,
      isSubmitting: false,
      errorMessage: null,
    );
  }

  PostDetailState copyWith({
    Object? post = _sentinel,
    List<Comment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
  }) {
    return PostDetailState(
      post: identical(post, _sentinel) ? this.post : post as Post?,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
