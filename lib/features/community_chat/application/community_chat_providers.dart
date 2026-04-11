import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_community_chat_repository.dart';
import '../domain/community_chat_repository.dart';
import 'community_chat_controller.dart';
import 'community_chat_state.dart';

final communityChatRepositoryProvider = Provider<CommunityChatRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCommunityChatRepository(client);
});

final communityChatControllerProvider =
    StateNotifierProvider<CommunityChatController, CommunityChatState>((ref) {
      final repository = ref.watch(communityChatRepositoryProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      return CommunityChatController(repository, analytics);
    });
