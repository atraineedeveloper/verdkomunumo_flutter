import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/supabase_post_interactions_repository.dart';
import '../domain/post_interactions_repository.dart';
import 'post_interaction_controller.dart';
import 'post_interaction_state.dart';

class PostInteractionArgs {
  final String postId;
  final int initialLikesCount;

  const PostInteractionArgs({
    required this.postId,
    required this.initialLikesCount,
  });

  @override
  bool operator ==(Object other) {
    return other is PostInteractionArgs &&
        other.postId == postId &&
        other.initialLikesCount == initialLikesCount;
  }

  @override
  int get hashCode => Object.hash(postId, initialLikesCount);
}

final postInteractionsRepositoryProvider =
    Provider<PostInteractionsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePostInteractionsRepository(client);
});

final postInteractionControllerProvider = StateNotifierProvider.family
    .autoDispose<PostInteractionController, PostInteractionState,
        PostInteractionArgs>((ref, args) {
  final repository = ref.watch(postInteractionsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return PostInteractionController(
    repository: repository,
    postId: args.postId,
    userId: userId,
    initialLikesCount: args.initialLikesCount,
  );
});
