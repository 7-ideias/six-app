import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/desempenho_colaborador_model.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/desempenho_colaborador_home_provider.dart';
import '../../../providers/locale_settings_provider.dart';

class CollaboratorPerformanceHomeMobileDashboard extends StatelessWidget {
  const CollaboratorPerformanceHomeMobileDashboard({
    super.key,
    required this.provider,
  });

  final DesempenhoColaboradorHomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final LocaleSettingsProvider locale = context
        .watch<LocaleSettingsProvider>();
    final bool initialLoading =
        !provider.hasLoaded ||
        (provider.loading && provider.resultados.isEmpty);

    return Semantics(
      container: true,
      liveRegion: initialLoading,
      label: context.t(
        initialLoading
            ? 'performance.home.loading'
            : 'performance.home.accessibilityLabel',
        fallback: initialLoading
            ? 'Carregando suas metas'
            : 'Dashboard das minhas metas',
      ),
      child: Container(
        key: const ValueKey<String>('collaborator-performance-dashboard'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: provider.hasError && provider.resultados.isEmpty
                ? colors.errorBorder
                : colors.border,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.navigationShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: initialLoading
              ? _PerformanceLoading(colors: colors)
              : provider.hasError && provider.resultados.isEmpty
              ? _PerformanceError(colors: colors, onRetry: provider.load)
              : provider.resultados.isEmpty
              ? _PerformanceEmpty(colors: colors)
              : _PerformanceResults(
                  provider: provider,
                  colors: colors,
                  regionalizacao: locale,
                ),
        ),
      ),
    );
  }
}

class _PerformanceLoading extends StatelessWidget {
  const _PerformanceLoading({required this.colors});

  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey<String>('collaborator-performance-loading'),
      child: Column(
        children: List<Widget>.generate(2, (int index) {
          return Container(
            height: 122,
            margin: EdgeInsets.only(bottom: index == 0 ? 12 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.track_changes_rounded,
                  color: colors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SkeletonLine(colors: colors, widthFactor: .62),
                      const SizedBox(height: 16),
                      _SkeletonLine(colors: colors, widthFactor: .88),
                      const Spacer(),
                      _SkeletonLine(colors: colors, widthFactor: 1),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.colors, required this.widthFactor});

  final SixMobileColorScheme colors;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: colors.border.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PerformanceError extends StatelessWidget {
  const _PerformanceError({required this.colors, required this.onRetry});

  final SixMobileColorScheme colors;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey<String>('collaborator-performance-error'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.cloud_off_rounded, color: colors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t(
                    'performance.home.loadError',
                    fallback: 'Não foi possível atualizar suas metas.',
                  ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 14,
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

class _PerformanceEmpty extends StatelessWidget {
  const _PerformanceEmpty({required this.colors});

  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey<String>('collaborator-performance-empty'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.flag_outlined, color: colors.mutedText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'performance.home.emptyTitle',
                    fallback: 'Nenhuma meta ativa neste mês',
                  ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(
                    'performance.home.emptySubtitle',
                    fallback:
                        'Quando uma meta for cadastrada para você, o resultado aparecerá aqui.',
                  ),
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceResults extends StatelessWidget {
  const _PerformanceResults({
    required this.provider,
    required this.colors,
    required this.regionalizacao,
  });

  final DesempenhoColaboradorHomeProvider provider;
  final SixMobileColorScheme colors;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final String period = context
        .t('performance.home.period', fallback: 'Resultados de {start} a {end}')
        .replaceAll(
          '{start}',
          regionalizacao.formatDate(provider.periodoInicio ?? DateTime.now()),
        )
        .replaceAll(
          '{end}',
          regionalizacao.formatDate(provider.periodoFim ?? DateTime.now()),
        );

    return KeyedSubtree(
      key: const ValueKey<String>('collaborator-performance-success'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colors.mutedText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  period,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (provider.loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...provider.resultados.indexed.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 < provider.resultados.length - 1 ? 12 : 0,
              ),
              child: _PerformanceCard(
                item: entry.$2,
                colors: colors,
                regionalizacao: regionalizacao,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.item,
    required this.colors,
    required this.regionalizacao,
  });

  final DesempenhoColaboradorItemModel item;
  final SixMobileColorScheme colors;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final DesempenhoIndicadorOption indicator = indicadorPorCodigo(
      item.indicador,
    );
    final double progress = (item.percentualAtingido / 100).clamp(0.0, 1.0);
    final Color progressColor = item.percentualAtingido >= 100
        ? colors.accent
        : item.percentualAtingido >= 70
        ? Theme.of(context).colorScheme.tertiary
        : colors.error;

    return Semantics(
      container: true,
      label: _indicatorLabel(context, item.indicador),
      value: regionalizacao.formatPercent(item.percentualAtingido),
      child: Container(
        key: ValueKey<String>('collaborator-goal-${item.idMeta}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.iconSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    indicator.valorMonetario
                        ? Icons.payments_outlined
                        : Icons.flag_outlined,
                    color: progressColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _indicatorLabel(context, item.indicador),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  regionalizacao.formatPercent(item.percentualAtingido),
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _PerformanceMetric(
                    label: context.t(
                      'performance.home.result',
                      fallback: 'Resultado',
                    ),
                    value: item.valorRealizado,
                    indicator: indicator,
                    regionalizacao: regionalizacao,
                    animate: true,
                    animationKey: '${item.idMeta}-${item.valorRealizado}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerformanceMetric(
                    label: context.t(
                      'performance.home.target',
                      fallback: 'Meta',
                    ),
                    value: item.valorAlvo,
                    indicator: indicator,
                    regionalizacao: regionalizacao,
                    animate: false,
                    animationKey: '${item.idMeta}-${item.valorAlvo}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>(
                  '${item.idMeta}-${item.percentualAtingido}',
                ),
                tween: Tween<double>(begin: 0, end: progress),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 560),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return LinearProgressIndicator(
                    minHeight: 8,
                    value: value,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.indicator,
    required this.regionalizacao,
    required this.animate,
    required this.animationKey,
  });

  final String label;
  final double value;
  final DesempenhoIndicadorOption indicator;
  final LocaleSettingsProvider regionalizacao;
  final bool animate;
  final String animationKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: colorsOf(context).mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          key: ValueKey<String>(animationKey),
          tween: Tween<double>(begin: animate ? 0 : value, end: value),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: animate ? 520 : 0),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double animatedValue, Widget? child) {
            return Text(
              _formatValue(animatedValue, indicator, regionalizacao),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorsOf(context).titleText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),
      ],
    );
  }

  SixMobileColorScheme colorsOf(BuildContext context) =>
      context.sixMobileColors;
}

String _formatValue(
  double value,
  DesempenhoIndicadorOption indicator,
  LocaleSettingsProvider regionalizacao,
) {
  if (indicator.valorMonetario) {
    return regionalizacao.formatCurrency(value);
  }
  final NumberFormat formatter = NumberFormat.decimalPattern(
    regionalizacao.currentLocale.toLanguageTag(),
  )..maximumFractionDigits = value.truncateToDouble() == value ? 0 : 1;
  return formatter.format(value);
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
    _ => indicadorPorCodigo(code).label,
  };
}
