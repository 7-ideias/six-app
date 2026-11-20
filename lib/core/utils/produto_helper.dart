import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class ProdutoHelper {
  static final AuthService _authService = AuthService();

  static Future<void> retornarProdutosList(
    BuildContext context, {
    String tipo = 'PRODUTO',
    bool? produtosAtivos,
    Function(List<ProdutoModel>)? onSucesso,
  }) async {
    final provider = Provider.of<ProdutosListProvider<ProdutoModel>>(
      context,
      listen: false,
    );

    await provider.carregar(
      headers: await headersListagem(tipo, produtosAtivos),
    );

    if (onSucesso != null) {
      onSucesso(provider.listaDeProdutos);
    }
  }

  static Future<Map<String, String>> headersListagem(
    String tipo, [
    bool? ativos,
  ]) async {
    final empresa = await _authService.getEmpresaId();
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresa ?? '',
      'Authorization': 'Bearer $token',
      'tipo': tipo,
      if (ativos != null) 'produtosAtivos': '$ativos',
    };
  }

  static List<ProdutoModel> filtrarEOrdenarProdutos({
    required List<ProdutoModel> produtos,
    required String termoBusca,
    required String ordenacao,
  }) {
    List<ProdutoModel> resultado = [...produtos];
    final termoNormalizado = termoBusca.trim().toLowerCase();

    if (termoNormalizado.isNotEmpty) {
      resultado =
          resultado
              .where(
                (p) =>
                    p.nomeProduto.toLowerCase().contains(termoNormalizado) ||
                    p.codigoDeBarras.toLowerCase().contains(termoNormalizado),
              )
              .toList();
    }

    if (ordenacao == 'nome') {
      resultado.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
    } else if (ordenacao == 'preco' || ordenacao == 'precoAsc') {
      resultado.sort((a, b) => a.precoVenda.compareTo(b.precoVenda));
    } else if (ordenacao == 'precoDesc') {
      resultado.sort((a, b) => b.precoVenda.compareTo(a.precoVenda));
    }

    return resultado;
  }
}
