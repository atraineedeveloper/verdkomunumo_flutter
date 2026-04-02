import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/responsive.dart';
import '../../models/notification.dart';
import '../../widgets/user_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select('*, actor:profiles!actor_id(id, username, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications =
          data.map((j) => AppNotification.fromJson(j)).toList();
      final hasUnread = notifications.any((n) => !n.isRead);

      setState(() {
        _notifications = notifications;
        _loading = false;
      });

      if (hasUnread) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markAllAsRead(userId);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ne eblis ŝargi la sciigojn.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    if (_markingRead || _notifications.every((n) => n.isRead)) return;

    _markingRead = true;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map(
              (notification) => notification.isRead
                  ? notification
                  : notification.copyWith(isRead: true),
            )
            .toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ne eblis marki la sciigojn kiel legitaj.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _markingRead = false;
    }
  }

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
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sciigoj'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _load,
              child: const Text('Ĝisdatigi'),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(60),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ensalutu por vidi sciigojn'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/ensaluti'),
                      child: const Text('Ensalutu'),
                    ),
                  ],
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(60),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Neniu sciigo ankoraŭ',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ResponsiveLayout.contentMaxWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: ListView.separated(
                              itemCount: _notifications.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final n = _notifications[i];
                                return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                UserAvatar(
                                  avatarUrl: n.actorAvatarUrl,
                                  username: n.actorUsername ?? '?',
                                  radius: 22,
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _colorForType(n.type),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _iconForType(n.type),
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              n.message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              timeago.format(n.createdAt, locale: 'es'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                            tileColor: n.isRead
                                ? null
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(15),
                                  onTap: () {
                                    if (n.postId != null) {
                                      context.push('/afisxo/${n.postId}');
                                    } else if (n.actorUsername != null) {
                                      context.push('/profilo/${n.actorUsername}');
                                    }
                                  },
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
