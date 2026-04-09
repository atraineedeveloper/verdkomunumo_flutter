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

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return const Color(0xFF22C55E);
      case 'follow':
        return Colors.blueAccent;
      case 'mention':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final state = ref.watch(notificationsControllerProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sciigoj'),
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsControllerProvider.notifier).load(),
              child: const Text('Gxisdatigi'),
            ),
        ],
      ),
      body: userId == null
          ? Center(
              child: ResponsiveContent(
                maxWidth: ResponsiveLayout.formMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ensalutu por vidi sciigojn'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push(AppRoutes.login),
                      child: const Text('Ensalutu'),
                    ),
                  ],
                ),
              ),
            )
          : state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.notifications.isEmpty
                  ? Center(
                      child: ResponsiveContent(
                        maxWidth: ResponsiveLayout.formMaxWidth,
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(60),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Neniu sciigo ankorau',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(150),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(notificationsControllerProvider.notifier).load(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ResponsiveLayout.contentMaxWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: ListView.separated(
                              itemCount: state.notifications.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final notification = state.notifications[index];
                                return _NotificationTile(
                                  notification: notification,
                                  icon: _iconForType(notification.type),
                                  color: _colorForType(notification.type),
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

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(
            avatarUrl: notification.actorAvatarUrl,
            username: notification.actorUsername ?? '?',
            radius: 22,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        notification.message,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        timeago.format(notification.createdAt, locale: 'es'),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
      tileColor: notification.isRead
          ? null
          : Theme.of(context).colorScheme.primary.withAlpha(15),
      onTap: () {
        if (notification.postId != null) {
          context.push('${AppRoutes.postDetailPrefix}/${notification.postId}');
        } else if (notification.actorUsername != null) {
          context.push('${AppRoutes.profilePrefix}/${notification.actorUsername}');
        }
      },
    );
  }
}
