import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_suggestions_repository.dart';
import '../domain/suggestions_repository.dart';
import 'suggestions_controller.dart';

final suggestionsRepositoryProvider = Provider<SuggestionsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSuggestionsRepository(client);
});

final suggestionsControllerProvider =
    StateNotifierProvider<SuggestionsController, AsyncValue<void>>((ref) {
      final repository = ref.watch(suggestionsRepositoryProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      return SuggestionsController(repository, analytics);
    });
