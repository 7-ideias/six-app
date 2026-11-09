class StorageLimits {
  const StorageLimits({
    this.databaseLimitBytes,
    this.fileLimitBytes,
    this.maxUploadBytes,
    this.version = 0,
  });
  final int? databaseLimitBytes;
  final int? fileLimitBytes;
  final int? maxUploadBytes;
  final int version;
  factory StorageLimits.fromJson(Map<String, dynamic> json) => StorageLimits(
    databaseLimitBytes: _integer(json['databaseLimitBytes'], positive: true),
    fileLimitBytes: _integer(json['fileLimitBytes'], positive: true),
    maxUploadBytes: _integer(json['maxUploadBytes'], positive: true),
    version: _integer(json['version']) ?? 0,
  );
  Map<String, dynamic> toRequest() => {
    'databaseLimitBytes': databaseLimitBytes,
    'fileLimitBytes': fileLimitBytes,
    'maxUploadBytes': maxUploadBytes,
    'expectedVersion': version,
  };
  static const maxBytes = 1000000000000000;
}

class StoragePlan {
  const StoragePlan({
    required this.id,
    required this.code,
    required this.status,
    required this.names,
    required this.limits,
  });
  final String id;
  final String code;
  final String status;
  final Map<String, String> names;
  final StorageLimits limits;
  bool get assignable => status == 'PUBLICADO';
  bool get editable => status != 'ARQUIVADO';
  factory StoragePlan.fromJson(Map<String, dynamic> json) => StoragePlan(
    id: json['id'] as String,
    code: json['code'] as String,
    status: json['status'] as String,
    names: Map<String, String>.from(json['names'] as Map),
    limits: StorageLimits.fromJson(json['limits'] as Map<String, dynamic>),
  );
  String name(String locale) => storagePlanName(names, code, locale);
}

class StorageEffectivePlan {
  const StorageEffectivePlan({
    this.planId,
    this.code,
    this.names = const {},
    this.assignmentVersion = 0,
    this.limits = const StorageLimits(),
  });
  final String? planId;
  final String? code;
  final Map<String, String> names;
  final int assignmentVersion;
  final StorageLimits limits;
  factory StorageEffectivePlan.fromJson(Map<String, dynamic> json) =>
      StorageEffectivePlan(
        planId: json['planId'] as String?,
        code: json['code'] as String?,
        names: Map<String, String>.from(json['names'] as Map? ?? {}),
        assignmentVersion: _integer(json['assignmentVersion']) ?? 0,
        limits: StorageLimits.fromJson(
          json['limits'] as Map<String, dynamic>? ?? {},
        ),
      );
  Map<String, dynamic> assignmentRequest(String? id) => {
    'planId': id,
    'expectedVersion': assignmentVersion,
  };
  String name(String locale) => storagePlanName(names, code ?? '', locale);
}

String storagePlanName(
  Map<String, String> names,
  String fallback,
  String locale,
) {
  final normalized = locale.replaceAll('_', '-');
  final exact = names[normalized];
  if (exact != null && exact.trim().isNotEmpty) return exact;
  final language = normalized.split('-').first;
  for (final entry in names.entries) {
    if (entry.key.split(RegExp('[-_]')).first == language &&
        entry.value.trim().isNotEmpty)
      return entry.value;
  }
  return fallback;
}

int? _integer(dynamic value, {bool positive = false}) {
  if (value == null) return null;
  if (value is! num ||
      !value.isFinite ||
      value != value.toInt() ||
      value < (positive ? 1 : 0) ||
      value > StorageLimits.maxBytes) {
    throw const FormatException('Invalid storage limit');
  }
  return value.toInt();
}

String storageQuotaStatus(int? used, int? limit) {
  if (limit == null) return 'quotaNotConfigured';
  if (used == null) return 'noMeasurement';
  if (used > limit) return 'quotaExceeded';
  if (used == limit) return 'quotaReached';
  if (used >= (limit * 4 + 4) ~/ 5) return 'quotaNear';
  return 'quotaWithin';
}

// Exact decimal MB input; no floating-point rounding or silent truncation.
int? storageMegabytesToBytes(String input, String decimalSeparator) {
  final text = input.trim();
  if (text.isEmpty) return null;
  if (decimalSeparator != '.' && text.contains('.'))
    throw const FormatException('invalidLimits');
  final normalized = decimalSeparator == '.'
      ? text
      : text.replaceAll(decimalSeparator, '.');
  if (!RegExp(r'^\d+(\.\d{1,6})?$').hasMatch(normalized))
    throw const FormatException('invalidLimits');
  final parts = normalized.split('.');
  final bytes =
      BigInt.parse(parts.first) * BigInt.from(1000000) +
      BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(6, '0'));
  if (bytes <= BigInt.zero || bytes > BigInt.from(StorageLimits.maxBytes))
    throw const FormatException('invalidLimits');
  return bytes.toInt();
}

String storageBytesToMegabytes(int? bytes, String decimalSeparator) {
  if (bytes == null) return '';
  final fraction = (bytes % 1000000)
      .toString()
      .padLeft(6, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${bytes ~/ 1000000}${fraction.isEmpty ? '' : '$decimalSeparator$fraction'}';
}
