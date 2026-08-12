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

  test('alterarStatus envia bypass de assinatura quando informado', () async {
    late Uri requestedUri;
    late Map<String, dynamic> body;
    final AtendimentoTecnicoApiClient client = AtendimentoTecnicoApiClient(
      httpClient: MockClient((http.Request request) async {
        requestedUri = request.url;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(_atendimentoJson);
      }),
    );

    await client.alterarStatus(
      id: 'at-1',
      statusId: 60,
      statusCodigo: 'IN_PROGRESS',
      statusI18nKey: 'technicalService.status.inProgress',
      observacao: 'Autorizado no balcão.',
      bypassAssinatura: true,
    );

    expect(requestedUri.path, '/atendimentos-tecnicos/at-1/status');
    expect(body['statusId'], 60);
    expect(body['statusCodigo'], 'IN_PROGRESS');
    expect(body['bypassAssinatura'], isTrue);
  });

  test('assinarNoDispositivo envia assinatura e status selecionado', () async {
    late Uri requestedUri;
    late Map<String, dynamic> body;
    final AtendimentoTecnicoApiClient client = AtendimentoTecnicoApiClient(
      httpClient: MockClient((http.Request request) async {
        requestedUri = request.url;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(_atendimentoJson);
      }),
    );

    await client.assinarNoDispositivo(
      id: 'at-1',
      statusId: 40,
      statusCodigo: 'WAITING_CUSTOMER_APROVAL',
      statusI18nKey: 'technicalService.status.waitingCustomerAproval',
      observacaoStatus: 'Aguardando assinatura presencial.',
      nomeAssinante: 'Cliente Six',
      documentoAssinante: '123',
      assinaturaDataUrl: 'data:image/png;base64,abc',
      observacaoAssinatura: 'Assinou no balcão.',
    );

    expect(
      requestedUri.path,
      '/atendimentos-tecnicos/at-1/assinatura/dispositivo',
    );
    expect(body['statusId'], 40);
    expect(body['statusCodigo'], 'WAITING_CUSTOMER_APROVAL');
    expect(body['nomeAssinante'], 'Cliente Six');
    expect(body['documentoAssinante'], '123');
    expect(body['assinaturaDataUrl'], 'data:image/png;base64,abc');
    expect(body['observacaoAssinatura'], 'Assinou no balcão.');
  });

  test(
    'consultarStatusPublico parseia comercio institucional no response',
    () async {
      late Uri requestedUri;
      final AtendimentoTecnicoApiClient client = AtendimentoTecnicoApiClient(
        httpClient: MockClient((http.Request request) async {
          requestedUri = request.url;
          expect(request.headers.containsKey('Authorization'), isFalse);
          return _jsonResponse(_statusPublicoJson);
        }),
      );

      final AtendimentoTecnicoStatusPublicoModel result = await client
          .consultarStatusPublico(
            idUnicoDaEmpresa: 'empresa-test',
            token: 'token-publico',
          );

      expect(requestedUri.path, '/public/api/atendimentos-tecnicos/status');
      expect(requestedUri.queryParameters['idUnicoDaEmpresa'], 'empresa-test');
      expect(requestedUri.queryParameters['token'], 'token-publico');
      expect(result.comercio?.nomeExibicao, 'Sete Ideias Assistência Técnica');
      expect(result.comercio?.documentoFiscal, '12.345.678/0001-99');
      expect(result.comercio?.horariosAtendimento, hasLength(2));
      expect(result.comercio?.horariosAtendimento.first.diaSemana, 'MONDAY');
    },
  );
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

const String _atendimentoJson = '''
{
  "id": "at-1",
  "numero": "AT-1",
  "statusId": 60,
  "statusCodigo": "IN_PROGRESS",
  "statusI18nKey": "technicalService.status.inProgress",
  "statusNomePtBr": "Em execução",
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
''';

const String _statusPublicoJson = '''
{
  "status": "SUCCESS",
  "code": "TECHNICAL_SERVICE_PUBLIC_STATUS_TOKEN_VALID",
  "message": "Status público do atendimento técnico disponível.",
  "token": "token-publico",
  "idUnicoDaEmpresa": "empresa-test",
  "comercio": {
    "nomeEmpresa": "Sete Ideias Assistência Técnica LTDA",
    "nomeFantasia": "Sete Ideias Assistência Técnica",
    "documentoFiscal": "12.345.678/0001-99",
    "tipoDocumentoFiscal": null,
    "telefone": "(47) 3333-2020",
    "whatsapp": "(47) 99999-2020",
    "email": "suporte@empresa.com",
    "site": "empresa.com",
    "enderecoPublico": "Rua Central, 123",
    "logoBase64": "data:image/png;base64,abc",
    "timeZone": "America/Sao_Paulo",
    "horariosAtendimento": [
      {
        "diaSemana": "MONDAY",
        "fechado": false,
        "inicio": "08:00",
        "fim": "18:00"
      },
      {
        "diaSemana": "SUNDAY",
        "fechado": true
      }
    ]
  },
  "numero": "AT-1",
  "descricao": "Troca de tela",
  "nomeClienteSnapshot": "Cliente Six",
  "equipamentoResumo": "Celular Apple iPhone",
  "defeitoRelatado": "Tela quebrada",
  "statusId": 60,
  "statusCodigo": "IN_PROGRESS",
  "statusI18nKey": "technicalService.status.inProgress",
  "statusNomePtBr": "Em execução",
  "assinaturaAprovada": true,
  "requerNovaAssinatura": false,
  "etapas": [],
  "historicoStatus": []
}
''';
