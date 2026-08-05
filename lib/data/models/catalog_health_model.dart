enum CatalogHealthMetricType {
  products,
  services,
  missingPhoto,
  outOfStock,
  lowStock,
  highStock,
  withoutSales,
  incompleteRegistration,
  missingCategory,
  unknown,
}

enum CatalogHealthMetricSeverity { neutral, informative, warning, critical }

class CatalogHealthSummary {
  const CatalogHealthSummary({
    required this.header,
    required this.health,
    required this.thermometer,
    required this.overview,
    required this.actions,
    required this.pendingSection,
    required this.appliedCustomization,
    required this.metrics,
    this.trend,
    required this.isDemonstrationData,
  });

  factory CatalogHealthSummary.empty() {
    const CatalogHealthOverviewItem emptyProducts = CatalogHealthOverviewItem(
      quantity: 0,
      title: 'Produtos',
      description: '',
      iconCode: 'PRODUTO',
      actionCode: 'ABRIR_LISTA_PRODUTOS',
    );
    const CatalogHealthOverviewItem emptyServices = CatalogHealthOverviewItem(
      quantity: 0,
      title: 'Serviços',
      description: '',
      iconCode: 'SERVICO',
      actionCode: 'ABRIR_LISTA_SERVICOS',
    );

    return CatalogHealthSummary(
      header: const CatalogHealthHeader(
        title: 'Saúde do catálogo',
        description: '',
        badge: '',
      ),
      health: const CatalogHealthScore(
        percentage: 0,
        percentageDecimal: 0,
        situation: 'SEM_DADOS',
        severity: 'NEUTRA',
        temperatureLevel: 'FRIO',
        semanticColor: 'NEUTRO',
        title: '0% de saúde',
        description: '',
        calculationVersion: '',
      ),
      thermometer: const CatalogHealthThermometer(
        value: 0,
        min: 0,
        max: 100,
        unit: 'PERCENTUAL',
        centerLabel: '0%',
        segments: <CatalogHealthThermometerSegment>[],
      ),
      overview: const CatalogHealthOverview(
        attentionItems: 0,
        products: emptyProducts,
        services: emptyServices,
      ),
      actions: const <CatalogHealthAction>[],
      pendingSection: const CatalogHealthPendingSection(
        title: 'Pendências',
        description: '',
        total: 0,
        items: <CatalogHealthMetric>[],
      ),
      appliedCustomization: const CatalogHealthCustomization(
        lowStockThreshold: 0,
        highStockThreshold: 0,
        inactiveSalesDays: 0,
        includeProductsWithoutPhoto: false,
        includeProductsWithoutCategory: false,
        includeProductsWithoutSales: false,
        includeProductsWithHighStock: false,
        includeServices: false,
        weights: <String, int>{},
      ),
      metrics: const <CatalogHealthMetric>[
        CatalogHealthMetric(
          type: CatalogHealthMetricType.products,
          code: 'PRODUTOS',
          title: 'Produtos',
          subtitle: '',
          value: 0,
          iconCode: 'PRODUTO',
        ),
        CatalogHealthMetric(
          type: CatalogHealthMetricType.services,
          code: 'SERVICOS',
          title: 'Serviços',
          subtitle: '',
          value: 0,
          iconCode: 'SERVICO',
        ),
      ],
      isDemonstrationData: false,
    );
  }

