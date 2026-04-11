import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  const AnalyticsService(this._analytics);

  const AnalyticsService.disabled() : _analytics = null;

  FirebaseAnalytics? get analytics => _analytics;

  bool get isEnabled => _analytics != null;

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (_analytics == null) return;
    await _analytics!.logEvent(name: name, parameters: parameters);
  }

  Future<void> logLogin(String method) {
    return logEvent('login', parameters: {'method': method});
  }

  Future<void> logSignUp(String method) {
    return logEvent('sign_up', parameters: {'method': method});
  }

  Future<void> logPasswordResetRequested() {
    return logEvent('password_reset_requested');
  }

  Future<void> logPasswordResetCompleted() {
    return logEvent('password_reset_completed');
  }

  Future<void> logMessageSent() {
    return logEvent('message_sent');
  }

  Future<void> logConversationStarted() {
    return logEvent('conversation_started');
  }

  Future<void> logCommunityMessageSent() {
    return logEvent('community_message_sent');
  }

  Future<void> logReportSubmitted({required String targetType}) {
    return logEvent('report_submitted', parameters: {'target': targetType});
  }

  Future<void> logSuggestionSubmitted() {
    return logEvent('suggestion_submitted');
  }
}
