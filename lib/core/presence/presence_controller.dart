import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceController extends StateNotifier<Set<String>> {
  final SupabaseClient _client;
  final String? _currentUserId;
  RealtimeChannel? _channel;

  PresenceController(this._client, this._currentUserId) : super(const {}) {
    _init();
  }

  Future<void> _init() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    _channel = _client.channel(
      'presence:online_users',
      opts: RealtimeChannelConfig(key: userId, enabled: true),
    );

    _channel!
      ..onPresenceSync((_) => _syncPresence())
      ..onPresenceJoin((_) => _syncPresence())
      ..onPresenceLeave((_) => _syncPresence());

    await _channel!.subscribe();
         _channel!.track({
      'user_id': userId,
      'online_at': DateTime.now().toIso8601String(),
    });
  }

  void _syncPresence() {
    final channel = _channel;
    if (channel == null) return;
    final presenceState = channel.presenceState();
    final ids = <String>{};
    for (final entry in presenceState) {
      if (entry.key.isNotEmpty) {
        ids.add(entry.key);
      }
    }
    state = ids;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
