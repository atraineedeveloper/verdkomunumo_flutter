import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/constants.dart';

void main() {
  group('AppConstants.validateSupabaseConfig', () {
    test('returns error when values are missing', () {
      expect(
        AppConstants.validateSupabaseConfig(url: '', anonKey: ''),
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY.',
      );
    });

    test('returns error for invalid URL', () {
      expect(
        AppConstants.validateSupabaseConfig(
          url: 'not-a-url',
          anonKey: 'token',
        ),
        'SUPABASE_URL is invalid.',
      );
    });

    test('accepts valid values', () {
      expect(
        AppConstants.validateSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'token',
        ),
        isNull,
      );
    });
  });
}
