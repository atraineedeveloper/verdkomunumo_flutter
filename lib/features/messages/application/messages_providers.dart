import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/supabase_messages_repository.dart';
import '../domain/messages_repository.dart';
import 'conversation_controller.dart';
import 'conversation_state.dart';
import 'messages_controller.dart';
import 'messages_state.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseMessagesRepository(client);
});

final messagesControllerProvider =
    StateNotifierProvider<MessagesController, MessagesState>((ref) {
  final repository = ref.watch(messagesRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return MessagesController(repository, analytics);
});

final conversationControllerProvider =
    StateNotifierProvider.family<ConversationController, ConversationState, String>(
  (ref, conversationId) {
    final repository = ref.watch(messagesRepositoryProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    return ConversationController(
      repository,
      analytics,
      conversationId,
      currentUserId,
    );
  },
);
