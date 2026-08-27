import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/notificacao_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final NotificacaoService notificacaoService = NotificacaoService();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  setUp(() {
    notificacaoService.limpar();
  });

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

  test('consolida venda e recebimento imediato em uma unica notificacao', () {
    final bool vendaRegistrada = notificacaoService
        .registrarPayload(<String, dynamic>{
          'tipoDeEvento': 'NOVA_VENDA',
          'canal': 'FIREBASE_PUSH',
          'numeroOperacao': '1787852888665',
          'idOperacaoApp': '82ebec87b38347038ca8c0f7313c1366',
          'valorTotalVenda': 250.75,
          'operacaoLiquidada': false,
          'recebidoEmIso': '2026-08-27T14:48:00Z',
        });

    final bool recebimentoRegistrado = notificacaoService
        .registrarPayload(<String, dynamic>{
          'tipoDeEvento': 'NOVA_OPERACAO',
          'canal': 'FIREBASE_PUSH',
          'numeroOperacao': '1787852888665',
          'idOperacao': '82ebec87b38347038ca8c0f7313c1366',
          'valorRecebido': 250.75,
          'statusPagamento': 'RECEBIDO',
          'recebidoEmIso': '2026-08-27T14:48:30Z',
        });

    expect(vendaRegistrada, isTrue);
    expect(recebimentoRegistrado, isTrue);
    expect(notificacaoService.total, 1);

    final SixNotificationEvent event = notificacaoService.ultimaNotificacao!;
    expect(event.title, 'Nova venda registrada');
    expect(event.description, 'Venda de R\$250,75. Liquidada.');
    expect(event.status, 'LIQUIDADA');
    expect(event.entity, 'Venda 1787852888665');
  });

  test('normaliza venda pendente em uma unica mensagem com valor e status', () {
    final SixNotificationEvent event =
        SixNotificationEvent.fromPayload(<String, dynamic>{
          'tipoDeEvento': 'NOVA_OPERACAO',
          'canal': 'WEBSOCKET',
          'numeroOperacao': '42',
          'idOperacaoApp': 'op-42',
          'valorTotalOperacao': 89.9,
          'statusLiquidacaoCodigo': 'NAO_LIQUIDADA',
          'recebidoEmIso': '2026-08-27T10:00:00Z',
        });

    expect(event.title, 'Nova venda registrada');
    expect(event.description, 'Venda de R\$89,90. Não liquidada.');
    expect(event.status, 'NAO_LIQUIDADA');
    expect(event.entity, 'Venda 42');
    expect(event.payload['operacaoLiquidada'], isFalse);
  });
}
