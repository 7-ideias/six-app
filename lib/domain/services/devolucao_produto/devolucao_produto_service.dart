import '../../../data/models/caixa_models.dart';
import '../../../data/models/devolucao_produto_models.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/services/devolucao_produto/devolucao_produto_api_client.dart';

class DevolucaoProdutoService {
  DevolucaoProdutoService({DevolucaoProdutoApiClient? apiClient})
      : _apiClient = apiClient ?? HttpDevolucaoProdutoApiClient();

  final DevolucaoProdutoApiClient _apiClient;

  Future<VendaElegivelDevolucao> buscarVendaElegivel(String identificador) {
    final String valor = identificador.trim();
    if (valor.isEmpty) {
      throw const DevolucaoProdutoValidacaoException(
        'Informe o código ou identificador da venda.',
      );
    }
    return _apiClient.buscarVendaElegivel(valor);
  }

  Future<DevolucaoProdutoResponse> registrar(
    RegistrarDevolucaoProdutoRequest request,
  ) {
    if (request.itensDevolvidos.isEmpty) {
      throw const DevolucaoProdutoValidacaoException(
        'Selecione pelo menos um produto para devolver.',
      );
    }
    if (request.tipo == TipoDevolucaoProduto.troca &&
        request.itensTroca.isEmpty) {
      throw const DevolucaoProdutoValidacaoException(
        'Adicione pelo menos um produto que o cliente receberá na troca.',
      );
    }
    return _apiClient.registrar(request);
  }

  Future<List<DevolucaoProdutoResponse>> listarRecentes() {
    return _apiClient.listarRecentes();
  }

  Future<List<ProdutoModel>> listarProdutosParaTroca() {
    return _apiClient.listarProdutosParaTroca();
  }

  Future<List<TiposRecebimento>> listarTiposDeAcertoImediato() {
    return _apiClient.listarTiposDeAcertoImediato();
  }
}

class DevolucaoProdutoValidacaoException implements Exception {
  const DevolucaoProdutoValidacaoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
