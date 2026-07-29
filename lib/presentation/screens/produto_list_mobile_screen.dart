import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
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
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            base.ProdutolistMobileScreen(
              isSelecao: isSelecao,
              permitirSelecaoMultipla: permitirSelecaoMultipla,
            ),
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: provider.isLoading,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  reverseDuration: const Duration(milliseconds: 140),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child:
                      provider.isLoading
                          ? _ProductCatalogLoadingOverlay(
                            label: _loadingLabel(context),
                          )
                          : const SizedBox.shrink(
                            key: ValueKey<String>('catalog-loading-hidden'),
                          ),
                ),
              ),
            ),
          ],
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

class _ProductCatalogLoadingOverlay extends StatelessWidget {
  const _ProductCatalogLoadingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey<String>('catalog-loading-visible'),
      container: true,
      liveRegion: true,
      label: label,
      child: const ColoredBox(
        color: SixMobilePalette.background,
        child: Center(
          child: SizedBox.square(
            dimension: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: SixMobilePalette.accent,
              backgroundColor: SixMobilePalette.activeBorder,
            ),
          ),
        ),
      ),
    );
  }
}
