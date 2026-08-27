import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/notificacao_service.dart';

void main() {
  test('usa eventId estavel para deduplicar canais diferentes', () {
    final SixNotificationEvent websocket =
        SixNotificationEvent.fromPayload(<String, dynamic>{
          'eventId': 'evento-123',
          'tipoDeEvento': 'NOVA_VENDA',
          'canal': 'WEBSOCKET',
          'recebidoEmIso': '2026-08-27T10:00:00Z',
        });
    final SixNotificationEvent push =
        SixNotificationEvent.fromPayload(<String, dynamic>{
          'eventId': 'evento-123',
          'tipoDeEvento': 'NOVA_VENDA',
          'canal': 'FIREBASE_PUSH',
          'recebidoEmIso': '2026-08-27T10:00:01Z',
        });

    expect(websocket.id, 'evento-123');
    expect(push.id, websocket.id);
  });

  test('serializa evento persistido preservando leitura e payload', () {
    final SixNotificationEvent original =
        SixNotificationEvent.fromPayload(<String, dynamic>{
          'eventId': 'evento-456',
          'tipoDeEvento': 'NOVO_PRODUTO',
          'nomeProduto': 'Cabo USB',
          'recebidoEmIso': '2026-08-27T11:15:00Z',
        }).copyWith(isUnread: false);

    final SixNotificationEvent restaurado = SixNotificationEvent.fromJson(
      original.toJson(),
    );

    expect(restaurado.id, original.id);
    expect(restaurado.receivedAt, original.receivedAt);
    expect(restaurado.isUnread, isFalse);
    expect(restaurado.payload['nomeProduto'], 'Cabo USB');
  });
}
