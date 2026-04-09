import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/post/post_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../widgets/main_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

String? resolveAuthRedirect({
  required bool isAuthenticated,
  required String matchedLocation,
}) {
  final isAuthScreen = matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.register;
  final protectedRoutes = <String>[
    AppRoutes.settings,
    AppRoutes.notifications,
  ];
  final isProtected = protectedRoutes.any(matchedLocation.startsWith);

  if (isProtected && !isAuthenticated) {
    return AppRoutes.login;
  }

  if (isAuthScreen && isAuthenticated) {
    return AppRoutes.feed;
  }

  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ref.watch(authStateNotifierProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.feed,
    refreshListenable: authStateNotifier,
    redirect: (context, state) => resolveAuthRedirect(
      isAuthenticated: authStateNotifier.isAuthenticated,
      matchedLocation: state.matchedLocation,
    ),
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.feed,
            builder: (_, _) => const FeedScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (_, _) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.profilePrefix}/:username',
            builder: (_, state) =>
                ProfileScreen(username: state.pathParameters['username']!),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.postDetailPrefix}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            PostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const RegisterScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
