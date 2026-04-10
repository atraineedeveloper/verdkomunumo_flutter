class PushTokenRegistration {
  final String platform;
  final String pushProvider;
  final String token;
  final String? locale;
  final String? timezone;

  const PushTokenRegistration({
    required this.platform,
    required this.pushProvider,
    required this.token,
    required this.locale,
    required this.timezone,
  });
}
