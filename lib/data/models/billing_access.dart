class BillingAccess {
  const BillingAccess({
    required this.companyId,
    required this.status,
    required this.allowed,
    required this.manualRelease,
    required this.version,
    this.validUntil,
  });
  final String companyId;
  final String status;
  final bool allowed;
  final bool manualRelease;
  final int version;
  final DateTime? validUntil;
  factory BillingAccess.fromJson(Map<String, dynamic> json) => BillingAccess(
    companyId: json['companyId'] as String,
    status: json['status'] as String,
    allowed: json['allowed'] == true,
    manualRelease: json['manualRelease'] == true,
    version: (json['version'] as num).toInt(),
    validUntil: DateTime.tryParse(json['validUntil']?.toString() ?? ''),
  );
}
