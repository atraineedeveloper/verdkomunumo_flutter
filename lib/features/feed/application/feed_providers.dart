import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'feed_controller.dart';
import 'feed_state.dart';
import '../data/supabase_feed_repository.dart';
import '../domain/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFeedRepository(client);
});

final feedControllerProvider =
    StateNotifierProvider<FeedController, FeedState>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedController(repository);
});
