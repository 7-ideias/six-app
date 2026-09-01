enum ProcedureStatus { draft, active, inactive }

enum ProcedureOperationPoint {
  saleStartBefore,
  saleFinishBefore,
  technicalServiceStartBefore,
  cashRegisterStartBefore,
}

enum ProcedurePlatform { mobile, web }

extension ProcedureOperationPointDetails on ProcedureOperationPoint {
  String get id {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore => 'sale.start.before',
      ProcedureOperationPoint.saleFinishBefore => 'sale.finish.before',
      ProcedureOperationPoint.technicalServiceStartBefore =>
        'technical-service.start.before',
      ProcedureOperationPoint.cashRegisterStartBefore =>
        'cash-register.start.before',
    };
  }

  ProcedureOperationType get operationType {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore => ProcedureOperationType.sale,
      ProcedureOperationPoint.saleFinishBefore => ProcedureOperationType.sale,
      ProcedureOperationPoint.technicalServiceStartBefore =>
        ProcedureOperationType.technicalService,
      ProcedureOperationPoint.cashRegisterStartBefore =>
        ProcedureOperationType.cashRegister,
    };
  }

  ProcedureTriggerMoment get triggerMoment {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore =>
        ProcedureTriggerMoment.beforeStart,
      ProcedureOperationPoint.saleFinishBefore =>
        ProcedureTriggerMoment.beforeFinish,
      ProcedureOperationPoint.technicalServiceStartBefore =>
        ProcedureTriggerMoment.beforeStart,
      ProcedureOperationPoint.cashRegisterStartBefore =>
        ProcedureTriggerMoment.beforeStart,
    };
  }

  bool get mobileAvailable {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore ||
      ProcedureOperationPoint.saleFinishBefore ||
      ProcedureOperationPoint.technicalServiceStartBefore ||
      ProcedureOperationPoint.cashRegisterStartBefore => true,
    };
  }

  bool get webAvailable {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore ||
      ProcedureOperationPoint.saleFinishBefore ||
      ProcedureOperationPoint.technicalServiceStartBefore ||
      ProcedureOperationPoint.cashRegisterStartBefore => true,
    };
  }

  bool isAvailableOn(ProcedurePlatform platform) {
    return switch (platform) {
      ProcedurePlatform.mobile => mobileAvailable,
      ProcedurePlatform.web => webAvailable,
    };
  }
}

class ProcedureOperationPointCatalog {
  const ProcedureOperationPointCatalog();

  List<ProcedureOperationPoint> get all => ProcedureOperationPoint.values;

  List<ProcedureOperationPoint> publishedFor(ProcedurePlatform platform) {
    return all
        .where((ProcedureOperationPoint point) => point.isAvailableOn(platform))
        .toList(growable: false);
  }

  bool isPublishedFor(
    ProcedureOperationPoint point,
    ProcedurePlatform platform,
  ) {
    return point.isAvailableOn(platform);
  }
}

const ProcedureOperationPointCatalog procedureOperationPointCatalog =
    ProcedureOperationPointCatalog();

@Deprecated('Use procedureOperationPointCatalog.publishedFor(mobile).')
const List<ProcedureOperationPoint> publishedMobileProcedureOperationPoints =
    <ProcedureOperationPoint>[
      ProcedureOperationPoint.saleStartBefore,
      ProcedureOperationPoint.saleFinishBefore,
      ProcedureOperationPoint.technicalServiceStartBefore,
      ProcedureOperationPoint.cashRegisterStartBefore,
    ];

ProcedureOperationPoint? procedureOperationPointFor(
  ProcedureOperationType operationType,
  ProcedureTriggerMoment triggerMoment,
) {
  for (final ProcedureOperationPoint point in ProcedureOperationPoint.values) {
    if (point.operationType == operationType &&
        point.triggerMoment == triggerMoment) {
      return point;
    }
  }
  return null;
}

enum ProcedureOperationType {
  sale,
  technicalService,
  quote,
  delivery,
  cashRegister,
  customerRegistration,
}

enum ProcedureMoment { beforeStart, beforeFinish, beforeDelivery }

