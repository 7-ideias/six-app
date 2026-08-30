class OperationalProcedureExecutionResult {
  const OperationalProcedureExecutionResult({
    required this.id,
    required this.procedureId,
    required this.procedureName,
    required this.context,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.negativeResponses,
    this.saleId,
    this.userId,
  });

  final String id;
  final String procedureId;
  final String procedureName;
  final String context;
  final String status;
  final String? saleId;
  final String? userId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  final int negativeResponses;

  factory OperationalProcedureExecutionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalProcedureExecutionResult(
      id: json['id']?.toString() ?? '',
      procedureId: json['procedimentoId']?.toString() ?? '',
      procedureName: json['procedimentoNome']?.toString() ?? '',
      context: json['contexto']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      saleId: _nullableText(json['idVenda']),
      userId: _nullableText(json['idUnicoDoUsuario']),
      startedAt: _parseDate(json['iniciadoEm']),
      completedAt: _parseDate(json['concluidoEm']),
      durationSeconds: (json['duracaoSegundos'] as num?)?.toInt() ?? 0,
      negativeResponses: (json['respostasNegativas'] as num?)?.toInt() ?? 0,
    );
  }
}

class OperationalProcedureAnalytics {
  const OperationalProcedureAnalytics({
    required this.periodDays,
    required this.totalExecutions,
    required this.completed,
    required this.skipped,
    required this.completionRate,
    required this.negativeResponses,
    required this.averageDurationSeconds,
    required this.sampleLimited,
    required this.byContext,
    required this.byProcedure,
    required this.byQuestion,
    required this.recentExecutions,
  });

  final int periodDays;
  final int totalExecutions;
  final int completed;
  final int skipped;
  final double completionRate;
  final int negativeResponses;
  final double averageDurationSeconds;
  final bool sampleLimited;
  final List<OperationalProcedureContextMetric> byContext;
  final List<OperationalProcedureMetric> byProcedure;
  final List<OperationalProcedureQuestionMetric> byQuestion;
  final List<OperationalProcedureExecutionResult> recentExecutions;

  factory OperationalProcedureAnalytics.fromJson(Map<String, dynamic> json) {
    return OperationalProcedureAnalytics(
      periodDays: (json['periodoDias'] as num?)?.toInt() ?? 30,
      totalExecutions: (json['totalExecucoes'] as num?)?.toInt() ?? 0,
      completed: (json['concluidas'] as num?)?.toInt() ?? 0,
      skipped: (json['ignoradas'] as num?)?.toInt() ?? 0,
      completionRate: (json['taxaConclusao'] as num?)?.toDouble() ?? 0,
      negativeResponses: (json['respostasNegativas'] as num?)?.toInt() ?? 0,
      averageDurationSeconds:
          (json['duracaoMediaSegundos'] as num?)?.toDouble() ?? 0,
      sampleLimited: json['amostraLimitada'] == true,
      byContext: _maps(
        json['porContexto'],
      ).map(OperationalProcedureContextMetric.fromJson).toList(growable: false),
      byProcedure: _maps(
        json['porProcedimento'],
      ).map(OperationalProcedureMetric.fromJson).toList(growable: false),
      byQuestion: _maps(json['porPergunta'])
          .map(OperationalProcedureQuestionMetric.fromJson)
          .toList(growable: false),
      recentExecutions: _maps(json['execucoesRecentes'])
          .map(OperationalProcedureExecutionResult.fromJson)
          .toList(growable: false),
    );
  }
}

class OperationalProcedureContextMetric {
  const OperationalProcedureContextMetric({
    required this.context,
    required this.total,
    required this.completed,
    required this.negativeResponses,
  });

  final String context;
  final int total;
  final int completed;
  final int negativeResponses;

  factory OperationalProcedureContextMetric.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalProcedureContextMetric(
      context: json['contexto']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['concluidas'] as num?)?.toInt() ?? 0,
      negativeResponses: (json['negativas'] as num?)?.toInt() ?? 0,
    );
  }
}

class OperationalProcedureMetric {
  const OperationalProcedureMetric({
    required this.procedureId,
    required this.name,
    required this.total,
    required this.completed,
    required this.negativeResponses,
    required this.averageDurationSeconds,
  });

  final String procedureId;
  final String name;
  final int total;
  final int completed;
  final int negativeResponses;
  final double averageDurationSeconds;

  factory OperationalProcedureMetric.fromJson(Map<String, dynamic> json) {
    return OperationalProcedureMetric(
      procedureId: json['procedimentoId']?.toString() ?? '',
      name: json['nome']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['concluidas'] as num?)?.toInt() ?? 0,
      negativeResponses: (json['negativas'] as num?)?.toInt() ?? 0,
      averageDurationSeconds:
          (json['duracaoMediaSegundos'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OperationalProcedureQuestionMetric {
  const OperationalProcedureQuestionMetric({
    required this.itemId,
    required this.question,
    required this.totalAnswers,
    required this.positiveAnswers,
    required this.negativeAnswers,
  });

  final String itemId;
  final String question;
  final int totalAnswers;
  final int positiveAnswers;
  final int negativeAnswers;

  factory OperationalProcedureQuestionMetric.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalProcedureQuestionMetric(
      itemId: json['itemId']?.toString() ?? '',
      question: json['pergunta']?.toString() ?? '',
      totalAnswers: (json['totalRespostas'] as num?)?.toInt() ?? 0,
      positiveAnswers: (json['positivas'] as num?)?.toInt() ?? 0,
      negativeAnswers: (json['negativas'] as num?)?.toInt() ?? 0,
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

String? _nullableText(dynamic value) {
  final String result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}
