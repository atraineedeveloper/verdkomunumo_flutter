import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth_repository.dart';

class AuthStateNotifier extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription<bool> _subscription;

  AuthStateNotifier(this._repository)
    : _isAuthenticated = _repository.isAuthenticated {
    _subscription = _repository.authStateChanges().listen((isAuthenticated) {
      if (_isAuthenticated == isAuthenticated) return;
      _isAuthenticated = isAuthenticated;
      notifyListeners();
    });
  }

  bool _isAuthenticated;

  bool get isAuthenticated => _isAuthenticated;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