const Map<ProcedureOperationType, List<ProcedureMoment>>
procedureMomentOptions = <ProcedureOperationType, List<ProcedureMoment>>{
  ProcedureOperationType.sale: <ProcedureMoment>[
    ProcedureMoment.beforeStart,
    ProcedureMoment.beforeFinish,
  ],
  ProcedureOperationType.technicalService: <ProcedureMoment>[
    ProcedureMoment.beforeStart,
    ProcedureMoment.beforeFinish,
    ProcedureMoment.beforeDelivery,
  ],
  ProcedureOperationType.quote: <ProcedureMoment>[
    ProcedureMoment.beforeStart,
    ProcedureMoment.beforeFinish,
  ],
  ProcedureOperationType.delivery: <ProcedureMoment>[
    ProcedureMoment.beforeDelivery,
  ],
  ProcedureOperationType.cashRegister: <ProcedureMoment>[
    ProcedureMoment.beforeStart,
    ProcedureMoment.beforeFinish,
  ],
  ProcedureOperationType.customerRegistration: <ProcedureMoment>[
    ProcedureMoment.beforeFinish,
  ],
};

List<ProcedureMoment> procedureMomentsForOperation(
  ProcedureOperationType operationType,
) {
  return procedureMomentOptions[operationType] ?? const <ProcedureMoment>[];
}

ProcedureTriggerMoment? procedureTriggerMomentForMoment(
  ProcedureMoment moment,
) {
  return switch (moment) {
    ProcedureMoment.beforeStart => ProcedureTriggerMoment.beforeStart,
    ProcedureMoment.beforeFinish => ProcedureTriggerMoment.beforeFinish,
    ProcedureMoment.beforeDelivery => ProcedureTriggerMoment.beforeDelivery,
  };
}

ProcedureMoment? procedureMomentForTriggerMoment(
  ProcedureTriggerMoment moment,
) {
  return switch (moment) {
    ProcedureTriggerMoment.beforeStart => ProcedureMoment.beforeStart,
    ProcedureTriggerMoment.beforeFinish => ProcedureMoment.beforeFinish,
    ProcedureTriggerMoment.beforeDelivery => ProcedureMoment.beforeDelivery,
    ProcedureTriggerMoment.afterStart ||
    ProcedureTriggerMoment.afterFinish ||
    ProcedureTriggerMoment.afterDelivery ||
    ProcedureTriggerMoment.onDemand => null,
  };
}

enum ProcedureTriggerMoment {
  beforeStart,
  afterStart,
  beforeFinish,
  afterFinish,
  beforeDelivery,
  afterDelivery,
  onDemand,
}

enum ProcedureTriggerActivationMode { manual, automatic }

enum ProcedureEnforcementMode { informative, recommended, required }

enum ProcedureResponseType {
  instruction,
  confirmation,
  yesNo,
  photo,
  signature,
  location,
  barcode,
  imei,
  document,
  audio,
  freeText,
  number,
  date,
  singleChoice,
  multipleChoice,
}

enum OperationalProcedureFilter { all, active, inactive }

enum ProcedureAdminNotificationCondition {
  always,
  negativeResponse,
  procedureSkipped,
}

class ProcedureAdminNotificationConfiguration {
  const ProcedureAdminNotificationConfiguration({
    this.enabled = false,
    this.condition = ProcedureAdminNotificationCondition.negativeResponse,
  });

  final bool enabled;
  final ProcedureAdminNotificationCondition condition;

  ProcedureAdminNotificationConfiguration copyWith({
    bool? enabled,
    ProcedureAdminNotificationCondition? condition,
  }) {
    return ProcedureAdminNotificationConfiguration(
      enabled: enabled ?? this.enabled,
      condition: condition ?? this.condition,
    );
  }
}

class OperationalProcedure {
  const OperationalProcedure({
    required this.id,
    required this.name,
    required this.description,
    required this.operationType,
    required this.moment,
    required this.status,
    required this.required,
    this.triggers = const <ProcedureTrigger>[],
    required this.stages,
    required this.createdAt,
    required this.updatedAt,
    this.nameTranslations = const <String, String>{},
    this.descriptionTranslations = const <String, String>{},
    this.adminNotification = const ProcedureAdminNotificationConfiguration(),
  });

