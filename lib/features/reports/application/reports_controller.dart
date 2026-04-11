import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../domain/reports_repository.dart';

class ReportsController extends StateNotifier<AsyncValue<void>> {
  final ReportsRepository _repository;
  final AnalyticsService _analytics;

  ReportsController(this._repository, this._analytics)
    : super(const AsyncData(null));

  Future<void> submitPostReport({
    required String postId,
    required String reason,
    required String details,
  }) {
    return _run(() async {
      await _repository.submitPostReport(
        postId: postId,
        reason: reason,
        details: details,
      );
      await _analytics.logReportSubmitted(targetType: 'post');
    });
  }

  Future<void> submitCommentReport({
    required String commentId,
    required String reason,
    required String details,
  }) {
    return _run(() async {
      await _repository.submitCommentReport(
        commentId: commentId,
        reason: reason,
        details: details,
      );
      await _analytics.logReportSubmitted(targetType: 'comment');
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
