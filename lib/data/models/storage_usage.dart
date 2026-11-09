class StorageUsage {
  const StorageUsage({
    required this.companyId,
    required this.status,
    this.databaseBytes,
    this.fileBytes,
    this.fileCount,
    this.measuredAt,
  });

  final String companyId;
  final String status;
  final int? databaseBytes;
  final int? fileBytes;
  final int? fileCount;
  final DateTime? measuredAt;

  bool get pending => status == 'PENDENTE' || status == 'PROCESSANDO';

  factory StorageUsage.fromJson(Map<String, dynamic> json) {
    if (json['companyId'] is! String || json['status'] is! String) {
      throw const FormatException('Invalid storage response');
    }
    int? bytes(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! num || value < 0 || value != value.toInt()) {
        throw const FormatException('Invalid storage amount');
      }
      return value.toInt();
    }

    return StorageUsage(
      companyId: json['companyId'] as String,
      status: json['status'] as String,
      databaseBytes: bytes('databaseBytes'),
      fileBytes: bytes('fileBytes'),
      fileCount: bytes('fileCount'),
      measuredAt: json['measuredAt'] == null
          ? null
          : DateTime.parse(json['measuredAt'] as String),
    );
  }
}
