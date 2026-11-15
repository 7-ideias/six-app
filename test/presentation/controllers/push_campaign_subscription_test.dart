import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/billing_access.dart';
import 'package:sixpos/data/models/subscription_billing.dart';
import 'package:sixpos/data/services/billing_access_api.dart';
import 'package:sixpos/data/services/subscription_billing_api.dart';
import 'package:sixpos/presentation/controllers/subscription_billing_controller.dart';

class CampaignApi implements SubscriptionBillingApi {
  String? requestedCompany, requestedLocale, requestedCurrency;
  @override
  Future<Map<String, dynamic>> campaignContext(String id) async => {
    'companyId': 'target',
    'languageCode': 'en',
    'currency': 'USD',
  };
  @override
  Future<SubscriptionSummary> summary(
    String company, {
    bool sync = false,
    String locale = 'pt-BR',
    String currency = 'BRL',
  }) async {
    requestedCompany = company;
    requestedLocale = locale;
    requestedCurrency = currency;
    return SubscriptionSummary.fromJson({
      'companyId': company,
      'available': true,
      'canManage': true,
      'offers': [],
    });
  }

  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CampaignAccess implements BillingAccessApi {
  @override
  Future<BillingAccess> load(String company, {bool admin = false}) async =>
      BillingAccess(
        companyId: company,
        status: 'TRIAL',
        allowed: true,
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
  test('campanha usa empresa idioma e moeda validados pelo backend', () async {
    final api = CampaignApi();
    final controller = SubscriptionBillingController(
      companyId: 'old-company',
      campaignId: 'campaign',
      api: api,
      accessApi: CampaignAccess(),
    );
    controller.setEffectiveLocale(const Locale('pt'));
    await controller.load();
    expect(api.requestedCompany, 'target');
    expect(api.requestedLocale, 'en-US');
    expect(api.requestedCurrency, 'USD');
    expect(controller.value?.companyId, 'target');
    controller.dispose();
  });
}
