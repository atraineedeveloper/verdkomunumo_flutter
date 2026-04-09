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

  Future<void> signOut();
}
