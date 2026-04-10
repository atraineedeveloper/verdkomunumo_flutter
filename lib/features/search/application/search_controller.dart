import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/search_repository.dart';
import 'search_state.dart';

class SearchController extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  int _requestId = 0;

  SearchController(this._repository) : super(SearchState.initial());

  Future<void> search(String rawQuery) async {
    final query = rawQuery.trim();
    final requestId = ++_requestId;

    if (query.isEmpty) {
      state = SearchState.initial();
      return;
    }

    if (query.length < 2) {
      state = state.copyWith(
        query: query,
        isLoading: false,
        posts: const [],
        users: const [],
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(query: query, isLoading: true, errorMessage: null);

    try {
      final results = await _repository.search(query);
      if (requestId != _requestId) return;
      state = state.copyWith(
        posts: results.posts,
        users: results.users,
        isLoading: false,
        query: query,
        errorMessage: null,
      );
    } catch (_) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        query: query,
        errorMessage: 'Ne eblis ŝargi la serĉrezultojn.',
      );
    }
  }

  void clear() {
    _requestId++;
    state = SearchState.initial();
  }
}
