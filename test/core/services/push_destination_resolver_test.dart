import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/push_destination_resolver.dart';

void main() {
  final PushDestinationResolver resolver = const PushDestinationResolver();

  test('resolves explicit destination for pending sales', () {
    final PushNavigationIntent intent = PushNavigationIntent(
      payload: <String, dynamic>{
        'destination': 'sales.pending',
        'entityId': 'op-1',
      },
      source: PushNavigationSource.firebaseNotificationTap,
    );

    final ResolvedPushNavigation resolved = resolver.resolve(intent);

    expect(resolved.destination, PushNavigationDestination.salesPending);
    expect(resolved.destinationKey, 'sales.pending');
    expect(resolved.shellTab, PushNavigationShellTab.service);
  });

  test('falls back to sales pending when event type is sale like', () {
    final PushNavigationIntent intent = PushNavigationIntent(
      payload: <String, dynamic>{
        'tipoDeEvento': 'NOVA_VENDA',
        'numeroOperacao': '123',
      },
      source: PushNavigationSource.firebaseNotificationTap,
    );

    final ResolvedPushNavigation resolved = resolver.resolve(intent);

    expect(resolved.destination, PushNavigationDestination.salesPending);
  });

  test('maps explicit technical orders destination', () {
    final PushNavigationIntent intent = PushNavigationIntent(
      payload: <String, dynamic>{
        'destination': 'technical.orders',
        'ordemId': 'os-42',
      },
      source: PushNavigationSource.firebaseNotificationTap,
    );

    final ResolvedPushNavigation resolved = resolver.resolve(intent);

    expect(resolved.destination, PushNavigationDestination.technicalOrders);
    expect(resolved.shellTab, PushNavigationShellTab.service);
  });

  test('maps explicit customers list destination', () {
    final PushNavigationIntent intent = PushNavigationIntent(
      payload: <String, dynamic>{
        'destination': 'customers.list',
        'idCliente': 'cliente-1',
      },
      source: PushNavigationSource.firebaseNotificationTap,
    );

    final ResolvedPushNavigation resolved = resolver.resolve(intent);

    expect(resolved.destination, PushNavigationDestination.customersList);
    expect(resolved.shellTab, PushNavigationShellTab.management);
  });

  test('maps support chat and keeps it outside shell tabs', () {
    final PushNavigationIntent intent = PushNavigationIntent(
      payload: <String, dynamic>{
        'destination': 'support.chat',
        'conversationId': 'conversation-42',
        'idUnicoDaEmpresa': 'company-1',
      },
      source: PushNavigationSource.firebaseNotificationTap,
    );

    final ResolvedPushNavigation resolved = resolver.resolve(intent);

    expect(resolved.destination, PushNavigationDestination.supportChat);
    expect(resolved.destinationKey, 'support.chat');
    expect(resolved.shellTab, isNull);
    expect(intent.dedupKey, 'conversation-42');
  });

  test('infers support chat from conversation id', () {
    final ResolvedPushNavigation resolved = resolver.resolve(
      PushNavigationIntent(
        payload: <String, dynamic>{'conversationId': 'conversation-99'},
        source: PushNavigationSource.firebaseInitialMessage,
      ),
    );

    expect(resolved.destination, PushNavigationDestination.supportChat);
  });

  test('falls back to inbox for unknown payload', () {
    final PushNavigationIntent intent = PushNavigationIntent(
      payload: <String, dynamic>{'titulo': 'Atualizacao generica'},
      source: PushNavigationSource.localNotificationTap,
    );

    final ResolvedPushNavigation resolved = resolver.resolve(intent);

    expect(resolved.destination, PushNavigationDestination.notificationsInbox);
    expect(resolved.destinationKey, 'notifications.inbox');
    expect(resolved.shellTab, isNull);
  });
}
