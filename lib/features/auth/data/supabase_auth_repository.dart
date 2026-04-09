import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Stream<bool> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) => event.session != null);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (_) {
      throw const AuthFailure('Unable to sign in right now.');
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String esperantoLevel,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username,
          'esperanto_level': esperantoLevel,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Unable to create the account.');
      }

      await _client.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'esperanto_level': esperantoLevel,
      });
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (_) {
      throw const AuthFailure('Unable to create the account right now.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (_) {
      throw const AuthFailure('Unable to sign out right now.');
    }
  }
}
