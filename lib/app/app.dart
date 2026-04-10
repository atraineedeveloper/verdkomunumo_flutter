import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/theme_controller.dart';
import 'push_notification_bootstrap.dart';
import 'routing/app_router.dart';

class VerdkomunumoApp extends ConsumerWidget {
  final AppThemeController themeController;

  const VerdkomunumoApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ThemeControllerScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return PushNotificationBootstrap(
            child: MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeController.themeMode,
              routerConfig: router,
            ),
          );
        },
      ),
    );
  }
}
