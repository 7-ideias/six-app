import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/atendimento_tecnico_models.dart';
import 'package:sixpos/data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
  });

  test('listar envia status opcional para o backend', () async {
    late Uri requestedUri;
    final AtendimentoTecnicoApiClient client = AtendimentoTecnicoApiClient(
      httpClient: MockClient((http.Request request) async {
        requestedUri = request.url;
        expect(request.headers['Authorization'], 'Bearer token-test');
        expect(request.headers['idUnicoDaEmpresa'], 'empresa-test');
        return _jsonResponse(_atendimentosJson);
      }),
    );

    final List<AtendimentoTecnicoModel> result = await client.listar(
      status: 'WAITING_CUSTOMER_APROVAL',
    );

    expect(requestedUri.path, '/atendimentos-tecnicos');
    expect(requestedUri.queryParameters['status'], 'WAITING_CUSTOMER_APROVAL');
    expect(result.single.statusCodigo, 'WAITING_CUSTOMER_APROVAL');
  });

  test('listar sem status preserva chamada atual sem filtro', () async {
    late Uri requestedUri;
    final AtendimentoTecnicoApiClient client = AtendimentoTecnicoApiClient(
      httpClient: MockClient((http.Request request) async {
        requestedUri = request.url;
        return _jsonResponse(_atendimentosJson);
      }),
    );

    await client.listar();

    expect(requestedUri.path, '/atendimentos-tecnicos');
    expect(requestedUri.queryParameters.containsKey('status'), isFalse);
  });
}

http.Response _jsonResponse(String body) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

const String _atendimentosJson = '''
[
  {
    "id": "at-1",
    "numero": "AT-1",
    "statusId": 40,
    "statusCodigo": "WAITING_CUSTOMER_APROVAL",
    "statusI18nKey": "technicalService.status.waitingCustomerAproval",
    "statusNomePtBr": "Aguardando aprovação do cliente",
    "valorTotalProdutos": 0,
    "valorTotalServicos": 100,
    "valorTotalAtendimento": 100,
    "valorRecebido": 0,
    "valorEmAberto": 100,
    "operacaoLiquidada": false,
    "statusLiquidacaoCodigo": "NAO_LIQUIDADA",
    "itens": [],
    "historicoStatus": [],
    "historicoAuditoria": [],
    "recebimentos": []
  }
]
''';