  final String id;
  final String name;
  final String description;
  final ProcedureOperationType operationType;
  final ProcedureMoment moment;
  final ProcedureStatus status;
  final bool required;
  final List<ProcedureTrigger> triggers;
  final List<ProcedureStage> stages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> nameTranslations;
  final Map<String, String> descriptionTranslations;
  final ProcedureAdminNotificationConfiguration adminNotification;

  int get numberOfStages => stages.length;
  int get numberOfItems =>
      stages.fold<int>(0, (int total, ProcedureStage stage) {
        return total + stage.items.length;
      });
  bool get isActive => status == ProcedureStatus.active;
  bool get isInactive => status == ProcedureStatus.inactive;
  int get activeTriggerCount =>
      triggers.where((ProcedureTrigger trigger) => trigger.enabled).length;
  bool get hasAutomaticTriggers => triggers.any(
    (ProcedureTrigger trigger) =>
        trigger.enabled &&
        trigger.activationMode == ProcedureTriggerActivationMode.automatic,
  );

  OperationalProcedure copyWith({
    String? id,
    String? name,
    String? description,
    ProcedureOperationType? operationType,
    ProcedureMoment? moment,
    ProcedureStatus? status,
    bool? required,
    List<ProcedureTrigger>? triggers,
    List<ProcedureStage>? stages,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? nameTranslations,
    Map<String, String>? descriptionTranslations,
    ProcedureAdminNotificationConfiguration? adminNotification,
  }) {
    return OperationalProcedure(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      operationType: operationType ?? this.operationType,
      moment: moment ?? this.moment,
      status: status ?? this.status,
      required: required ?? this.required,
      triggers: triggers ?? this.triggers,
      stages: stages ?? this.stages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nameTranslations: nameTranslations ?? this.nameTranslations,
      descriptionTranslations:
          descriptionTranslations ?? this.descriptionTranslations,
      adminNotification: adminNotification ?? this.adminNotification,
    );
  }

  factory OperationalProcedure.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTriggers = json['gatilhos'] as List<dynamic>? ?? [];
    final List<dynamic> rawStages = json['etapas'] as List<dynamic>? ?? [];
    final ProcedureOperationType operationType = _operationTypeFromApi(
      json['contexto']?.toString(),
    );
    return OperationalProcedure(
      id: json['id']?.toString() ?? '',
      name: json['nome']?.toString() ?? '',
      description: json['descricao']?.toString() ?? '',
      nameTranslations: _stringMap(json['nomePorIdioma']),
      descriptionTranslations: _stringMap(json['descricaoPorIdioma']),
      operationType: operationType,
      moment: _momentFromApi(json['momento']?.toString()),
      status: _procedureStatusFromApi(json['status']?.toString()),
      required: json['obrigatorio'] == true,
      triggers: rawTriggers
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => ProcedureTrigger.fromJson(
              item.cast<String, dynamic>(),
              operationType: operationType,
            ),
          )
          .toList(growable: false),
      stages: rawStages
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                ProcedureStage.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      adminNotification: _adminNotificationFromJson(json['notificacaoAdmin']),
      createdAt: _dateTime(json['criadoEm']),
      updatedAt: _dateTime(json['atualizadoEm']),
    );
  }

  Map<String, dynamic> toApiJson(String localeTag) {
    return <String, dynamic>{
      'nomePorIdioma': _currentTranslation(nameTranslations, localeTag, name),
      'descricaoPorIdioma': _currentTranslation(
        descriptionTranslations,
        localeTag,
        description,
      ),
      'contexto': _operationTypeToApi(operationType),
      'momento': _momentToApi(moment),
      'status': _procedureStatusToApi(status),
      'obrigatorio': required,
      'gatilhos': triggers
          .map((ProcedureTrigger item) => item.toApiJson())
          .toList(growable: false),
      'etapas': stages
          .map((ProcedureStage item) => item.toApiJson(localeTag))
          .toList(growable: false),
      'notificacaoAdmin': <String, dynamic>{
        'habilitada': adminNotification.enabled,
        'condicao': _adminNotificationConditionToApi(
          adminNotification.condition,
        ),
      },
    };
  }
}

