import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/routing/app_routes.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/messages/application/messages_providers.dart';
import '../features/notifications/application/notifications_providers.dart';
import '../features/settings/application/settings_providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  // Settings maps to Profile tab (index 4) — settings lives inside profile
  int _loggedInLocationToIndex(String location) {
    if (location.startsWith(AppRoutes.feed)) return 0;
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.messages)) return 2;
    if (location.startsWith(AppRoutes.notifications)) return 3;
    if (location.startsWith(AppRoutes.profilePrefix)) return 4;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  int _guestLocationToIndex(String location) {
    if (location.startsWith(AppRoutes.feed)) return 0;
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.login) ||
        location.startsWith(AppRoutes.register)) { return 2; }
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
      const SnackBar(content: Text('Ne eblis malfermi vian profilon.')),
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
    HapticFeedback.selectionClick();

    if (!isLoggedIn) {
      switch (index) {
        case 0: context.go(AppRoutes.feed); return;
        case 1: context.go(AppRoutes.search); return;
        case 2: context.go(AppRoutes.login); return;
      }
      return;
    }

    switch (index) {
      case 0: context.go(AppRoutes.feed); return;
      case 1: context.go(AppRoutes.search); return;
      case 2: context.go(AppRoutes.messages); return;
      case 3: context.go(AppRoutes.notifications); return;
      case 4:
        await _openCurrentProfile(context, ref, currentUsernameAsync);
        if (!context.mounted) return;
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
    final currentIndex = isLoggedIn
        ? _loggedInLocationToIndex(location)
        : _guestLocationToIndex(location);
    final currentUsernameAsync = ref.watch(currentUsernameProvider);
    final useRailNavigation = ResponsiveLayout.useRailNavigation(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Badges ────────────────────────────────────────────────────────────────
    final notificationsState = ref.watch(notificationsControllerProvider);
    final messagesState = ref.watch(messagesControllerProvider);
    final unreadNotifications =
        notificationsState.notifications.where((n) => !n.isRead).length;
    final unreadMessages = messagesState.conversations
        .fold<int>(0, (sum, c) => sum + c.unreadCount);

    // ── Profile avatar ────────────────────────────────────────────────────────
    final settingsState = ref.watch(settingsControllerProvider);
    final avatarUrl = settingsState.profile?.avatarUrl;
    final avatarUsername = settingsState.profile?.username ?? '';

    // ── Nav destinations ──────────────────────────────────────────────────────
    final loggedInDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Fonto',
      ),
      const NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search_rounded),
        label: 'Serĉi',
      ),
      NavigationDestination(
        icon: _BadgeIcon(
          count: unreadMessages,
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        selectedIcon: _BadgeIcon(
          count: unreadMessages,
          child: const Icon(Icons.chat_bubble_rounded),
        ),
        label: 'Mesaĝoj',
      ),
      NavigationDestination(
        icon: _BadgeIcon(
          count: unreadNotifications,
          child: const Icon(Icons.notifications_outlined),
        ),
        selectedIcon: _BadgeIcon(
          count: unreadNotifications,
          child: const Icon(Icons.notifications_rounded),
        ),
        label: 'Sciigoj',
      ),
      NavigationDestination(
        icon: _ProfileNavIcon(
          avatarUrl: isLoggedIn ? avatarUrl : null,
          username: avatarUsername,
          selected: false,
          primary: colorScheme.primary,
        ),
        selectedIcon: _ProfileNavIcon(
          avatarUrl: isLoggedIn ? avatarUrl : null,
          username: avatarUsername,
          selected: true,
          primary: colorScheme.primary,
        ),
        label: 'Profilo',
      ),
    ];

    const guestDestinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Fonto',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search_rounded),
        label: 'Serĉi',
      ),
      NavigationDestination(
        icon: Icon(Icons.login_outlined),
        selectedIcon: Icon(Icons.login_rounded),
        label: 'Ensalutu',
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: !useRailNavigation
          ? child
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (i) => _onDestinationSelected(
                    context, ref, i, isLoggedIn, currentUsernameAsync,
                  ),
                  labelType: NavigationRailLabelType.all,
                  useIndicator: true,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.eco_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  destinations: isLoggedIn
                      ? [
                          const NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: Text('Fonto'),
                          ),
                          const NavigationRailDestination(
                            icon: Icon(Icons.search_outlined),
                            selectedIcon: Icon(Icons.search_rounded),
                            label: Text('Serĉi'),
                          ),
                          NavigationRailDestination(
                            icon: _BadgeIcon(
                              count: unreadMessages,
                              child:
                                  const Icon(Icons.chat_bubble_outline_rounded),
                            ),
                            selectedIcon: _BadgeIcon(
                              count: unreadMessages,
                              child: const Icon(Icons.chat_bubble_rounded),
                            ),
                            label: const Text('Mesaĝoj'),
                          ),
                          NavigationRailDestination(
                            icon: _BadgeIcon(
                              count: unreadNotifications,
                              child: const Icon(Icons.notifications_outlined),
                            ),
                            selectedIcon: _BadgeIcon(
                              count: unreadNotifications,
                              child: const Icon(Icons.notifications_rounded),
                            ),
                            label: const Text('Sciigoj'),
                          ),
                          NavigationRailDestination(
                            icon: _ProfileNavIcon(
                              avatarUrl: avatarUrl,
                              username: avatarUsername,
                              selected: false,
                              primary: colorScheme.primary,
                            ),
                            selectedIcon: _ProfileNavIcon(
                              avatarUrl: avatarUrl,
                              username: avatarUsername,
                              selected: true,
                              primary: colorScheme.primary,
                            ),
                            label: const Text('Profilo'),
                          ),
                        ]
                      : const [
                          NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: Text('Fonto'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.search_outlined),
                            selectedIcon: Icon(Icons.search_rounded),
                            label: Text('Serĉi'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.login_outlined),
                            selectedIcon: Icon(Icons.login_rounded),
                            label: Text('Ensalutu'),
                          ),
                        ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: colorScheme.outline,
                ),
                Expanded(child: child),
              ],
            ),

      // ── Bottom nav bar with frosted glass ─────────────────────────────────
      bottomNavigationBar: !useRailNavigation
          ? _FrostedNavBar(
              isDark: isDark,
              colorScheme: colorScheme,
              child: NavigationBar(
                selectedIndex: currentIndex,
                backgroundColor: isDark
                    ? const Color(0xFF1C1C1E).withAlpha(210)
                    : Colors.white.withAlpha(220),
                onDestinationSelected: (i) => _onDestinationSelected(
                  context, ref, i, isLoggedIn, currentUsernameAsync,
                ),
                destinations:
                    isLoggedIn ? loggedInDestinations : guestDestinations,
              ),
            )
          : null,
    );
  }
}

// ── Frosted glass wrapper ──────────────────────────────────────────────────────

class _FrostedNavBar extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final Widget child;

  const _FrostedNavBar({
    required this.isDark,
    required this.colorScheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withAlpha(isDark ? 60 : 80),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: child,
        ),
      ),
    );
  }
}

// ── Badge icon ─────────────────────────────────────────────────────────────────

class _BadgeIcon extends StatelessWidget {
  final int count;
  final Widget child;

  const _BadgeIcon({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;

    return Badge(
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFFF43F5E),
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? 4 : 5,
        vertical: 1,
      ),
      child: child,
    );
  }
}

// ── Profile nav icon ───────────────────────────────────────────────────────────

class _ProfileNavIcon extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool selected;
  final Color primary;

  const _ProfileNavIcon({
    required this.avatarUrl,
    required this.username,
    required this.selected,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return Icon(
        selected ? Icons.person_rounded : Icons.person_outline_rounded,
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: primary, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: primary,
          ),
          errorWidget: (_, _, _) => Icon(
            selected ? Icons.person_rounded : Icons.person_outline_rounded,
          ),
        ),
      ),
    );
  }
}
