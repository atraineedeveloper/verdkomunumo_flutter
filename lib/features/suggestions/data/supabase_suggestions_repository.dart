import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../domain/suggestions_repository.dart';

class SupabaseSuggestionsRepository implements SuggestionsRepository {
  final SupabaseClient _client;

  const SupabaseSuggestionsRepository(this._client);

  @override
  Future<void> submitSuggestion({
    required String title,
    required String description,
    required String context,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const SuggestionsFailure('You must be signed in.');
    }

    try {
      await _client.from('app_suggestions').insert({
        'user_id': userId,
        'title': title.trim(),
        'description': description.trim(),
        'context': context.trim(),
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to submit the suggestion right now.',
      );
      throw SuggestionsFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class SuggestionsFailure extends AppFailure {
  const SuggestionsFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
