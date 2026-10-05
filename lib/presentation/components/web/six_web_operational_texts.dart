import 'package:flutter/widgets.dart';

import '../../../data/models/web_header_assets_model.dart';
import '../../../l10n/six_i18n.dart';

/// Fallbacks locais para os novos headers, enquanto o pacote remoto não os contém.
abstract final class SixWebOperationalTexts {
  static String title(BuildContext context, WebHeaderAssetPage page) =>
      _resolve(context, page, 'title', _titles);

  static String subtitle(BuildContext context, WebHeaderAssetPage page) =>
      _resolve(context, page, 'subtitle', _subtitles);

  static String _resolve(
    BuildContext context,
    WebHeaderAssetPage page,
    String field,
    Map<WebHeaderAssetPage, List<String>> values,
  ) {
    final int index = switch (Localizations.localeOf(context).languageCode) {
      'en' => 1,
      'es' => 2,
      _ => 0,
    };
    return context.t(
      'web.operational.${page.backendCode.toLowerCase()}.$field',
      fallback: values[page]![index],
    );
  }

  static const _titles = <WebHeaderAssetPage, List<String>>{
    WebHeaderAssetPage.devolucoes: [
      'Devoluções e trocas',
      'Returns and exchanges',
      'Devoluciones y cambios',
    ],
    WebHeaderAssetPage.caixa: [
      'Operações de caixa',
      'Cash register operations',
      'Operaciones de caja',
    ],
    WebHeaderAssetPage.assistencias: [
      'Atendimentos criados',
      'Technical assistance',
      'Asistencias técnicas',
    ],
    WebHeaderAssetPage.estoque: ['Estoque', 'Inventory', 'Inventario'],
  };

  static const _subtitles = <WebHeaderAssetPage, List<String>>{
    WebHeaderAssetPage.devolucoes: [
      'Localize a venda, selecione os produtos e conclua estoque e acerto financeiro em uma única jornada.',
      'Find the sale, select products and complete inventory and financial adjustments in one flow.',
      'Localice la venta, seleccione productos y complete inventario y ajuste financiero en un solo flujo.',
    ],
    WebHeaderAssetPage.assistencias: [
      'Consulte, receba, edite, audite e gere assinatura.',
      'Search, receive payments, edit, audit and collect signatures.',
      'Consulte, cobre, edite, audite y recopile firmas.',
    ],
    WebHeaderAssetPage.estoque: [
      'Controle operacional de saldos, reposição, rupturas e movimentações do estoque.',
      'Track inventory balances, replenishment, shortages and stock movements.',
      'Controle saldos, reposición, faltantes y movimientos del inventario.',
    ],
  };
}
