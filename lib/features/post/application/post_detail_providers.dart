import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_post_detail_repository.dart';
import '../domain/post_detail_repository.dart';
import 'post_detail_controller.dart';
import 'post_detail_state.dart';

final postDetailRepositoryProvider = Provider<PostDetailRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePostDetailRepository(client);
});

final postDetailControllerProvider =
    StateNotifierProvider.family<PostDetailController, PostDetailState, String>(
      (ref, postId) {
        final repository = ref.watch(postDetailRepositoryProvider);
        return PostDetailController(repository, postId);
      },
    );
