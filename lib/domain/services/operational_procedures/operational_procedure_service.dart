import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/models/operational_procedure_persistence_models.dart';
import 'package:sixpos/data/services/operational_procedures/operational_procedure_api_client.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_flow_controller.dart';

class OperationalProcedureService
    implements OperationalProcedureRuntimeRepository {
  OperationalProcedureService({
    HttpOperationalProcedureApiClient? apiClient,
    this.localeTag = 'pt-BR',
  }) : _apiClient = apiClient ?? HttpOperationalProcedureApiClient();

  final HttpOperationalProcedureApiClient _apiClient;
  final String localeTag;

  @override
  Future<List<OperationalProcedure>> fetchProcedures() async {
    final OperationalProcedureSummary summary = await _apiClient
        .fetchProcedures(idioma: localeTag, somenteAtivos: true);
    return summary.procedures;
  }

  Future<OperationalProcedureExecutionResult> persistExecution({
    required OperationalProcedure procedure,
    required ProcedureExecutionDraft execution,
    required ProcedureExecutionConfiguration configuration,
    required String status,
    required ProcedurePlatform platform,
  }) {
    return _apiClient.registerExecution(<String, dynamic>{
      'procedimentoId': procedure.id,
      'pontoOperacional': configuration.operationPoint?.id ?? '',
      'status': status,
      'iniciadoEm': execution.startedAt.toUtc().toIso8601String(),
      'concluidoEm': (execution.completedAt ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      'plataforma': platform.name,
      'idioma': localeTag,
      'respostas': _responses(procedure, execution),
    });
  }

  Future<OperationalProcedureAnalytics> fetchAnalytics({int days = 30}) {
    return _apiClient.fetchAnalytics(idioma: localeTag, days: days);
  }

  Future<void> linkExecutionsToSale({
    required List<String> executionIds,
    required String saleId,
  }) {
    return _apiClient.linkExecutionsToSale(
      executionIds: executionIds,
      saleId: saleId,
    );
  }

  List<Map<String, dynamic>> _responses(
    OperationalProcedure procedure,
    ProcedureExecutionDraft execution,
  ) {
    final Map<String, ProcedureStage> stageByItem = <String, ProcedureStage>{};
    final Map<String, ProcedureItem> itemById = <String, ProcedureItem>{};
    for (final ProcedureStage stage in procedure.stages) {
      for (final ProcedureItem item in stage.items) {
        stageByItem[item.id] = stage;
        itemById[item.id] = item;
      }
    }
    return execution.responses.values
        .map((ProcedureItemResponse response) {
          final ProcedureItem? item = itemById[response.itemId];
          return <String, dynamic>{
            'etapaId': stageByItem[response.itemId]?.id ?? '',
            'itemId': response.itemId,
            'tipoResposta': _responseTypeCode(response.responseType),
            'valor': _responseValue(response),
            'comentario': response.responseType == ProcedureResponseType.yesNo
                ? response.textValue.trim()
                : null,
            'negativa':
                response.responseType == ProcedureResponseType.yesNo &&
                response.boolValue == false,
            'evidencia': response.evidence == null
                ? <String, dynamic>{}
                : <String, dynamic>{
                    'rotulo': response.evidence!.label,
                    'detalhe': response.evidence!.detail,
                    'tipo': response.evidence!.iconKey,
                  },
            'respondidoEm': response.updatedAt.toUtc().toIso8601String(),
            if (item != null) 'itemObrigatorio': item.required,
          };
        })
        .toList(growable: false);
  }

  dynamic _responseValue(ProcedureItemResponse response) {
    return switch (response.responseType) {
      ProcedureResponseType.yesNo => response.boolValue,
      ProcedureResponseType.number => response.numberValue,
      ProcedureResponseType.date => response.dateValue?.toIso8601String(),
      ProcedureResponseType.singleChoice ||
      ProcedureResponseType.multipleChoice => response.selectedOptions,
      ProcedureResponseType.freeText ||
      ProcedureResponseType.barcode ||
      ProcedureResponseType.imei => response.textValue,
      _ => response.completed,
    };
  }

  String _responseTypeCode(ProcedureResponseType type) {
    return switch (type) {
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
}
