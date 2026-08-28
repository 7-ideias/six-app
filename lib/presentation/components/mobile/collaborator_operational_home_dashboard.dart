import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/catalogo_reserva_model.dart';
import '../../../data/models/consulta_vendas_models.dart';
import '../../../data/models/venda_nao_liquidada_models.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/colaborador_home_operacional_provider.dart';
import '../../../providers/locale_settings_provider.dart';

class CollaboratorOperationalHomeMobileDashboard extends StatelessWidget {
  const CollaboratorOperationalHomeMobileDashboard({
    super.key,
    required this.provider,
    required this.showSales,
    required this.showServices,
    required this.showReservations,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final bool showSales;
  final bool showServices;
  final bool showReservations;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (!showSales && !showServices && !showReservations) {
      return const SizedBox.shrink();
    }

    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final LocaleSettingsProvider regionalizacao = context
        .watch<LocaleSettingsProvider>();
    final Widget content = !provider.hasLoaded
        ? const _OperationalMobileLoading(
            key: ValueKey<String>('operational-mobile-loading'),
          )
        : provider.globalErrorCode != null
        ? _OperationalMobileError(
            key: const ValueKey<String>('operational-mobile-error'),
            onRetry: onRetry,
          )
        : _OperationalMobileContent(
            key: const ValueKey<String>('operational-mobile-content'),
            provider: provider,
            regionalizacao: regionalizacao,
            showSales: showSales,
            showServices: showServices,
            showReservations: showReservations,
            onRetry: onRetry,
          );

    return Semantics(
      container: true,
      liveRegion: !provider.hasLoaded,
      label: context.t(
        !provider.hasLoaded
            ? 'collaboratorHome.loading'
            : 'collaboratorHome.title',
        fallback: !provider.hasLoaded
            ? 'Carregando seu painel operacional'
            : 'Meu painel',
      ),
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 240),
        child: content,
      ),
    );
  }
}

class _OperationalMobileContent extends StatelessWidget {
  const _OperationalMobileContent({
    super.key,
    required this.provider,
    required this.regionalizacao,
    required this.showSales,
    required this.showServices,
    required this.showReservations,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final bool showSales;
  final bool showServices;
  final bool showReservations;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _AttentionMobileCard(
          provider: provider,
          regionalizacao: regionalizacao,
          showSales: showSales,
          showServices: showServices,
          showReservations: showReservations,
        ),
        if (showSales) ...<Widget>[
          const SizedBox(height: 12),
          _SalesMobileCard(
            provider: provider,
            regionalizacao: regionalizacao,
            onRetry: onRetry,
          ),
        ],
        if (showServices) ...<Widget>[
          const SizedBox(height: 12),
          _ServicesMobileCard(
            provider: provider,
            regionalizacao: regionalizacao,
            onRetry: onRetry,
          ),
        ],
        if (showReservations) ...<Widget>[
          const SizedBox(height: 12),
          _ReservationsMobileCard(
            provider: provider,
            regionalizacao: regionalizacao,
            onRetry: onRetry,
          ),
        ],
      ],
    );
  }
}

