import '../../../data/models/atendimento_tecnico_models.dart';
import '../../../data/models/dominio_models.dart';
import '../../../data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart';

class AtendimentoTecnicoService {
  AtendimentoTecnicoService({AtendimentoTecnicoApiClient? apiClient})
    : _apiClient = apiClient ?? AtendimentoTecnicoApiClient();

  final AtendimentoTecnicoApiClient _apiClient;

  Future<AtendimentoTecnicoDominiosBaseModel> buscarDominiosBase() {
    return _apiClient.buscarDominiosBase();
  }

  Future<List<AtendimentoTecnicoModel>> listar() {
    return _apiClient.listar();
  }

  Future<AtendimentoTecnicoModel> criar(AtendimentoTecnicoCreateInput input) {
    return _apiClient.criar(input);
  }

  Future<AtendimentoTecnicoModel> alterarStatus({
    required String id,
    required DominioOpcaoModel status,
    String? observacao,
  }) {
    return _apiClient.alterarStatus(
      id: id,
      statusId: status.id,
      statusCodigo: status.codigo,
      statusI18nKey: status.i18nKey,
      observacao: observacao,
    );
  }
}