class ProcedureTrigger {
  const ProcedureTrigger({
    required this.id,
    this.operationPoint,
    required this.operationType,
    required this.triggerMoment,
    required this.activationMode,
    required this.enforcementMode,
    required this.enabled,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ProcedureOperationPoint? operationPoint;
  final ProcedureOperationType operationType;
  final ProcedureTriggerMoment triggerMoment;
  final ProcedureTriggerActivationMode activationMode;
  final ProcedureEnforcementMode enforcementMode;
  final bool enabled;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProcedureOperationPoint? get effectiveOperationPoint {
    final ProcedureOperationPoint? point = operationPoint;
    if (point != null &&
        point.operationType == operationType &&
        point.triggerMoment == triggerMoment) {
      return point;
    }
    return procedureOperationPointFor(operationType, triggerMoment);
  }

  ProcedureTrigger copyWith({
    String? id,
    ProcedureOperationPoint? operationPoint,
    ProcedureOperationType? operationType,
    ProcedureTriggerMoment? triggerMoment,
    ProcedureTriggerActivationMode? activationMode,
    ProcedureEnforcementMode? enforcementMode,
    bool? enabled,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProcedureTrigger(
      id: id ?? this.id,
      operationPoint: operationPoint ?? this.operationPoint,
      operationType: operationType ?? this.operationType,
      triggerMoment: triggerMoment ?? this.triggerMoment,
      activationMode: activationMode ?? this.activationMode,
      enforcementMode: enforcementMode ?? this.enforcementMode,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProcedureTrigger.fromJson(
    Map<String, dynamic> json, {
    ProcedureOperationType? operationType,
  }) {
    final ProcedureOperationType effectiveOperationType =
        operationType ?? _operationTypeFromApi(json['contexto']?.toString());
    final ProcedureTriggerMoment triggerMoment = _triggerMomentFromApi(
      json['momento']?.toString(),
    );
    final String pointId = json['pontoOperacional']?.toString() ?? '';
    return ProcedureTrigger(
      id: json['id']?.toString() ?? '',
      operationPoint: _operationPointFromId(pointId),
      operationType: effectiveOperationType,
      triggerMoment: triggerMoment,
      activationMode: _activationModeFromApi(json['modoAtivacao']?.toString()),
      enforcementMode: _enforcementModeFromApi(
        json['modoExigencia']?.toString(),
      ),
      enabled: json['habilitado'] != false,
      order: (json['ordem'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'id': id,
      'pontoOperacional': effectiveOperationPoint?.id ?? '',
      'contexto': _operationTypeToApi(operationType),
      'momento': _triggerMomentToApi(triggerMoment),
      'modoAtivacao': _activationModeToApi(activationMode),
      'modoExigencia': _enforcementModeToApi(enforcementMode),
      'habilitado': enabled,
      'ordem': order,
    };
  }
}

class ProcedureStage {
  const ProcedureStage({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.items,
    this.titleTranslations = const <String, String>{},
    this.descriptionTranslations = const <String, String>{},
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final List<ProcedureItem> items;
  final Map<String, String> titleTranslations;
  final Map<String, String> descriptionTranslations;

  ProcedureStage copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    List<ProcedureItem>? items,
    Map<String, String>? titleTranslations,
    Map<String, String>? descriptionTranslations,
  }) {
    return ProcedureStage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      items: items ?? this.items,
      titleTranslations: titleTranslations ?? this.titleTranslations,
      descriptionTranslations:
          descriptionTranslations ?? this.descriptionTranslations,
    );
  }

  factory ProcedureStage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['itens'] as List<dynamic>? ?? [];
    return ProcedureStage(
      id: json['id']?.toString() ?? '',
      title: json['titulo']?.toString() ?? '',
      description: json['descricao']?.toString() ?? '',
      titleTranslations: _stringMap(json['tituloPorIdioma']),
      descriptionTranslations: _stringMap(json['descricaoPorIdioma']),
      order: (json['ordem'] as num?)?.toInt() ?? 0,
      items: rawItems
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                ProcedureItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toApiJson(String localeTag) {
    return <String, dynamic>{
      'id': id,
      'tituloPorIdioma': _currentTranslation(
        titleTranslations,
        localeTag,
        title,
      ),
      'descricaoPorIdioma': _currentTranslation(
        descriptionTranslations,
        localeTag,
        description,
      ),
      'ordem': order,
      'itens': items
          .map((ProcedureItem item) => item.toApiJson(localeTag))
          .toList(growable: false),
    };
  }
}

class ProcedureItem {
  const ProcedureItem({
    required this.id,
    required this.title,
    required this.guidance,
    required this.responseType,
    required this.required,
    required this.order,
    this.options = const <String>[],
    this.configuration = const ProcedureItemConfiguration(),
    this.titleTranslations = const <String, String>{},
    this.guidanceTranslations = const <String, String>{},
  });

  final String id;
  final String title;
  final String guidance;
  final ProcedureResponseType responseType;
  final bool required;
  final int order;
  final List<String> options;
  final ProcedureItemConfiguration configuration;
  final Map<String, String> titleTranslations;
  final Map<String, String> guidanceTranslations;

  ProcedureItem copyWith({
    String? id,
    String? title,
    String? guidance,
    ProcedureResponseType? responseType,
    bool? required,
    int? order,
    List<String>? options,
    ProcedureItemConfiguration? configuration,
    Map<String, String>? titleTranslations,
    Map<String, String>? guidanceTranslations,
  }) {
    return ProcedureItem(
      id: id ?? this.id,
      title: title ?? this.title,
      guidance: guidance ?? this.guidance,
      responseType: responseType ?? this.responseType,
      required: required ?? this.required,
      order: order ?? this.order,
      options: options ?? this.options,
      configuration: configuration ?? this.configuration,
      titleTranslations: titleTranslations ?? this.titleTranslations,
      guidanceTranslations: guidanceTranslations ?? this.guidanceTranslations,
    );
  }

  factory ProcedureItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawOptions = json['opcoes'] as List<dynamic>? ?? [];
    return ProcedureItem(
      id: json['id']?.toString() ?? '',
      title: json['titulo']?.toString() ?? '',
      guidance: json['orientacao']?.toString() ?? '',
      titleTranslations: _stringMap(json['tituloPorIdioma']),
      guidanceTranslations: _stringMap(json['orientacaoPorIdioma']),
      responseType: _responseTypeFromApi(json['tipoResposta']?.toString()),
      required: json['obrigatorio'] == true,
      order: (json['ordem'] as num?)?.toInt() ?? 0,
      options: rawOptions
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> option) =>
                option['rotulo']?.toString() ?? '',
          )
          .where((String option) => option.isNotEmpty)
          .toList(growable: false),
      configuration: ProcedureItemConfiguration(
        requireTextWhenNo: json['exigeTextoQuandoNao'] == true,
      ),
    );
  }

  Map<String, dynamic> toApiJson(String localeTag) {
    return <String, dynamic>{
      'id': id,
      'tipoResposta': _responseTypeToApi(responseType),
      'tituloPorIdioma': _currentTranslation(
        titleTranslations,
        localeTag,
        title,
      ),
      'orientacaoPorIdioma': _currentTranslation(
        guidanceTranslations,
        localeTag,
        guidance,
      ),
      'obrigatorio': required,
      'permiteComentario': configuration.requireTextWhenNo,
      'exigeTextoQuandoNao': configuration.requireTextWhenNo,
      'ordem': order,
      'opcoes': options
          .asMap()
          .entries
          .map((MapEntry<int, String> entry) {
            return <String, dynamic>{
              'id': 'option-${entry.key + 1}',
              'rotuloPorIdioma': <String, String>{localeTag: entry.value},
            };
          })
          .toList(growable: false),
    };
  }
}

class ProcedureItemConfiguration {
  const ProcedureItemConfiguration({
    this.placeholder = '',
    this.unit = '',
    this.requireTextWhenNo = false,
    this.negativeTextPlaceholder = '',
  });

  final String placeholder;
  final String unit;
  final bool requireTextWhenNo;
  final String negativeTextPlaceholder;

  bool get hasPlaceholder => placeholder.trim().isNotEmpty;
  bool get hasUnit => unit.trim().isNotEmpty;
  bool get hasNegativeTextPlaceholder =>
      negativeTextPlaceholder.trim().isNotEmpty;

  ProcedureItemConfiguration copyWith({
    String? placeholder,
    String? unit,
    bool? requireTextWhenNo,
    String? negativeTextPlaceholder,
  }) {
    return ProcedureItemConfiguration(
      placeholder: placeholder ?? this.placeholder,
      unit: unit ?? this.unit,
      requireTextWhenNo: requireTextWhenNo ?? this.requireTextWhenNo,
      negativeTextPlaceholder:
          negativeTextPlaceholder ?? this.negativeTextPlaceholder,
    );
  }
}

class ProcedureExecutionDraft {
  const ProcedureExecutionDraft({
    required this.procedureId,
    required this.currentStageIndex,
    required this.responses,
    required this.startedAt,
    this.completedAt,
  });

  final String procedureId;
  final int currentStageIndex;
  final Map<String, ProcedureItemResponse> responses;
  final DateTime startedAt;
  final DateTime? completedAt;

  ProcedureExecutionDraft copyWith({
    int? currentStageIndex,
    Map<String, ProcedureItemResponse>? responses,
    DateTime? completedAt,
  }) {
    return ProcedureExecutionDraft(
      procedureId: procedureId,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      responses: responses ?? this.responses,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class ProcedureItemResponse {
  const ProcedureItemResponse({
    required this.itemId,
    required this.responseType,
    this.completed = false,
    this.boolValue,
    this.textValue = '',
    this.numberValue,
    this.dateValue,
    this.selectedOptions = const <String>[],
    this.evidence,
    required this.updatedAt,
  });

  final String itemId;
  final ProcedureResponseType responseType;
  final bool completed;
  final bool? boolValue;
  final String textValue;
  final num? numberValue;
  final DateTime? dateValue;
  final List<String> selectedOptions;
  final ProcedureSimulatedEvidence? evidence;
  final DateTime updatedAt;

  ProcedureItemResponse copyWith({
    bool? completed,
    bool? boolValue,
    String? textValue,
    num? numberValue,
    DateTime? dateValue,
    List<String>? selectedOptions,
    ProcedureSimulatedEvidence? evidence,
    bool clearBoolValue = false,
    bool clearNumberValue = false,
    bool clearDateValue = false,
    bool clearEvidence = false,
  }) {
    return ProcedureItemResponse(
      itemId: itemId,
      responseType: responseType,
      completed: completed ?? this.completed,
      boolValue: clearBoolValue ? null : boolValue ?? this.boolValue,
      textValue: textValue ?? this.textValue,
      numberValue: clearNumberValue ? null : numberValue ?? this.numberValue,
      dateValue: clearDateValue ? null : dateValue ?? this.dateValue,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      evidence: clearEvidence ? null : evidence ?? this.evidence,
      updatedAt: DateTime.now(),
    );
  }
}

class ProcedureSimulatedEvidence {
  const ProcedureSimulatedEvidence({
    required this.label,
    required this.detail,
    required this.iconKey,
  });

  final String label;
  final String detail;
  final String iconKey;
}

class OperationalProcedureSummary {
  const OperationalProcedureSummary({
    required this.procedures,
    this.isDemonstrationData = true,
  });

  final List<OperationalProcedure> procedures;
  final bool isDemonstrationData;

  bool get isEmpty => procedures.isEmpty;
}

Map<String, String> _stringMap(dynamic value) {
  if (value is! Map) return const <String, String>{};
  return value.map<String, String>(
    (dynamic key, dynamic item) =>
        MapEntry<String, String>(key.toString(), item?.toString() ?? ''),
  );
}

Map<String, String> _currentTranslation(
  Map<String, String> translations,
  String localeTag,
  String value,
) {
  final Map<String, String> result = Map<String, String>.of(translations);
  if (value.trim().isNotEmpty) result[localeTag] = value.trim();
  return result;
}

DateTime _dateTime(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

ProcedureAdminNotificationConfiguration _adminNotificationFromJson(
  dynamic value,
) {
  if (value is! Map) {
    return const ProcedureAdminNotificationConfiguration();
  }
  final String condition = value['condicao']?.toString().toUpperCase() ?? '';
  return ProcedureAdminNotificationConfiguration(
    enabled: value['habilitada'] == true,
    condition: switch (condition) {
      'SEMPRE' => ProcedureAdminNotificationCondition.always,
      'PROCEDIMENTO_IGNORADO' =>
        ProcedureAdminNotificationCondition.procedureSkipped,
      _ => ProcedureAdminNotificationCondition.negativeResponse,
    },
  );
}

String _adminNotificationConditionToApi(
  ProcedureAdminNotificationCondition value,
) {
  return switch (value) {
    ProcedureAdminNotificationCondition.always => 'SEMPRE',
    ProcedureAdminNotificationCondition.negativeResponse => 'RESPOSTA_NEGATIVA',
    ProcedureAdminNotificationCondition.procedureSkipped =>
      'PROCEDIMENTO_IGNORADO',
  };
}

ProcedureStatus _procedureStatusFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'RASCUNHO' => ProcedureStatus.draft,
    'INATIVO' => ProcedureStatus.inactive,
    _ => ProcedureStatus.active,
  };
}

String _procedureStatusToApi(ProcedureStatus value) {
  return switch (value) {
    ProcedureStatus.draft => 'RASCUNHO',
    ProcedureStatus.active => 'ATIVO',
    ProcedureStatus.inactive => 'INATIVO',
  };
}

ProcedureOperationType _operationTypeFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'ATENDIMENTO_TECNICO' => ProcedureOperationType.technicalService,
    'CAIXA' => ProcedureOperationType.cashRegister,
    'ORCAMENTO' => ProcedureOperationType.quote,
    'ENTREGA' => ProcedureOperationType.delivery,
    'CADASTRO_CLIENTE' => ProcedureOperationType.customerRegistration,
    _ => ProcedureOperationType.sale,
  };
}

String _operationTypeToApi(ProcedureOperationType value) {
  return switch (value) {
    ProcedureOperationType.sale => 'VENDA',
    ProcedureOperationType.technicalService => 'ATENDIMENTO_TECNICO',
    ProcedureOperationType.quote => 'ORCAMENTO',
    ProcedureOperationType.delivery => 'ENTREGA',
    ProcedureOperationType.cashRegister => 'CAIXA',
    ProcedureOperationType.customerRegistration => 'CADASTRO_CLIENTE',
  };
}

ProcedureMoment _momentFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'ANTES_FINALIZAR' => ProcedureMoment.beforeFinish,
    'ANTES_ENTREGAR' => ProcedureMoment.beforeDelivery,
    _ => ProcedureMoment.beforeStart,
  };
}

String _momentToApi(ProcedureMoment value) {
  return switch (value) {
    ProcedureMoment.beforeStart => 'ANTES_INICIAR',
    ProcedureMoment.beforeFinish => 'ANTES_FINALIZAR',
    ProcedureMoment.beforeDelivery => 'ANTES_ENTREGAR',
  };
}

ProcedureTriggerMoment _triggerMomentFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'DEPOIS_INICIAR' => ProcedureTriggerMoment.afterStart,
    'ANTES_FINALIZAR' => ProcedureTriggerMoment.beforeFinish,
    'DEPOIS_FINALIZAR' => ProcedureTriggerMoment.afterFinish,
    'ANTES_ENTREGAR' => ProcedureTriggerMoment.beforeDelivery,
    'DEPOIS_ENTREGAR' => ProcedureTriggerMoment.afterDelivery,
    'SOB_DEMANDA' => ProcedureTriggerMoment.onDemand,
    _ => ProcedureTriggerMoment.beforeStart,
  };
}

