import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../domain/suggestions_repository.dart';

class SuggestionsController extends StateNotifier<AsyncValue<void>> {
  final SuggestionsRepository _repository;
  final AnalyticsService _analytics;

  SuggestionsController(this._repository, this._analytics)
    : super(const AsyncData(null));

  Future<void> submitSuggestion({
    required String title,
    required String description,
    required String context,
  }) {
    return _run(() async {
      await _repository.submitSuggestion(
        title: title,
        description: description,
        context: context,
      );
      await _analytics.logSuggestionSubmitted();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(action);

    if (state.hasError) {
      throw state.error!;
    }
  }
}
