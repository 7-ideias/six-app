import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/push_destination_resolver.dart';
import 'package:sixpos/core/services/push_navigation_service.dart';

void main() {
  late PushNavigationService service;

  setUp(() {
    service = PushNavigationService.test();
  });

  tearDown(() {
    service.reset();
  });

  test('keeps pending intent until executor is bound', () async {
    await service.handlePayload(<String, dynamic>{
      'destination': 'notifications.inbox',
      'eventId': 'evento-1',
    }, source: PushNavigationSource.firebaseInitialMessage);

    expect(service.pendingIntent?.dedupKey, 'evento-1');

    final List<String> dispatched = <String>[];
    service.bindExecutor((ResolvedPushNavigation navigation) {
      dispatched.add(navigation.destinationKey);
    });

    await Future<void>.delayed(Duration.zero);

    expect(dispatched, <String>['notifications.inbox']);
    expect(service.pendingIntent, isNull);
    expect(service.lastHandledIntentKey, 'evento-1');
  });

  test('does not dispatch the same intent twice', () async {
    final List<String> dispatched = <String>[];
    service.bindExecutor((ResolvedPushNavigation navigation) {
      dispatched.add(navigation.intent.dedupKey);
    });

    await service.handlePayload(<String, dynamic>{
      'destination': 'sales.pending',
      'eventId': 'evento-2',
    }, source: PushNavigationSource.firebaseNotificationTap);
    await service.handlePayload(<String, dynamic>{
      'destination': 'sales.pending',
      'eventId': 'evento-2',
    }, source: PushNavigationSource.localNotificationTap);

    await Future<void>.delayed(Duration.zero);

    expect(dispatched, <String>['evento-2']);
  });

  test('preserves pending intent when executor fails', () async {
    final Completer<void> completer = Completer<void>();
    service.bindExecutor((ResolvedPushNavigation navigation) async {
      if (!completer.isCompleted) {
        completer.complete();
      }
      throw StateError('shell indisponivel');
    });

    await service.handlePayload(<String, dynamic>{
      'destination': 'technical.orders',
      'eventId': 'evento-3',
    }, source: PushNavigationSource.firebaseNotificationTap);

    await completer.future;
    await Future<void>.delayed(Duration.zero);

    expect(service.pendingIntent?.dedupKey, 'evento-3');
    expect(service.lastHandledIntentKey, isNull);
  });
}
