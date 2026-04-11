import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../notifications/firebase_push_config.dart';
import 'analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  if (!FirebasePushConfig.hasCurrentPlatformConfig) {
    return const AnalyticsService.disabled();
  }

  return AnalyticsService(FirebaseAnalytics.instance);
});
