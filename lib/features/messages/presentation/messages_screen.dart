import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/routing/app_routes.dart';
import '../../../core/presence/presence_providers.dart';
import '../../../core/responsive.dart';
import '../../../models/profile.dart';
import '../../../widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../application/messages_providers.dart';
import '../domain/conversation.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(messagesControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Profile? _otherParticipant(
    List<Profile> participants,
    String? currentUserId,
  ) {
    if (participants.isEmpty) return null;
    if (currentUserId == null) return participants.first;
    return participants.firstWhere(
      (profile) => profile.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  Future<void> _openNewConversationSheet(BuildContext context) async {
    _searchController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final state = ref.watch(messagesControllerProvider);
        final controller = ref.read(messagesControllerProvider.notifier);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nova mesaĝo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Serĉi uzanton',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: controller.searchUsers,
              ),
              const SizedBox(height: 12),
              if (state.isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                )
              else if (state.searchQuery.isNotEmpty &&
                  state.searchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Neniu rezulto',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (_, index) {
                      final profile = state.searchResults[index];
                      return ListTile(
                        leading: UserAvatar(
                          avatarUrl: profile.avatarUrl,
                          username: profile.username,
                          radius: 18,
                        ),
                        title: Text(profile.name),
                        subtitle: Text('@${profile.username}'),
                        onTap: () async {
                          try {
                            final conversationId = await controller
                                .startConversation(profile);
                            if (!mounted || conversationId == null) return;
                            Navigator.of(sheetContext).pop();
                            context.go(
                              '${AppRoutes.conversationPrefix}/$conversationId',
                            );
                          } catch (_) {}
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: state.searchResults.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final onlineIds = ref.watch(presenceControllerProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesaĝoj'),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.communityChat),
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Komunuma babilejo',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.isStarting
            ? null
            : () => _openNewConversationSheet(context),
        child: state.isStarting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add_comment),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(messagesControllerProvider.notifier).load(),
                      child: const Text('Reprovi'),
                    ),
                  ],
                ),
              ),
            )
          : state.conversations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ankoraŭ neniu konversacio.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              itemBuilder: (_, index) {
                final conversation = state.conversations[index];
                final other = _otherParticipant(
                  conversation.participants,
                  currentUserId,
                );
                final isOnline =
                    other != null && onlineIds.contains(other.id);
                return _ConversationTile(
                  conversation: conversation,
                  other: other,
                  isOnline: isOnline,
                  onTap: () => context.go(
                    '${AppRoutes.conversationPrefix}/${conversation.id}',
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: state.conversations.length,
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary conversation;
  final Profile? other;
  final bool isOnline;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.other,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastMessage = conversation.lastMessage;
    final unreadCount = conversation.unreadCount;

    return Material(
      color: colorScheme.surfaceContainerHighest.withAlpha(120),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _AvatarWithPresence(
                avatarUrl: other?.avatarUrl,
                username: other?.username ?? 'uzanto',
                radius: 24,
                isOnline: isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other?.name ?? 'Nekonata uzanto',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage?.content ?? 'Neniu mesaĝo ankoraŭ.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMessage != null)
                    Text(
                      timeago.format(lastMessage.createdAt, locale: 'es'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(130),
                      ),
                    ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarWithPresence extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;
  final bool isOnline;

  const _AvatarWithPresence({
    required this.avatarUrl,
    required this.username,
    required this.radius,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(
          avatarUrl: avatarUrl,
          username: username,
          radius: radius,
        ),
        if (isOnline)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
