import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../domain/auth_repository.dart';

class AuthActionController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final AnalyticsService _analytics;

  AuthActionController(this._repository, this._analytics)
    : super(const AsyncData(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _run(() async {
      await _repository.signIn(email: email, password: password);
      await _analytics.logLogin('password');
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String esperantoLevel,
  }) {
    return _run(() async {
      await _repository.signUp(
        email: email,
        password: password,
        username: username,
        esperantoLevel: esperantoLevel,
      );
      await _analytics.logSignUp('password');
    });
  }

  Future<void> signInWithGoogle({String? redirectUrl}) {
    return _run(() async {
      await _repository.signInWithGoogle(redirectUrl: redirectUrl);
      await _analytics.logLogin('google');
    });
  }

  Future<void> sendPasswordReset({
    required String email,
    String? redirectUrl,
  }) {
    return _run(() async {
      await _repository.sendPasswordReset(
        email: email,
        redirectUrl: redirectUrl,
      );
      await _analytics.logPasswordResetRequested();
    });
  }

  Future<void> updatePassword({required String newPassword}) {
    return _run(() async {
      await _repository.updatePassword(newPassword: newPassword);
      await _analytics.logPasswordResetCompleted();
    });
  }

  Future<void> signOut() {
    return _run(_repository.signOut);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(action);

    if (state.hasError) {
      throw state.error!;
    }
  }
}
