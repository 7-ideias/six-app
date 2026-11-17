import 'dart:convert';
import 'dart:async';
import 'package:sixpos/data/models/workspace_home_model.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/services/workspace_home/workspace_home_api_client.dart';

void main() {
  test(
    'section request includes captured tenant and discards a late response',
    () async {
      var company = 'company-a';
      final response = Completer<http.Response>();
      final started = Completer<void>();
      final client = HttpWorkspaceHomeApiClient(
        accessTokenProvider: () async => 'token-test',
        empresaIdProvider: () async => company,
        userIdProvider: () async => 'user',
        httpClient: MockClient((request) {
          expect(request.url.path, '/private/api/workspace/home/STOCK');
          expect(request.headers['idUnicoDaEmpresa'], 'company-a');
          started.complete();
          return response.future;
        }),
      );
      final scope = await client.currentScope();
      final result = client.buscarSecao(WorkspaceHomeSection.stock, scope);
      final rejected = expectLater(result, throwsStateError);
      await started.future;
      company = 'company-b';
      response.complete(_jsonResponse(_workspaceHomeJson));
      await rejected;
    },
  );

  test('buscarHome consulta endpoint agregado com empresa e token', () async {
    late http.Request capturedRequest;
    final client = HttpWorkspaceHomeApiClient(
      accessTokenProvider: () async => 'token-test',
      empresaIdProvider: () async => 'empresa-test',
      httpClient: MockClient((http.Request request) async {
        capturedRequest = request;
        return _jsonResponse(_workspaceHomeJson);
      }),
    );

    final result = await client.buscarHome();

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/private/api/web/workspace/home');
    expect(capturedRequest.headers['Authorization'], 'Bearer token-test');
    expect(capturedRequest.headers['idUnicoDaEmpresa'], 'empresa-test');
    expect(result.technicalServices.readyForPickup, 4);
  });

  test('buscarHome exige credenciais', () {
    final client = HttpWorkspaceHomeApiClient(
      accessTokenProvider: () async => null,
      empresaIdProvider: () async => 'empresa-test',
      httpClient: MockClient((http.Request request) async {
        return _jsonResponse(_workspaceHomeJson);
      }),
    );

    expect(client.buscarHome, throwsA(isA<WorkspaceHomeApiException>()));
  });

  test('status inesperado vira exception tipada', () {
    final client = HttpWorkspaceHomeApiClient(
      accessTokenProvider: () async => 'token-test',
      empresaIdProvider: () async => 'empresa-test',
      httpClient: MockClient((http.Request request) async {
        return http.Response('erro', 503);
      }),
    );

    expect(client.buscarHome, throwsA(isA<WorkspaceHomeApiException>()));
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

const String _workspaceHomeJson = '''
{
  "date": "2026-08-10",
  "timeZone": "America/Sao_Paulo",
  "cash": {
    "available": true,
    "open": true,
    "sessionId": "sessao-1",
    "openedAt": "2026-08-10T08:12:00",
    "responsibleName": "Carlos"
  },
  "technicalServices": {
    "available": true,
    "active": 8,
    "waitingApproval": 5,
    "late": 3,
    "readyForPickup": 4
  },
  "financial": {
    "available": true,
    "receivableToday": { "count": 4, "amount": 1240.50 },
    "payableToday": { "count": 2, "amount": 680.00 },
    "overdueReceivable": { "count": 1, "amount": 230.00 },
    "overduePayable": { "count": 3, "amount": 540.00 }
  },
  "stock": {
    "available": true,
    "belowMinimum": 6,
    "withoutStock": 2,
    "negative": 1
  }
}
''';
