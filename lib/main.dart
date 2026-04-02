import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configError = AppConstants.validateSupabaseConfig(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  if (configError != null) {
    runApp(ConfigurationErrorApp(message: configError));
    return;
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  timeago.setLocaleMessages('es', timeago.EsMessages());

  final themeController = await AppThemeController.load();

  runApp(VerdkomunumoApp(themeController: themeController));
}

class VerdkomunumoApp extends StatelessWidget {
  final AppThemeController themeController;

  const VerdkomunumoApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  final String message;

  const ConfigurationErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Supabase configuration is missing',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Start the app with --dart-define=SUPABASE_URL=... '
                  '--dart-define=SUPABASE_ANON_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
