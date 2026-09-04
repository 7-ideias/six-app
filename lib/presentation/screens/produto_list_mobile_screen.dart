import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_mobile_loading_scene.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';

import 'produto_list_mobile_screen_base.dart' as base;

/// Mantem a tela de catalogo desacoplada do feedback visual de carregamento.
///
/// A implementacao original permanece em [base.ProdutolistMobileScreen]. Este
/// host observa somente o estado do provider e exibe o loading ate o backend
/// concluir a requisicao.
class ProdutolistMobileScreen extends StatelessWidget {
  const ProdutolistMobileScreen({
    super.key,
    this.isSelecao = false,
    this.permitirSelecaoMultipla = false,
    this.tipoInicial = 'PRODUTO',
    this.apenasAtivosNoBackend = false,
    this.exibirInformacoesEstoque = false,
    this.produtoService,
  });

  final bool isSelecao;
  final bool permitirSelecaoMultipla;
  final String tipoInicial;
  final bool apenasAtivosNoBackend;
  final bool exibirInformacoesEstoque;
  final ProdutoService? produtoService;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProdutosListProvider<ProdutoModel>>(
      builder: (
        BuildContext context,
        ProdutosListProvider<ProdutoModel> provider,
        _,
      ) {
        return SixoAppMobileLoadingOverlay(
          isLoading: provider.isLoading,
          message: _loadingLabel(context),
          visibleKey: const ValueKey<String>('catalog-loading-visible'),
          child: base.ProdutolistMobileScreen(
            isSelecao: isSelecao,
            permitirSelecaoMultipla: permitirSelecaoMultipla,
            tipoInicial: tipoInicial,
            apenasAtivosNoBackend: apenasAtivosNoBackend,
            exibirInformacoesEstoque: exibirInformacoesEstoque,
            produtoService: produtoService,
          ),
        );
      },
    );
  }

  String _loadingLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Loading products and services';
      case 'es':
        return 'Cargando productos y servicios';
      default:
        return 'Carregando produtos e serviços';
    }
  }
}