  factory CatalogHealthSummary.fromJson(Map<String, dynamic> json) {
    final CatalogHealthHeader header = CatalogHealthHeader.fromJson(
      _asMap(json['cabecalho']),
    );
    final CatalogHealthOverview overview = CatalogHealthOverview.fromJson(
      _asMap(json['resumo']),
    );
    final CatalogHealthPendingSection pendingSection =
        CatalogHealthPendingSection.fromJson(_asMap(json['secaoPendencias']));

    final List<CatalogHealthMetric> metrics = <CatalogHealthMetric>[
      overview.products.toMetric(
        type: CatalogHealthMetricType.products,
        code: 'PRODUTOS',
      ),
      overview.services.toMetric(
        type: CatalogHealthMetricType.services,
        code: 'SERVICOS',
      ),
      ...pendingSection.items,
    ];

    return CatalogHealthSummary(
      header: header,
      health: CatalogHealthScore.fromJson(_asMap(json['saudeCatalogo'])),
      thermometer: CatalogHealthThermometer.fromJson(
        _asMap(json['termometro']),
      ),
      overview: overview,
      actions: _asList(json['acoes'])
          .map((dynamic item) => CatalogHealthAction.fromJson(_asMap(item)))
          .toList(growable: false),
      pendingSection: pendingSection,
      appliedCustomization: CatalogHealthCustomization.fromJson(
        _asMap(json['personalizacaoAplicada']),
      ),
      trend:
          json['tendencia'] == null
              ? null
              : CatalogHealthTrend.fromJson(_asMap(json['tendencia'])),
      metrics: metrics,
      isDemonstrationData: header.badge.toLowerCase().contains('demonstrativo'),
    );
  }

  final CatalogHealthHeader header;
  final CatalogHealthScore health;
  final CatalogHealthThermometer thermometer;
  final CatalogHealthOverview overview;
  final List<CatalogHealthAction> actions;
  final CatalogHealthPendingSection pendingSection;
  final CatalogHealthCustomization appliedCustomization;
  final CatalogHealthTrend? trend;
  final List<CatalogHealthMetric> metrics;
  final bool isDemonstrationData;

  bool get isEmpty =>
      overview.products.quantity == 0 &&
      overview.services.quantity == 0 &&
      attentionItems == 0;

  int get attentionItems {
    if (pendingSection.total > 0) return pendingSection.total;
    return pendingSection.items.fold<int>(
      0,
      (int total, CatalogHealthMetric metric) => total + metric.value,
    );
  }

  CatalogHealthMetric? metric(CatalogHealthMetricType type) {
    for (final CatalogHealthMetric metric in metrics) {
      if (metric.type == type) return metric;
    }
    return null;
  }

  CatalogHealthAction? action(String code) {
    for (final CatalogHealthAction action in actions) {
      if (action.code == code) return action;
    }
    return null;
  }
}

class CatalogHealthHeader {
  const CatalogHealthHeader({
    required this.title,
    required this.description,
    required this.badge,
  });

  factory CatalogHealthHeader.fromJson(Map<String, dynamic> json) {
    return CatalogHealthHeader(
      title: _string(json, 'titulo', 'Saúde do catálogo'),
      description: _string(json, 'descricao'),
      badge: _string(json, 'badge'),
    );
  }

  final String title;
  final String description;
  final String badge;
}

class CatalogHealthScore {
  const CatalogHealthScore({
    required this.percentage,
    required this.percentageDecimal,
    required this.situation,
    required this.severity,
    required this.temperatureLevel,
    required this.semanticColor,
    required this.title,
    required this.description,
    this.evaluatedAt,
    required this.calculationVersion,
  });

  factory CatalogHealthScore.fromJson(Map<String, dynamic> json) {
    return CatalogHealthScore(
      percentage: _int(json, 'percentual'),
      percentageDecimal: _double(json, 'percentualDecimal'),
      situation: _string(json, 'situacao'),
      severity: _string(json, 'severidade'),
      temperatureLevel: _string(json, 'nivelTemperatura'),
      semanticColor: _string(json, 'corSemantica'),
      title: _string(json, 'titulo'),
      description: _string(json, 'descricao'),
      evaluatedAt: DateTime.tryParse(_string(json, 'avaliadoEm')),
      calculationVersion: _string(json, 'versaoCalculo'),
    );
  }

  final int percentage;
  final double percentageDecimal;
  final String situation;
  final String severity;
  final String temperatureLevel;
  final String semanticColor;
  final String title;
  final String description;
  final DateTime? evaluatedAt;
  final String calculationVersion;
}

