import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/analytics/analytics_service.dart';
import 'package:verdkomunumo_flutter/features/reports/application/reports_controller.dart';
import 'package:verdkomunumo_flutter/features/reports/domain/reports_repository.dart';

void main() {
  group('ReportsController', () {
    test('submitPostReport delegates to repository', () async {
      final repository = _FakeReportsRepository();
      final controller = ReportsController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.submitPostReport(
        postId: 'p1',
        reason: 'spam',
        details: 'test',
      );

      expect(repository.postCalls, 1);
      expect(repository.lastPostId, 'p1');
    });

    test('submitCommentReport delegates to repository', () async {
      final repository = _FakeReportsRepository();
      final controller = ReportsController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.submitCommentReport(
        commentId: 'c1',
        reason: 'other',
        details: '',
      );

      expect(repository.commentCalls, 1);
      expect(repository.lastCommentId, 'c1');
    });
  });
}

class _FakeReportsRepository implements ReportsRepository {
  int postCalls = 0;
  int commentCalls = 0;
  String? lastPostId;
  String? lastCommentId;

  @override
  Future<void> submitPostReport({
    required String postId,
    required String reason,
    required String details,
  }) async {
    postCalls += 1;
    lastPostId = postId;
  }

  @override
  Future<void> submitCommentReport({
    required String commentId,
    required String reason,
    required String details,
  }) async {
    commentCalls += 1;
    lastCommentId = commentId;
  }
}
