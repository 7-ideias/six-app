import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/dashboard_inicio_model.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/dashboard_inicio_provider.dart';
import 'web_dashboard_widgets.dart';

/// Ponto de entrada da dashboard inicial Web.
///
/// Cria o [DashboardInicioProvider] em escopo local — não requer registro
/// global em main.dart. Aceita callbacks de navegação do pai, mantendo
/// o desacoplamento entre a dashboard e o shell da aplicação.
class DashboardInicioWeb extends StatelessWidget {
  const DashboardInicioWeb({
    super.key,
    required this.compact,
    required this.onIniciarVenda,
    required this.onAbrirAtendimentoTecnico,
  });

  final bool compact;
  final VoidCallback onIniciarVenda;
  final VoidCallback onAbrirAtendimentoTecnico;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardInicioProvider>(
      create: (_) => DashboardInicioProvider(),
      child: _DashboardView(
        compact: compact,
        onIniciarVenda: onIniciarVenda,
        onAbrirAtendimentoTecnico: onAbrirAtendimentoTecnico,
      ),
    );
  }
}

// ─── View principal ──────────────────────────────────────────────────────────

class _DashboardView extends StatefulWidget {
  const _DashboardView({
    required this.compact,
    required this.onIniciarVenda,
    required this.onAbrirAtendimentoTecnico,
  });

