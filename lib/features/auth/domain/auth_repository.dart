abstract class AuthRepository {
  bool get isAuthenticated;

  Stream<bool> authStateChanges();

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String esperantoLevel,
  });

  Future<void> signInWithGoogle({String? redirectUrl});

  Future<void> sendPasswordReset({
    required String email,
    String? redirectUrl,
  });

  Future<void> updatePassword({required String newPassword});

  Future<void> signOut();
}
