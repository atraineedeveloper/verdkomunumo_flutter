import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/models/notification.dart';

void main() {
  test('AppNotification.message returns readable strings per type', () {
    final notification = AppNotification(
      id: '1',
      userId: 'user-1',
      type: 'like',
      actorUsername: 'lina',
      isRead: false,
      createdAt: DateTime(2026, 1, 1),
    );

    expect(notification.message, 'lina sxatis vian afisxon');
    expect(
      notification.copyWith(type: 'comment').message,
      'lina komentis vian afisxon',
    );
    expect(
      notification.copyWith(type: 'follow').message,
      'lina eksekvatas vin',
    );
    expect(
      notification.copyWith(type: 'mention').message,
      'lina menciis vin en afisxo',
    );
    expect(notification.copyWith(type: 'unknown').message, 'Nova sciigo');
  });
}
