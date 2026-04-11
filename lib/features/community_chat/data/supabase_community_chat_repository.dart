import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_failure_mapper.dart';
import '../domain/community_chat_repository.dart';
import '../domain/community_message.dart';

class SupabaseCommunityChatRepository implements CommunityChatRepository {
  final SupabaseClient _client;

  const SupabaseCommunityChatRepository(this._client);

  @override
  Future<List<CommunityMessage>> fetchMessages({required int limit}) async {
    try {
      final data = await _client
          .from('community_messages')
          .select('*, author:profiles(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      final messages =
          data.map((row) => CommunityMessage.fromJson(row)).toList();
      return messages.reversed.toList(growable: false);
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to load community chat right now.',
      );
      throw CommunityChatFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }

  @override
  Stream<CommunityMessage> streamMessages() {
    final controller = StreamController<CommunityMessage>.broadcast();
    RealtimeChannel? channel;

    controller.onListen = () {
      channel = _client
          .channel('community-messages-stream')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'community_messages',
            callback: (payload) async {
              final record = payload.newRecord;
              if (record == null) return;

              final data = await _client
                  .from('community_messages')
                  .select('*, author:profiles(*)')
                  .eq('id', record['id'])
                  .maybeSingle();
              if (data == null) return;

              controller.add(CommunityMessage.fromJson(data));
            },
          );
      channel!.subscribe();
    };

    controller.onCancel = () async {
      if (channel != null) {
        await channel!.unsubscribe();
      }
    };

    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String content,
    required String clientNonce,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const CommunityChatFailure('You must be signed in.');
    }

    try {
      await _client.from('community_messages').insert({
        'user_id': userId,
        'content': content.trim(),
        'client_nonce': clientNonce,
      });
    } catch (error) {
      final failure = mapSupabaseFailure(
        error,
        fallbackMessage: 'Unable to send the message right now.',
      );
      throw CommunityChatFailure(
        failure.message,
        kind: failure.kind,
        cause: failure.cause,
      );
    }
  }
}

class CommunityChatFailure extends AppFailure {
  const CommunityChatFailure(
    super.message, {
    super.kind = AppFailureKind.backend,
    super.cause,
  });
}
