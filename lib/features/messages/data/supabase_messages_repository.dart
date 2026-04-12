import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../../../models/profile.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/messages_repository.dart';

class SupabaseMessagesRepository implements MessagesRepository {
  final SupabaseClient _client;

  const SupabaseMessagesRepository(this._client);

  @override
  Future<List<ConversationSummary>> fetchConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MessagesFailure('You must be signed in.');
    }

    try {
      final memberships = await _client
          .from('conversation_participants')
          .select('conversation_id, last_read_at')
          .eq('user_id', userId);

      if (memberships.isEmpty) {
        return const [];
      }

      final conversationIds =
          memberships.map((row) => row['conversation_id'] as String).toList();

      final conversations = await _client
          .from('conversations')
          .select('id, updated_at')
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      final participantsRows = await _client
          .from('conversation_participants')
          .select('conversation_id, profile:profiles(*)')
          .inFilter('conversation_id', conversationIds);

      final messagesRows = await _client
          .from('messages')
          .select('id, conversation_id, sender_id, content, is_read, created_at')
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      final lastReadMap = {
        for (final row in memberships)
          row['conversation_id'] as String:
              row['last_read_at']?.toString()
      };

      final participantsByConversation = <String, List<Profile>>{};
      for (final row in participantsRows) {
        final conversationId = row['conversation_id'] as String;
        final profileJson = row['profile'] as Map<String, dynamic>?;
        if (profileJson == null) continue;
        participantsByConversation
            .putIfAbsent(conversationId, () => [])
            .add(Profile.fromJson(profileJson));
      }

      final lastMessageByConversation = <String, Message>{};
      final unreadCountByConversation = <String, int>{};

      for (final row in messagesRows) {
        final conversationId = row['conversation_id'] as String;
        lastMessageByConversation.putIfAbsent(
          conversationId,
          () => Message.fromJson(row),
        );

        if ((row['sender_id'] as String?) == userId) {
          continue;
        }

        final lastReadAt = lastReadMap[conversationId];
        if (lastReadAt == null) {
          unreadCountByConversation[conversationId] =
              (unreadCountByConversation[conversationId] ?? 0) + 1;
          continue;
        }

        final createdAt = DateTime.parse(row['created_at'] as String);
        if (createdAt.isAfter(DateTime.parse(lastReadAt))) {
          unreadCountByConversation[conversationId] =
              (unreadCountByConversation[conversationId] ?? 0) + 1;
        }
      }

      return conversations.map((conversation) {
        final id = conversation['id'] as String;
        return ConversationSummary(
          id: id,
          participants: participantsByConversation[id] ?? const [],
          lastMessage: lastMessageByConversation[id],
          unreadCount: unreadCountByConversation[id] ?? 0,
          updatedAt: conversation['updated_at'] == null
              ? null
              : DateTime.parse(conversation['updated_at'] as String),
        );
      }).toList();
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load messages right now.',
      );
      throw MessagesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<ConversationThread> fetchConversation(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MessagesFailure('You must be signed in.');
    }

    try {
      final participantsRows = await _client
          .from('conversation_participants')
          .select('conversation_id, profile:profiles(*)')
          .eq('conversation_id', conversationId);

      final messagesRows = await _client
          .from('messages')
          .select('*, sender:profiles!sender_id(*)')
          .eq('conversation_id', conversationId)
          .order('created_at');

      await Future.wait([
        _client
            .from('messages')
            .update({'is_read': true})
            .eq('conversation_id', conversationId)
            .neq('sender_id', userId),
        _client
            .from('conversation_participants')
            .update({'last_read_at': DateTime.now().toIso8601String()})
            .eq('conversation_id', conversationId)
            .eq('user_id', userId),
      ]);

      final participants = participantsRows
          .map((row) => row['profile'])
          .whereType<Map<String, dynamic>>()
          .map(Profile.fromJson)
          .toList();

      final messages = messagesRows
          .map((row) => Message.fromJson(row))
          .toList(growable: false);

      return ConversationThread(
        id: conversationId,
        participants: participants,
        messages: messages,
      );
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load the conversation right now.',
      );
      throw MessagesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MessagesFailure('You must be signed in.');
    }

    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content.trim(),
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to send the message right now.',
      );
      throw MessagesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<String> startConversationWithUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MessagesFailure('You must be signed in.');
    }

    try {
      final existing = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      if (existing.isNotEmpty) {
        final myConversations =
            existing.map((row) => row['conversation_id'] as String).toList();
        final shared = await _client
            .from('conversation_participants')
            .select('conversation_id')
            .eq('user_id', targetUserId)
            .inFilter('conversation_id', myConversations)
            .maybeSingle();

        final existingId = shared?['conversation_id'] as String?;
        if (existingId != null && existingId.isNotEmpty) {
          return existingId;
        }
      }

      final response = await _client.rpc(
        'create_conversation_with_participant',
        params: {'target_user_id': targetUserId},
      );

      return response.toString();
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to start the conversation right now.',
      );
      throw MessagesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Future<List<Profile>> searchUsers(String query) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MessagesFailure('You must be signed in.');
    }

    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const [];
    }

    try {
      final data = await _client
          .from('profiles')
          .select('*')
          .or('username.ilike.%$trimmed%,display_name.ilike.%$trimmed%')
          .limit(8);

      return data
          .where((row) => row['id'] != userId)
          .map(Profile.fromJson)
          .toList(growable: false);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to search users right now.',
      );
      throw MessagesFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class MessagesFailure extends AppFailure {
  const MessagesFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
