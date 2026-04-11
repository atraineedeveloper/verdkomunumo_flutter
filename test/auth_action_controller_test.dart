import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/analytics/analytics_service.dart';
import 'package:verdkomunumo_flutter/features/auth/application/auth_action_controller.dart';
import 'package:verdkomunumo_flutter/features/auth/domain/auth_repository.dart';

void main() {
  group('AuthActionController', () {
    test('signInWithGoogle delegates to repository', () async {
      final repository = _FakeAuthRepository();
      final controller = AuthActionController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.signInWithGoogle(redirectUrl: 'app://callback');

      expect(repository.googleCalls, 1);
      expect(repository.lastRedirectUrl, 'app://callback');
    });

    test('sendPasswordReset delegates to repository', () async {
      final repository = _FakeAuthRepository();
      final controller = AuthActionController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.sendPasswordReset(
        email: 'user@example.com',
        redirectUrl: 'app://reset',
      );

      expect(repository.resetCalls, 1);
      expect(repository.lastResetEmail, 'user@example.com');
      expect(repository.lastRedirectUrl, 'app://reset');
    });

    test('updatePassword delegates to repository', () async {
      final repository = _FakeAuthRepository();
      final controller = AuthActionController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.updatePassword(newPassword: 'new-pass');

      expect(repository.updatePasswordCalls, 1);
      expect(repository.lastPassword, 'new-pass');
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  int googleCalls = 0;
  int resetCalls = 0;
  int updatePasswordCalls = 0;
  String? lastRedirectUrl;
  String? lastResetEmail;
  String? lastPassword;

  @override
  bool get isAuthenticated => false;

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String esperantoLevel,
  }) async {}

  @override
  Future<void> signInWithGoogle({String? redirectUrl}) async {
    googleCalls += 1;
    lastRedirectUrl = redirectUrl;
  }

  @override
  Future<void> sendPasswordReset({
    required String email,
    String? redirectUrl,
  }) async {
    resetCalls += 1;
    lastResetEmail = email;
    lastRedirectUrl = redirectUrl;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatePasswordCalls += 1;
    lastPassword = newPassword;
  }

  @override
  Future<void> signOut() async {}
}
