enum ProcedureStatus { draft, active, inactive }

enum ProcedureOperationPoint { saleStartBefore }

enum ProcedurePlatform { mobile, web }

extension ProcedureOperationPointDetails on ProcedureOperationPoint {
  String get id {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore => 'sale.start.before',
    };
  }

  ProcedureOperationType get operationType {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore => ProcedureOperationType.sale,
    };
  }

  ProcedureTriggerMoment get triggerMoment {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore =>
        ProcedureTriggerMoment.beforeStart,
    };
  }

  bool get mobileAvailable {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore => true,
    };
  }

  bool get webAvailable {
    return switch (this) {
      ProcedureOperationPoint.saleStartBefore => false,
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
    <ProcedureOperationPoint>[ProcedureOperationPoint.saleStartBefore];

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
    );
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
}

class ProcedureStage {
  const ProcedureStage({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.items,
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final List<ProcedureItem> items;

  ProcedureStage copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    List<ProcedureItem>? items,
  }) {
    return ProcedureStage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      items: items ?? this.items,
    );
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
  });

  final String id;
  final String title;
  final String guidance;
  final ProcedureResponseType responseType;
  final bool required;
  final int order;
  final List<String> options;
  final ProcedureItemConfiguration configuration;

  ProcedureItem copyWith({
    String? id,
    String? title,
    String? guidance,
    ProcedureResponseType? responseType,
    bool? required,
    int? order,
    List<String>? options,
    ProcedureItemConfiguration? configuration,
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
    );
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
