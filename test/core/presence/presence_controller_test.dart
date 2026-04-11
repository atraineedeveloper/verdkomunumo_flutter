import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verdkomunumo_flutter/core/presence/presence_controller.dart';

class MockSupabaseClient implements SupabaseClient {
  RealtimeChannel? mockedChannel;
  String? channelName;
  RealtimeChannelConfig? channelOpts;

  @override
  RealtimeChannel channel(String name, {RealtimeChannelConfig? opts}) {
    channelName = name;
    channelOpts = opts;
    return mockedChannel!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRealtimeChannel implements RealtimeChannel {
  bool subscribeCalled = false;
  Map<String, dynamic>? trackCalledWith;
  void Function(RealtimePresenceSyncPayload)? onPresenceSyncCallback;
  void Function(RealtimePresenceJoinPayload)? onPresenceJoinCallback;
  void Function(RealtimePresenceLeavePayload)? onPresenceLeaveCallback;
  List<SinglePresenceState> mockedPresenceState = [];
  bool unsubscribeCalled = false;

  @override
  RealtimeChannel onPresenceSync(void Function(RealtimePresenceSyncPayload payload) callback) {
    onPresenceSyncCallback = callback;
    return this;
  }

  @override
  RealtimeChannel onPresenceJoin(void Function(RealtimePresenceJoinPayload payload) callback) {
    onPresenceJoinCallback = callback;
    return this;
  }

  @override
  RealtimeChannel onPresenceLeave(void Function(RealtimePresenceLeavePayload payload) callback) {
    onPresenceLeaveCallback = callback;
    return this;
  }

  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus status, Object? error)? callback, Duration? timeout]) {
    subscribeCalled = true;
    return this;
  }

  @override
  Future<ChannelResponse> track(Map<String, dynamic> payload, [Map<String, dynamic> opts = const {}]) async {
    trackCalledWith = payload;
    return ChannelResponse.ok;
  }

  @override
  List<SinglePresenceState> presenceState() {
    return mockedPresenceState;
  }

  @override
  Future<String> unsubscribe([Duration? timeout]) async {
    unsubscribeCalled = true;
    return 'UNSUBSCRIBED';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PresenceController', () {
    late MockSupabaseClient mockClient;
    late MockRealtimeChannel mockChannel;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockChannel = MockRealtimeChannel();
      mockClient.mockedChannel = mockChannel;
    });

    test('initial state is empty set when no user', () {
      final controller = PresenceController(mockClient, null);
      expect(controller.state, isEmpty);
      expect(mockClient.channelName, isNull);
    });

    test('initial state is empty set when user is empty', () {
      final controller = PresenceController(mockClient, '');
      expect(controller.state, isEmpty);
      expect(mockClient.channelName, isNull);
    });

    test('initializes tracking when user exists', () async {
      // ignore: unused_local_variable
      final controller = PresenceController(mockClient, 'user-1');

      // Wait for async initialization
      await Future.delayed(Duration.zero);

      expect(mockClient.channelName, 'presence:online_users');
      expect(mockClient.channelOpts?.key, 'user-1');
      expect(mockClient.channelOpts?.enabled, isTrue);

      expect(mockChannel.subscribeCalled, isTrue);
      expect(mockChannel.trackCalledWith, isNotNull);
      expect(mockChannel.trackCalledWith?['user_id'], 'user-1');
      expect(mockChannel.trackCalledWith?['online_at'], isNotNull);
    });

    test('syncs presence correctly on sync, join, and leave', () async {
      final controller = PresenceController(mockClient, 'user-1');
      await Future.delayed(Duration.zero);

      // Setup mocked presence state
      mockChannel.mockedPresenceState = [
        SinglePresenceState(key: 'user-2', presences: []),
        SinglePresenceState(key: 'user-3', presences: []),
        SinglePresenceState(key: '', presences: []), // should be ignored
      ];

      // Trigger sync
      mockChannel.onPresenceSyncCallback?.call(RealtimePresenceSyncPayload(
        event: PresenceEvent.sync,
      ));

      expect(controller.state, {'user-2', 'user-3'});

      // Trigger join
      mockChannel.mockedPresenceState = [
        SinglePresenceState(key: 'user-2', presences: []),
        SinglePresenceState(key: 'user-3', presences: []),
        SinglePresenceState(key: 'user-4', presences: []),
      ];
      mockChannel.onPresenceJoinCallback?.call(RealtimePresenceJoinPayload(
        event: PresenceEvent.join,
        key: 'user-4',
        newPresences: [],
        currentPresences: [],
      ));

      expect(controller.state, {'user-2', 'user-3', 'user-4'});

      // Trigger leave
      mockChannel.mockedPresenceState = [
        SinglePresenceState(key: 'user-2', presences: []),
        SinglePresenceState(key: 'user-3', presences: []),
      ];
      mockChannel.onPresenceLeaveCallback?.call(RealtimePresenceLeavePayload(
        event: PresenceEvent.leave,
        key: 'user-4',
        leftPresences: [],
        currentPresences: [],
      ));

      expect(controller.state, {'user-2', 'user-3'});
    });

    test('dispose unsubscribes channel', () async {
      final controller = PresenceController(mockClient, 'user-1');
      await Future.delayed(Duration.zero);

      controller.dispose();

      expect(mockChannel.unsubscribeCalled, isTrue);
    });
  });
}
