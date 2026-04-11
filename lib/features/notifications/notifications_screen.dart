import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../app/routing/app_routes.dart';
import '../../core/responsive.dart';
import '../../models/notification.dart';
import '../../widgets/user_avatar.dart';
import '../auth/application/auth_providers.dart';
import 'application/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final state = ref.watch(notificationsControllerProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sciigoj'),
        actions: [
          if (state.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Ĝisdatigi',
              onPressed: () =>
                  ref.read(notificationsControllerProvider.notifier).load(),
            ),
        ],
      ),
      body: userId == null
          ? _AuthPrompt(horizontalPadding: horizontalPadding)
          : state.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : state.notifications.isEmpty
          ? _EmptyNotifications(horizontalPadding: horizontalPadding)
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: () =>
                  ref.read(notificationsControllerProvider.notifier).load(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ResponsiveLayout.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: ListView.builder(
                      itemCount: state.notifications.length,
                      itemBuilder: (_, index) {
                        final notification = state.notifications[index];
                        return _NotificationTile(
                          notification: notification,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Notification tile ──────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  static IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'like':
        return const Color(0xFFF43F5E);
      case 'comment':
        return const Color(0xFF22C55E);
      case 'follow':
        return const Color(0xFF3B82F6);
      case 'mention':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final typeColor = _colorForType(notification.type);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () {
        if (notification.postId != null) {
          context.push(
            '${AppRoutes.postDetailPrefix}/${notification.postId}',
          );
        } else if (notification.actorUsername != null) {
          context.push(
            '${AppRoutes.profilePrefix}/${notification.actorUsername}',
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnread
              ? colorScheme.primary.withAlpha(8)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isUnread ? typeColor : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(
              color: colorScheme.outline.withAlpha(60),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar with type badge ─────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatarUrl: notification.actorAvatarUrl,
                  username: notification.actorUsername ?? '?',
                  radius: 21,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _iconForType(notification.type),
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeago.format(notification.createdAt, locale: 'es'),
                    style: textTheme.labelSmall?.copyWith(
                      color: typeColor.withAlpha(isUnread ? 220 : 160),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // ── Unread dot ────────────────────────────────────────────────
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty / auth states ────────────────────────────────────────────────────────

class _AuthPrompt extends StatelessWidget {
  final double horizontalPadding;

  const _AuthPrompt({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ResponsiveContent(
        maxWidth: ResponsiveLayout.formMaxWidth,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: colorScheme.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ensalutu por vidi sciigojn',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Ensalutu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final double horizontalPadding;

  const _EmptyNotifications({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ResponsiveContent(
        maxWidth: ResponsiveLayout.formMaxWidth,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: colorScheme.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Neniu sciigo ankoraŭ',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ni sciigos vin kiam io okazos.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