class CatalogHealthThermometer {
  const CatalogHealthThermometer({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.centerLabel,
    required this.segments,
  });

  factory CatalogHealthThermometer.fromJson(Map<String, dynamic> json) {
    return CatalogHealthThermometer(
      value: _int(json, 'valor'),
      min: _int(json, 'minimo'),
      max: _int(json, 'maximo', 100),
      unit: _string(json, 'unidade', 'PERCENTUAL'),
      centerLabel: _string(json, 'rotuloCentral'),
      segments: _asList(json['segmentos'])
          .map(
            (dynamic item) =>
                CatalogHealthThermometerSegment.fromJson(_asMap(item)),
          )
          .toList(growable: false),
    );
  }

  final int value;
  final int min;
  final int max;
  final String unit;
  final String centerLabel;
  final List<CatalogHealthThermometerSegment> segments;
}

class CatalogHealthThermometerSegment {
  const CatalogHealthThermometerSegment({
    required this.start,
    required this.end,
    required this.code,
    required this.title,
    required this.semanticColor,
  });

  factory CatalogHealthThermometerSegment.fromJson(Map<String, dynamic> json) {
    return CatalogHealthThermometerSegment(
      start: _int(json, 'inicio'),
      end: _int(json, 'fim'),
      code: _string(json, 'codigo'),
      title: _string(json, 'titulo'),
      semanticColor: _string(json, 'corSemantica'),
    );
  }

  final int start;
  final int end;
  final String code;
  final String title;
  final String semanticColor;
}

class CatalogHealthOverview {
  const CatalogHealthOverview({
    required this.attentionItems,
    required this.products,
    required this.services,
  });

  factory CatalogHealthOverview.fromJson(Map<String, dynamic> json) {
    return CatalogHealthOverview(
      attentionItems: _int(json, 'itensPrecisamAtencao'),
      products: CatalogHealthOverviewItem.fromJson(_asMap(json['produtos'])),
      services: CatalogHealthOverviewItem.fromJson(_asMap(json['servicos'])),
    );
  }

  final int attentionItems;
  final CatalogHealthOverviewItem products;
  final CatalogHealthOverviewItem services;
}

class CatalogHealthOverviewItem {
  const CatalogHealthOverviewItem({
    required this.quantity,
    required this.title,
    required this.description,
    required this.iconCode,
    required this.actionCode,
  });

  factory CatalogHealthOverviewItem.fromJson(Map<String, dynamic> json) {
    return CatalogHealthOverviewItem(
      quantity: _int(json, 'quantidade'),
      title: _string(json, 'titulo'),
      description: _string(json, 'descricao'),
      iconCode: _string(json, 'icone'),
      actionCode: _string(json, 'acao'),
    );
  }

  final int quantity;
  final String title;
  final String description;
  final String iconCode;
  final String actionCode;

  CatalogHealthMetric toMetric({
    required CatalogHealthMetricType type,
    required String code,
  }) {
    return CatalogHealthMetric(
      type: type,
      code: code,
      title: title,
      subtitle: description,
      value: quantity,
      iconCode: iconCode,
      action: CatalogHealthTapAction(type: actionCode),
    );
  }
}

class CatalogHealthAction {
  const CatalogHealthAction({
    required this.code,
    required this.title,
    required this.type,
    required this.iconCode,
  });

  factory CatalogHealthAction.fromJson(Map<String, dynamic> json) {
    return CatalogHealthAction(
      code: _string(json, 'codigo'),
      title: _string(json, 'titulo'),
      type: _string(json, 'tipo'),
      iconCode: _string(json, 'icone'),
    );
  }

  final String code;
  final String title;
  final String type;
  final String iconCode;
}

class CatalogHealthPendingSection {
  const CatalogHealthPendingSection({
    required this.title,
    required this.description,
    required this.total,
    required this.items,
  });

