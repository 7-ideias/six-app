enum ProcedureStatus { draft, active, inactive }

enum ProcedureOperationType { sale, technicalService, quote, delivery }

enum ProcedureMoment { beforeStart, beforeFinish, beforeDelivery }

enum ProcedureResponseType { instruction, confirmation, yesNo }

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

  OperationalProcedure copyWith({
    String? id,
    String? name,
    String? description,
    ProcedureOperationType? operationType,
    ProcedureMoment? moment,
    ProcedureStatus? status,
    bool? required,
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
      stages: stages ?? this.stages,
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
  });

  final String id;
  final String title;
  final String guidance;
  final ProcedureResponseType responseType;
  final bool required;
  final int order;

  ProcedureItem copyWith({
    String? id,
    String? title,
    String? guidance,
    ProcedureResponseType? responseType,
    bool? required,
    int? order,
  }) {
    return ProcedureItem(
      id: id ?? this.id,
      title: title ?? this.title,
      guidance: guidance ?? this.guidance,
      responseType: responseType ?? this.responseType,
      required: required ?? this.required,
      order: order ?? this.order,
    );
  }
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
