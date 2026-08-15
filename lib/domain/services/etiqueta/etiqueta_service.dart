import '../../../data/models/etiqueta_models.dart';
import '../../../data/services/etiqueta/etiqueta_api_client.dart';

class EtiquetaService {
  EtiquetaService({EtiquetaApiClient? apiClient})
      : _apiClient = apiClient ?? HttpEtiquetaApiClient();

  final EtiquetaApiClient _apiClient;

  Future<bool> buscarAcesso() => _apiClient.buscarAcesso();

  Future<List<EtiquetaModelo>> listarModelos() => _apiClient.listarModelos();

  Future<EtiquetaModelo> buscarModelo(String id) => _apiClient.buscarModelo(id);

  Future<EtiquetaModelo> salvarModelo(EtiquetaModelo modelo) {
    return modelo.id == null
        ? _apiClient.criarModelo(modelo)
        : _apiClient.atualizarModelo(modelo);
  }

  Future<EtiquetaModelo> duplicarModelo(String id) =>
      _apiClient.duplicarModelo(id);

  Future<void> excluirModelo(String id) => _apiClient.excluirModelo(id);

  Future<EtiquetaPdfResponse> gerarPdf({
    required String templateId,
    required List<EtiquetaImpressaoItem> items,
  }) =>
      _apiClient.gerarPdf(templateId: templateId, items: items);

  Future<bool> buscarPermissaoColaborador(String idUnicoDoUsuario) =>
      _apiClient.buscarPermissaoColaborador(idUnicoDoUsuario);

  Future<bool> atualizarPermissaoColaborador(
    String idUnicoDoUsuario, {
    required bool permitido,
  }) =>
      _apiClient.atualizarPermissaoColaborador(
        idUnicoDoUsuario,
        permitido: permitido,
      );
}
