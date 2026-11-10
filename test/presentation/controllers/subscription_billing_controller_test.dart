import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/billing_access.dart';
import 'package:sixpos/data/models/subscription_billing.dart';
import 'package:sixpos/data/services/billing_access_api.dart';
import 'package:sixpos/data/services/subscription_billing_api.dart';
import 'package:sixpos/presentation/controllers/subscription_billing_controller.dart';

SubscriptionSummary summary(String name) => SubscriptionSummary.fromJson({
  'companyId': 'shop',
  'available': true,
  'canManage': true,
  'offers': [
    {
      'planId': 'pro',
      'name': name,
      'interval': 'year',
      'currency': 'USD',
      'amountMinor': 100,
    },
  ],
});

class Api implements SubscriptionBillingApi {
  final requests = <String>[];
  final currencies = <String>[];
  final responses = <Completer<SubscriptionSummary>>[];
  @override
  Future<SubscriptionSummary> summary(
    String company, {
    bool sync = false,
    String locale = 'pt-BR',
    String currency = 'BRL',
  }) {
    requests.add(locale);
    currencies.add(currency);
    final result = Completer<SubscriptionSummary>();
    responses.add(result);
    return result.future;
  }

  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Access implements BillingAccessApi {
  @override
  Future<BillingAccess> load(String company, {bool admin = false}) async =>
      BillingAccess(
        companyId: company,
        status: 'PAYMENT_REQUIRED',
        allowed: false,
        manualRelease: false,
        version: 0,
      );
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'canonical locale overrides public URL and preserves selected currency',
    () async {
      final api = Api();
      final controller = SubscriptionBillingController(
        companyId: 'shop',
        api: api,
        accessApi: Access(),
        selection: Uri.parse(
          'https://sixoapp.com/app/assinatura?locale=pt-BR&currency=USD&plan=pro&interval=year',
        ),
      );
      addTearDown(controller.dispose);
      controller.setEffectiveLocale(const Locale('en', 'US'));
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, ['en-US']);
      expect(api.currencies, ['USD']);
      api.responses.single.complete(summary('Professional'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.visibleOffers.single.name, 'Professional');
      controller.setEffectiveLocale(const Locale('en', 'US'));
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, hasLength(1));
    },
  );

  test(
    'language change during request discards old result and reloads once',
    () async {
      final api = Api();
      final controller = SubscriptionBillingController(
        companyId: 'shop',
        api: api,
        accessApi: Access(),
      );
      addTearDown(controller.dispose);
      controller.setEffectiveLocale(const Locale('en', 'US'));
      await Future<void>.delayed(Duration.zero);
      controller.setEffectiveLocale(const Locale('es', 'ES'));
      api.responses.first.complete(summary('Old English'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.value, isNull);
      expect(api.requests, ['en-US', 'es-ES']);
      api.responses.last.complete(summary('Profesional'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.visibleOffers.single.name, 'Profesional');
    },
  );

  test(
    'missing locale falls back to Portuguese even with English URL',
    () async {
      final api = Api();
      final controller = SubscriptionBillingController(
        companyId: 'shop',
        api: api,
        accessApi: Access(),
        selection: Uri.parse('https://sixoapp.com/?locale=en-US'),
      );
      controller.setEffectiveLocale(null);
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, ['pt-BR']);
      controller.dispose();
      api.responses.single.complete(summary('Profissional'));
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, hasLength(1));
    },
  );
}
