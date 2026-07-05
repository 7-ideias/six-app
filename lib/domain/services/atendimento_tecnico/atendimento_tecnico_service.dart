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

  Future<List<DominioStatusAtendimentoCustomizacaoModel>> listarCustomizacoesStatusAtendimento() {
    return _apiClient.listarCustomizacoesStatusAtendimento();
  }

  Future<List<DominioStatusAtendimentoCustomizacaoModel>> salvarCustomizacoesStatusAtendimento(List<Map<String, dynamic>> customizacoes) {
    return _apiClient.salvarCustomizacoesStatusAtendimento(customizacoes);
  }

  Future<List<AtendimentoTecnicoModel>> listar() {
    return _apiClient.listar();
  }

  Future<AtendimentoTecnicoModel> criar(AtendimentoTecnicoCreateInput input) {
    return _apiClient.criar(input);
  }

  Future<AtendimentoTecnicoModel> atualizar({required String id, required AtendimentoTecnicoUpdateInput input}) {
    return _apiClient.atualizar(id: id, input: input);
  }

  Future<AtendimentoTecnicoModel> receber({required String id, required AtendimentoTecnicoRecebimentoInput input}) {
    return _apiClient.receber(id: id, input: input);
  }

  Future<AtendimentoTecnicoModel> alterarStatus({required String id, required DominioOpcaoModel status, String? observacao}) {
    return _apiClient.alterarStatus(
      id: id,
      statusId: status.id,
      statusCodigo: status.codigo,
      statusI18nKey: status.i18nKey,
      observacao: observacao,
    );
  }

  Future<Map<String, dynamic>> gerarLinkAssinatura({required String id, required String baseUrl}) {
    return _apiClient.gerarLinkAssinatura(id: id, baseUrl: baseUrl);
  }

  Future<Map<String, dynamic>> consultarAssinaturaPublica({required String idUnicoDaEmpresa, required String token}) {
    return _apiClient.consultarAssinaturaPublica(idUnicoDaEmpresa: idUnicoDaEmpresa, token: token);
  }

  Future<Map<String, dynamic>> aprovarAssinaturaPublica({required String idUnicoDaEmpresa, required String token, required String nomeAssinante, required String? documentoAssinante, required String assinaturaDataUrl, required String? observacao}) {
    return _apiClient.aprovarAssinaturaPublica(
      idUnicoDaEmpresa: idUnicoDaEmpresa,
      token: token,
      nomeAssinante: nomeAssinante,
      documentoAssinante: documentoAssinante,
      assinaturaDataUrl: assinaturaDataUrl,
      observacao: observacao,
    );
  }
}
