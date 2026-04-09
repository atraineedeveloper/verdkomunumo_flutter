import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';

class AuthActionController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthActionController(this._repository) : super(const AsyncData(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _run(() {
      return _repository.signIn(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String esperantoLevel,
  }) {
    return _run(() {
      return _repository.signUp(
        email: email,
        password: password,
        username: username,
        esperantoLevel: esperantoLevel,
      );
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
