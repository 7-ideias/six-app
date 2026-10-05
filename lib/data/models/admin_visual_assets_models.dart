class AdminVisualAssetCompany {
  const AdminVisualAssetCompany({
    required this.id,
    required this.name,
    required this.timeZone,
  });

  final String id;
  final String name;
  final String timeZone;

  factory AdminVisualAssetCompany.fromJson(Map<String, dynamic> json) {
    return AdminVisualAssetCompany(
      id: json['idUnicoDaEmpresa']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      timeZone: json['timeZone']?.toString() ?? 'UTC',
    );
  }
}

class AdminVisualAssetItem {
  const AdminVisualAssetItem({
    required this.id,
    required this.slot,
    required this.platform,
    required this.scope,
    required this.environment,
    required this.version,
    required this.status,
    required this.imageUrl,
    required this.activateAtUtc,
    required this.timeZone,
    required this.width,
    required this.height,
    required this.focalX,
    required this.focalY,
    required this.migrated,
    this.companyId,
    this.segment,
    this.subsegments = const <String>[],
    this.includeWithoutSubsegment = false,
  });

  final String id;
  final String slot;
  final String platform;
  final String scope;
  final String environment;
  final String? companyId;
  final String? segment;
  final List<String> subsegments;
  final bool includeWithoutSubsegment;
  final String version;
  final String status;
  final DateTime? activateAtUtc;
  final String timeZone;
  final String imageUrl;
  final int width;
  final int height;
  final double focalX;
  final double focalY;
  final bool migrated;

  factory AdminVisualAssetItem.fromJson(Map<String, dynamic> json) {
    final dynamic rawSubs = json['subsegmentos'];
    return AdminVisualAssetItem(
      id: json['id']?.toString() ?? '',
      slot: json['slot']?.toString() ?? '',
      platform: json['plataforma']?.toString() ?? '',
      scope: json['escopo']?.toString() ?? '',
      environment: json['environment']?.toString() ?? 'LIVE',
      companyId: _nullable(json['idUnicoDaEmpresa']),
      segment: _nullable(json['segmentoPrincipal']),
      subsegments: rawSubs is List
          ? rawSubs.map((dynamic item) => item.toString()).toList()
          : const <String>[],
      includeWithoutSubsegment: json['incluiSemSubsegmento'] == true,
      version: json['versao']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      activateAtUtc: DateTime.tryParse(
        json['ativarEmUtc']?.toString() ?? '',
      )?.toUtc(),
      timeZone: json['timeZoneAtivacao']?.toString() ?? 'UTC',
      imageUrl: json['imageUrl']?.toString() ?? '',
      width: _int(json['width']),
      height: _int(json['height']),
      focalX: _double(json['focalX'], 0.5),
      focalY: _double(json['focalY'], 0.5),
      migrated: json['migrado'] == true,
    );
  }
}

class AdminVisualAssetSlotPanel {
  const AdminVisualAssetSlotPanel({
    required this.slot,
    required this.platform,
    required this.labelKey,
    required this.labelFallback,
    required this.recommendedWidth,
    required this.recommendedHeight,
    required this.displayMode,
    required this.additionalScheduled,
    required this.historyCount,
    this.current,
    this.fallback,
    this.next,
  });

  final String slot;
  final String platform;
  final String labelKey;
  final String labelFallback;
  final int recommendedWidth;
  final int recommendedHeight;
  final String displayMode;
  final AdminVisualAssetItem? current;
  final AdminVisualAssetItem? fallback;
  final AdminVisualAssetItem? next;
  final int additionalScheduled;
  final int historyCount;

  double get aspectRatio {
    if (recommendedWidth <= 0 || recommendedHeight <= 0) return 16 / 9;
    return recommendedWidth / recommendedHeight;
  }

  factory AdminVisualAssetSlotPanel.fromJson(Map<String, dynamic> json) {
    final dynamic current = json['current'];
    final dynamic fallback = json['fallback'];
    final dynamic next = json['next'];
    return AdminVisualAssetSlotPanel(
      slot: json['slot']?.toString() ?? '',
      platform: json['plataforma']?.toString() ?? '',
      fallback: fallback is Map
          ? AdminVisualAssetItem.fromJson(Map<String, dynamic>.from(fallback))
          : null,
      labelKey: json['labelKey']?.toString() ?? '',
      labelFallback: json['labelFallback']?.toString() ?? '',
      recommendedWidth: _int(json['recommendedWidth']),
      recommendedHeight: _int(json['recommendedHeight']),
      displayMode: json['displayMode']?.toString() ?? '',
      current: current is Map
          ? AdminVisualAssetItem.fromJson(
              Map<String, dynamic>.from(current),
            )
          : null,
      next: next is Map
          ? AdminVisualAssetItem.fromJson(
              Map<String, dynamic>.from(next),
            )
          : null,
      additionalScheduled: _int(json['additionalScheduled']),
      historyCount: _int(json['historyCount']),
    );
  }
}

class AdminVisualAssetPanel {
  const AdminVisualAssetPanel({
    required this.assetsVersion,
    required this.environment,
    required this.scope,
    required this.slots,
    this.companyId,
    this.segment,
    this.subsegment,
  });

  final String assetsVersion;
  final String environment;
  final String scope;
  final String? companyId;
  final String? segment;
  final String? subsegment;
  final List<AdminVisualAssetSlotPanel> slots;

  factory AdminVisualAssetPanel.fromJson(Map<String, dynamic> json) {
    final dynamic rawSlots = json['slots'];
    return AdminVisualAssetPanel(
      assetsVersion: json['assetsVersion']?.toString() ?? '',
      environment: json['environment']?.toString() ?? 'LIVE',
      scope: json['scope']?.toString() ?? 'GLOBAL',
      companyId: _nullable(json['idUnicoDaEmpresa']),
      segment: _nullable(json['segmentoPrincipal']),
      subsegment: _nullable(json['subsegmento']),
      slots: rawSlots is List
          ? rawSlots.whereType<Map>().map(
              (Map item) => AdminVisualAssetSlotPanel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ).toList(growable: false)
          : const <AdminVisualAssetSlotPanel>[],
    );
  }
}

String? _nullable(dynamic value) {
  final String normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

double _double(dynamic value, double fallback) =>
    value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? fallback;
