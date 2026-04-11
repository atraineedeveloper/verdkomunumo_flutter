import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_reports_repository.dart';
import '../domain/reports_repository.dart';
import 'reports_controller.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseReportsRepository(client);
});

final reportsControllerProvider =
    StateNotifierProvider<ReportsController, AsyncValue<void>>((ref) {
      final repository = ref.watch(reportsRepositoryProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      return ReportsController(repository, analytics);
    });
