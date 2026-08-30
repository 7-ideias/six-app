import '../../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../../data/models/documento_models.dart';
import '../../../data/models/operacao_models.dart';
import '../../../data/services/operacao/operacao_api_client.dart';
import '../../../mappers/operacao_mapper.dart';
import '../operational_procedures/operational_procedure_pending_execution_store.dart';
import '../operational_procedures/operational_procedure_service.dart';
import 'package:flutter/foundation.dart';

class OperacaoService {
  OperacaoService({
    required OperacaoApiClient apiClient,
    required OperacaoRequestMapper mapper,
    OperationalProcedureService? operationalProcedureService,
  }) : _apiClient = apiClient,
       _mapper = mapper,
       _operationalProcedureService =
           operationalProcedureService ?? OperationalProcedureService();

  final OperacaoApiClient _apiClient;
  final OperacaoRequestMapper _mapper;
  final OperationalProcedureService _operationalProcedureService;

  Future<OperacaoInserirResponse> finalizarVenda(
    OperacaoVendaInput input,
  ) async {
    final request = _mapper.toRequest(input);

    final OperacaoInserirResponse response =
        await LoadingDoMobileComunicandoComBackendController.track(
          () => _apiClient.inserirOperacao(request: request),
        );
    final OperationalProcedurePendingExecutionStore store =
        OperationalProcedurePendingExecutionStore.instance;
    final List<String> executionIds = store.pendingSaleExecutionIds;
    if (executionIds.isNotEmpty && response.uuid.trim().isNotEmpty) {
      try {
        await _operationalProcedureService.linkExecutionsToSale(
          executionIds: executionIds,
          saleId: response.uuid,
        );
        store.markSaleLinked(executionIds);
      } catch (error) {
        debugPrint(
          '[OperacaoService] venda concluída, mas vínculo dos procedimentos '
          'ficou pendente: $error',
        );
      }
    }
    return response;
  }

  Future<DocumentoPdfResponse> imprimirComprovanteDaOperacao({
    required String idOperacao,
    required FormatoImpressaoOperacao formato,
  }) => _apiClient.imprimirComprovanteOperacao(
    idOperacao: idOperacao,
    formato: formato,
  );
}
