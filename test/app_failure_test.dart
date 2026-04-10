import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/error/app_failure.dart';
import 'package:verdkomunumo_flutter/features/auth/domain/auth_failure.dart';

void main() {
  group('failureMessageOf', () {
    test('returns the message from AppFailure instances', () {
      const error = AuthFailure('Invalid credentials');

      expect(
        failureMessageOf(error, fallback: 'Fallback message'),
        'Invalid credentials',
      );
    });

    test('returns the fallback for non-AppFailure errors', () {
      expect(
        failureMessageOf(Exception('boom'), fallback: 'Fallback message'),
        'Fallback message',
      );
    });
  });
}
