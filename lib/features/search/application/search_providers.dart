import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_search_repository.dart';
import '../domain/search_repository.dart';
import 'search_controller.dart';
import 'search_state.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSearchRepository(client);
});

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchController(repository);
});
