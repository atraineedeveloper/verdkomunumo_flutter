import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_post_detail_repository.dart';
import '../domain/post_detail_repository.dart';
import 'post_detail_state.dart';

class PostDetailController extends StateNotifier<PostDetailState> {
  final PostDetailRepository _repository;
  final String _postId;

  PostDetailController(this._repository, this._postId)
      : super(PostDetailState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.fetchPostDetail(_postId);
      state = state.copyWith(
        post: result.post,
        comments: result.comments,
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        post: null,
        comments: const [],
        errorMessage: 'Ne eblis sxargi la afisxon.',
      );
    }
  }

  Future<void> submitComment(String content) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.createComment(
        postId: _postId,
        content: normalizedContent,
      );
      state = state.copyWith(isSubmitting: false);
      await load();
    } on PostCommentFailure {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Ne eblis sendi la komenton.',
      );
    }
  }
}
