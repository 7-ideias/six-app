import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/services/workspace_home/workspace_home_api_client.dart';

void main() {
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
