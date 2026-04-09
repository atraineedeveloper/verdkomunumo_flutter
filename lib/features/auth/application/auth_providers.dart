import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import 'auth_action_controller.dart';
import 'auth_state_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});

final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateNotifierProvider);
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id;
});

final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateNotifierProvider);
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.email;
});

final currentUsernameProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateNotifierProvider);
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  final metadataUsername = (user.userMetadata?['username'] as String?)?.trim();
  if (metadataUsername != null && metadataUsername.isNotEmpty) {
    return metadataUsername;
  }

  final profileData = await client
      .from('profiles')
      .select('username')
      .eq('id', user.id)
      .maybeSingle();
  final username = (profileData?['username'] as String?)?.trim();
  if (username == null || username.isEmpty) {
    return null;
  }

  return username;
});

final authStateNotifierProvider = ChangeNotifierProvider<AuthStateNotifier>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});

final authActionControllerProvider =
    StateNotifierProvider<AuthActionController, AsyncValue<void>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthActionController(repository);
    });