  final bool compact;
  final VoidCallback onIniciarVenda;
  final VoidCallback onAbrirAtendimentoTecnico;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _tabIndex = 0; // 0 = Gestão, 1 = Equipe

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 1,
  );
  final NumberFormat _decimal = NumberFormat.decimalPattern('pt_BR');
  final DateFormat _dateShort = DateFormat('dd/MM', 'pt_BR');
  final DateFormat _timeShort = DateFormat('HH:mm', 'pt_BR');

  String _money(double v) => _currency.format(v);
  String _moneyCompact(double v) => _compact.format(v);
  String _num(double v) => _decimal.format(v.round());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool compact = widget.compact;
    final DashboardInicioProvider provider =
        context.watch<DashboardInicioProvider>();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _buildHeader(context, theme, provider, compact),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: SizedBox.expand(
                key: ValueKey<int>(_tabIndex),
                child:
                    provider.isLoading
                        ? _buildLoading(theme)
                        : _tabIndex == 0
                        ? _GestaoView(
                          data: provider.data,
                          compact: compact,
                          money: _money,
                          moneyCompact: _moneyCompact,
                          num: _num,
                          dateShort: _dateShort,
                          onAbrirAtendimentoTecnico:
                              widget.onAbrirAtendimentoTecnico,
                        )
                        : _EquipeView(
                          data: provider.data,
                          compact: compact,
                          money: _money,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cabeçalho ────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DashboardInicioProvider provider,
    bool compact,
  ) {
    final DateTime updated = provider.data.lastUpdated;
    final String updatedText =
        '${context.t('dashboardInicio.updatedAt', fallback: 'Atualizado às')} ${_timeShort.format(updated)}';

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 14 : 18,
        compact ? 12 : 20,
        compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.055),
      ),
      child:
          compact
              ? _buildHeaderCompact(context, theme, provider, updatedText)
              : _buildHeaderWide(context, theme, provider, updatedText),
    );
  }

  Widget _buildHeaderWide(
    BuildContext context,
    ThemeData theme,
    DashboardInicioProvider provider,
    String updatedText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _headerIcon(theme),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.t('paginaPrincipalWeb.homeTitle', fallback: 'Início'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                updatedText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _buildPeriodFilter(context, theme, provider, compact: false),
            _buildTabSwitcher(context, theme, compact: false),
            _buildRefreshButton(theme, provider),
            FilledButton.icon(
              onPressed: widget.onIniciarVenda,
              icon: const Icon(Icons.point_of_sale_rounded, size: 18),
              label: Text(
                context.t(
                  'paginaPrincipalWeb.openPdvAction',
                  fallback: 'Frente de caixa',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onAbrirAtendimentoTecnico,
              icon: const Icon(Icons.handyman_outlined, size: 18),
              label: Text(
                context.t(
                  'paginaPrincipalWeb.openServiceAction',
                  fallback: 'Atendimento técnico',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCompact(
    BuildContext context,
    ThemeData theme,
    DashboardInicioProvider provider,
    String updatedText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _headerIcon(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.t(
                      'paginaPrincipalWeb.homeTitle',
                      fallback: 'Início',
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    updatedText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildRefreshButton(theme, provider),
          ],
        ),
        const SizedBox(height: 12),
        _buildPeriodFilter(context, theme, provider, compact: true),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(child: _buildTabSwitcher(context, theme, compact: true)),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onIniciarVenda,
                icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                label: Text(
                  context.t(
                    'paginaPrincipalWeb.openPdvAction',
                    fallback: 'Frente de caixa',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerIcon(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.dashboard_customize_outlined,
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildRefreshButton(
    ThemeData theme,
    DashboardInicioProvider provider,
  ) {
    return Tooltip(
      message: context.t('dashboardInicio.refresh', fallback: 'Atualizar'),
      child: IconButton(
        onPressed: provider.isLoading ? null : provider.reload,
        icon:
            provider.isLoading
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
                : const Icon(Icons.refresh_rounded),
      ),
    );
  }

  // ── Filtro de período ────────────────────────────────────────────────────

  Widget _buildPeriodFilter(
    BuildContext context,
    ThemeData theme,
    DashboardInicioProvider provider, {
    required bool compact,
  }) {
    final List<(DashboardPeriod, String)> options = <(DashboardPeriod, String)>[
      (
        DashboardPeriod.today,
        context.t('dashboardInicio.periodToday', fallback: 'Hoje'),
      ),
      (
        DashboardPeriod.last7Days,
        context.t('dashboardInicio.period7d', fallback: '7 dias'),
      ),
      (
        DashboardPeriod.last30Days,
        context.t('dashboardInicio.period30d', fallback: '30 dias'),
      ),
      (
        DashboardPeriod.currentMonth,
        context.t('dashboardInicio.periodMonth', fallback: 'Mês atual'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children:
            options.map((option) {
              final bool selected = provider.period == option.$1;
              return _PeriodChip(
                label: option.$2,
                selected: selected,
                expand: compact,
                onTap:
                    () => context.read<DashboardInicioProvider>().setPeriod(
                      option.$1,
                    ),
              );
            }).toList(),
      ),
    );
  }

  // ── Alternância Gestão / Equipe ──────────────────────────────────────────

  Widget _buildTabSwitcher(
    BuildContext context,
    ThemeData theme, {
    required bool compact,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          _TabChip(
            icon: Icons.insights_rounded,
            label: context.t(
              'paginaPrincipalWeb.managementTab',
              fallback: 'Gestão',
            ),
            selected: _tabIndex == 0,
            expand: compact,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          _TabChip(
            icon: Icons.groups_2_outlined,
            label: context.t('paginaPrincipalWeb.teamTab', fallback: 'Equipe'),
            selected: _tabIndex == 1,
            expand: compact,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }

  // ── Estado de carregamento ───────────────────────────────────────────────

  Widget _buildLoading(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 110,
            ),
            itemBuilder: (context, i) => _skeletonCard(theme, i == 1),
          ),
          const SizedBox(height: 14),
          _skeletonBlock(theme, height: 280),
          const SizedBox(height: 14),
          _skeletonBlock(theme, height: 200),
        ],
      ),
    );
  }

  Widget _skeletonCard(ThemeData theme, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            highlight
                ? theme.colorScheme.primary.withValues(alpha: 0.88)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  highlight
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.16)
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        highlight
                            ? theme.colorScheme.onPrimary.withValues(
                              alpha: 0.22,
                            )
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 110,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        highlight
                            ? theme.colorScheme.onPrimary.withValues(
                              alpha: 0.28,
                            )
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBlock(ThemeData theme, {required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}

// ─── Visão de Gestão ─────────────────────────────────────────────────────────

class _GestaoView extends StatelessWidget {
  const _GestaoView({
    required this.data,
    required this.compact,
    required this.money,
    required this.moneyCompact,
    required this.num,
    required this.dateShort,
    required this.onAbrirAtendimentoTecnico,
  });

  final DashboardInicioModel data;
  final bool compact;
  final String Function(double) money;
  final String Function(double) moneyCompact;
  final String Function(double) num;
  final DateFormat dateShort;
  final VoidCallback onAbrirAtendimentoTecnico;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SixWebEntry(order: 0, child: _buildKpis(context)),
          const SizedBox(height: 16),
          SixWebEntry(
            order: 1,
            child: sixWebResponsiveGroup(
              compact: compact,
              children: <Widget>[_buildChart(context), _buildAlerts(context)],
            ),
          ),
          const SizedBox(height: 16),
          SixWebEntry(
            order: 2,
            child: sixWebResponsiveGroup(
              compact: compact,
              children: <Widget>[
                _buildUpcoming(context),
                _buildOperations(context),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── KPIs ─────────────────────────────────────────────────────────────────

  Widget _buildKpis(BuildContext context) {
    final kpis = <(String, DashboardKpi)>[
      (
        context.t('dashboardInicio.salesTotal', fallback: 'Vendas realizadas'),
        data.vendasRealizadas,
      ),
      (
        context.t('dashboardInicio.receivedTotal', fallback: 'Valor recebido'),
        data.valorRecebido,
      ),
      (
        context.t('dashboardInicio.toReceive', fallback: 'A receber'),
        data.valorAReceber,
      ),
      (
        context.t('dashboardInicio.periodResult', fallback: 'Resultado'),
        data.resultado,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool grid2cols = compact || constraints.maxWidth < 900;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid2cols ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 118,
          ),
          itemBuilder:
              (context, i) =>
                  _KpiCard(label: kpis[i].$1, kpi: kpis[i].$2, money: money),
        );
      },
    );
  }

  // ── Gráfico de evolução ──────────────────────────────────────────────────

  Widget _buildChart(BuildContext context) {
    return SixWebSectionCard(
      icon: Icons.show_chart_rounded,
      title: context.t(
        'dashboardInicio.chartTitle',
        fallback: 'Evolução do período',
      ),
      subtitle: context.t(
        'dashboardInicio.chartSubtitle',
        fallback: 'Vendas realizadas vs. valor recebido',
      ),
      child: _LineChartWidget(points: data.chartData, money: moneyCompact),
    );
  }

  // ── Alertas ──────────────────────────────────────────────────────────────

  Widget _buildAlerts(BuildContext context) {
    return SixWebSectionCard(
      icon: Icons.notifications_active_outlined,
      title: context.t(
        'dashboardInicio.alertsTitle',
        fallback: 'Atenção necessária',
      ),
      child:
          data.alerts.isEmpty
              ? SixWebNoData(
                text: context.t(
                  'dashboardInicio.noAlerts',
                  fallback: 'Nenhum alerta para o período selecionado.',
                ),
                height: 120,
              )
              : Column(
                children:
                    data.alerts
                        .map(
                          (a) => _AlertRow(
                            alert: a,
                            money: money,
                            onNavigate:
                                a.routeHint == 'atendimentos_tecnicos'
                                    ? onAbrirAtendimentoTecnico
                                    : null,
                          ),
                        )
                        .toList(),
              ),
    );
  }

  // ── Próximos 7 dias ──────────────────────────────────────────────────────

  Widget _buildUpcoming(BuildContext context) {
    return SixWebSectionCard(
      icon: Icons.upcoming_outlined,
      title: context.t(
        'dashboardInicio.upcomingTitle',
        fallback: 'Próximos 7 dias',
      ),
      subtitle: context.t(
        'dashboardInicio.upcomingSubtitle',
        fallback: 'Compromissos registrados para os próximos dias.',
      ),
      child:
          data.upcoming.isEmpty
              ? SixWebNoData(
                text: context.t(
                  'dashboardInicio.noUpcoming',
                  fallback: 'Nenhum compromisso previsto.',
                ),
                height: 100,
              )
              : Column(
                children:
                    data.upcoming
                        .map(
                          (u) => _UpcomingRow(
                            item: u,
                            money: money,
                            date: dateShort,
                          ),
                        )
                        .toList(),
              ),
    );
  }

  // ── Operação atual ───────────────────────────────────────────────────────

  Widget _buildOperations(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ops = data.operations;
    final items = <(IconData, String, int)>[
      (
        Icons.build_circle_outlined,
        context.t(
          'dashboardInicio.opsServices',
          fallback: 'Atendimentos em andamento',
        ),
        ops.atendimentosEmAndamento,
      ),
      (
        Icons.request_quote_outlined,
        context.t(
          'dashboardInicio.opsQuotes',
          fallback: 'Orçamentos aguardando',
        ),
        ops.orcamentosAguardando,
      ),
      (
        Icons.inventory_2_outlined,
        context.t(
          'dashboardInicio.opsEquipments',
          fallback: 'Equipamentos p/ retirada',
        ),
        ops.equipamentosParaRetirada,
      ),
      (
        Icons.point_of_sale_outlined,
        context.t('dashboardInicio.opsCaixas', fallback: 'Caixas abertos'),
        ops.caixasAbertos,
      ),
    ];

    return SixWebSectionCard(
      icon: Icons.tune_outlined,
      title: context.t('dashboardInicio.opsTitle', fallback: 'Operação atual'),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children:
            items.map((item) {
              return _OperationChip(
                icon: item.$1,
                label: item.$2,
                count: item.$3,
                theme: theme,
              );
            }).toList(),
      ),
    );
  }
}

// ─── Visão de Equipe ──────────────────────────────────────────────────────────

class _EquipeView extends StatelessWidget {
  const _EquipeView({
    required this.data,
    required this.compact,
    required this.money,
  });

  final DashboardInicioModel data;
  final bool compact;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SixWebEntry(
            order: 0,
            child: SixWebSectionCard(
              icon: Icons.groups_2_outlined,
              title: context.t(
                'dashboardInicio.teamTitle',
                fallback: 'Visão de equipe',
              ),
              subtitle: context.t(
                'dashboardInicio.teamSubtitle',
                fallback:
                    'Carga operacional e pendências por colaborador no período selecionado.',
              ),
              child:
                  data.team.isEmpty
                      ? SixWebNoData(
                        text: context.t(
                          'dashboardInicio.noTeam',
                          fallback: 'Nenhum colaborador no período.',
                        ),
                      )
                      : Column(
                        children:
                            data.team
                                .asMap()
                                .entries
                                .map(
                                  (e) => SixWebEntry(
                                    order: e.key + 1,
                                    child: _TeamMemberRow(
                                      member: e.value,
                                      money: money,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
            ),
          ),
          const SizedBox(height: 12),
          SixWebEntry(order: 5, child: _buildTeamNote(context)),
        ],
      ),
    );
  }

  Widget _buildTeamNote(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'dashboardInicio.teamNote',
                fallback:
                    'Esta visão tem como objetivo identificar carga operacional e possíveis gargalos — não é um ranking.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Componentes internos ─────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.kpi, required this.money});

  final String label;
  final DashboardKpi kpi;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hi = kpi.highlight;
    final Color bg = hi ? theme.colorScheme.primary : theme.colorScheme.surface;
    final Color fg =
        hi ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final Color mu =
        hi
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.80)
            : theme.colorScheme.onSurfaceVariant;
    final Color iconBg =
        hi
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.14)
            : theme.colorScheme.primary.withValues(alpha: 0.10);
    final Color iconFg =
        hi ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    final double? delta = kpi.deltaPercent;
    final bool? positive = kpi.isPositive;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              hi ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(kpi.icon, color: iconFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mu,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>('kpi:$label:${kpi.value}'),
                  tween: Tween<double>(begin: 0, end: kpi.value),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, value, _) => Text(
                        money(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                ),
                if (delta != null) ...<Widget>[
                  const SizedBox(height: 3),
                  _DeltaBadge(
                    delta: delta,
                    positive: positive!,
                    highlight: hi,
                    theme: theme,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({
    required this.delta,
    required this.positive,
    required this.highlight,
    required this.theme,
  });

  final double delta;
  final bool positive;
  final bool highlight;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final String sign = positive ? '+' : '';
    final Color color =
        highlight
            ? (positive
                ? theme.colorScheme.onPrimary.withValues(alpha: 0.90)
                : theme.colorScheme.onPrimary.withValues(alpha: 0.75))
            : (positive ? Colors.green.shade600 : theme.colorScheme.error);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '$sign${delta.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'vs. anterior',
          style: TextStyle(
            color:
                highlight
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.55)
                    : theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.80,
                    ),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Gráfico de linhas ─────────────────────────────────────────────────────────

class _LineChartWidget extends StatefulWidget {
  const _LineChartWidget({required this.points, required this.money});

  final List<DashboardChartPoint> points;
  final String Function(double) money;

  @override
  State<_LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<_LineChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SixWebNoData();
    }

    final ThemeData theme = Theme.of(context);
    final Color colorVendas = theme.colorScheme.primary;
    final Color colorReceb = Colors.green.shade600;
    final double maxY =
        widget.points.fold<double>(
          0,
          (m, p) => math.max(m, math.max(p.vendas, p.recebimentos)),
        ) *
        1.15;

    return Column(
      children: <Widget>[
        TweenAnimationBuilder<double>(
          key: ValueKey<int>(widget.points.length),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) {
            return SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 100 : maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY <= 0 ? 20 : maxY / 4,
                    getDrawingHorizontalLine:
                        (_) => FlLine(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
                          strokeWidth: 1,
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _buildTitles(theme),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) {
                        setState(() => _touchedIndex = -1);
                        return;
                      }
                      final idx = response?.lineBarSpots?.first.spotIndex ?? -1;
                      setState(() => _touchedIndex = idx);
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface,
                      tooltipBorder: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      getTooltipItems:
                          (spots) =>
                              spots.map((spot) {
                                final label =
                                    spot.barIndex == 0 ? 'Vendas' : 'Recebido';
                                final color =
                                    spot.barIndex == 0
                                        ? colorVendas
                                        : colorReceb;
                                return LineTooltipItem(
                                  '$label\n${widget.money(spot.y)}',
                                  TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                    ),
                  ),
                  lineBarsData: <LineChartBarData>[
                    _buildLine(
                      color: colorVendas,
                      spots: List<FlSpot>.generate(
                        widget.points.length,
                        (i) => FlSpot(
                          i.toDouble(),
                          widget.points[i].vendas * progress,
                        ),
                      ),
                    ),
                    _buildLine(
                      color: colorReceb,
                      spots: List<FlSpot>.generate(
                        widget.points.length,
                        (i) => FlSpot(
                          i.toDouble(),
                          widget.points[i].recebimentos * progress,
                        ),
                      ),
                      dashed: true,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildLegend(context, colorVendas, colorReceb),
      ],
    );
  }

  LineChartBarData _buildLine({
    required Color color,
    required List<FlSpot> spots,
    bool dashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: dashed ? 2 : 2.5,
      dashArray: dashed ? <int>[6, 4] : null,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter:
            (spot, percent, bar, index) => FlDotCirclePainter(
              radius: _touchedIndex == index ? 5 : 3,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
      ),
      belowBarData: BarAreaData(
        show: !dashed,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.01),
          ],
        ),
      ),
    );
  }

  FlTitlesData _buildTitles(ThemeData theme) {
    final pts = widget.points;
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 52,
          getTitlesWidget:
              (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= pts.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                pts[i].label,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    Color colorVendas,
    Color colorReceb,
  ) {
    return Wrap(
      spacing: 18,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _LegendItem(
          color: colorVendas,
          label: context.t(
            'dashboardInicio.legendSales',
            fallback: 'Vendas realizadas',
          ),
        ),
        _LegendItem(
          color: colorReceb,
          label: context.t(
            'dashboardInicio.legendReceived',
            fallback: 'Valor recebido',
          ),
          dashed: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        dashed
            ? Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(width: 6, height: 2, color: color),
                const SizedBox(width: 2),
                Container(width: 4, height: 2, color: color),
              ],
            )
            : Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        const SizedBox(width: 7),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Alertas ───────────────────────────────────────────────────────────────────

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.money, this.onNavigate});

  final DashboardAlertItem alert;
  final String Function(double) money;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = _alertColor(theme, alert.severity);
    final IconData icon = _alertIcon(alert.severity);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alert.titulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.descricao,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (alert.valor != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    money(alert.valor!),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  alert.quantidade.toInt().toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (onNavigate != null) ...<Widget>[
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: 'Ver detalhes',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onNavigate,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Ver',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: color,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _alertColor(ThemeData theme, DashboardAlertSeverity severity) {
    switch (severity) {
      case DashboardAlertSeverity.critical:
        return theme.colorScheme.error;
      case DashboardAlertSeverity.warning:
        return Colors.orange.shade700;
      case DashboardAlertSeverity.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _alertIcon(DashboardAlertSeverity severity) {
    switch (severity) {
      case DashboardAlertSeverity.critical:
        return Icons.priority_high_rounded;
      case DashboardAlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case DashboardAlertSeverity.info:
        return Icons.info_outline_rounded;
    }
  }
}

// ── Próximos compromissos ─────────────────────────────────────────────────────

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.money,
    required this.date,
  });

  final DashboardUpcomingItem item;
  final String Function(double) money;
  final DateFormat date;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color color, IconData icon) = _style(theme, item.tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date.format(item.dataPrevista),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (item.valor > 0) ...<Widget>[
            const SizedBox(width: 8),
            Text(
              money(item.valor),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData) _style(ThemeData theme, String tipo) {
    switch (tipo) {
      case 'receber':
        return (Colors.green.shade600, Icons.arrow_circle_down_outlined);
      case 'pagar':
        return (theme.colorScheme.error, Icons.arrow_circle_up_outlined);
      case 'entrega':
        return (theme.colorScheme.primary, Icons.handyman_outlined);
      default:
        return (theme.colorScheme.onSurfaceVariant, Icons.event_outlined);
    }
  }
}

// ── Chip de operação ──────────────────────────────────────────────────────────

class _OperationChip extends StatelessWidget {
  const _OperationChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 17, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:
                  count > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color:
                    count > 0
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Membro da equipe ──────────────────────────────────────────────────────────

class _TeamMemberRow extends StatelessWidget {
  const _TeamMemberRow({required this.member, required this.money});

  final DashboardTeamMember member;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color cargaColor, String cargaLabel) = _carga(theme, member.carga);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.iniciais,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                _cargaChip(cargaColor, cargaLabel),
              ],
            ),
          ),
          _stat(
            context,
            theme,
            icon: Icons.build_circle_outlined,
            value: '${member.atendimentosEmAndamento}',
            label: 'em andamento',
          ),
          _stat(
            context,
            theme,
            icon: Icons.pending_actions_rounded,
            value: '${member.pendencias}',
            label: 'pendências',
            highlight: member.pendencias > 3,
          ),
          _stat(
            context,
            theme,
            icon: Icons.attach_money_rounded,
            value: money(member.vendasPeriodo),
            label: 'vendas',
          ),
        ],
      ),
    );
  }

  Widget _cargaChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    bool highlight = false,
  }) {
    final Color fg =
        highlight ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _carga(ThemeData theme, String carga) {
    switch (carga) {
      case 'critica':
        return (theme.colorScheme.error, 'Crítica');
      case 'alta':
        return (Colors.orange.shade700, 'Alta');
      case 'normal':
        return (theme.colorScheme.primary, 'Normal');
      case 'baixa':
        return (Colors.green.shade600, 'Baixa');
      default:
        return (theme.colorScheme.onSurfaceVariant, carga);
    }
  }
}

// ─── Chips utilitários ────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.expand,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg =
        selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant;

    Widget chip = Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? Expanded(child: chip) : chip;
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expand,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg =
        selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant;

    Widget chip = Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return expand ? Expanded(child: chip) : chip;
  }
}
