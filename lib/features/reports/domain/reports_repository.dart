abstract class ReportsRepository {
  Future<void> submitPostReport({
    required String postId,
    required String reason,
    required String details,
  });

  Future<void> submitCommentReport({
    required String commentId,
    required String reason,
    required String details,
  });
}
