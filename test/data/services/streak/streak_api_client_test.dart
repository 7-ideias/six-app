import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/streak_models.dart';
import 'package:sixpos/data/services/streak/streak_api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
  });

  test('getStreaks consulta endpoint compartilhado com timezone', () async {
    late http.Request capturedRequest;
    final client = HttpStreakApiClient(
      httpClient: MockClient((http.Request request) async {
        capturedRequest = request;
        return _jsonResponse(_streaksJson);
      }),
    );

    final result = await client.getStreaks(timezone: 'America/Sao_Paulo');

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/private/api/me/streaks');
    expect(capturedRequest.headers['Authorization'], 'Bearer token-test');
    expect(capturedRequest.headers['idUnicoDaEmpresa'], 'empresa-test');
    expect(capturedRequest.headers['X-Six-Timezone'], 'America/Sao_Paulo');
    expect(result.shared.currentDays, 12);
  });

  test('registerActivity envia MOBILE sem userId nem data', () async {
    late http.Request capturedRequest;
    final client = HttpStreakApiClient(
      httpClient: MockClient((http.Request request) async {
        capturedRequest = request;
        return _jsonResponse(_streaksJson);
      }),
    );

    await client.registerActivity(
      const StreakActivityRequest(
        platform: StreakPlatform.mobile,
        timezone: 'America/Sao_Paulo',
      ),
    );

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/private/api/me/streaks/activity');
    expect(body['platform'], 'MOBILE');
    expect(body['timezone'], 'America/Sao_Paulo');
    expect(body.containsKey('userId'), isFalse);
    expect(body.containsKey('day'), isFalse);
    expect(body.containsKey('currentDays'), isFalse);
    expect(body.containsKey('longestDays'), isFalse);
  });

  test('status inesperado vira exception tipada', () async {
    final client = HttpStreakApiClient(
      httpClient: MockClient((http.Request request) async {
        return http.Response('erro', 503);
      }),
    );

    expect(() => client.getStreaks(), throwsA(isA<StreakApiException>()));
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

const String _streaksJson = '''
{
  "mobile": {
    "currentDays": 5,
    "longestDays": 18,
    "activeToday": true,
    "lastActivityDay": "2026-08-09"
  },
  "web": {
    "currentDays": 2,
    "longestDays": 9,
    "activeToday": true,
    "lastActivityDay": "2026-08-09"
  },
  "shared": {
    "currentDays": 12,
    "longestDays": 31,
    "activeToday": true,
    "lastActivityDay": "2026-08-09"
  }
}
''';
