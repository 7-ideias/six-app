import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/billing_http_client.dart';

void main() {
  tearDown(() {
    billingCompanyResolver = null;
    paymentRequiredCompany.value = null;
  });
  test(
    '402 preserves the response and does not replay the operation',
    () async {
      var calls = 0;
      billingCompanyResolver = () async => 'a';
      final client = BillingHttpClient(
        MockClient((request) async {
          calls++;
          expect(request.headers['idUnicoDaEmpresa'], 'a');
          return http.Response('{"code":"PAYMENT_REQUIRED"}', 402);
        }),
      );
      final response = await client.post(
        Uri.parse('${AppConfig.baseUrl}/operacao/inserir'),
        headers: {'Authorization': 'Bearer test'},
      );
      expect(response.statusCode, 402);
      expect(calls, 1);
      expect(paymentRequiredCompany.value, 'a');
      client.close();
    },
  );
  test(
    'late response from previous commerce does not block current commerce',
    () async {
      var selected = 'a';
      billingCompanyResolver = () async => selected;
      final started = Completer<void>();
      final finish = Completer<void>();
      final client = BillingHttpClient(
        MockClient((request) async {
          started.complete();
          await finish.future;
          return http.Response('', 402);
        }),
      );
      final pending = client.get(
        Uri.parse('${AppConfig.baseUrl}/private/api/produto/lista'),
        headers: {'Authorization': 'Bearer test'},
      );
      await started.future;
      selected = 'b';
      finish.complete();
      await pending;
      expect(paymentRequiredCompany.value, isNull);
      client.close();
    },
  );
  test('third party requests never receive commerce context', () async {
    billingCompanyResolver = () async => 'private-company';
    final client = BillingHttpClient(
      MockClient((request) async {
        expect(
          request.headers.keys.any(
            (key) => key.toLowerCase() == 'idunicodaempresa',
          ),
          isFalse,
        );
        return http.Response('', 402);
      }),
    );
    await client.get(
      Uri.parse('https://example.invalid/api'),
      headers: {'Authorization': 'Bearer test'},
    );
    expect(paymentRequiredCompany.value, isNull);
    client.close();
  });
}
