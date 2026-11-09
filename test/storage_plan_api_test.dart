import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/storage_plan.dart';
import 'package:sixpos/data/services/storage/storage_usage_api_client.dart';

class _Auth implements AuthService {
  @override
  Future<String?> getAccessToken() async => 'test-token';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'quota update sends bytes and expected version with authentication',
    () async {
      final client = StorageUsageApiClient(
        auth: _Auth(),
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(
            request.url.path,
            '/private/api/admin/armazenamento/planos/pro',
          );
          expect(request.headers['Authorization'], 'Bearer test-token');
          final body = jsonDecode(request.body) as Map;
          expect(body['fileLimitBytes'], 1000000);
          expect(body['expectedVersion'], 2);
          return http.Response(
            jsonEncode({
              'id': 'pro',
              'code': 'PRO',
              'status': 'PUBLICADO',
              'names': {},
              'limits': {'fileLimitBytes': 1000000, 'version': 3},
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      expect(
        (await client.saveLimits(
          'pro',
          const StorageLimits(fileLimitBytes: 1000000, version: 2),
        )).limits.version,
        3,
      );
    },
  );
  test('concurrent edit is surfaced instead of retried blindly', () async {
    int calls = 0;
    final client = StorageUsageApiClient(
      auth: _Auth(),
      client: MockClient((request) async {
        calls++;
        return http.Response('{}', 409);
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client.assignPlan(
        'company-a',
        'pro',
        const StorageEffectivePlan(assignmentVersion: 4),
      ),
      throwsA(
        isA<StorageUsageException>().having(
          (e) => e.code,
          'code',
          'planConflict',
        ),
      ),
    );
    expect(calls, 1);
  });
}
