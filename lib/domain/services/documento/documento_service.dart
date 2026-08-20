import '../../../data/models/documento_models.dart';
import '../../../data/services/documento/documento_api_client.dart';

class DocumentoService {
  DocumentoService({DocumentoApiClient? apiClient})
    : _apiClient = apiClient ?? HttpDocumentoApiClient();

  final DocumentoApiClient _apiClient;

  Future<bool> buscarAcesso() => _apiClient.buscarAcesso();

  Future<List<ModeloDocumento>> listarModelos() => _apiClient.listarModelos();

  Future<List<ModeloPadraoDocumento>> listarPadroes() =>
      _apiClient.listarPadroes();

  Future<ModeloDocumento> salvarModelo(ModeloDocumento modelo) =>
      modelo.id == null
      ? _apiClient.criarModelo(modelo)
      : _apiClient.atualizarModelo(modelo);

  Future<ModeloDocumento> duplicarModelo(String id) =>
      _apiClient.duplicarModelo(id);

  Future<void> excluirModelo(String id) => _apiClient.excluirModelo(id);

  Future<ModeloPadraoDocumento> definirPadrao(ModeloPadraoDocumento padrao) =>
      _apiClient.definirPadrao(padrao);

  Future<DocumentoPdfResponse> gerarPrevia({
    required String idModelo,
    required TipoDocumentoPdf tipoDocumento,
  }) =>
      _apiClient.gerarPrevia(idModelo: idModelo, tipoDocumento: tipoDocumento);
}