  factory CatalogHealthPendingSection.fromJson(Map<String, dynamic> json) {
    final List<CatalogHealthMetric> items = _asList(json['itens'])
      .map((dynamic item) => CatalogHealthMetric.fromPendingJson(_asMap(item)))
      .toList(growable: false)..sort(
      (CatalogHealthMetric first, CatalogHealthMetric second) =>
          first.priority.compareTo(second.priority),
    );

    return CatalogHealthPendingSection(
      title: _string(json, 'titulo', 'Pendências'),
      description: _string(json, 'descricao'),
      total: _int(json, 'total'),
      items: items,
    );
  }

  final String title;
  final String description;
  final int total;
  final List<CatalogHealthMetric> items;
}

class CatalogHealthMetric {
  const CatalogHealthMetric({
    required this.type,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.iconCode,
    this.semanticColor = 'NEUTRO',
    this.category = '',
    this.severity = CatalogHealthMetricSeverity.neutral,
    this.requiresStockPermission = false,
    this.countsAsAttention = false,
    this.priority = 0,
    this.impact,
    this.action,
  });

  factory CatalogHealthMetric.fromPendingJson(Map<String, dynamic> json) {
    final String code = _string(json, 'codigo');
    final String category = _string(json, 'categoria');

    return CatalogHealthMetric(
      type: _metricTypeFromCode(code),
      code: code,
      title: _string(json, 'titulo'),
      subtitle: _string(json, 'descricao'),
      value: _int(json, 'quantidade'),
      iconCode: _string(json, 'icone'),
      semanticColor: _string(json, 'corSemantica'),
      category: category,
      severity: _severityFromCode(_string(json, 'severidade')),
      requiresStockPermission: category == 'ESTOQUE' || _isStockMetric(code),
      countsAsAttention: true,
      priority: _int(json, 'prioridade', 999),
      impact: CatalogHealthImpact.fromJson(_asMap(json['impactoSaude'])),
      action: CatalogHealthTapAction.fromJson(_asMap(json['acaoAoTocar'])),
    );
  }

  final CatalogHealthMetricType type;
  final String code;
  final String title;
  final String subtitle;
  final int value;
  final String iconCode;
  final String semanticColor;
  final String category;
  final CatalogHealthMetricSeverity severity;
  final bool requiresStockPermission;
  final bool countsAsAttention;
  final int priority;
  final CatalogHealthImpact? impact;
  final CatalogHealthTapAction? action;

  bool get isPositive => value == 0 && countsAsAttention;
}

class CatalogHealthImpact {
  const CatalogHealthImpact({
    required this.lostPoints,
    required this.maxPoints,
    required this.affectedPercentage,
  });

  factory CatalogHealthImpact.fromJson(Map<String, dynamic> json) {
    return CatalogHealthImpact(
      lostPoints: _double(json, 'pontosPerdidos'),
      maxPoints: _double(json, 'pontosMaximos'),
      affectedPercentage: _double(json, 'percentualAfetado'),
    );
  }

  final double lostPoints;
  final double maxPoints;
  final double affectedPercentage;
}

class CatalogHealthTapAction {
  const CatalogHealthTapAction({
    required this.type,
    this.filter = const <String, dynamic>{},
  });

  factory CatalogHealthTapAction.fromJson(Map<String, dynamic> json) {
    return CatalogHealthTapAction(
      type: _string(json, 'tipo'),
      filter: _asMap(json['filtro']),
    );
  }

  final String type;
  final Map<String, dynamic> filter;
}

class CatalogHealthCustomization {
  const CatalogHealthCustomization({
    this.companyId,
    required this.lowStockThreshold,
    required this.highStockThreshold,
    required this.inactiveSalesDays,
    required this.includeProductsWithoutPhoto,
    required this.includeProductsWithoutCategory,
    required this.includeProductsWithoutSales,
    required this.includeProductsWithHighStock,
    required this.includeServices,
    required this.weights,
  });

