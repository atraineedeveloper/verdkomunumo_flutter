import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_providers.dart';
import '../../features/auth/application/auth_providers.dart';
import 'presence_controller.dart';

final presenceControllerProvider =
    StateNotifierProvider.autoDispose<PresenceController, Set<String>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return PresenceController(client, currentUserId);
});
