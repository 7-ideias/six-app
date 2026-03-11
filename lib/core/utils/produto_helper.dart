import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class ProdutoHelper {
  static final AuthService _authService = AuthService();

  static Future<void> retornarProdutosList(BuildContext context,
      {String tipo = 'PRODUTO', Function(List<ProdutoModel>)? onSucesso}) async {
    final provider = Provider.of<ProdutosListProvider<ProdutoModel>>(
      context,
      listen: false,
    );

    final empresaId = await _authService.getEmpresaId();
    final accessToken = await _authService.getAccessToken();

    await provider.carregar(
      headers: {
        'Content-Type': 'application/json',
        'idUnicoDaEmpresa': empresaId ?? '',
        'Authorization': 'Bearer $accessToken',
        'produtosAtivos': 'true',
        'tipo': tipo
      },
    );

    if (onSucesso != null) {
      onSucesso(provider.listaDeProdutos);
    }
  }

  static List<ProdutoModel> filtrarEOrdenarProdutos({
    required List<ProdutoModel> produtos,
    required String termoBusca,
    required String ordenacao,
  }) {
    List<ProdutoModel> resultado = [...produtos];

    if (termoBusca.isNotEmpty) {
      resultado = resultado
          .where(
            (p) => p.nomeProduto.toLowerCase().contains(
                  termoBusca.toLowerCase(),
                ),
          )
          .toList();
    }

    // Ordenação
    if (ordenacao == 'nome') {
      resultado.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
    } else if (ordenacao == 'preco') {
      resultado.sort((a, b) => a.precoVenda.compareTo(b.precoVenda));
    }

    return resultado;
  }
}
