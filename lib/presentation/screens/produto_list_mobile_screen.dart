import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/constants/six_animation_assets.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/presentation/components/six_full_screen_lottie_loading.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';

import 'produto_list_mobile_screen_base.dart' as base;

/// Mantém a tela de catálogo desacoplada do feedback visual de carregamento.
///
/// A implementação original permanece em [base.ProdutolistMobileScreen]. Este
/// host observa somente o estado do provider e exibe a animação até o backend
/// concluir a requisição.
class ProdutolistMobileScreen extends StatelessWidget {
  const ProdutolistMobileScreen({
    super.key,
    this.isSelecao = false,
    this.permitirSelecaoMultipla = false,
  });

  final bool isSelecao;
  final bool permitirSelecaoMultipla;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProdutosListProvider<ProdutoModel>>(
      builder: (
        BuildContext context,
        ProdutosListProvider<ProdutoModel> provider,
        _,
      ) {
        return SixFullScreenLottieLoading(
          isLoading: provider.isLoading,
          animationAsset: SixAnimationAssets.productCatalogLoading,
          semanticsLabel: _loadingLabel(context),
          child: base.ProdutolistMobileScreen(
            isSelecao: isSelecao,
            permitirSelecaoMultipla: permitirSelecaoMultipla,
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
