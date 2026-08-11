class WorkspaceHomeModel {
  const WorkspaceHomeModel({
    required this.date,
    required this.timeZone,
    required this.cash,
    required this.technicalServices,
    required this.financial,
    required this.stock,
  });

  factory WorkspaceHomeModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceHomeModel(
      date: _parseDate(json['date']),
      timeZone: json['timeZone']?.toString() ?? '',
      cash: WorkspaceHomeCash.fromJson(_asMap(json['cash'])),
      technicalServices: WorkspaceHomeTechnicalServices.fromJson(
        _asMap(json['technicalServices']),
      ),
      financial: WorkspaceHomeFinancial.fromJson(_asMap(json['financial'])),
      stock: WorkspaceHomeStock.fromJson(_asMap(json['stock'])),
    );
  }

  final DateTime date;
  final String timeZone;
  final WorkspaceHomeCash cash;
  final WorkspaceHomeTechnicalServices technicalServices;
  final WorkspaceHomeFinancial financial;
  final WorkspaceHomeStock stock;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': _formatDate(date),
      'timeZone': timeZone,
      'cash': cash.toJson(),
      'technicalServices': technicalServices.toJson(),
      'financial': financial.toJson(),
      'stock': stock.toJson(),
    };
  }
}

class WorkspaceHomeCash {
  const WorkspaceHomeCash({
    required this.available,
    this.open,
    this.sessionId,
    this.openedAt,
    this.responsibleName,
  });

  factory WorkspaceHomeCash.fromJson(Map<String, dynamic> json) {
    return WorkspaceHomeCash(
      available: _asBool(json['available']),
      open: _asNullableBool(json['open']),
      sessionId: json['sessionId']?.toString(),
      openedAt: _parseNullableDateTime(json['openedAt']),
      responsibleName: json['responsibleName']?.toString(),
    );
  }

  final bool available;
  final bool? open;
  final String? sessionId;
  final DateTime? openedAt;
  final String? responsibleName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'available': available,
      if (open != null) 'open': open,
      if (sessionId != null) 'sessionId': sessionId,
      if (openedAt != null) 'openedAt': openedAt!.toIso8601String(),
      if (responsibleName != null) 'responsibleName': responsibleName,
    };
  }
}

class WorkspaceHomeTechnicalServices {
  const WorkspaceHomeTechnicalServices({
    required this.available,
    this.active,
    this.waitingApproval,
    this.late,
    this.readyForPickup,
  });

  factory WorkspaceHomeTechnicalServices.fromJson(Map<String, dynamic> json) {
    return WorkspaceHomeTechnicalServices(
      available: _asBool(json['available']),
      active: _asNullableInt(json['active']),
      waitingApproval: _asNullableInt(json['waitingApproval']),
      late: _asNullableInt(json['late']),
      readyForPickup: _asNullableInt(json['readyForPickup']),
    );
  }

  final bool available;
  final int? active;
  final int? waitingApproval;
  final int? late;
  final int? readyForPickup;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'available': available,
      if (active != null) 'active': active,
      if (waitingApproval != null) 'waitingApproval': waitingApproval,
      if (late != null) 'late': late,
      if (readyForPickup != null) 'readyForPickup': readyForPickup,
    };
  }
}

class WorkspaceHomeFinancial {
  const WorkspaceHomeFinancial({
    required this.available,
    this.receivableToday,
    this.payableToday,
    this.overdueReceivable,
    this.overduePayable,
  });

  factory WorkspaceHomeFinancial.fromJson(Map<String, dynamic> json) {
    return WorkspaceHomeFinancial(
      available: _asBool(json['available']),
      receivableToday: _asNullableSummary(json['receivableToday']),
      payableToday: _asNullableSummary(json['payableToday']),
      overdueReceivable: _asNullableSummary(json['overdueReceivable']),
      overduePayable: _asNullableSummary(json['overduePayable']),
    );
  }

  final bool available;
  final WorkspaceHomeFinancialSummary? receivableToday;
  final WorkspaceHomeFinancialSummary? payableToday;
  final WorkspaceHomeFinancialSummary? overdueReceivable;
  final WorkspaceHomeFinancialSummary? overduePayable;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'available': available,
      if (receivableToday != null) 'receivableToday': receivableToday!.toJson(),
      if (payableToday != null) 'payableToday': payableToday!.toJson(),
      if (overdueReceivable != null)
        'overdueReceivable': overdueReceivable!.toJson(),
      if (overduePayable != null) 'overduePayable': overduePayable!.toJson(),
    };
  }
}

class WorkspaceHomeFinancialSummary {
  const WorkspaceHomeFinancialSummary({
    required this.count,
    required this.amount,
  });

  factory WorkspaceHomeFinancialSummary.fromJson(Map<String, dynamic> json) {
    return WorkspaceHomeFinancialSummary(
      count: _asInt(json['count']),
      amount: _asDouble(json['amount']),
    );
  }

  final int count;
  final double amount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'count': count, 'amount': amount};
  }
}

class WorkspaceHomeStock {
  const WorkspaceHomeStock({
    required this.available,
    this.belowMinimum,
    this.withoutStock,
    this.negative,
  });

  factory WorkspaceHomeStock.fromJson(Map<String, dynamic> json) {
    return WorkspaceHomeStock(
      available: _asBool(json['available']),
      belowMinimum: _asNullableInt(json['belowMinimum']),
      withoutStock: _asNullableInt(json['withoutStock']),
      negative: _asNullableInt(json['negative']),
    );
  }

  final bool available;
  final int? belowMinimum;
  final int? withoutStock;
  final int? negative;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'available': available,
      if (belowMinimum != null) 'belowMinimum': belowMinimum,
      if (withoutStock != null) 'withoutStock': withoutStock,
      if (negative != null) 'negative': negative,
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }
  return <String, dynamic>{};
}

WorkspaceHomeFinancialSummary? _asNullableSummary(dynamic value) {
  if (value == null) {
    return null;
  }
  return WorkspaceHomeFinancialSummary.fromJson(_asMap(value));
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.parse(value);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

DateTime? _parseNullableDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool _asBool(dynamic value) {
  return value == true || value?.toString().toLowerCase() == 'true';
}

bool? _asNullableBool(dynamic value) {
  if (value == null) {
    return null;
  }
  return _asBool(value);
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  return _asInt(value);
}

double _asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
