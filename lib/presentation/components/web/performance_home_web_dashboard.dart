import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/colaborador_usuario_model.dart';
import '../../../data/models/desempenho_colaborador_model.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/desempenho_colaborador_home_provider.dart';
import '../../../providers/locale_settings_provider.dart';
import '../../theme/web_theme_tokens.dart';
import '../six_backend_loading.dart';
import '../web_dashboard_widgets.dart';

class PerformanceHomeWebDashboard extends StatelessWidget {
  const PerformanceHomeWebDashboard({
    super.key,
    required this.provider,
    required this.regionalizacao,
  });

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool hasData = provider.loadRevision > 0;
    final bool initialLoading = provider.loading && !hasData;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    Widget entry(Widget child, {int order = 0}) {
      return reduceMotion ? child : SixWebEntry(order: order, child: child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _DashboardHeader(provider: provider, regionalizacao: regionalizacao),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : WebThemeTokens.transitionDuration,
          switchInCurve: WebThemeTokens.transitionCurve,
          switchOutCurve: WebThemeTokens.transitionCurve,
          child:
              initialLoading
                  ? const _InitialLoading(
                    key: ValueKey<String>('performance-web-loading'),
                  )
                  : provider.hasError && !hasData
                  ? _LoadError(
                    key: const ValueKey<String>('performance-web-error'),
                    onRetry: provider.load,
                  )
                  : KeyedSubtree(
                    key: ValueKey<String>(
                      'performance-web-content-${provider.loadRevision}',
                    ),
                    child: Column(
                      children: <Widget>[
                        if (provider.hasError && hasData)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.danger.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tokens.danger.withValues(alpha: .25),
                              ),
                            ),
                            child: Text(
                              context.t(
                                'performance.dashboard.staleData',
                                fallback:
                                    'Os últimos dados continuam visíveis. Não foi possível atualizar agora.',
                              ),
                              style: TextStyle(
                                color: tokens.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        entry(
                          _KpiGrid(
                            provider: provider,
                            regionalizacao: regionalizacao,
                          ),
                        ),
                        const SizedBox(height: 16),
                        entry(
                          _PerformanceChart(
                            key: ValueKey<String>(
                              'performance-chart-${provider.loadRevision}',
                            ),
                            provider: provider,
                          ),
                          order: 1,
                        ),
                        const SizedBox(height: 16),
                        entry(
                          _GoalsSection(
                            provider: provider,
                            regionalizacao: regionalizacao,
                          ),
                          order: 2,
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.provider,
    required this.regionalizacao,
  });

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String period =
        provider.periodoInicio == null || provider.periodoFim == null
            ? ''
            : '${regionalizacao.formatDate(provider.periodoInicio!)} – '
                '${regionalizacao.formatDate(provider.periodoFim!)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.insights_rounded, color: tokens.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(
                        provider.isAdmin
                            ? 'performance.dashboard.teamTitle'
                            : 'performance.dashboard.myTitle',
                        fallback:
                            provider.isAdmin
                                ? 'Desempenho da equipe'
                                : 'Meu desempenho',
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t(
                        'performance.dashboard.subtitle',
                        fallback:
                            'Metas ativas, vendas, assistências e situação do caixa em um só lugar.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.loading && provider.hasLoaded) ...<Widget>[
                const SizedBox(width: 12),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.info,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (provider.isAdmin)
                OutlinedButton.icon(
                  key: const Key('performance-web-collaborator-filter'),
                  onPressed:
                      provider.loading
                          ? null
                          : () => _showCollaboratorDialog(context, provider),
                  icon: const Icon(Icons.group_outlined, size: 18),
                  label: Text(_collaboratorFilterLabel(context, provider)),
                ),
              _PeriodDropdown(provider: provider),
              if (period.isNotEmpty)
                _HeaderPill(icon: Icons.date_range_outlined, label: period),
              _HeaderPill(
                icon: Icons.bolt_rounded,
                label: context.t(
                  'performance.dashboard.live',
                  fallback: 'Atualização automática',
                ),
                positive: true,
              ),
              IconButton.outlined(
                onPressed: provider.loading ? null : provider.reload,
                tooltip: context.t('common.refresh', fallback: 'Atualizar'),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _collaboratorFilterLabel(
    BuildContext context,
    DesempenhoColaboradorHomeProvider provider,
  ) {
    final Set<String> selected = provider.idsColaboradoresSelecionados;
    if (selected.isEmpty) {
      return context.t(
        'performance.dashboard.allCollaborators',
        fallback: 'Todos os colaboradores',
      );
    }
    if (selected.length == 1) {
      return provider.nomeDoParticipante(selected.first);
    }
    return context
        .t(
          'performance.dashboard.selectedCollaborators',
          fallback: '{count} colaboradores',
        )
        .replaceAll('{count}', selected.length.toString());
  }

  Future<void> _showCollaboratorDialog(
    BuildContext context,
    DesempenhoColaboradorHomeProvider provider,
  ) async {
    final Set<String> staged = provider.idsColaboradoresSelecionados.toSet();
    String query = '';
    final Set<String>? result = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final WebThemeTokens tokens = WebThemeTokens.of(context);
            final String normalizedQuery = query.trim().toLowerCase();
            final List<ColaboradorUsuarioResumo> filtered = provider
                .participantes
                .where((ColaboradorUsuarioResumo participant) {
                  if (normalizedQuery.isEmpty) return true;
                  return provider
                          .nomeDoParticipante(participant.idUnicoPessoal)
                          .toLowerCase()
                          .contains(normalizedQuery) ||
                      participant.email.toLowerCase().contains(normalizedQuery);
                })
                .toList(growable: false);
            return AlertDialog(
              backgroundColor: tokens.surface,
              title: Text(
                context.t(
                  'performance.dashboard.filterTitle',
                  fallback: 'Filtrar colaboradores',
                ),
              ),
              content: SizedBox(
                width: 440,
                height:
                    (190.0 + provider.participantes.length * 56.0)
                        .clamp(340.0, 520.0)
                        .toDouble(),
                child: Column(
                  children: <Widget>[
                    TextField(
                      onChanged:
                          (String value) => setDialogState(() => query = value),
                      decoration: InputDecoration(
                        hintText: context.t(
                          'performance.dashboard.searchCollaborators',
                          fallback: 'Buscar colaborador',
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: tokens.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.cardBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: staged.isEmpty,
                      title: Text(
                        context.t(
                          'performance.dashboard.allCollaborators',
                          fallback: 'Todos os colaboradores',
                        ),
                      ),
                      secondary: const Icon(Icons.groups_rounded),
                      onChanged: (_) => setDialogState(() => staged.clear()),
                    ),
                    const Divider(),
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? Center(
                                child: Text(
                                  context.t(
                                    'performance.dashboard.noCollaboratorsFound',
                                    fallback: 'Nenhum colaborador encontrado.',
                                  ),
                                  style: TextStyle(color: tokens.mutedText),
                                ),
                              )
                              : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final ColaboradorUsuarioResumo participant =
                                      filtered[index];
                                  final String id = participant.idUnicoPessoal;
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: staged.contains(id),
                                    title: Text(
                                      provider.nomeDoParticipante(id),
                                    ),
                                    subtitle:
                                        participant.email.trim().isEmpty
                                            ? null
                                            : Text(participant.email),
                                    onChanged: (bool? checked) {
                                      setDialogState(() {
                                        if (checked == true) {
                                          staged.add(id);
                                        } else {
                                          staged.remove(id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.t('common.cancel', fallback: 'Cancelar')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(staged),
                  child: Text(context.t('common.apply', fallback: 'Aplicar')),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      await provider.setColaboradoresSelecionados(result);
    }
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.provider});

  final DesempenhoColaboradorHomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return PopupMenuButton<DesempenhoInicioPeriodo>(
      enabled: !provider.loading,
      tooltip: context.t(
        'performance.dashboard.periodFilter',
        fallback: 'Selecionar período',
      ),
      color: tokens.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.cardBorder),
      ),
      onSelected: provider.setPeriodo,
      itemBuilder:
          (BuildContext context) => DesempenhoInicioPeriodo.values
              .map(
                (DesempenhoInicioPeriodo period) => PopupMenuItem(
                  value: period,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        provider.periodoSelecionado == period
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color:
                            provider.periodoSelecionado == period
                                ? tokens.info
                                : tokens.mutedText,
                      ),
                      const SizedBox(width: 10),
                      Text(_periodLabel(context, period)),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
      child: Container(
        key: const Key('performance-web-period-filter'),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.calendar_month_outlined, size: 18, color: tokens.info),
            const SizedBox(width: 8),
            Text(
              _periodLabel(context, provider.periodoSelecionado),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: tokens.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    this.positive = false,
  });

  final IconData icon;
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = positive ? tokens.success : tokens.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.provider, required this.regionalizacao});

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final DesempenhoColaboradorResumoModel data = provider.resumo;
    final DesempenhoCaixaModel cash = data.caixa;
    final String cashValue =
        !cash.disponivel
            ? context.t(
              'performance.dashboard.cashUnavailable',
              fallback: 'Indisponível',
            )
            : cash.aberto == true
            ? context.t('performance.dashboard.cashOpen', fallback: 'Aberto')
            : context.t(
              'performance.dashboard.cashClosed',
              fallback: 'Fechado',
            );
    final List<String> cashDetails = <String>[
      if (cash.responsavel.trim().isNotEmpty) cash.responsavel.trim(),
      if (cash.abertoEm != null) regionalizacao.formatTime(cash.abertoEm!),
    ];
    final String cashCaption =
        cashDetails.isNotEmpty
            ? cashDetails.join(' • ')
            : context.t(
              provider.isAdmin
                  ? 'performance.dashboard.cashCaption'
                  : 'performance.dashboard.cashCaptionMine',
              fallback:
                  provider.isAdmin
                      ? 'Situação do comércio atual'
                      : 'Situação do meu caixa',
            );
    final List<_KpiData> items = <_KpiData>[
      _KpiData(
        id: 'score',
        icon: Icons.speed_rounded,
        label: context.t('performance.dashboard.score', fallback: 'Desempenho'),
        numericValue: data.scoreMedio,
        numericFormatter:
            (double value) =>
                regionalizacao.formatPercent(value, decimalPlaces: 1),
        caption: context
            .t(
              'performance.dashboard.activeGoals',
              fallback: '{count} metas ativas',
            )
            .replaceAll(
              '{count}',
              regionalizacao.formatInteger(data.totalMetas),
            ),
      ),
      _KpiData(
        id: 'sales',
        icon: Icons.point_of_sale_outlined,
        label: context.t('performance.dashboard.sales', fallback: 'Vendas'),
        numericValue: data.valorTotalVendido,
        numericFormatter:
            (double value) => regionalizacao.formatCurrency(value),
        caption: context
            .t('performance.dashboard.salesCount', fallback: '{count} vendas')
            .replaceAll(
              '{count}',
              regionalizacao.formatInteger(data.quantidadeVendas),
            ),
      ),
      _KpiData(
        id: 'assistance',
        icon: Icons.build_circle_outlined,
        label: context.t(
          'performance.dashboard.assistance',
          fallback: 'Assistências',
        ),
        numericValue: data.quantidadeAtendimentos.toDouble(),
        numericFormatter: (double value) => regionalizacao.formatInteger(value),
        caption: context
            .t(
              'performance.dashboard.assistanceCaption',
              fallback: '{count} finalizadas • {amount}',
            )
            .replaceAll(
              '{count}',
              regionalizacao.formatInteger(
                data.quantidadeAtendimentosFinalizados,
              ),
            )
            .replaceAll(
              '{amount}',
              regionalizacao.formatCurrency(data.valorTotalAssistencias),
            ),
      ),
      _KpiData(
        id: 'cash',
        icon:
            cash.aberto == true ? Icons.lock_open_rounded : Icons.lock_outline,
        label: context.t('performance.dashboard.cash', fallback: 'Caixa'),
        textValue: cashValue,
        caption: cashCaption,
        positive: cash.aberto == true,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns =
            constraints.maxWidth >= 1040
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 1;
        final double width =
            (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(width: width, child: _KpiCard(data: item)),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.id,
    required this.icon,
    required this.label,
    required this.caption,
    this.numericValue,
    this.numericFormatter,
    this.textValue,
    this.positive = false,
  }) : assert(
         (numericValue != null && numericFormatter != null) ||
             textValue != null,
       );

  final String id;
  final IconData icon;
  final String label;
  final String caption;
  final double? numericValue;
  final String Function(double value)? numericFormatter;
  final String? textValue;
  final bool positive;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = data.positive ? tokens.success : tokens.info;
    final TextStyle valueStyle =
        Theme.of(context).textTheme.titleLarge?.copyWith(
          color: tokens.primaryText,
          fontWeight: FontWeight.w900,
        ) ??
        TextStyle(color: tokens.primaryText, fontWeight: FontWeight.w900);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Widget valueWidget;
    if (data.numericValue != null && data.numericFormatter != null) {
      valueWidget = TweenAnimationBuilder<double>(
        key: ValueKey<String>(
          '${data.id}:${data.numericValue!.toStringAsFixed(4)}',
        ),
        tween: Tween<double>(begin: 0, end: data.numericValue!),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, Widget? child) {
          return Text(
            data.numericFormatter!(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          );
        },
      );
    } else {
      valueWidget = Text(
        data.textValue ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: valueStyle,
      );
    }
    return Container(
      height: 126,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.label,
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget,
                const SizedBox(height: 2),
                Text(
                  data.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatefulWidget {
  const _PerformanceChart({super.key, required this.provider});

  final DesempenhoColaboradorHomeProvider provider;

  @override
  State<_PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<_PerformanceChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<_ChartItem> items =
        _chartItems(context, widget.provider).take(10).toList();
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final String chartKey = items
        .map((item) => '${item.label}:${item.value.toStringAsFixed(3)}')
        .join('|');
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              widget.provider.isAdmin && widget.provider.comparativos.length > 1
                  ? 'performance.dashboard.teamComparison'
                  : 'performance.dashboard.goalProgress',
              fallback:
                  widget.provider.isAdmin &&
                          widget.provider.comparativos.length > 1
                      ? 'Comparativo da equipe'
                      : 'Progresso das metas',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'performance.dashboard.chartCaption',
              fallback:
                  'Percentual realizado em relação ao objetivo do período.',
            ),
            style: TextStyle(color: tokens.secondaryText),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  context.t(
                    'performance.dashboard.chartEmpty',
                    fallback: 'Não há metas com dados para o gráfico.',
                  ),
                  style: TextStyle(color: tokens.mutedText),
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: Semantics(
                label: context.t(
                  widget.provider.isAdmin &&
                          widget.provider.comparativos.length > 1
                      ? 'performance.dashboard.teamComparison'
                      : 'performance.dashboard.goalProgress',
                  fallback:
                      widget.provider.isAdmin &&
                              widget.provider.comparativos.length > 1
                          ? 'Comparativo da equipe'
                          : 'Progresso das metas',
                ),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<String>('performance-web-bars-$chartKey'),
                  tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 680),
                  curve: Curves.easeOutCubic,
                  builder: (
                    BuildContext context,
                    double reveal,
                    Widget? child,
                  ) {
                    return BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: math.max(
                          120.0,
                          items.fold<double>(
                                0,
                                (value, item) => math.max(value, item.value),
                              ) +
                              12,
                        ),
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine:
                              (_) =>
                                  FlLine(color: tokens.divider, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              getTitlesWidget:
                                  (double value, TitleMeta meta) => Text(
                                    '${value.round()}%',
                                    style: TextStyle(
                                      color: tokens.mutedText,
                                      fontSize: 10,
                                    ),
                                  ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final int index = value.round();
                                if (index < 0 || index >= items.length)
                                  return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: 74,
                                    child: Text(
                                      items[index].label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: tokens.secondaryText,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchCallback: (FlTouchEvent event, response) {
                            final int nextIndex =
                                event.isInterestedForInteractions &&
                                        response?.spot != null
                                    ? response!.spot!.touchedBarGroupIndex
                                    : -1;
                            if (nextIndex != _touchedIndex) {
                              setState(() => _touchedIndex = nextIndex);
                            }
                          },
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: tokens.surfaceElevated,
                            getTooltipItem:
                                (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) => BarTooltipItem(
                                  '${items[groupIndex].label}\n${items[groupIndex].value.toStringAsFixed(1)}%',
                                  TextStyle(
                                    color: tokens.primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          ),
                        ),
                        barGroups: items
                            .asMap()
                            .entries
                            .map((entry) {
                              final double value = entry.value.value;
                              final Color baseColor =
                                  value >= 100
                                      ? tokens.success
                                      : value >= 70
                                      ? tokens.info
                                      : value >= 40
                                      ? tokens.warning
                                      : tokens.danger;
                              final bool highlighted =
                                  _touchedIndex == entry.key;
                              final bool dimmed =
                                  _touchedIndex >= 0 && !highlighted;
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: value * reveal,
                                    color: baseColor.withValues(
                                      alpha: dimmed ? .34 : 1,
                                    ),
                                    width: highlighted ? 27 : 22,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 100,
                                      color: tokens.surfaceMuted,
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(growable: false),
                      ),
                      swapAnimationDuration: Duration.zero,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_ChartItem> _chartItems(
    BuildContext context,
    DesempenhoColaboradorHomeProvider provider,
  ) {
    if (provider.isAdmin && provider.comparativos.length > 1) {
      final List<_ChartItem> comparativos = provider.comparativos
          .map(
            (item) => _ChartItem(
              label:
                  item.nomeColaborador.trim().isEmpty
                      ? provider.nomeDoParticipante(item.idColaborador)
                      : item.nomeColaborador,
              value: item.scoreMedio,
            ),
          )
          .toList(growable: false);
      comparativos.sort(
        (_ChartItem a, _ChartItem b) => b.value.compareTo(a.value),
      );
      return comparativos;
    }
    return provider.metasAtivas
        .map(
          (item) => _ChartItem(
            label: _indicatorLabel(context, item.indicador),
            value: item.percentualAtingido,
          ),
        )
        .toList(growable: false);
  }
}

class _ChartItem {
  const _ChartItem({required this.label, required this.value});

  final String label;
  final double value;
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.provider, required this.regionalizacao});

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              'performance.dashboard.goalsTitle',
              fallback: 'Metas ativas',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (provider.metasAtivas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  context.t(
                    'performance.home.emptyTitle',
                    fallback: 'Nenhuma meta ativa neste período',
                  ),
                  style: TextStyle(color: tokens.mutedText),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 820 ? 2 : 1;
                final double width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: provider.metasAtivas
                      .map(
                        (item) => SizedBox(
                          width: width,
                          child: _GoalCard(
                            item: item,
                            regionalizacao: regionalizacao,
                            showCollaborator: provider.isAdmin,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.item,
    required this.regionalizacao,
    required this.showCollaborator,
  });

  final DesempenhoColaboradorItemModel item;
  final LocaleSettingsProvider regionalizacao;
  final bool showCollaborator;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final DesempenhoIndicadorOption indicator = indicadorPorCodigo(
      item.indicador,
    );
    final double progress =
        (item.percentualAtingido / 100).clamp(0.0, 1.0).toDouble();
    final Color color =
        item.percentualAtingido >= 100
            ? tokens.success
            : item.percentualAtingido >= 70
            ? tokens.info
            : item.percentualAtingido >= 40
            ? tokens.warning
            : tokens.danger;
    String format(double value) =>
        indicator.valorMonetario
            ? regionalizacao.formatCurrency(value)
            : regionalizacao.formatDecimal(value);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return Semantics(
      container: true,
      label: _indicatorLabel(context, item.indicador),
      value: regionalizacao.formatPercent(
        item.percentualAtingido,
        decimalPlaces: 1,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _indicatorLabel(context, item.indicador),
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>(
                    'goal-percent-${item.idMeta}-${item.percentualAtingido}',
                  ),
                  tween: Tween<double>(
                    begin: reduceMotion ? item.percentualAtingido : 0,
                    end: item.percentualAtingido,
                  ),
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 560),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, Widget? child) {
                    return Text(
                      regionalizacao.formatPercent(value, decimalPlaces: 1),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (showCollaborator &&
                item.nomeColaborador.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                item.nomeColaborador,
                style: TextStyle(color: tokens.secondaryText, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>(
                  'goal-progress-${item.idMeta}-${item.percentualAtingido}',
                ),
                tween: Tween<double>(
                  begin: reduceMotion ? progress : 0,
                  end: progress,
                ),
                duration:
                    reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 560),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: tokens.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${context.t('performance.home.result', fallback: 'Resultado')}: '
                    '${format(item.valorRealizado)}',
                    style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                  ),
                ),
                Text(
                  '${context.t('performance.home.target', fallback: 'Meta')}: '
                  '${format(item.valorAlvo)}',
                  style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialLoading extends StatelessWidget {
  const _InitialLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t(
        'performance.home.loading',
        fallback: 'Carregando suas metas',
      ),
      child: TickerMode(
        enabled: !reduceMotion,
        child: Column(
          children: <Widget>[
            SixBackendLoading(
              title: context.t(
                'performance.home.loading',
                fallback: 'Carregando suas metas',
              ),
              subtitle: context.t(
                'performance.dashboard.subtitle',
                fallback:
                    'Metas ativas, vendas, assistências e situação do caixa em um só lugar.',
              ),
              animation: SixBackendLoadingAnimation.skeletonPulse,
              leadingIcon: Icons.insights_rounded,
              backgroundColor: tokens.surface,
              borderColor: tokens.cardBorder,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns =
                    constraints.maxWidth >= 1040
                        ? 4
                        : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                final double width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List<Widget>.generate(
                    4,
                    (int index) => SizedBox(
                      width: width,
                      child: const SixWebLoadingBlock(height: 126),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.danger.withValues(alpha: .4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, color: tokens.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t(
                'performance.home.loadError',
                fallback: 'Não foi possível carregar o desempenho.',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

String _periodLabel(BuildContext context, DesempenhoInicioPeriodo period) {
  return switch (period) {
    DesempenhoInicioPeriodo.hoje => context.t(
      'performance.dashboard.periodToday',
      fallback: 'Hoje',
    ),
    DesempenhoInicioPeriodo.ultimos7Dias => context.t(
      'performance.dashboard.period7Days',
      fallback: 'Últimos 7 dias',
    ),
    DesempenhoInicioPeriodo.ultimos30Dias => context.t(
      'performance.dashboard.period30Days',
      fallback: 'Últimos 30 dias',
    ),
    DesempenhoInicioPeriodo.mesAtual => context.t(
      'performance.dashboard.periodMonth',
      fallback: 'Mês atual',
    ),
  };
}

String _indicatorLabel(BuildContext context, String code) {
  return switch (code) {
    'VENDA_VALOR' => context.t(
      'performance.indicator.salesValue',
      fallback: 'Valor vendido',
    ),
    'VENDA_QUANTIDADE' => context.t(
      'performance.indicator.salesQuantity',
      fallback: 'Quantidade de vendas',
    ),
    'SERVICO_VALOR' => context.t(
      'performance.indicator.servicesValue',
      fallback: 'Valor em serviços',
    ),
    'ATENDIMENTO_QUANTIDADE' => context.t(
      'performance.indicator.serviceCalls',
      fallback: 'Atendimentos técnicos',
    ),
    'ATENDIMENTO_FINALIZADO' => context.t(
      'performance.indicator.finishedServiceCalls',
      fallback: 'Atendimentos finalizados',
    ),
    'ATENDIMENTO_VALOR' => context.t(
      'performance.indicator.serviceCallsValue',
      fallback: 'Valor em atendimentos',
    ),
    _ => code,
  };
}
