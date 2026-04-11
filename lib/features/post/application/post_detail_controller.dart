import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
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
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        post: null,
        comments: const [],
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ŝargi la afiŝon.',
        ),
      );
    }
  }

  Future<void> submitComment(String content, {String? parentId}) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.createComment(
        postId: _postId,
        content: normalizedContent,
        parentId: parentId,
      );
      state = state.copyWith(isSubmitting: false);
      await load();
    } on PostCommentFailure {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis sendi la komenton.',
        ),
      );
    }
  }

  Future<void> updatePost(String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.updatePost(postId: _postId, content: normalized);
      state = state.copyWith(isSubmitting: false);
      await load();
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ĝisdatigi la afiŝon.',
        ),
      );
    }
  }

  Future<void> deletePost() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.deletePost(postId: _postId);
      state = state.copyWith(
        isSubmitting: false,
        post: null,
        comments: const [],
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis forigi la afiŝon.',
        ),
      );
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.updateComment(
        commentId: commentId,
        content: normalized,
      );
      state = state.copyWith(isSubmitting: false);
      await load();
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis ĝisdatigi la komenton.',
        ),
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.deleteComment(commentId: commentId);
      state = state.copyWith(isSubmitting: false);
      await load();
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessageOf(
          error,
          fallback: 'Ne eblis forigi la komenton.',
        ),
      );
    }
  }
}
