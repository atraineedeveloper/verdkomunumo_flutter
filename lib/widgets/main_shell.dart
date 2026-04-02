import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/responsive.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<AuthState>? _authSubscription;
  String? _currentUsername;
  bool _loadingUsername = false;

  int _locationToIndex(String location) {
    if (location.startsWith('/fonto')) return 0;
    if (location.startsWith('/sercxi')) return 1;
    if (location.startsWith('/sciigoj')) return 2;
    if (location.startsWith('/profilo')) return 3;
    if (location.startsWith('/agordoj')) return 4;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _refreshCurrentUsername();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      _refreshCurrentUsername(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshCurrentUsername({bool forceRefresh = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _currentUsername = null;
          _loadingUsername = false;
        });
      }
      return;
    }

    if (!forceRefresh && _currentUsername != null) return;

    final metadataUsername = (user.userMetadata?['username'] as String?)
        ?.trim();
    if (metadataUsername != null && metadataUsername.isNotEmpty) {
      if (mounted) {
        setState(() => _currentUsername = metadataUsername);
      }
      return;
    }

    if (mounted) {
      setState(() => _loadingUsername = true);
    }

    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      final username = (profileData?['username'] as String?)?.trim();
      if (!mounted) return;
      setState(() {
        _currentUsername =
            username != null && username.isNotEmpty ? username : null;
        _loadingUsername = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUsername = false);
    }
  }

  Future<void> _openCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/ensaluti');
      return;
    }

    var username = _currentUsername;
    if ((username == null || username.isEmpty) && !_loadingUsername) {
      await _refreshCurrentUsername(forceRefresh: true);
      username = _currentUsername;
    }

    if (!mounted) return;

    if (username != null && username.isNotEmpty) {
      context.go('/profilo/$username');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ne eblis malfermi vian profilon.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    context.go('/agordoj');
  }

  Future<void> _onDestinationSelected(int index, bool isLoggedIn) async {
    switch (index) {
      case 0:
        context.go('/fonto');
        return;
      case 1:
        context.go('/sercxi');
        return;
      case 2:
        if (isLoggedIn) {
          context.go('/sciigoj');
        } else {
          context.go('/ensaluti');
        }
        return;
      case 3:
        await _openCurrentProfile();
        return;
      case 4:
        context.go('/agordoj');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final useRailNavigation = ResponsiveLayout.useRailNavigation(context);

    return Scaffold(
      body: !useRailNavigation
          ? widget.child
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) =>
                      _onDestinationSelected(index, isLoggedIn),
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
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
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
                      label: Text('Serĉi'),
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
                Expanded(child: widget.child),
              ],
            ),
      bottomNavigationBar: !useRailNavigation
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) =>
                  _onDestinationSelected(index, isLoggedIn),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Fonto',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  activeIcon: Icon(Icons.search),
                  label: 'Serĉi',
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
