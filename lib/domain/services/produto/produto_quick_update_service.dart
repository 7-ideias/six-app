import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/produto_model.dart';

class ProdutoQuickUpdateService {
  ProdutoQuickUpdateService({ProdutoService? produtoService})
    : _produtoService = produtoService ?? ProdutoService();

  final ProdutoService _produtoService;

  Future<ProdutoModel> alternarFavorito(ProdutoModel produto) async {
    final String? produtoId = produto.id;
    if (produtoId == null || produtoId.isEmpty) {
      throw Exception('Produto sem ID para atualização.');
    }

    final ProdutoModel atualizado = produto.copyWith(
      favorito: !produto.favorito,
    );

    await _produtoService.atualizarFavoritoProduto(
      produtoId: produtoId,
      ativo: atualizado.ativo,
      favorito: atualizado.favorito,
    );

    return atualizado;
  }

  Future<ProdutoModel> alternarDisponivelParaCatalogo(
    ProdutoModel produto,
  ) async {
    final String? produtoId = produto.id;
    if (produtoId == null || produtoId.isEmpty) {
      throw Exception('Produto sem ID para atualização.');
    }

    final ProdutoModel atualizado = produto.copyWith(
      disponivelParaCatalogo: !produto.disponivelParaCatalogo,
    );

    await _produtoService.atualizarDisponivelParaCatalogoProduto(
      produtoId: produtoId,
      ativo: atualizado.ativo,
      disponivelParaCatalogo: atualizado.disponivelParaCatalogo,
    );

    return atualizado;
  }

  Future<void> atualizarFavorito({
    required String produtoId,
    required bool ativo,
    required bool favorito,
  }) {
    if (produtoId.isEmpty) {
      throw Exception('Produto sem ID para atualização.');
    }

    return _produtoService.atualizarFavoritoProduto(
      produtoId: produtoId,
      ativo: ativo,
      favorito: favorito,
    );
  }

  Future<void> atualizarDisponivelParaCatalogo({
    required String produtoId,
    required bool ativo,
    required bool disponivelParaCatalogo,
  }) {
    if (produtoId.isEmpty) {
      throw Exception('Produto sem ID para atualização.');
    }

    return _produtoService.atualizarDisponivelParaCatalogoProduto(
      produtoId: produtoId,
      ativo: ativo,
      disponivelParaCatalogo: disponivelParaCatalogo,
    );
  }
}