class _AttentionMobileCard extends StatelessWidget {
  const _AttentionMobileCard({
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final int urgentCount =
        (showSales ? provider.vendasVencidas : 0) +
        (showServices ? provider.servicosAtrasados : 0) +
        (showReservations ? provider.reservasAguardandoAcao : 0);
    final int overdueCount =
        (showSales ? provider.vendasVencidas : 0) +
        (showServices ? provider.servicosAtrasados : 0);
    final bool allClear = urgentCount == 0;
    final Color accent = overdueCount > 0 ? colors.error : colors.accent;

    return _MobileDashboardCard(
      emphasized: true,
      borderColor: accent.withValues(alpha: .38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MobileSectionHeader(
            icon: allClear
                ? Icons.verified_outlined
                : Icons.notification_important_outlined,
            iconColor: accent,
            title: context.t(
              'collaboratorHome.attention.title',
              fallback: 'Prioridades do trabalho',
            ),
            subtitle: allClear
                ? context.t(
                    'collaboratorHome.attention.clear',
                    fallback: 'Tudo em dia nas suas frentes de trabalho.',
                  )
                : context
                      .t(
                        'collaboratorHome.attention.pending',
                        fallback: '{count} pontos precisam de atenção.',
                      )
                      .replaceAll(
                        '{count}',
                        regionalizacao.formatInteger(urgentCount),
                      ),
          ),
          const SizedBox(height: 14),
          if (showSales)
            _AttentionMobileRow(
              icon: Icons.schedule_outlined,
              label: context.t(
                'collaboratorHome.attention.overdueSales',
                fallback: 'Vendas vencidas',
              ),
              value: provider.vendasVencidas,
              regionalizacao: regionalizacao,
              alert: provider.vendasVencidas > 0,
              danger: true,
            ),
          if (showServices) ...<Widget>[
            if (showSales) const SizedBox(height: 8),
            _AttentionMobileRow(
              icon: Icons.build_circle_outlined,
              label: context.t(
                'collaboratorHome.attention.overdueServices',
                fallback: 'Entregas atrasadas',
              ),
              value: provider.servicosAtrasados,
              regionalizacao: regionalizacao,
              alert: provider.servicosAtrasados > 0,
              danger: true,
            ),
          ],
          if (showReservations) ...<Widget>[
            if (showSales || showServices) const SizedBox(height: 8),
            _AttentionMobileRow(
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
        ],
      ),
    );
  }
}

class _AttentionMobileRow extends StatelessWidget {
  const _AttentionMobileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.regionalizacao,
    required this.alert,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final LocaleSettingsProvider regionalizacao;
  final bool alert;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool critical = alert && danger;
    final Color accent = critical ? colors.error : colors.accent;
    return Semantics(
      label: label,
      value: regionalizacao.formatInteger(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: critical
              ? colors.error.withValues(alpha: .07)
              : alert
              ? colors.softAccentSurface
              : colors.softSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: critical
                ? colors.errorBorder.withValues(alpha: .72)
                : alert
                ? colors.accent.withValues(alpha: .34)
                : colors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.titleText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AnimatedMetricText(
              value: value.toDouble(),
              formatter: (double current) =>
                  regionalizacao.formatInteger(current),
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesMobileCard extends StatelessWidget {
  const _SalesMobileCard({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ResumoConsultaVendas? summary = provider.vendasMes?.resumo;
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

    return _MobileDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MobileSectionHeader(
            icon: Icons.point_of_sale_outlined,
            title: context.t(
              'collaboratorHome.sales.title',
              fallback: 'Minhas vendas',
            ),
            subtitle: period,
          ),
          const SizedBox(height: 14),
          if (summary == null)
            _MobileInlineError(
              message: context.t(
                'collaboratorHome.sales.loadError',
                fallback: 'Não foi possível carregar o resumo das suas vendas.',
              ),
              onRetry: onRetry,
            )
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double spacing = 8;
                final double width = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: <Widget>[
                    _MobileMetricTile(
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
                    _MobileMetricTile(
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
                    _MobileMetricTile(
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
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.pending_actions_outlined,
                      label: context.t(
                        'collaboratorHome.sales.openMonth',
                        fallback: 'Em aberto no mês',
                      ),
                      value: summary.valorTotalEmAberto,
                      formatter: (double value) =>
                          regionalizacao.formatCurrency(value),
                      alert: summary.valorTotalEmAberto > 0,
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 18),
          _OpenSalesMobileList(
            provider: provider,
            regionalizacao: regionalizacao,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _OpenSalesMobileList extends StatelessWidget {
  const _OpenSalesMobileList({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final List<VendaNaoLiquidadaModel> sales = provider.vendasEmAberto;
    final List<VendaNaoLiquidadaModel> visibleSales = sales
        .take(3)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.t(
                      'collaboratorHome.openSales.subtitle',
                      fallback: 'Somente vendas registradas por você.',
                    ),
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (sales.isNotEmpty) ...<Widget>[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.softAccentSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  regionalizacao.formatInteger(sales.length),
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 11),
        if (provider.vendasEmAbertoErrorCode != null && sales.isEmpty)
          _MobileInlineError(
            message: context.t(
              'collaboratorHome.openSales.loadError',
              fallback: 'Não foi possível carregar suas vendas em aberto.',
            ),
            onRetry: onRetry,
          )
        else if (sales.isEmpty)
          _MobileEmptyState(
            icon: Icons.task_alt_rounded,
            message: context.t(
              'collaboratorHome.openSales.empty',
              fallback: 'Você não possui vendas aguardando liquidação.',
            ),
          )
        else ...<Widget>[
          for (int index = 0; index < visibleSales.length; index++) ...<Widget>[
            _OpenSaleMobileRow(
              sale: visibleSales[index],
              regionalizacao: regionalizacao,
            ),
            if (index < visibleSales.length - 1) const SizedBox(height: 8),
          ],
          if (sales.length > 3) ...<Widget>[
            const SizedBox(height: 9),
            Text(
              context
                  .t(
                    'collaboratorHome.openSales.more',
                    fallback: 'Mais {count} vendas em aberto',
                  )
                  .replaceAll(
                    '{count}',
                    regionalizacao.formatInteger(sales.length - 3),
                  ),
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _OpenSaleMobileRow extends StatelessWidget {
  const _OpenSaleMobileRow({required this.sale, required this.regionalizacao});

  final VendaNaoLiquidadaModel sale;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
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
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: overdue ? colors.errorBorder : colors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: overdue
                    ? colors.error.withValues(alpha: .08)
                    : colors.softAccentSurface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                overdue ? Icons.event_busy_outlined : Icons.schedule_outlined,
                color: overdue ? colors.error : colors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    identifier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    regionalizacao.formatCurrency(sale.valorAberto),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 12,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: overdue ? colors.error : colors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesMobileCard extends StatelessWidget {
  const _ServicesMobileCard({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final List<ColaboradorServicoStatusResumo> statuses =
        provider.servicosPorStatus;
    return _MobileDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MobileSectionHeader(
            icon: Icons.engineering_outlined,
            title: context.t(
              'collaboratorHome.services.title',
              fallback: 'Meus serviços por status',
            ),
            subtitle: context.t(
              'collaboratorHome.services.subtitle',
              fallback:
                  'Distribuição dos atendimentos em que você é o técnico.',
            ),
          ),
          const SizedBox(height: 14),
          if (provider.servicosErrorCode != null && statuses.isEmpty)
            _MobileInlineError(
              message: context.t(
                'collaboratorHome.services.loadError',
                fallback: 'Não foi possível carregar seus serviços.',
              ),
              onRetry: onRetry,
            )
          else if (statuses.isEmpty)
            _MobileEmptyState(
              icon: Icons.handyman_outlined,
              message: context.t(
                'collaboratorHome.services.empty',
                fallback: 'Nenhum atendimento está atribuído a você.',
              ),
            )
          else ...<Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double spacing = 8;
                final double width = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: <Widget>[
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.assignment_outlined,
                      label: context.t(
                        'collaboratorHome.services.total',
                        fallback: 'Total atribuído',
                      ),
                      value: provider.servicos.length.toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                    ),
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.build_outlined,
                      label: context.t(
                        'collaboratorHome.services.inProgress',
                        fallback: 'Em andamento',
                      ),
                      value: provider.servicosEmAndamento.toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                    ),
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.today_outlined,
                      label: context.t(
                        'collaboratorHome.services.dueToday',
                        fallback: 'Entregas hoje',
                      ),
                      value: provider.servicosComEntregaHoje.toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                      alert: provider.servicosComEntregaHoje > 0,
                    ),
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.event_busy_outlined,
                      label: context.t(
                        'collaboratorHome.services.overdue',
                        fallback: 'Atrasados',
                      ),
                      value: provider.servicosAtrasados.toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                      danger: provider.servicosAtrasados > 0,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _ServiceStatusMobileChart(
              statuses: statuses,
              regionalizacao: regionalizacao,
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceStatusMobileChart extends StatelessWidget {
  const _ServiceStatusMobileChart({
    required this.statuses,
    required this.regionalizacao,
  });

  final List<ColaboradorServicoStatusResumo> statuses;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final List<ColaboradorServicoStatusResumo> visible = statuses
        .take(5)
        .toList(growable: false);
    final int maxCount = visible.fold<int>(1, (
      int current,
      ColaboradorServicoStatusResumo status,
    ) {
      return status.count > current ? status.count : current;
    });

    return Column(
      children: <Widget>[
        for (int index = 0; index < visible.length; index++) ...<Widget>[
          _MobileProgressRow(
            label: _serviceStatusLabel(context, visible[index], regionalizacao),
            count: visible[index].count,
            maxCount: maxCount,
            color: _statusColor(context, visible[index].colorHex, index),
            regionalizacao: regionalizacao,
            animationOrder: index,
          ),
          if (index < visible.length - 1) const SizedBox(height: 11),
        ],
        if (statuses.length > visible.length) ...<Widget>[
          const SizedBox(height: 11),
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
                    regionalizacao.formatInteger(
                      statuses.length - visible.length,
                    ),
                  ),
              style: TextStyle(
                color: context.sixMobileColors.mutedText,
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

class _ReservationsMobileCard extends StatelessWidget {
  const _ReservationsMobileCard({
    required this.provider,
    required this.regionalizacao,
    required this.onRetry,
  });

  final ColaboradorHomeOperacionalProvider provider;
  final LocaleSettingsProvider regionalizacao;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final List<_ReservationMobileEntry> entries = <_ReservationMobileEntry>[
      _ReservationMobileEntry(
        status: CatalogoReservaStatus.recebida,
        label: context.t(
          'collaboratorHome.reservations.received',
          fallback: 'Recebidas',
        ),
        color: colors.accent,
      ),
      _ReservationMobileEntry(
        status: CatalogoReservaStatus.emAnalise,
        label: context.t(
          'collaboratorHome.reservations.analysis',
          fallback: 'Em análise',
        ),
        color: Theme.of(context).colorScheme.tertiary,
      ),
      _ReservationMobileEntry(
        status: CatalogoReservaStatus.confirmada,
        label: context.t(
          'collaboratorHome.reservations.confirmed',
          fallback: 'Confirmadas',
        ),
        color: colors.secondary,
      ),
      _ReservationMobileEntry(
        status: CatalogoReservaStatus.convertida,
        label: context.t(
          'collaboratorHome.reservations.converted',
          fallback: 'Convertidas',
        ),
        color: colors.accent,
      ),
    ];
    final int maxCount = entries.fold<int>(1, (
      int current,
      _ReservationMobileEntry entry,
    ) {
      final int count = provider.reservaCount(entry.status);
      return count > current ? count : current;
    });
    final int total = provider.reservasPorStatus.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );

    return _MobileDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MobileSectionHeader(
            icon: Icons.bookmarks_outlined,
            title: context.t(
              'collaboratorHome.reservations.title',
              fallback: 'Fila de reservas',
            ),
            subtitle: context.t(
              'collaboratorHome.reservations.subtitle',
              fallback: 'Pedidos do catálogo que podem virar venda.',
            ),
          ),
          const SizedBox(height: 14),
          if (provider.reservasErrorCode != null && total == 0)
            _MobileInlineError(
              message: context.t(
                'collaboratorHome.reservations.loadError',
                fallback: 'Não foi possível carregar as reservas.',
              ),
              onRetry: onRetry,
            )
          else ...<Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double spacing = 8;
                final double width = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  children: <Widget>[
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.pending_actions_outlined,
                      label: context.t(
                        'collaboratorHome.reservations.pending',
                        fallback: 'Pendentes',
                      ),
                      value: provider.reservasPendentes.toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                      alert: provider.reservasPendentes > 0,
                    ),
                    _MobileMetricTile(
                      width: width,
                      icon: Icons.shopping_cart_checkout_outlined,
                      label: context.t(
                        'collaboratorHome.reservations.converted',
                        fallback: 'Convertidas',
                      ),
                      value: provider
                          .reservaCount(CatalogoReservaStatus.convertida)
                          .toDouble(),
                      formatter: (double value) =>
                          regionalizacao.formatInteger(value),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            for (int index = 0; index < entries.length; index++) ...<Widget>[
              _MobileProgressRow(
                label: entries[index].label,
                count: provider.reservaCount(entries[index].status),
                maxCount: maxCount,
                color: entries[index].color,
                regionalizacao: regionalizacao,
                animationOrder: index,
              ),
              if (index < entries.length - 1) const SizedBox(height: 11),
            ],
          ],
        ],
      ),
    );
  }
}

class _MobileDashboardCard extends StatelessWidget {
  const _MobileDashboardCard({
    required this.child,
    this.emphasized = false,
    this.borderColor,
  });

  final Widget child;
  final bool emphasized;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasized ? colors.surfaceElevated : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: emphasized ? 16 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MobileSectionHeader extends StatelessWidget {
  const _MobileSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.iconSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, color: iconColor ?? colors.accent, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.titleText,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileMetricTile extends StatelessWidget {
  const _MobileMetricTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.formatter,
    this.alert = false,
    this.danger = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final double value;
  final String Function(double value) formatter;
  final bool alert;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color accent = danger ? colors.error : colors.accent;
    return Semantics(
      label: label,
      value: formatter(value),
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: danger
              ? colors.error.withValues(alpha: .05)
              : alert
              ? colors.softAccentSurface
              : colors.softSurface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: danger
                ? colors.errorBorder
                : alert
                ? colors.accent.withValues(alpha: .34)
                : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: accent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _AnimatedMetricText(
              value: value,
              formatter: formatter,
              style: TextStyle(
                color: danger ? colors.error : colors.titleText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMetricText extends StatelessWidget {
  const _AnimatedMetricText({
    required this.value,
    required this.formatter,
    required this.style,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('mobile-metric-${value.toStringAsFixed(2)}'),
      tween: Tween<double>(begin: 0, end: value),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 580),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double current, Widget? child) {
        return Text(
          formatter(current),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

class _MobileProgressRow extends StatelessWidget {
  const _MobileProgressRow({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
    required this.regionalizacao,
    required this.animationOrder,
  });

  final String label;
  final int count;
  final int maxCount;
  final Color color;
  final LocaleSettingsProvider regionalizacao;
  final int animationOrder;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double progress = maxCount <= 0 ? 0 : count / maxCount;
    return Semantics(
      label: label,
      value: regionalizacao.formatInteger(count),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                regionalizacao.formatInteger(count),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              key: ValueKey<String>('mobile-progress-$label-$count'),
              tween: Tween<double>(begin: 0, end: progress),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : Duration(milliseconds: 480 + animationOrder * 55),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double current, Widget? child) {
                return LinearProgressIndicator(
                  minHeight: 7,
                  value: current,
                  backgroundColor: colors.border.withValues(alpha: .7),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileEmptyState extends StatelessWidget {
  const _MobileEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileInlineError extends StatelessWidget {
  const _MobileInlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.sync_problem_outlined, color: colors.error, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: context.t('common.tryAgain', fallback: 'Tentar novamente'),
            icon: Icon(Icons.refresh_rounded, color: colors.error, size: 18),
          ),
        ],
      ),
    );
  }
}

class _OperationalMobileError extends StatelessWidget {
  const _OperationalMobileError({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return _MobileDashboardCard(
      borderColor: colors.errorBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.cloud_off_outlined, color: colors.error, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t(
                    'collaboratorHome.error.user',
                    fallback:
                        'Não foi possível identificar seu painel pessoal.',
                  ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

class _OperationalMobileLoading extends StatelessWidget {
  const _OperationalMobileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      children: <Widget>[
        _MobileLoadingCard(colors: colors, height: 166),
        const SizedBox(height: 12),
        _MobileLoadingCard(colors: colors, height: 292),
        const SizedBox(height: 12),
        _MobileLoadingCard(colors: colors, height: 264),
      ],
    );
  }
}

class _MobileLoadingCard extends StatelessWidget {
  const _MobileLoadingCard({required this.colors, required this.height});

  final SixMobileColorScheme colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.iconSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_outlined,
                  color: colors.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _MobileSkeletonLine(color: colors.border, widthFactor: .54),
                    const SizedBox(height: 8),
                    _MobileSkeletonLine(color: colors.border, widthFactor: .82),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.softSurface,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSkeletonLine extends StatelessWidget {
  const _MobileSkeletonLine({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ReservationMobileEntry {
  const _ReservationMobileEntry({
    required this.status,
    required this.label,
    required this.color,
  });

  final CatalogoReservaStatus status;
  final String label;
  final Color color;
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
  final SixMobileColorScheme colors = context.sixMobileColors;
  final List<Color> fallbacks = <Color>[
    colors.accent,
    Theme.of(context).colorScheme.tertiary,
    colors.secondary,
    colors.error,
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
