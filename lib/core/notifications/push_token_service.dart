import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_push_config.dart';
import 'push_token_registration.dart';

class PushTokenService {
  Future<bool>? _initialization;

  Future<bool> initializeIfAvailable() {
    return _initialization ??= _initialize();
  }

  Future<PushTokenRegistration?> getCurrentRegistration() async {
    final initialized = await initializeIfAvailable();
    if (!initialized) return null;

    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return null;

    return PushTokenRegistration(
      platform: _platformName,
      pushProvider: 'fcm',
      token: token,
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      timezone: DateTime.now().timeZoneName,
    );
  }

  Future<Stream<String>> tokenRefreshStream() async {
    final initialized = await initializeIfAvailable();
    if (!initialized) return const Stream<String>.empty();
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  Future<void> deleteToken() async {
    final initialized = await initializeIfAvailable();
    if (!initialized) return;
    await FirebaseMessaging.instance.deleteToken();
  }

  Future<bool> _initialize() async {
    if (!FirebasePushConfig.hasCurrentPlatformConfig) {
      return false;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebasePushConfig.currentPlatform);
    }

    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    return true;
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
