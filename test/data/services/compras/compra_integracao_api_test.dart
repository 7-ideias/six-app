import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/services/compras/compra_api_client.dart';

void main() {
  test('recebimento envia chave e quantidade vinculada à empresa', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/private/api/compras/compra-1/recebimentos');
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        expect(request.headers['idUnicoDaEmpresa'], 'loja-A');
        final payload = jsonDecode(request.body) as Map<String,dynamic>;
        expect(payload['chaveIdempotencia'], 'recebimento-123');
        expect((payload['itens'] as List).single,
            {'itemId':'item-1','quantidade':8});
        return http.Response(jsonEncode({
          'id': 'compra-1',
          'statusRecebimento': 'PARCIAL',
          'recebimentos': [{'status':'CONCLUIDO'}],
        }), 200);
      }),
      accessTokenProvider: () async => 'jwt-token',
      empresaIdProvider: () async => 'loja-A',
    );
    final result = await api.receber('compra-1', 'recebimento-123',
        [{'itemId':'item-1','quantidade':8}]);
    expect(result['statusRecebimento'], 'PARCIAL');
  });

  test('reprocessamento financeiro usa endpoint sem duplicar pagamento no cliente', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path,
            '/private/api/compras/compra-1/reconciliar-financeiro');
        return http.Response(jsonEncode({
          'id':'compra-1', 'integracaoFinanceiraStatus':'CONCLUIDA'
        }), 200);
      }),
      accessTokenProvider: () async => 'jwt',
      empresaIdProvider: () async => 'loja-A',
    );
    final result = await api.reconciliarFinanceiro('compra-1');
    expect(result['integracaoFinanceiraStatus'], 'CONCLUIDA');
  });

  test('não chama API se não existir comércio selecionado', () async {
    final api = CompraApiClient(
      httpClient: MockClient((_) async => fail('Nao deve enviar pedido sem empresa')),
      accessTokenProvider: () async => 'jwt',
      empresaIdProvider: () async => '',
    );
    expect(api.receber('compra-1', 'chave-1', [{'itemId':'i','quantidade':2}]),
        throwsA(isA<CompraApiException>()));
  });
}
