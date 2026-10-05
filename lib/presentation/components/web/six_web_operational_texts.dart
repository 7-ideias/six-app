import 'package:flutter/widgets.dart';

import '../../../data/models/web_header_assets_model.dart';
import '../../../l10n/six_i18n.dart';

/// Fallbacks locais para os novos headers, enquanto o pacote remoto não os contém.
abstract final class SixWebOperationalTexts {
  static String title(BuildContext context, WebHeaderAssetPage page) =>
      _resolve(context, page, 'title', _titles);

  static String subtitle(BuildContext context, WebHeaderAssetPage page) =>
      _resolve(context, page, 'subtitle', _subtitles);

  static String action(BuildContext context, String key) =>
      _localized(context, key, _actions[key]!);

  static String updatedAt(BuildContext context, String time) => _localized(
    context,
    'agenda.updatedAt',
    ['Atualizado às {time}', 'Updated at {time}', 'Actualizado a las {time}'],
  ).replaceAll('{time}', time);

  static String _resolve(
    BuildContext context,
    WebHeaderAssetPage page,
    String field,
    Map<WebHeaderAssetPage, List<String>> values,
  ) {
    return _localized(
      context,
      'web.operational.${page.backendCode.toLowerCase()}.$field',
      values[page]!,
    );
  }

  static String _localized(
    BuildContext context,
    String key,
    List<String> values,
  ) {
    final int index = switch (Localizations.localeOf(context).languageCode) {
      'en' => 1,
      'es' => 2,
      _ => 0,
    };
    return context.t(key, fallback: values[index]);
  }

  static const _titles = <WebHeaderAssetPage, List<String>>{
    WebHeaderAssetPage.agendaFinanceira: [
      'Agenda financeira',
      'Financial agenda',
      'Agenda financiera',
    ],
    WebHeaderAssetPage.clientes: ['Clientes', 'Customers', 'Clientes'],
    WebHeaderAssetPage.desempenho: [
      'Desempenho do colaborador',
      'Employee performance',
      'Desempeño del colaborador',
    ],
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
    WebHeaderAssetPage.agendaFinanceira: [
      'Filtre os lançamentos e acompanhe seus detalhes.',
      'Filter financial entries and track their details.',
      'Filtre los movimientos financieros y consulte sus detalles.',
    ],
    WebHeaderAssetPage.clientes: [
      'Resumo da base de clientes, fiado, contatos e relacionamento comercial.',
      'Overview of customers, credit accounts, contacts and business relationships.',
      'Resumen de clientes, crédito, contactos y relaciones comerciales.',
    ],
    WebHeaderAssetPage.desempenho: [
      'Resumo executivo de metas, vendas, serviços e atendimentos por participante.',
      'Overview of goals, sales, services and assistance by participant.',
      'Resumen de metas, ventas, servicios y asistencias por participante.',
    ],
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

  static const _actions = <String, List<String>>{
    'common.refresh': ['Atualizar', 'Refresh', 'Actualizar'],
    'common.close': ['Fechar', 'Close', 'Cerrar'],
    'agenda.newEntry': ['Novo lançamento', 'New entry', 'Nuevo movimiento'],
    'clientes.autoRegistration': [
      'Auto cadastro',
      'Self-registration',
      'Autorregistro',
    ],
    'clientes.newCustomer': ['Novo cliente', 'New customer', 'Nuevo cliente'],
    'desempenho.newGoal': ['Nova meta', 'New goal', 'Nueva meta'],
  };
}
