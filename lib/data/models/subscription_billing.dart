class BillingOffer {
  const BillingOffer({
    required this.planId,
    required this.name,
    required this.interval,
    required this.currency,
    required this.amountMinor,
    this.description = '',
    this.benefits = const [],
    this.featured = false,
  });
  factory BillingOffer.fromJson(Map<String, dynamic> json) => BillingOffer(
    planId: json['planId'] as String,
    name: json['name'] as String,
    interval: json['interval'] as String,
    currency: json['currency'] as String,
    amountMinor: (json['amountMinor'] as num).toInt(),
    description: json['description'] as String? ?? '',
    benefits: (json['benefits'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    featured: json['featured'] == true,
  );
  final String planId, name, interval, currency;
  final int amountMinor;
  final String description;
  final List<String> benefits;
  final bool featured;
  Map<String, dynamic> purchase({String locale = 'pt-BR'}) => {
    'planId': planId,
    'interval': interval,
    'currency': currency,
    'expectedAmountMinor': amountMinor,
    'locale': locale,
  };
}

class SubscriptionSummary {
  SubscriptionSummary.fromJson(Map<String, dynamic> json)
    : companyId = json['companyId'] as String,
      available = json['available'] == true,
      testMode = json['testMode'] == true,
      canManage = json['canManage'] == true,
      hasSubscription = json['hasSubscription'] == true,
      cancelAtPeriodEnd = json['cancelAtPeriodEnd'] == true,
      status = json['status'] as String?,
      paidUntil = DateTime.tryParse(json['paidUntil'] as String? ?? ''),
      offers = (json['offers'] as List)
          .map((v) => BillingOffer.fromJson(v as Map<String, dynamic>))
          .toList(growable: false);
  final String companyId;
  final String? status;
  final bool available, testMode, canManage, hasSubscription, cancelAtPeriodEnd;
  final DateTime? paidUntil;
  final List<BillingOffer> offers;
}
