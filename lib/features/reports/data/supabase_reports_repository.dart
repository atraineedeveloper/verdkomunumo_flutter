import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../domain/reports_repository.dart';

class SupabaseReportsRepository implements ReportsRepository {
  final SupabaseClient _client;

  const SupabaseReportsRepository(this._client);

  @override
  Future<void> submitPostReport({
    required String postId,
    required String reason,
    required String details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ReportsFailure('You must be signed in.');
    }

    try {
      await _client.from('content_reports').insert({
        'user_id': userId,
        'post_id': postId,
        'reason': reason,
        'details': details.trim(),
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to send the report right now.',
      );
      throw ReportsFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> submitCommentReport({
    required String commentId,
    required String reason,
    required String details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ReportsFailure('You must be signed in.');
    }

    try {
      await _client.from('content_reports').insert({
        'user_id': userId,
        'comment_id': commentId,
        'reason': reason,
        'details': details.trim(),
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to send the report right now.',
      );
      throw ReportsFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class ReportsFailure extends AppFailure {
  const ReportsFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
