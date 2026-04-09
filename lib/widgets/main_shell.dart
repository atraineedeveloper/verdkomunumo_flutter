import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/routing/app_routes.dart';
import '../core/responsive.dart';
import '../features/auth/application/auth_providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.feed)) return 0;
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.profilePrefix)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  Future<void> _openCurrentProfile(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<String?> currentUsernameAsync,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.go(AppRoutes.login);
      return;
    }

    var username = currentUsernameAsync.valueOrNull;
    if ((username == null || username.isEmpty) &&
        currentUsernameAsync.isLoading) {
      username = await ref.read(currentUsernameProvider.future);
      if (!context.mounted) return;
    }

    if (username != null && username.isNotEmpty) {
      context.go('${AppRoutes.profilePrefix}/$username');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ne eblis malfermi vian profilon.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    context.go(AppRoutes.settings);
  }

  Future<void> _onDestinationSelected(
    BuildContext context,
    WidgetRef ref,
    int index,
    bool isLoggedIn,
    AsyncValue<String?> currentUsernameAsync,
  ) async {
    switch (index) {
      case 0:
        context.go(AppRoutes.feed);
        return;
      case 1:
        context.go(AppRoutes.search);
        return;
      case 2:
        context.go(isLoggedIn ? AppRoutes.notifications : AppRoutes.login);
        return;
      case 3:
        await _openCurrentProfile(context, ref, currentUsernameAsync);
        if (!context.mounted) return;
        return;
      case 4:
        context.go(AppRoutes.settings);
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
    final currentUsernameAsync = ref.watch(currentUsernameProvider);
    final useRailNavigation = ResponsiveLayout.useRailNavigation(context);

    return Scaffold(
      body: !useRailNavigation
          ? child
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => _onDestinationSelected(
                    context,
                    ref,
                    index,
                    isLoggedIn,
                    currentUsernameAsync,
                  ),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedIconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Icon(
                      Icons.eco_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Fonto'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Serchi'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(Icons.notifications),
                      label: Text('Sciigoj'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profilo'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Agordoj'),
                    ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
                Expanded(child: child),
              ],
            ),
      bottomNavigationBar: !useRailNavigation
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => _onDestinationSelected(
                context,
                ref,
                index,
                isLoggedIn,
                currentUsernameAsync,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Fonto',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  activeIcon: Icon(Icons.search),
                  label: 'Serchi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_outlined),
                  activeIcon: Icon(Icons.notifications),
                  label: 'Sciigoj',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profilo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Agordoj',
                ),
              ],
            )
          : null,
    );
  }
}
