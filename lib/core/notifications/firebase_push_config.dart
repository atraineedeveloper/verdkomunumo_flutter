import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebasePushConfig {
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const String androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );
  static const String iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  static bool get supportsCurrentPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get hasCurrentPlatformConfig {
    if (!supportsCurrentPlatform) return false;

    if (apiKey.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidAppId.isNotEmpty;
      case TargetPlatform.iOS:
        return iosAppId.isNotEmpty;
      default:
        return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: apiKey,
          appId: androidAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket.isEmpty ? null : storageBucket,
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: apiKey,
          appId: iosAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket.isEmpty ? null : storageBucket,
        );
      default:
        throw UnsupportedError('Firebase push is only configured for mobile.');
    }
  }
}
