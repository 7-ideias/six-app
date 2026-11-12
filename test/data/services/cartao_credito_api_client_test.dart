import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/utils/uuid_v4.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';

const input = CartaoCreditoRequest(id: '4a24e962-e2c1-43de-a4b6-09c19edecaf2',
  nome: ' Nubank ', instituicao: 'Nu', diaFechamento: 3, diaVencimento: 10, ativo: true);
Map<String, dynamic> response() => {...input.toJson(), 'nome': 'Nubank', 'versao': 0};

CartaoCreditoApiClient client(MockClient http, {String espaco = 'PESSOAL'}) => CartaoCreditoApiClient(
  espaco: espaco, client: http, tokenProvider: () async => 'test-token', empresaProvider: () async => 'empresa-1',
);

void main() {
  test('UUID reutilizavel segue formato v4 sem dependencia adicional', () {
    final id = gerarUuidV4();
    expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(gerarUuidV4(), isNot(id));
  });

  test('consulta respeita espaco, tenant, permissao e lista vazia real', () async {
    final api = client(MockClient((request) async {
      expect(request.headers['espacoFinanceiro'], 'EMPRESA');
      expect(request.headers['idUnicoDaEmpresa'], 'empresa-1');
      expect(request.url.path.endsWith('/agenda-financeira/cartoes'), isTrue);
      return http.Response(jsonEncode({'podeEditar': false, 'cartoes': []}), 200);
    }), espaco: 'EMPRESA');
    addTearDown(api.dispose);
    final result = await api.listar();
    expect(result.podeEditar, isFalse);
    expect(result.cartoes, isEmpty);
  });

  test('falha nao vira lista vazia ou sucesso e distingue status', () async {
    for (final entry in {401: 'session', 403: 'permission', 404: 'unavailable', 409: 'conflict', 500: 'server'}.entries) {
      final api = client(MockClient((_) async => http.Response('{}', entry.key)));
      await expectLater(api.listar(), throwsA(isA<CartaoCreditoApiException>().having((e) => e.kind, 'kind', entry.value)));
      api.dispose();
    }
    final api = client(MockClient((_) async => http.Response('{}', 200)));
    addTearDown(api.dispose);
    await expectLater(api.listar(), throwsA(isA<CartaoCreditoApiException>().having((e) => e.kind, 'kind', 'invalidResponse')));
  });

  test('retry conserva ID e comando depois de uma resposta perdida', () async {
    final payloads = <String>[];
    final api = client(MockClient((request) async {
      expect(request.method, 'POST');
      payloads.add(request.body);
      if (payloads.length == 1) throw http.ClientException('offline');
      return http.Response(jsonEncode(response()), 200);
    }));
    addTearDown(api.dispose);
    await expectLater(api.salvar(input), throwsA(isA<CartaoCreditoApiException>()));
    expect((await api.salvar(input)).id, input.id);
    expect(payloads[0], payloads[1]);
    expect(jsonDecode(payloads[1])['nome'], 'Nubank');
  });

  test('edicao envia versao por PUT e preserva conta nula explicita', () async {
    final api = client(MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path.endsWith('/${input.id}'), isTrue);
      final body = jsonDecode(request.body);
      expect(body['versao'], 3);
      expect(body.containsKey('contaPrevistaId'), isTrue);
      expect(body['ativo'], isFalse);
      return http.Response(jsonEncode({...response(), 'ativo': false, 'versao': 4}), 200);
    }));
    addTearDown(api.dispose);
    final result = await api.salvar(CartaoCreditoRequest(id: input.id, nome: input.nome,
      instituicao: input.instituicao, diaFechamento: 3, diaVencimento: 10, ativo: false, versao: 3));
    expect(result.ativo, isFalse);
    expect(result.versao, 4);
  });
}
