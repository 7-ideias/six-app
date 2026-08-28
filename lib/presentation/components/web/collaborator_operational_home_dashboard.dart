import 'package:flutter/material.dart';

import '../../../data/models/catalogo_reserva_model.dart';
import '../../../data/models/consulta_vendas_models.dart';
import '../../../data/models/venda_nao_liquidada_models.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/colaborador_home_operacional_provider.dart';
import '../../../providers/locale_settings_provider.dart';
import '../../theme/web_theme_tokens.dart';
import '../web_dashboard_widgets.dart';

class CollaboratorOperationalHomeWebDashboard extends StatelessWidget {
  const CollaboratorOperationalHomeWebDashboard({
    super.key,
    required this.provider,
    required this.regionalizacao,
    required this.showSales,
    required this.showServices,
    required this.showReservations,
    required this.onRetry,
    this.onOpenServices,
    this.onOpenReservations,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final bool showSales;
  final bool showServices;
  final bool showReservations;
  final Future<void> Function() onRetry;
  final VoidCallback? onOpenServices;
  final VoidCallback? onOpenReservations;

  @override
  Widget build(BuildContext context) {
    if (!showSales && !showServices && !showReservations) {
      return const SizedBox.shrink();
    }

    if (!provider.hasLoaded) {
      return const _OperationalLoading();
    }

    if (provider.globalErrorCode != null) {
      return _OperationalError(onRetry: onRetry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SixWebEntry(
          order: 0,
          child: _AttentionOverview(
            provider: provider,
            regionalizacao: regionalizacao,
            showSales: showSales,
            showServices: showServices,
            showReservations: showReservations,
          ),
        ),
        if (showSales) ...<Widget>[
          const SizedBox(height: 16),
          SixWebEntry(
            order: 1,
            child: _SalesOverview(
              provider: provider,
              regionalizacao: regionalizacao,
              onRetry: onRetry,
            ),
          ),
        ],
        if (showServices || showReservations) ...<Widget>[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stack =
                  constraints.maxWidth < 920 ||
                  !showServices ||
                  !showReservations;
              final Widget services = _ServicesOverview(
                provider: provider,
                regionalizacao: regionalizacao,
                onRetry: onRetry,
                onOpen: onOpenServices,
              );
              final Widget reservations = _ReservationsOverview(
                provider: provider,
                regionalizacao: regionalizacao,
                onRetry: onRetry,
                onOpen: onOpenReservations,
              );

              if (stack) {
                return Column(
                  children: <Widget>[
                    if (showServices) SixWebEntry(order: 2, child: services),
                    if (showServices && showReservations)
                      const SizedBox(height: 16),
                    if (showReservations)
                      SixWebEntry(order: 3, child: reservations),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: SixWebEntry(order: 2, child: services),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: SixWebEntry(order: 3, child: reservations),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _OperationalLoading extends StatelessWidget {
  const _OperationalLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.t(
        'collaboratorHome.loading',
        fallback: 'Carregando seu painel operacional',
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 760;
          const Widget first = SixWebLoadingBlock(height: 286);
          const Widget second = SixWebLoadingBlock(height: 286);
          return Column(
            children: <Widget>[
              const SixWebLoadingBlock(height: 104, highlight: true),
              const SizedBox(height: 16),
              const SixWebLoadingBlock(height: 316),
              const SizedBox(height: 16),
              if (stack) ...<Widget>[
                first,
                const SizedBox(height: 16),
                second,
              ] else
                const Row(
                  children: <Widget>[
                    Expanded(child: first),
                    SizedBox(width: 16),
                    Expanded(child: second),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OperationalError extends StatelessWidget {
  const _OperationalError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.danger.withValues(alpha: .45)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: tokens.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t(
                'collaboratorHome.error.user',
                fallback: 'Não foi possível identificar seu painel pessoal.',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionOverview extends StatelessWidget {
  const _AttentionOverview({
    required this.provider,
    required this.regionalizacao,
    required this.showSales,
    required this.showServices,
    required this.showReservations,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final bool showSales;
  final bool showServices;
  final bool showReservations;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final int urgentCount =
        (showSales ? provider.vendasVencidas : 0) +
        (showServices ? provider.servicosAtrasados : 0) +
        (showReservations ? provider.reservasAguardandoAcao : 0);
    final bool allClear = urgentCount == 0;
    final Color accent = allClear ? tokens.success : tokens.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: .07),
          tokens.cardBackground,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 700;
          final Widget title = Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  allClear
                      ? Icons.verified_outlined
                      : Icons.notification_important_outlined,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(
                        'collaboratorHome.attention.title',
                        fallback: 'Prioridades do trabalho',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      allClear
                          ? context.t(
                              'collaboratorHome.attention.clear',
                              fallback:
                                  'Tudo em dia nas suas frentes de trabalho.',
                            )
                          : context
                                .t(
                                  'collaboratorHome.attention.pending',
                                  fallback:
                                      '{count} pontos precisam de atenção.',
                                )
                                .replaceAll(
                                  '{count}',
                                  regionalizacao.formatInteger(urgentCount),
                                ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final Widget indicators = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              if (showSales)
                _AttentionPill(
                  icon: Icons.schedule_outlined,
                  label: context.t(
                    'collaboratorHome.attention.overdueSales',
                    fallback: 'Vendas vencidas',
                  ),
                  value: provider.vendasVencidas,
                  regionalizacao: regionalizacao,
                  alert: provider.vendasVencidas > 0,
                ),
              if (showServices)
                _AttentionPill(
                  icon: Icons.build_circle_outlined,
                  label: context.t(
                    'collaboratorHome.attention.overdueServices',
                    fallback: 'Entregas atrasadas',
                  ),
                  value: provider.servicosAtrasados,
                  regionalizacao: regionalizacao,
                  alert: provider.servicosAtrasados > 0,
                ),
              if (showReservations)
                _AttentionPill(
                  icon: Icons.bookmark_added_outlined,
                  label: context.t(
                    'collaboratorHome.attention.reservations',
                    fallback: 'Reservas para analisar',
                  ),
                  value: provider.reservasAguardandoAcao,
                  regionalizacao: regionalizacao,
                  alert: provider.reservasAguardandoAcao > 0,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[title, const SizedBox(height: 14), indicators],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: 18),
              Flexible(child: indicators),
            ],
          );
        },
      ),
    );
  }
}

class _AttentionPill extends StatelessWidget {
  const _AttentionPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.regionalizacao,
    required this.alert,
  });

  final IconData icon;
  final String label;
  final int value;
  final LocaleSettingsProvider regionalizacao;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = alert ? tokens.warning : tokens.success;
    return Semantics(
      label: label,
      value: regionalizacao.formatInteger(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              '$label: ${regionalizacao.formatInteger(value)}',
              style: TextStyle(
                color: tokens.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ConsultaVendasResponse? sales = provider.vendasMes;
    final ResumoConsultaVendas? summary = sales?.resumo;
    final String period = context
        .t(
          'collaboratorHome.sales.period',
          fallback: 'Resultados de {start} a {end}',
        )
        .replaceAll(
          '{start}',
          regionalizacao.formatDate(provider.periodoInicio ?? DateTime.now()),
        )
        .replaceAll(
          '{end}',
          regionalizacao.formatDate(provider.periodoFim ?? DateTime.now()),
        );

    return SixWebSectionCard(
      title: context.t(
        'collaboratorHome.sales.title',
        fallback: 'Minhas vendas',
      ),
      subtitle: period,
      icon: Icons.point_of_sale_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (summary != null)
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth < 620 ? 2 : 4;
                const double spacing = 10;
                final double width =
                    (constraints.maxWidth - (columns - 1) * spacing) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: <Widget>[
                    _SalesMetric(
                      width: width,
                      icon: Icons.receipt_long_outlined,
                      label: context.t(
                        'collaboratorHome.sales.count',
                        fallback: 'Vendas no mês',
                      ),
                      value: summary.quantidadeVendas.toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                    ),
                    _SalesMetric(
                      width: width,
                      icon: Icons.trending_up_rounded,
                      label: context.t(
                        'collaboratorHome.sales.total',
                        fallback: 'Total vendido',
                      ),
                      value: summary.valorTotalVendido,
                      formatter: (double value) =>
                          regionalizacao.formatCurrency(value),
                    ),
                    _SalesMetric(
                      width: width,
                      icon: Icons.check_circle_outline_rounded,
                      label: context.t(
                        'collaboratorHome.sales.received',
                        fallback: 'Já recebido',
                      ),
                      value: summary.valorTotalRecebido,
                      formatter: (double value) =>
                          regionalizacao.formatCurrency(value),
                    ),
                    _SalesMetric(
                      width: width,
                      icon: Icons.pending_actions_outlined,
                      label: context.t(
                        'collaboratorHome.sales.openMonth',
                        fallback: 'Em aberto no mês',
                      ),
                      value: summary.valorTotalEmAberto,
                      formatter: (double value) =>
                          regionalizacao.formatCurrency(value),
                      warning: summary.valorTotalEmAberto > 0,
                    ),
                  ],
                );
              },
            )
          else
            _InlineLoadError(
              message: context.t(
                'collaboratorHome.sales.loadError',
                fallback: 'Não foi possível carregar o resumo das suas vendas.',
              ),
              onRetry: onRetry,
            ),
          const SizedBox(height: 18),
          _OpenSalesList(
            provider: provider,
            regionalizacao: regionalizacao,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SalesMetric extends StatelessWidget {
  const _SalesMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.formatter,
    this.warning = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final double value;
  final String Function(double value) formatter;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = warning ? tokens.warning : tokens.info;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 106),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            key: ValueKey<String>('sales-$label-${value.toStringAsFixed(2)}'),
            tween: Tween<double>(begin: 0, end: value),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double current, Widget? child) {
              return Text(
                formatter(current),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OpenSalesList extends StatelessWidget {
  const _OpenSalesList({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<VendaNaoLiquidadaModel> sales = provider.vendasEmAberto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t(
                      'collaboratorHome.openSales.title',
                      fallback: 'Vendas ainda não liquidadas',
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.t(
                      'collaboratorHome.openSales.subtitle',
                      fallback: 'Somente vendas registradas por você.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (sales.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: tokens.warning.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${regionalizacao.formatInteger(sales.length)} • '
                  '${regionalizacao.formatCurrency(provider.valorTotalVendasEmAberto)}',
                  style: TextStyle(
                    color: tokens.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.vendasEmAbertoErrorCode != null && sales.isEmpty)
          _InlineLoadError(
            message: context.t(
              'collaboratorHome.openSales.loadError',
              fallback: 'Não foi possível carregar suas vendas em aberto.',
            ),
            onRetry: onRetry,
          )
        else if (sales.isEmpty)
          SixWebNoData(
            height: 104,
            text: context.t(
              'collaboratorHome.openSales.empty',
              fallback: 'Você não possui vendas aguardando liquidação.',
            ),
          )
        else
          Column(
            children: <Widget>[
              for (final VendaNaoLiquidadaModel sale in sales.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OpenSaleRow(
                    sale: sale,
                    regionalizacao: regionalizacao,
                  ),
                ),
              if (sales.length > 4)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context
                        .t(
                          'collaboratorHome.openSales.more',
                          fallback: 'Mais {count} vendas em aberto',
                        )
                        .replaceAll(
                          '{count}',
                          regionalizacao.formatInteger(sales.length - 4),
                        ),
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _OpenSaleRow extends StatelessWidget {
  const _OpenSaleRow({required this.sale, required this.regionalizacao});

  final VendaNaoLiquidadaModel sale;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final DateTime today = DateTime.now();
    final DateTime? due = sale.dataVencimento;
    final bool overdue =
        due != null &&
        DateTime(
          due.year,
          due.month,
          due.day,
        ).isBefore(DateTime(today.year, today.month, today.day));
    final String customer = sale.nomeCliente.trim().isEmpty
        ? context.t(
            'collaboratorHome.openSales.customerFallback',
            fallback: 'Cliente não informado',
          )
        : sale.nomeCliente.trim();
    final String identifier = sale.descricao.trim().isNotEmpty
        ? sale.descricao.trim()
        : sale.idOperacaoApp.trim().isNotEmpty
        ? sale.idOperacaoApp.trim()
        : context.t(
            'collaboratorHome.openSales.saleFallback',
            fallback: 'Venda',
          );

    return Semantics(
      container: true,
      label: '$identifier, $customer',
      value: regionalizacao.formatCurrency(sale.valorAberto),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: overdue
                ? tokens.danger.withValues(alpha: .32)
                : tokens.cardBorder,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (overdue ? tokens.danger : tokens.warning).withValues(
                  alpha: .09,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                overdue ? Icons.event_busy_outlined : Icons.schedule_outlined,
                color: overdue ? tokens.danger : tokens.warning,
                size: 18,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    identifier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  regionalizacao.formatCurrency(sale.valorAberto),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  due == null
                      ? context.t(
                          'collaboratorHome.openSales.noDueDate',
                          fallback: 'Sem vencimento',
                        )
                      : overdue
                      ? context.t(
                          'collaboratorHome.openSales.overdue',
                          fallback: 'Vencida',
                        )
                      : regionalizacao.formatDate(due),
                  style: TextStyle(
                    color: overdue ? tokens.danger : tokens.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesOverview extends StatelessWidget {
  const _ServicesOverview({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
    this.onOpen,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final List<ColaboradorServicoStatusResumo> statuses =
        provider.servicosPorStatus;
    return SixWebSectionCard(
      title: context.t(
        'collaboratorHome.services.title',
        fallback: 'Meus serviços por status',
      ),
      subtitle: context.t(
        'collaboratorHome.services.subtitle',
        fallback: 'Distribuição dos atendimentos em que você é o técnico.',
      ),
      icon: Icons.engineering_outlined,
      trailing: onOpen == null
          ? null
          : TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: Text(
                context.t(
                  'collaboratorHome.services.open',
                  fallback: 'Abrir atendimentos',
                ),
              ),
            ),
      child: provider.servicosErrorCode != null && statuses.isEmpty
          ? _InlineLoadError(
              message: context.t(
                'collaboratorHome.services.loadError',
                fallback: 'Não foi possível carregar seus serviços.',
              ),
              onRetry: onRetry,
            )
          : statuses.isEmpty
          ? SixWebNoData(
              height: 150,
              text: context.t(
                'collaboratorHome.services.empty',
                fallback: 'Nenhum atendimento está atribuído a você.',
              ),
            )
          : Column(
              children: <Widget>[
                _ServiceMetrics(
                  provider: provider,
                  regionalizacao: regionalizacao,
                ),
                const SizedBox(height: 18),
                _ServiceStatusChart(
                  statuses: statuses,
                  regionalizacao: regionalizacao,
                ),
              ],
            ),
    );
  }
}

class _ServiceMetrics extends StatelessWidget {
  const _ServiceMetrics({required this.provider, required this.regionalizacao});

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth < 520 ? 2 : 4;
        const double spacing = 8;
        final double width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            _SmallMetric(
              width: width,
              label: context.t(
                'collaboratorHome.services.total',
                fallback: 'Total atribuído',
              ),
              value: provider.servicos.length,
              regionalizacao: regionalizacao,
            ),
            _SmallMetric(
              width: width,
              label: context.t(
                'collaboratorHome.services.inProgress',
                fallback: 'Em andamento',
              ),
              value: provider.servicosEmAndamento,
              regionalizacao: regionalizacao,
            ),
            _SmallMetric(
              width: width,
              label: context.t(
                'collaboratorHome.services.dueToday',
                fallback: 'Entregas hoje',
              ),
              value: provider.servicosComEntregaHoje,
              regionalizacao: regionalizacao,
              warning: provider.servicosComEntregaHoje > 0,
            ),
            _SmallMetric(
              width: width,
              label: context.t(
                'collaboratorHome.services.overdue',
                fallback: 'Atrasados',
              ),
              value: provider.servicosAtrasados,
              regionalizacao: regionalizacao,
              danger: provider.servicosAtrasados > 0,
            ),
          ],
        );
      },
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.regionalizacao,
    this.warning = false,
    this.danger = false,
  });

  final double width;
  final String label;
  final int value;
  final LocaleSettingsProvider regionalizacao;
  final bool warning;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color valueColor = danger
        ? tokens.danger
        : warning
        ? tokens.warning
        : tokens.primaryText;
    return Container(
      width: width,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            key: ValueKey<String>('small-$label-$value'),
            tween: Tween<double>(begin: 0, end: value.toDouble()),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 520),
            builder: (BuildContext context, double current, Widget? child) {
              return Text(
                regionalizacao.formatInteger(current),
                style: TextStyle(
                  color: valueColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceStatusChart extends StatefulWidget {
  const _ServiceStatusChart({
    required this.statuses,
    required this.regionalizacao,
  });

  final List<ColaboradorServicoStatusResumo> statuses;
  final LocaleSettingsProvider regionalizacao;

  @override
  State<_ServiceStatusChart> createState() => _ServiceStatusChartState();
}

class _ServiceStatusChartState extends State<_ServiceStatusChart> {
  String? _hoveredKey;

  @override
  Widget build(BuildContext context) {
    final List<ColaboradorServicoStatusResumo> visible = widget.statuses
        .take(6)
        .toList(growable: false);
    final int maxCount = visible.fold<int>(
      1,
      (int current, ColaboradorServicoStatusResumo status) =>
          status.count > current ? status.count : current,
    );

    return Column(
      children: <Widget>[
        for (int index = 0; index < visible.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == visible.length - 1 ? 0 : 10,
            ),
            child: _ServiceStatusBar(
              status: visible[index],
              index: index,
              maxCount: maxCount,
              regionalizacao: widget.regionalizacao,
              highlighted: _hoveredKey == visible[index].key,
              dimmed: _hoveredKey != null && _hoveredKey != visible[index].key,
              onHover: (bool hovering) {
                setState(
                  () => _hoveredKey = hovering ? visible[index].key : null,
                );
              },
            ),
          ),
        if (widget.statuses.length > visible.length) ...<Widget>[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context
                  .t(
                    'collaboratorHome.services.moreStatuses',
                    fallback: 'Mais {count} status com movimentação',
                  )
                  .replaceAll(
                    '{count}',
                    widget.regionalizacao.formatInteger(
                      widget.statuses.length - visible.length,
                    ),
                  ),
              style: TextStyle(
                color: WebThemeTokens.of(context).secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceStatusBar extends StatelessWidget {
  const _ServiceStatusBar({
    required this.status,
    required this.index,
    required this.maxCount,
    required this.regionalizacao,
    required this.highlighted,
    required this.dimmed,
    required this.onHover,
  });

  final ColaboradorServicoStatusResumo status;
  final int index;
  final int maxCount;
  final LocaleSettingsProvider regionalizacao;
  final bool highlighted;
  final bool dimmed;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = _statusColor(context, status.colorHex, index);
    final String label = _serviceStatusLabel(context, status, regionalizacao);
    final double progress = status.count / maxCount;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Semantics(
        label: label,
        value: regionalizacao.formatInteger(status.count),
        child: AnimatedOpacity(
          opacity: dimmed ? .55 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(highlighted ? 9 : 8),
            decoration: BoxDecoration(
              color: highlighted
                  ? color.withValues(alpha: .07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      regionalizacao.formatInteger(status.count),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      'service-${status.key}-${status.count}',
                    ),
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : Duration(milliseconds: 520 + index * 55),
                    curve: Curves.easeOutCubic,
                    builder:
                        (BuildContext context, double current, Widget? child) {
                          return LinearProgressIndicator(
                            minHeight: highlighted ? 10 : 8,
                            value: current,
                            backgroundColor: tokens.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          );
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationsOverview extends StatelessWidget {
  const _ReservationsOverview({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
    this.onOpen,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final int total = provider.reservasPorStatus.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    final List<_ReservationEntry> entries = <_ReservationEntry>[
      _ReservationEntry(
        status: CatalogoReservaStatus.recebida,
        label: context.t(
          'collaboratorHome.reservations.received',
          fallback: 'Recebidas',
        ),
        color: WebThemeTokens.of(context).info,
      ),
      _ReservationEntry(
        status: CatalogoReservaStatus.emAnalise,
        label: context.t(
          'collaboratorHome.reservations.analysis',
          fallback: 'Em análise',
        ),
        color: WebThemeTokens.of(context).warning,
      ),
      _ReservationEntry(
        status: CatalogoReservaStatus.confirmada,
        label: context.t(
          'collaboratorHome.reservations.confirmed',
          fallback: 'Confirmadas',
        ),
        color: WebThemeTokens.of(context).success,
      ),
      _ReservationEntry(
        status: CatalogoReservaStatus.convertida,
        label: context.t(
          'collaboratorHome.reservations.converted',
          fallback: 'Convertidas',
        ),
        color: Theme.of(context).colorScheme.tertiary,
      ),
    ];

    return SixWebSectionCard(
      title: context.t(
        'collaboratorHome.reservations.title',
        fallback: 'Fila de reservas',
      ),
      subtitle: context.t(
        'collaboratorHome.reservations.subtitle',
        fallback: 'Pedidos do catálogo que podem virar venda.',
      ),
      icon: Icons.bookmarks_outlined,
      trailing: onOpen == null
          ? null
          : IconButton(
              onPressed: onOpen,
              tooltip: context.t(
                'collaboratorHome.reservations.open',
                fallback: 'Abrir reservas',
              ),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
      child: provider.reservasErrorCode != null && total == 0
          ? _InlineLoadError(
              message: context.t(
                'collaboratorHome.reservations.loadError',
                fallback: 'Não foi possível carregar as reservas.',
              ),
              onRetry: onRetry,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ReservationMainMetric(
                        label: context.t(
                          'collaboratorHome.reservations.pending',
                          fallback: 'Pendentes',
                        ),
                        value: provider.reservasPendentes,
                        regionalizacao: regionalizacao,
                        highlight: provider.reservasPendentes > 0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReservationMainMetric(
                        label: context.t(
                          'collaboratorHome.reservations.converted',
                          fallback: 'Convertidas',
                        ),
                        value: provider.reservaCount(
                          CatalogoReservaStatus.convertida,
                        ),
                        regionalizacao: regionalizacao,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (int index = 0; index < entries.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == entries.length - 1 ? 0 : 10,
                    ),
                    child: _ReservationStatusRow(
                      entry: entries[index],
                      count: provider.reservaCount(entries[index].status),
                      maxCount: entries.fold<int>(1, (int current, entry) {
                        final int count = provider.reservaCount(entry.status);
                        return count > current ? count : current;
                      }),
                      regionalizacao: regionalizacao,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ReservationMainMetric extends StatelessWidget {
  const _ReservationMainMetric({
    required this.label,
    required this.value,
    required this.regionalizacao,
    this.highlight = false,
  });

  final String label;
  final int value;
  final LocaleSettingsProvider regionalizacao;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: highlight
            ? tokens.warning.withValues(alpha: .08)
            : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: highlight
              ? tokens.warning.withValues(alpha: .25)
              : tokens.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            regionalizacao.formatInteger(value),
            style: TextStyle(
              color: highlight ? tokens.warning : tokens.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationStatusRow extends StatelessWidget {
  const _ReservationStatusRow({
    required this.entry,
    required this.count,
    required this.maxCount,
    required this.regionalizacao,
  });

  final _ReservationEntry entry;
  final int count;
  final int maxCount;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: entry.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.label,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              regionalizacao.formatInteger(count),
              style: TextStyle(
                color: entry.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            key: ValueKey<String>('reservation-${entry.status.name}-$count'),
            tween: Tween<double>(begin: 0, end: count / maxCount),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 520),
            builder: (BuildContext context, double current, Widget? child) {
              return LinearProgressIndicator(
                minHeight: 7,
                value: current,
                backgroundColor: tokens.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(entry.color),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReservationEntry {
  const _ReservationEntry({
    required this.status,
    required this.label,
    required this.color,
  });

  final CatalogoReservaStatus status;
  final String label;
  final Color color;
}

class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: .22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.sync_problem_outlined, color: tokens.danger, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: tokens.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: context.t('common.tryAgain', fallback: 'Tentar novamente'),
            icon: const Icon(Icons.refresh_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, String rawHex, int index) {
  final String normalized = rawHex.trim().replaceFirst('#', '');
  if (normalized.length == 6 || normalized.length == 8) {
    final int? value = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    if (value != null) return Color(value);
  }
  final WebThemeTokens tokens = WebThemeTokens.of(context);
  final List<Color> fallbacks = <Color>[
    tokens.info,
    tokens.warning,
    tokens.success,
    Theme.of(context).colorScheme.tertiary,
    tokens.danger,
    tokens.statusNeutral,
  ];
  return fallbacks[index % fallbacks.length];
}

String _serviceStatusLabel(
  BuildContext context,
  ColaboradorServicoStatusResumo status,
  LocaleSettingsProvider regionalizacao,
) {
  final String language = regionalizacao.currentLocale.languageCode;
  final String fallback = switch (language) {
    'en' => status.nameEnUs,
    'es' => status.nameEsEs,
    _ => status.namePtBr,
  };
  final String safeFallback = fallback.trim().isNotEmpty
      ? fallback.trim()
      : status.statusCode.trim().isNotEmpty
      ? status.statusCode.trim()
      : context.t(
          'collaboratorHome.services.unknownStatus',
          fallback: 'Sem status',
        );
  return status.i18nKey.trim().isEmpty
      ? safeFallback
      : context.t(status.i18nKey.trim(), fallback: safeFallback);
}
