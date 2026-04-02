import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/post/post_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/fonto',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggingIn = state.matchedLocation == '/ensaluti' ||
        state.matchedLocation == '/registrigxi';

    final protectedRoutes = ['/agordoj', '/sciigoj'];
    final isProtected = protectedRoutes.any(
      (r) => state.matchedLocation.startsWith(r),
    );

    if (isProtected && session == null) return '/ensaluti';
    if (loggingIn && session != null) return '/fonto';
    return null;
  },
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/fonto',
          builder: (_, _) => const FeedScreen(),
        ),
        GoRoute(
          path: '/sercxi',
          builder: (_, _) => const SearchScreen(),
        ),
        GoRoute(
          path: '/sciigoj',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profilo/:username',
          builder: (_, state) =>
              ProfileScreen(username: state.pathParameters['username']!),
        ),
        GoRoute(
          path: '/agordoj',
          builder: (_, _) => const SettingsScreen(),
        ),
      ],
    ),
    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/afisxo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) =>
          PostDetailScreen(postId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/ensaluti',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: '/registrigxi',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const RegisterScreen(),
    ),
  ],
);