String _triggerMomentToApi(ProcedureTriggerMoment value) {
  return switch (value) {
    ProcedureTriggerMoment.beforeStart => 'ANTES_INICIAR',
    ProcedureTriggerMoment.afterStart => 'DEPOIS_INICIAR',
    ProcedureTriggerMoment.beforeFinish => 'ANTES_FINALIZAR',
    ProcedureTriggerMoment.afterFinish => 'DEPOIS_FINALIZAR',
    ProcedureTriggerMoment.beforeDelivery => 'ANTES_ENTREGAR',
    ProcedureTriggerMoment.afterDelivery => 'DEPOIS_ENTREGAR',
    ProcedureTriggerMoment.onDemand => 'SOB_DEMANDA',
  };
}

ProcedureTriggerActivationMode _activationModeFromApi(String? value) {
  return value?.toUpperCase() == 'MANUAL'
      ? ProcedureTriggerActivationMode.manual
      : ProcedureTriggerActivationMode.automatic;
}

String _activationModeToApi(ProcedureTriggerActivationMode value) {
  return value == ProcedureTriggerActivationMode.manual
      ? 'MANUAL'
      : 'AUTOMATICO';
}

ProcedureEnforcementMode _enforcementModeFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'OBRIGATORIO' => ProcedureEnforcementMode.required,
    'RECOMENDADO' => ProcedureEnforcementMode.recommended,
    _ => ProcedureEnforcementMode.informative,
  };
}

