
import '../../../data/models/caixa_models.dart';
import '../../../data/services/caixa/caixa_api_client.dart';

class CaixaService {
  CaixaService({
    required CaixaApiClient apiClient,
  }) : _apiClient = apiClient;

  final CaixaApiClient _apiClient;

  Future<CaixaInformacoesBasicas> buscarInformacoesBasicas() {
    return _apiClient.getInformacoesBasicas();
  }

  Future<CaixaSessao?> buscarSessaoAtual() {
    return _apiClient.getSessaoAtual();
  }

  Future<void> abrirCaixa(AbrirCaixaRequest request) {
    return _apiClient.abrirCaixa(request);
  }

  Future<void> registrarMovimentacao(RegistrarMovimentoRequest request) {
    return _apiClient.registrarMovimento(request);
  }

  Future<List<MovimentoCaixa>> listarMovimentacoes(String idSessaoCaixa) {
    return _apiClient.getMovimentos(idSessaoCaixa);
  }

  Future<ResumoCaixa> buscarResumo(String idSessaoCaixa) {
    return _apiClient.getResumo(idSessaoCaixa);
  }

  Future<void> cancelarMovimentacao(String id) {
    return _apiClient.cancelarMovimento(id);
  }

  Future<void> fecharCaixa(FecharCaixaRequest request) {
    return _apiClient.fecharCaixa(request);
  }

  Future<void> encerrarSessao() {
    return _apiClient.encerrarSessao();
  }
}
