import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/desempenho_colaborador_model.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/desempenho_colaborador_home_provider.dart';
import '../../../providers/locale_settings_provider.dart';
import '../../theme/web_theme_tokens.dart';
import '../web_dashboard_widgets.dart';

class CollaboratorPerformanceHomeWebDashboard extends StatelessWidget {
  const CollaboratorPerformanceHomeWebDashboard({
    super.key,
    required this.provider,
    required this.regionalizacao,
  });

  final DesempenhoColaboradorHomeProvider provider;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    return SixWebSectionCard(
      title: context.t(
        'performance.home.dashboardTitle',
        fallback: 'Meta x resultado',
      ),
      icon: Icons.insights_rounded,
      trailing: provider.loading && provider.resultados.isNotEmpty
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WebThemeTokens.of(context).info,
              ),
            )
          : null,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : WebThemeTokens.transitionDuration,
        switchInCurve: WebThemeTokens.transitionCurve,
        switchOutCurve: WebThemeTokens.transitionCurve,
        child: _buildState(context),
      ),
    );
  }

  Widget _buildState(BuildContext context) {
    if (!provider.hasLoaded ||
        (provider.loading && provider.resultados.isEmpty)) {
      return const _PerformanceLoading(
        key: ValueKey<String>('performance-home-web-loading'),
      );
    }

    if (provider.hasError && provider.resultados.isEmpty) {
      return _PerformanceError(
        key: const ValueKey<String>('performance-home-web-error'),
        onRetry: provider.load,
      );
    }

    if (provider.resultados.isEmpty) {
      return SixWebNoData(
        key: const ValueKey<String>('performance-home-web-empty'),
        height: 128,
        text: context.t(
          'performance.home.emptySubtitle',
          fallback:
              'Quando uma meta for cadastrada para você, o resultado aparecerá aqui.',
        ),
      );
    }

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
      key: const ValueKey<String>('performance-home-web-success'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: WebThemeTokens.of(context).secondaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  period,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WebThemeTokens.of(context).secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stack = constraints.maxWidth < 720;
              final double itemWidth = stack
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final DesempenhoColaboradorItemModel item
                      in provider.resultados)
                    SizedBox(
                      width: itemWidth,
                      child: _PerformanceCard(
                        item: item,
                        regionalizacao: regionalizacao,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PerformanceLoading extends StatelessWidget {
  const _PerformanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Semantics(
      liveRegion: true,
      label: context.t(
        'performance.home.loading',
        fallback: 'Carregando suas metas',
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 720;
          final double itemWidth = stack
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List<Widget>.generate(2, (int index) {
              return Container(
                width: itemWidth,
                height: 176,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.track_changes_rounded,
                      color: tokens.info,
                      size: 20,
                    ),
                    const SizedBox(height: 18),
                    const _SkeletonLine(widthFactor: .62),
                    const SizedBox(height: 16),
                    const _SkeletonLine(widthFactor: .88),
                    const Spacer(),
                    const _SkeletonLine(widthFactor: 1),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: WebThemeTokens.of(context).cardBorder,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PerformanceError extends StatelessWidget {
  const _PerformanceError({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.danger.withValues(alpha: .52)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, color: tokens.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t(
                'performance.home.loadError',
                fallback: 'Não foi possível atualizar suas metas.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
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

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.item, required this.regionalizacao});

  final DesempenhoColaboradorItemModel item;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final DesempenhoIndicadorOption indicator = indicadorPorCodigo(
      item.indicador,
    );
    final double progress = (item.percentualAtingido / 100).clamp(0.0, 1.0);
    final Color progressColor = item.percentualAtingido >= 100
        ? tokens.success
        : item.percentualAtingido >= 70
        ? tokens.warning
        : tokens.danger;

    return Semantics(
      container: true,
      label: _indicatorLabel(context, item.indicador),
      value: regionalizacao.formatPercent(item.percentualAtingido),
      child: Container(
        key: Key('workspace-home-goal-${item.idMeta}'),
        constraints: const BoxConstraints(minHeight: 176),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.cardBorder),
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
                    color: Color.alphaBlend(
                      progressColor.withValues(alpha: .10),
                      tokens.surface,
                    ),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  regionalizacao.formatPercent(item.percentualAtingido),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 14),
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
                    backgroundColor: tokens.cardBorder,
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
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.secondaryText,
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
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),
      ],
    );
  }
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
