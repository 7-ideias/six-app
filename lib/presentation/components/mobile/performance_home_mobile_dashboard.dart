import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/colaborador_usuario_model.dart';
import '../../../data/models/desempenho_colaborador_model.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/desempenho_colaborador_home_provider.dart';
import '../../../providers/locale_settings_provider.dart';
import '../six_backend_loading.dart';

class PerformanceHomeMobileDashboard extends StatelessWidget {
  const PerformanceHomeMobileDashboard({super.key, required this.provider});

  final DesempenhoColaboradorHomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    final bool hasData = provider.loadRevision > 0;
    final bool initialLoading = provider.loading && !hasData;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MobileHeader(provider: provider, regionalizacao: regionalizacao),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
          child:
              initialLoading
                  ? _LoadingCard(
                    key: const ValueKey<String>('performance-mobile-loading'),
                    colors: colors,
                  )
                  : provider.hasError && !hasData
                  ? _ErrorCard(
                    key: const ValueKey<String>('performance-mobile-error'),
                    colors: colors,
                    onRetry: provider.load,
                  )
                  : KeyedSubtree(
                    key: ValueKey<String>(
                      'performance-mobile-content-${provider.loadRevision}',
                    ),
                    child: Column(
                      children: <Widget>[
                        if (provider.hasError && hasData) ...<Widget>[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.errorBorder),
                            ),
                            child: Text(
                              context.t(
                                'performance.dashboard.staleData',
                                fallback:
                                    'Exibindo os últimos dados disponíveis. A atualização falhou.',
                              ),
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MobileKpis(
                          provider: provider,
                          regionalizacao: regionalizacao,
                        ),
                        const SizedBox(height: 12),
                        _MobileChart(
                          key: ValueKey<String>(
                            'performance-mobile-chart-${provider.loadRevision}',
                          ),
                          provider: provider,
                        ),
                        const SizedBox(height: 12),
                        _MobileGoals(
                          provider: provider,
                          regionalizacao: regionalizacao,
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.provider, required this.regionalizacao});

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final String dates =
        provider.periodoInicio == null || provider.periodoFim == null
            ? ''
            : '${regionalizacao.formatDate(provider.periodoInicio!)} – '
                '${regionalizacao.formatDate(provider.periodoFim!)}';

    return Container(
      key: const Key('performance-mobile-dashboard-header'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.insights_rounded, color: colors.accent),
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
                      style: TextStyle(
                        color: colors.titleText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t(
                        'performance.dashboard.mobileSubtitle',
                        fallback:
                            'Metas, vendas, assistências e caixa em tempo quase real.',
                      ),
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.loading && provider.hasLoaded)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: provider.reload,
                  tooltip: context.t('common.refresh', fallback: 'Atualizar'),
                  icon: Icon(Icons.refresh_rounded, color: colors.mutedText),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (provider.isAdmin) ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('performance-mobile-collaborator-filter'),
                onPressed:
                    provider.loading
                        ? null
                        : () => _showCollaboratorSheet(context, provider),
                icon: const Icon(Icons.group_outlined, size: 18),
                label: Text(_collaboratorLabel(context, provider)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DesempenhoInicioPeriodo.values
                  .map((period) {
                    final bool selected = provider.periodoSelecionado == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('performance-mobile-period-${period.name}'),
                        selected: selected,
                        label: Text(_periodLabel(context, period)),
                        onSelected:
                            provider.loading
                                ? null
                                : (_) => provider.setPeriodo(period),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          if (dates.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.date_range_outlined,
                  size: 15,
                  color: colors.mutedText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dates,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.bolt_rounded, size: 15, color: colors.accent),
                const SizedBox(width: 4),
                Text(
                  context.t(
                    'performance.dashboard.liveShort',
                    fallback: 'Ao vivo',
                  ),
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _collaboratorLabel(
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

  Future<void> _showCollaboratorSheet(
    BuildContext context,
    DesempenhoColaboradorHomeProvider provider,
  ) async {
    final Set<String> staged = provider.idsColaboradoresSelecionados.toSet();
    String query = '';
    final Set<String>? result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .46),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final SixMobileColorScheme colors = context.sixMobileColors;
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
            final double keyboardInset =
                MediaQuery.viewInsetsOf(context).bottom;
            final double availableHeight =
                MediaQuery.sizeOf(context).height - keyboardInset;
            final double maximumHeight = availableHeight * .88;
            final double desiredHeight =
                (390.0 + provider.participantes.length * 54.0)
                    .clamp(math.min(500.0, maximumHeight), maximumHeight)
                    .toDouble();
            return Padding(
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Container(
                height: desiredHeight,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(top: BorderSide(color: colors.strongBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(top: 10, bottom: 14),
                          decoration: BoxDecoration(
                            color: colors.strongBorder,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.t(
                                'performance.dashboard.filterTitle',
                                fallback: 'Filtrar colaboradores',
                              ),
                              style: TextStyle(
                                color: colors.titleText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.t(
                                'performance.dashboard.filterHint',
                                fallback: 'Selecione um ou mais colaboradores.',
                              ),
                              style: TextStyle(
                                color: colors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              onChanged:
                                  (String value) =>
                                      setSheetState(() => query = value),
                              style: TextStyle(color: colors.titleText),
                              decoration: InputDecoration(
                                hintText: context.t(
                                  'performance.dashboard.searchCollaborators',
                                  fallback: 'Buscar colaborador',
                                ),
                                hintStyle: TextStyle(color: colors.mutedText),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: colors.mutedText,
                                ),
                                filled: true,
                                fillColor: colors.softSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CheckboxListTile(
                        value: staged.isEmpty,
                        activeColor: colors.accent,
                        checkColor: colors.onAccent,
                        title: Text(
                          context.t(
                            'performance.dashboard.allCollaborators',
                            fallback: 'Todos os colaboradores',
                          ),
                          style: TextStyle(color: colors.titleText),
                        ),
                        secondary: Icon(
                          Icons.groups_rounded,
                          color: colors.accent,
                        ),
                        onChanged: (_) => setSheetState(() => staged.clear()),
                      ),
                      Divider(height: 1, color: colors.border),
                      Expanded(
                        child:
                            filtered.isEmpty
                                ? Center(
                                  child: Text(
                                    context.t(
                                      'performance.dashboard.noCollaboratorsFound',
                                      fallback:
                                          'Nenhum colaborador encontrado.',
                                    ),
                                    style: TextStyle(color: colors.mutedText),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final ColaboradorUsuarioResumo participant =
                                        filtered[index];
                                    final String id =
                                        participant.idUnicoPessoal;
                                    return CheckboxListTile(
                                      value: staged.contains(id),
                                      activeColor: colors.accent,
                                      checkColor: colors.onAccent,
                                      title: Text(
                                        provider.nomeDoParticipante(id),
                                        style: TextStyle(
                                          color: colors.titleText,
                                        ),
                                      ),
                                      subtitle:
                                          participant.email.trim().isEmpty
                                              ? null
                                              : Text(
                                                participant.email,
                                                style: TextStyle(
                                                  color: colors.mutedText,
                                                ),
                                              ),
                                      secondary: CircleAvatar(
                                        backgroundColor: colors.softSurface,
                                        child: Icon(
                                          Icons.person_outline,
                                          color: colors.accent,
                                        ),
                                      ),
                                      onChanged: (bool? checked) {
                                        setSheetState(() {
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.titleText,
                                  side: BorderSide(color: colors.strongBorder),
                                ),
                                onPressed:
                                    () => Navigator.of(sheetContext).pop(),
                                child: Text(
                                  context.t(
                                    'common.cancel',
                                    fallback: 'Cancelar',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  foregroundColor: colors.onAccent,
                                ),
                                onPressed:
                                    () =>
                                        Navigator.of(sheetContext).pop(staged),
                                child: Text(
                                  context.t(
                                    'common.apply',
                                    fallback: 'Aplicar',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

class _MobileKpis extends StatelessWidget {
  const _MobileKpis({required this.provider, required this.regionalizacao});

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
                  provider.isAdmin ? 'Situação atual' : 'Situação do meu caixa',
            );
    final List<_MobileKpiData> items = <_MobileKpiData>[
      _MobileKpiData(
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
      _MobileKpiData(
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
      _MobileKpiData(
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
      _MobileKpiData(
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
        final double width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) =>
                    SizedBox(width: width, child: _MobileKpiCard(data: item)),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MobileKpiData {
  const _MobileKpiData({
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

class _MobileKpiCard extends StatelessWidget {
  const _MobileKpiCard({required this.data});

  final _MobileKpiData data;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color accent = colors.accent;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final TextStyle valueStyle = TextStyle(
      color: colors.titleText,
      fontSize: 19,
      fontWeight: FontWeight.w900,
    );
    final Widget valueWidget;
    if (data.numericValue != null && data.numericFormatter != null) {
      valueWidget = TweenAnimationBuilder<double>(
        key: ValueKey<String>(
          '${data.id}:${data.numericValue!.toStringAsFixed(4)}',
        ),
        tween: Tween<double>(begin: 0, end: data.numericValue!),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 620),
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
      height: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.positive ? colors.softAccentSurface : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(data.icon, color: accent, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          valueWidget,
          const SizedBox(height: 4),
          Text(
            data.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.mutedText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MobileChart extends StatefulWidget {
  const _MobileChart({super.key, required this.provider});

  final DesempenhoColaboradorHomeProvider provider;

  @override
  State<_MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<_MobileChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final List<_MobileChartItem> items =
        _items(context, widget.provider).take(6).toList();
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final String chartKey = items
        .map((item) => '${item.label}:${item.value.toStringAsFixed(3)}')
        .join('|');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 10, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
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
            style: TextStyle(
              color: colors.titleText,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'performance.dashboard.chartCaption',
              fallback: 'Percentual realizado no período.',
            ),
            style: TextStyle(color: colors.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  context.t(
                    'performance.dashboard.chartEmpty',
                    fallback: 'Não há dados para o gráfico.',
                  ),
                  style: TextStyle(color: colors.mutedText, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
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
                  key: ValueKey<String>('performance-mobile-bars-$chartKey'),
                  tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 650),
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
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine:
                              (_) => FlLine(
                                color: colors.border.withValues(alpha: .7),
                                strokeWidth: 1,
                              ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final int index = value.round();
                                if (index < 0 || index >= items.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: SizedBox(
                                    width: 48,
                                    child: Text(
                                      items[index].label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.mutedText,
                                        fontSize: 9,
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
                            tooltipBgColor: colors.surfaceElevated,
                            getTooltipItem:
                                (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) => BarTooltipItem(
                                  '${items[groupIndex].label}\n${items[groupIndex].value.toStringAsFixed(1)}%',
                                  TextStyle(
                                    color: colors.titleText,
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
                              final Color color =
                                  value >= 70 ? colors.accent : colors.error;
                              final bool highlighted =
                                  _touchedIndex == entry.key;
                              final bool dimmed =
                                  _touchedIndex >= 0 && !highlighted;
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: value * reveal,
                                    width: highlighted ? 22 : 18,
                                    color: color.withValues(
                                      alpha: dimmed ? .34 : 1,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 100,
                                      color: colors.softSurface,
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

  List<_MobileChartItem> _items(
    BuildContext context,
    DesempenhoColaboradorHomeProvider provider,
  ) {
    if (provider.isAdmin && provider.comparativos.length > 1) {
      final List<_MobileChartItem> comparativos = provider.comparativos
          .map(
            (item) => _MobileChartItem(
              label:
                  item.nomeColaborador.trim().isEmpty
                      ? provider.nomeDoParticipante(item.idColaborador)
                      : item.nomeColaborador,
              value: item.scoreMedio,
            ),
          )
          .toList(growable: false);
      comparativos.sort(
        (_MobileChartItem a, _MobileChartItem b) => b.value.compareTo(a.value),
      );
      return comparativos;
    }
    return provider.metasAtivas
        .map(
          (item) => _MobileChartItem(
            label: _indicatorLabel(context, item.indicador),
            value: item.percentualAtingido,
          ),
        )
        .toList(growable: false);
  }
}

class _MobileChartItem {
  const _MobileChartItem({required this.label, required this.value});

  final String label;
  final double value;
}

class _MobileGoals extends StatelessWidget {
  const _MobileGoals({required this.provider, required this.regionalizacao});

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              'performance.dashboard.goalsTitle',
              fallback: 'Metas ativas',
            ),
            style: TextStyle(
              color: colors.titleText,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (provider.metasAtivas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  context.t(
                    'performance.home.emptyTitle',
                    fallback: 'Nenhuma meta ativa neste período',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.mutedText, fontSize: 12),
                ),
              ),
            )
          else
            ...provider.metasAtivas.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == provider.metasAtivas.length - 1 ? 0 : 10,
                ),
                child: _MobileGoalCard(
                  item: entry.value,
                  regionalizacao: regionalizacao,
                  showCollaborator: provider.isAdmin,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MobileGoalCard extends StatelessWidget {
  const _MobileGoalCard({
    required this.item,
    required this.regionalizacao,
    required this.showCollaborator,
  });

  final DesempenhoColaboradorItemModel item;
  final LocaleSettingsProvider regionalizacao;
  final bool showCollaborator;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final DesempenhoIndicadorOption indicator = indicadorPorCodigo(
      item.indicador,
    );
    final double progress =
        (item.percentualAtingido / 100).clamp(0.0, 1.0).toDouble();
    final Color color =
        item.percentualAtingido >= 100
            ? colors.accent
            : item.percentualAtingido >= 70
            ? colors.accent
            : item.percentualAtingido >= 40
            ? colors.secondary
            : colors.error;
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
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
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
                      color: colors.titleText,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>(
                    'mobile-goal-percent-${item.idMeta}-${item.percentualAtingido}',
                  ),
                  tween: Tween<double>(
                    begin: reduceMotion ? item.percentualAtingido : 0,
                    end: item.percentualAtingido,
                  ),
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 540),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, Widget? child) {
                    return Text(
                      regionalizacao.formatPercent(value, decimalPlaces: 1),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (showCollaborator &&
                item.nomeColaborador.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 3),
              Text(
                item.nomeColaborador,
                style: TextStyle(color: colors.mutedText, fontSize: 10),
              ),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>(
                  'mobile-goal-progress-${item.idMeta}-${item.percentualAtingido}',
                ),
                tween: Tween<double>(
                  begin: reduceMotion ? progress : 0,
                  end: progress,
                ),
                duration:
                    reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 540),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${format(item.valorRealizado)} / ${format(item.valorAlvo)}',
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({super.key, required this.colors});

  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
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
                'performance.dashboard.mobileSubtitle',
                fallback:
                    'Metas, vendas, assistências e caixa em tempo quase real.',
              ),
              animation: SixBackendLoadingAnimation.skeletonPulse,
              leadingIcon: Icons.insights_rounded,
              compact: true,
              backgroundColor: colors.surface,
              borderColor: colors.border,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(
                    4,
                    (int index) => Container(
                      width: width,
                      height: 118,
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({super.key, required this.colors, required this.onRetry});

  final SixMobileColorScheme colors;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, color: colors.error),
          const SizedBox(height: 8),
          Text(
            context.t(
              'performance.home.loadError',
              fallback: 'Não foi possível carregar o desempenho.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
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
      fallback: '7 dias',
    ),
    DesempenhoInicioPeriodo.ultimos30Dias => context.t(
      'performance.dashboard.period30Days',
      fallback: '30 dias',
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