String _enforcementModeToApi(ProcedureEnforcementMode value) {
  return switch (value) {
    ProcedureEnforcementMode.informative => 'INFORMATIVO',
    ProcedureEnforcementMode.recommended => 'RECOMENDADO',
    ProcedureEnforcementMode.required => 'OBRIGATORIO',
  };
}

ProcedureOperationPoint? _operationPointFromId(String id) {
  for (final ProcedureOperationPoint point in ProcedureOperationPoint.values) {
    if (point.id == id) return point;
  }
  return null;
}

ProcedureResponseType _responseTypeFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'INSTRUCAO' => ProcedureResponseType.instruction,
    'SIM_NAO' => ProcedureResponseType.yesNo,
    'FOTO' => ProcedureResponseType.photo,
    'ASSINATURA' => ProcedureResponseType.signature,
    'LOCALIZACAO' => ProcedureResponseType.location,
    'CODIGO_BARRAS' => ProcedureResponseType.barcode,
    'IMEI' => ProcedureResponseType.imei,
    'DOCUMENTO' => ProcedureResponseType.document,
    'AUDIO' => ProcedureResponseType.audio,
    'TEXTO_LIVRE' => ProcedureResponseType.freeText,
    'NUMERO' => ProcedureResponseType.number,
    'DATA' => ProcedureResponseType.date,
    'ESCOLHA_UNICA' => ProcedureResponseType.singleChoice,
    'MULTIPLA_ESCOLHA' => ProcedureResponseType.multipleChoice,
    _ => ProcedureResponseType.confirmation,
  };
}

String _responseTypeToApi(ProcedureResponseType value) {
  return switch (value) {
    ProcedureResponseType.instruction => 'INSTRUCAO',
    ProcedureResponseType.confirmation => 'CONFIRMACAO',
    ProcedureResponseType.yesNo => 'SIM_NAO',
    ProcedureResponseType.photo => 'FOTO',
    ProcedureResponseType.signature => 'ASSINATURA',
    ProcedureResponseType.location => 'LOCALIZACAO',
    ProcedureResponseType.barcode => 'CODIGO_BARRAS',
    ProcedureResponseType.imei => 'IMEI',
    ProcedureResponseType.document => 'DOCUMENTO',
    ProcedureResponseType.audio => 'AUDIO',
    ProcedureResponseType.freeText => 'TEXTO_LIVRE',
    ProcedureResponseType.number => 'NUMERO',
    ProcedureResponseType.date => 'DATA',
    ProcedureResponseType.singleChoice => 'ESCOLHA_UNICA',
    ProcedureResponseType.multipleChoice => 'MULTIPLA_ESCOLHA',
  };
}
