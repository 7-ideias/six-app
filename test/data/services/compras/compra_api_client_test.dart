import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/services/compras/compra_api_client.dart';

void main() {
  test('lista somente no comercio selecionado e envia JWT', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/private/api/compras');
        expect(request.headers['idUnicoDaEmpresa'], 'loja-1');
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(jsonEncode([
          {'id':'compra-1','idUnicoDaEmpresa':'loja-1','status':'RASCUNHO'}
        ]), 200);
      }),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => 'loja-1',
    );
    expect((await api.listar()).single['id'], 'compra-1');
  });

  test('cria compra com payload e recebe ID persistido', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['fornecedorId'], 'f1');
        expect(payload.containsKey('idUnicoDaEmpresa'), isFalse);
        return http.Response(jsonEncode({'id':'uuid-1','status':'RASCUNHO'}), 201);
      }),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => 'loja-1',
    );
    final saved = await api.criar({'fornecedorId':'f1'});
    expect(saved['id'], 'uuid-1');
  });

  test('confirma e cancela apenas compra no comercio atual', () async {
    final calls = <String>[];
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.headers['idUnicoDaEmpresa'], 'loja-1');
        calls.add(request.url.path);
        if (request.url.path.endsWith('/cancelar')) {
          expect(jsonDecode(request.body), {'motivo': 'Erro comercial'});
        }
        return http.Response(jsonEncode({'id':'id','status':'CONFIRMADA'}), 200);
      }),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => 'loja-1',
    );
    await api.confirmar('id');
    await api.cancelar('id', 'Erro comercial');
    expect(calls, ['/private/api/compras/id/confirmar', '/private/api/compras/id/cancelar']);
  });

  test('sem empresa ativa nao faz requisicao', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async => fail('Request nao autorizado')),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => '',
    );
    expect(api.listar(), throwsA(isA<CompraApiException>()));
  });

  test('api informa conflito de concorrencia', () async {
    final api = CompraApiClient(
      httpClient: MockClient((_) async => http.Response('conflito', 409)),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => 'loja-1',
    );
    expect(api.listar(), throwsA(isA<CompraApiException>()
      .having((e) => e.statusCode, 'status', 409)));
  });
}
