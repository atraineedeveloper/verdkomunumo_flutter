import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verdkomunumo_flutter/widgets/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var initialized = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
    initialized = true;
  });

  tearDownAll(() async {
    if (initialized) {
      await Supabase.instance.dispose();
    }
  });

  Widget buildShell(Size size) {
    final router = GoRouter(
      initialLocation: '/fonto',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/fonto',
              builder: (context, state) => const Scaffold(body: Text('Feed')),
            ),
            GoRoute(
              path: '/sercxi',
              builder: (context, state) => const Scaffold(body: Text('Search')),
            ),
            GoRoute(
              path: '/sciigoj',
              builder: (context, state) =>
                  const Scaffold(body: Text('Notifications')),
            ),
            GoRoute(
              path: '/profilo/:username',
              builder: (context, state) =>
                  Scaffold(body: Text(state.pathParameters['username'] ?? '')),
            ),
            GoRoute(
              path: '/agordoj',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings')),
            ),
          ],
        ),
      ],
    );

    return MediaQuery(
      data: MediaQueryData(size: size),
      child: ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
  }

  testWidgets('shows bottom navigation on mobile', (tester) async {
    await tester.pumpWidget(buildShell(const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('keeps bottom navigation on phone landscape', (tester) async {
    await tester.pumpWidget(buildShell(const Size(844, 390)));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows navigation rail on desktop', (tester) async {
    await tester.pumpWidget(buildShell(const Size(1280, 900)));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('guest navigation only exposes public destinations', (
    tester,
  ) async {
    await tester.pumpWidget(buildShell(const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(find.text('Fonto'), findsOneWidget);
    expect(find.text('Serĉi'), findsOneWidget);
    expect(find.text('Ensalutu'), findsAtLeastNWidgets(1));
    expect(find.text('Sciigoj'), findsNothing);
    expect(find.text('Profilo'), findsNothing);
    expect(find.text('Agordoj'), findsNothing);
  });
}
