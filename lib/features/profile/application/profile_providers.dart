import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';
import 'profile_controller.dart';
import 'profile_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client);
});

final profileControllerProvider = StateNotifierProvider.family<
    ProfileController, ProfileState, String>((ref, username) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileController(repository, username);
});