  factory CatalogHealthCustomization.fromJson(Map<String, dynamic> json) {
    return CatalogHealthCustomization(
      companyId: _string(json, 'idEmpresa'),
      lowStockThreshold: _int(json, 'limiteEstoqueBaixo'),
      highStockThreshold: _int(json, 'limiteEstoqueAlto'),
      inactiveSalesDays: _int(json, 'diasSemVenda'),
      includeProductsWithoutPhoto: _bool(json, 'considerarProdutosSemFoto'),
      includeProductsWithoutCategory: _bool(
        json,
        'considerarProdutosSemCategoria',
      ),
      includeProductsWithoutSales: _bool(json, 'considerarProdutosSemVenda'),
      includeProductsWithHighStock: _bool(
        json,
        'considerarProdutosComEstoqueAlto',
      ),
      includeServices: _bool(json, 'considerarServicos'),
      weights: _asIntMap(json['pesos']),
    );
  }

  final String? companyId;
  final int lowStockThreshold;
  final int highStockThreshold;
  final int inactiveSalesDays;
  final bool includeProductsWithoutPhoto;
  final bool includeProductsWithoutCategory;
  final bool includeProductsWithoutSales;
  final bool includeProductsWithHighStock;
  final bool includeServices;
  final Map<String, int> weights;
}

class CatalogHealthTrend {
  const CatalogHealthTrend({
    required this.previousPercentage,
    required this.percentageDelta,
    required this.period,
  });

  factory CatalogHealthTrend.fromJson(Map<String, dynamic> json) {
    return CatalogHealthTrend(
      previousPercentage: _double(json, 'percentualAnterior'),
      percentageDelta: _double(json, 'variacaoPercentual'),
      period: _string(json, 'periodo'),
    );
  }

  final double previousPercentage;
  final double percentageDelta;
  final String period;
}

CatalogHealthMetricType _metricTypeFromCode(String code) {
  switch (code) {
    case 'PRODUTOS':
      return CatalogHealthMetricType.products;
    case 'SERVICOS':
      return CatalogHealthMetricType.services;
    case 'SEM_FOTO':
      return CatalogHealthMetricType.missingPhoto;
    case 'SEM_ESTOQUE':
      return CatalogHealthMetricType.outOfStock;
    case 'ESTOQUE_BAIXO':
      return CatalogHealthMetricType.lowStock;
    case 'ESTOQUE_ALTO':
      return CatalogHealthMetricType.highStock;
    case 'SEM_VENDAS':
      return CatalogHealthMetricType.withoutSales;
    case 'CADASTRO_INCOMPLETO':
      return CatalogHealthMetricType.incompleteRegistration;
    case 'SEM_CATEGORIA':
      return CatalogHealthMetricType.missingCategory;
    default:
      return CatalogHealthMetricType.unknown;
  }
}

CatalogHealthMetricSeverity _severityFromCode(String code) {
  switch (code) {
    case 'CRITICA':
      return CatalogHealthMetricSeverity.critical;
    case 'ALERTA':
      return CatalogHealthMetricSeverity.warning;
    case 'INFORMATIVA':
      return CatalogHealthMetricSeverity.informative;
    default:
      return CatalogHealthMetricSeverity.neutral;
  }
}

bool _isStockMetric(String code) {
  return code == 'SEM_ESTOQUE' ||
      code == 'ESTOQUE_BAIXO' ||
      code == 'ESTOQUE_ALTO';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

Map<String, int> _asIntMap(dynamic value) {
  if (value is! Map) return const <String, int>{};

  return value.map<String, int>((dynamic key, dynamic item) {
    final int parsedValue =
        item is num ? item.toInt() : int.tryParse(item.toString()) ?? 0;
    return MapEntry<String, int>(key.toString(), parsedValue);
  });
}

String _string(Map<String, dynamic> json, String key, [String fallback = '']) {
  final dynamic value = json[key];
  if (value == null) return fallback;
  final String text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _int(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final dynamic value = json[key];
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(Map<String, dynamic> json, String key, [double fallback = 0]) {
  final dynamic value = json[key];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final dynamic value = json[key];
  if (value is bool) return value;
  return bool.tryParse(value?.toString() ?? '') ?? fallback;
}
