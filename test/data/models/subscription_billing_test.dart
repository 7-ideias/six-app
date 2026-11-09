import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/subscription_billing.dart';

void main() {
  test('purchase sends only selected plan, interval and expected amount', () {
    final offer = BillingOffer.fromJson({
      'planId': 'plan',
      'name': 'Plano',
      'interval': 'year',
      'currency': 'BRL',
      'amountMinor': 99900,
    });
    expect(offer.purchase(), {
      'planId': 'plan',
      'interval': 'year',
      'expectedAmountMinor': 99900,
    });
    expect(offer.currency, 'BRL');
  });
  test('summary preserves commerce authorization and cancellation state', () {
    final value = SubscriptionSummary.fromJson({
      'companyId': 'company',
      'available': true,
      'testMode': true,
      'canManage': false,
      'hasSubscription': true,
      'cancelAtPeriodEnd': true,
      'status': 'active',
      'paidUntil': '2026-12-09T12:00:00Z',
      'offers': [],
    });
    expect(value.canManage, isFalse);
    expect(value.hasSubscription, isTrue);
    expect(value.cancelAtPeriodEnd, isTrue);
    expect(value.paidUntil!.isUtc, isTrue);
    expect(value.companyId, 'company');
  });
}
