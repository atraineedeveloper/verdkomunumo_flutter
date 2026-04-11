class AppConstants {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String supabaseAuthRedirectUrl =
      String.fromEnvironment('SUPABASE_AUTH_REDIRECT_URL', defaultValue: '');

  static const String appName = 'Verdkomunumo';
  static const String appTagline = 'La Verda Komunumo';

  static const int maxPostLength = 5000;
  static const int maxCommentLength = 2000;

  static const List<String> categories = [
    'Ĝenerala',
    'Lernado',
    'Kulturo',
    'Novaĵoj',
    'Teknologio',
    'Vojaĝoj',
    'Helpo',
    'Ludoj',
  ];

  static bool get hasSupabaseConfig =>
      validateSupabaseConfig(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ) ==
      null;

  static String? validateSupabaseConfig({
    required String url,
    required String anonKey,
  }) {
    if (url.trim().isEmpty || anonKey.trim().isEmpty) {
      return 'Missing SUPABASE_URL or SUPABASE_ANON_KEY.';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'SUPABASE_URL is invalid.';
    }

    return null;
  }
}
