import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_maturity_badge.dart';

enum ManagementActionEmphasis { primary, secondary, operational }

enum ManagementSummaryCardVariant { catalog, people, finance }

class ManagementAreaHeader extends StatelessWidget {
  const ManagementAreaHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedLabel,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String selectedLabel;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      selected: true,
      label: '$selectedLabel: $title',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.activeBorder, width: 0.7),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 12.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
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

class ManagementMetricData {
  const ManagementMetricData({
    this.id,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.value,
    this.valueText,
    this.semanticValue,
    this.loading = false,
    this.showAttentionDot = false,
    this.attentionSemanticLabel,
  });

  final String? id;
  final String label;
  final IconData icon;
  final Color accentColor;
  final int? value;
  final String? valueText;
  final String? semanticValue;
  final bool loading;
  final bool showAttentionDot;
  final String? attentionSemanticLabel;
}

class ManagementSummaryCard extends StatelessWidget {
  const ManagementSummaryCard({
    super.key,
    required this.title,
    required this.metrics,
    required this.unavailableLabel,
    required this.variant,
  });

  final String title;
  final List<ManagementMetricData> metrics;
  final String unavailableLabel;
  final ManagementSummaryCardVariant variant;

  static const Color _catalogStart = Color(0xFF173DFF);
  static const Color _catalogMiddle = Color(0xFF3D00D8);
  static const Color _catalogEnd = Color(0xFF2700A8);
  static const Color _peopleStart = Color(0xFF0F766E);
  static const Color _peopleMiddle = Color(0xFF155E75);
  static const Color _peopleEnd = Color(0xFF1D4ED8);
  static const Color _financeStart = Color(0xFF0E7490);
  static const Color _financeMiddle = Color(0xFF1D4ED8);
  static const Color _financeEnd = Color(0xFF312E81);
  static const Color _cyanTrace = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return Semantics(
      container: true,
      label: title,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double textScale = MediaQuery.textScalerOf(context).scale(1);
          final bool compactMetrics =
              constraints.maxWidth < 322 || textScale >= 1.28;
          final double illustrationWidth = constraints.maxWidth < 330 ? 70 : 84;

          return AnimatedContainer(
            duration:
                reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 192),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradientColors,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _shadowColor.withValues(alpha: 0.26),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: -6,
                  bottom: -34,
                  child: IgnorePointer(
                    child: Container(
                      width: 150,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: <Color>[
                            SixMobilePalette.onPrimary.withValues(alpha: 0.10),
                            SixMobilePalette.onPrimary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -2,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: illustrationWidth,
                      height: 68,
                      child: _SummaryIllustration(variant: variant),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: illustrationWidth - 8),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.onPrimary,
                          fontSize: 16,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _cyanTrace,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(height: compactMetrics ? 28 : 42),
                    _SummaryMetricLayout(
                      metrics: metrics,
                      unavailableLabel: unavailableLabel,
                      compact: compactMetrics,
                      reduceMotion: reduceMotion,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Color> get _gradientColors {
    return switch (variant) {
      ManagementSummaryCardVariant.catalog => const <Color>[
        _catalogStart,
        _catalogMiddle,
        _catalogEnd,
      ],
      ManagementSummaryCardVariant.people => const <Color>[
        _peopleStart,
        _peopleMiddle,
        _peopleEnd,
      ],
      ManagementSummaryCardVariant.finance => const <Color>[
        _financeStart,
        _financeMiddle,
        _financeEnd,
      ],
    };
  }

  Color get _shadowColor {
    return switch (variant) {
      ManagementSummaryCardVariant.catalog => _catalogMiddle,
      ManagementSummaryCardVariant.people => _peopleMiddle,
      ManagementSummaryCardVariant.finance => _financeMiddle,
    };
  }
}

class _SummaryMetricLayout extends StatelessWidget {
  const _SummaryMetricLayout({
    required this.metrics,
    required this.unavailableLabel,
    required this.compact,
    required this.reduceMotion,
  });

  final List<ManagementMetricData> metrics;
  final String unavailableLabel;
  final bool compact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double itemWidth = (constraints.maxWidth - 14) / 2;

          return Wrap(
            spacing: 14,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: metrics
                .map(
                  (ManagementMetricData metric) => SizedBox(
                    width:
                        metrics.length == 1 ? constraints.maxWidth : itemWidth,
                    child: _SummaryMetric(
                      metric: metric,
                      unavailableLabel: unavailableLabel,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metrics
          .map(
            (ManagementMetricData metric) => Expanded(
              child: _SummaryMetric(
                metric: metric,
                unavailableLabel: unavailableLabel,
                reduceMotion: reduceMotion,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.metric,
    required this.unavailableLabel,
    required this.reduceMotion,
  });

  final ManagementMetricData metric;
  final String unavailableLabel;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final int? value = metric.value;
    final String visualValue =
        value == null
            ? metric.valueText ?? unavailableLabel
            : MaterialLocalizations.of(context).formatDecimal(value);
    final bool hasAttention =
        !metric.loading && metric.showAttentionDot && (value ?? 0) > 0;
    final String semanticValue =
        metric.semanticValue ??
        (value == null
            ? visualValue
            : MaterialLocalizations.of(context).formatDecimal(value));
    final String semanticsLabel = <String>[
      '${metric.label}: $semanticValue',
      if (hasAttention && metric.attentionSemanticLabel != null)
        metric.attentionSemanticLabel!,
    ].join('. ');

    return Semantics(
      key:
          metric.id == null
              ? null
              : ValueKey<String>('management-summary-metric-${metric.id}'),
      container: true,
      liveRegion: metric.loading,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 36,
              child:
                  metric.loading
                      ? const Center(
                        child: _ManagementSkeletonBlock(
                          width: 42,
                          height: 24,
                          light: true,
                        ),
                      )
                      : _SummaryMetricValue(
                        value: value,
                        valueText: visualValue,
                        showAttentionDot: hasAttention,
                        attentionDotKey:
                            metric.id == null
                                ? null
                                : ValueKey<String>(
                                  'management-summary-${metric.id}-attention-dot',
                                ),
                        reduceMotion: reduceMotion,
                      ),
            ),
            const SizedBox(height: 6),
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.78),
                fontSize: 12.2,
                height: 1.18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricValue extends StatelessWidget {
  const _SummaryMetricValue({
    required this.value,
    required this.valueText,
    required this.showAttentionDot,
    required this.reduceMotion,
    this.attentionDotKey,
  });

  final int? value;
  final String valueText;
  final bool showAttentionDot;
  final bool reduceMotion;
  final Key? attentionDotKey;

  @override
  Widget build(BuildContext context) {
    final bool isNumeric = value != null;
    final TextStyle style = TextStyle(
      color: SixMobilePalette.onPrimary,
      fontSize: isNumeric || valueText == '--' ? 29 : 15.5,
      height: 1,
      fontWeight: FontWeight.w900,
    );

    Widget valueChild;
    if (isNumeric && !reduceMotion) {
      valueChild = TweenAnimationBuilder<int>(
        key: ValueKey<int>(value!),
        tween: IntTween(begin: 0, end: value!),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, int animatedValue, Widget? child) {
          return Text(
            MaterialLocalizations.of(context).formatDecimal(animatedValue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        },
      );
    } else {
      valueChild = Text(
        valueText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (showAttentionDot) ...<Widget>[
              Container(
                key: attentionDotKey,
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFFFACC15),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            valueChild,
          ],
        ),
      ),
    );
  }
}

class _SummaryIllustration extends StatelessWidget {
  const _SummaryIllustration({required this.variant});

  final ManagementSummaryCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ManagementSummaryCardVariant.catalog =>
        const _CatalogSummaryIllustration(),
      ManagementSummaryCardVariant.people => const _PeopleSummaryIllustration(),
      ManagementSummaryCardVariant.finance =>
        const _FinanceSummaryIllustration(),
    };
  }
}

class _CatalogSummaryIllustration extends StatelessWidget {
  const _CatalogSummaryIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: 17,
          top: 8,
          child: Transform.rotate(
            angle: -0.10,
            child: _CatalogLayer(
              width: 33,
              height: 43,
              colors: const <Color>[Color(0xFF253DFF), Color(0xFF7C3AED)],
              opacity: 0.44,
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 4,
          child: Transform.rotate(
            angle: -0.04,
            child: _CatalogLayer(
              width: 36,
              height: 48,
              colors: const <Color>[Color(0xFF0EA5E9), Color(0xFF4338CA)],
              opacity: 0.70,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: _CatalogLayer(
            width: 39,
            height: 52,
            colors: const <Color>[Color(0xFF38BDF8), Color(0xFF4F46E5)],
            opacity: 1,
            child: Center(
              child: Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: 19,
                  height: 24,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: SixMobilePalette.onPrimary.withValues(alpha: 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.sell_rounded,
                    size: 13,
                    color: SixMobilePalette.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogLayer extends StatelessWidget {
  const _CatalogLayer({
    required this.width,
    required this.height,
    required this.colors,
    required this.opacity,
    this.child,
  });

  final double width;
  final double height;
  final List<Color> colors;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SixMobilePalette.onPrimary.withValues(alpha: 0.22),
            width: 0.8,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.primary.withValues(alpha: 0.24),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PeopleSummaryIllustration extends StatelessWidget {
  const _PeopleSummaryIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: 7,
          top: 4,
          child: _GlowCircle(
            size: 45,
            colors: const <Color>[Color(0xFF34D399), Color(0xFF2563EB)],
            child: const Icon(
              Icons.groups_2_rounded,
              color: SixMobilePalette.onPrimary,
              size: 24,
            ),
          ),
        ),
        Positioned(
          right: 38,
          top: 23,
          child: _GlowCircle(
            size: 23,
            colors: const <Color>[Color(0xFF93C5FD), Color(0xFF14B8A6)],
            child: const Icon(
              Icons.person_rounded,
              color: SixMobilePalette.onPrimary,
              size: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceSummaryIllustration extends StatelessWidget {
  const _FinanceSummaryIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: 8,
          top: 7,
          child: _GlowCircle(
            size: 48,
            colors: const <Color>[Color(0xFF22D3EE), Color(0xFF4F46E5)],
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: SixMobilePalette.onPrimary,
              size: 24,
            ),
          ),
        ),
        Positioned(
          right: 38,
          top: 7,
          child: Transform.rotate(
            angle: -0.13,
            child: Container(
              width: 25,
              height: 31,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFBAE6FD), Color(0xFF38BDF8)],
                ),
                borderRadius: BorderRadius.circular(7),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: SixMobilePalette.primary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.attach_money_rounded,
                color: SixMobilePalette.accent,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.colors,
    required this.child,
  });

  final double size;
  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(
          color: SixMobilePalette.onPrimary.withValues(alpha: 0.20),
          width: 0.8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ManagementMetricStrip extends StatelessWidget {
  const ManagementMetricStrip({
    super.key,
    required this.metrics,
    required this.unavailableLabel,
  });

  final List<ManagementMetricData> metrics;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth < 350 ? 2 : 3;
        final double width =
            (constraints.maxWidth - (columns - 1) * 8) / columns;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map(
                (ManagementMetricData metric) => SizedBox(
                  width: width,
                  child: _ManagementMetricCard(
                    metric: metric,
                    unavailableLabel: unavailableLabel,
                    reduceMotion: reduceMotion,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ManagementMetricCard extends StatelessWidget {
  const _ManagementMetricCard({
    required this.metric,
    required this.unavailableLabel,
    required this.reduceMotion,
  });

  final ManagementMetricData metric;
  final String unavailableLabel;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final String semanticValue =
        metric.semanticValue ??
        metric.value?.toString() ??
        metric.valueText ??
        unavailableLabel;

    return Semantics(
      container: true,
      label: '${metric.label}: $semanticValue',
      liveRegion: metric.loading,
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          color: metric.accentColor.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: metric.accentColor.withValues(alpha: 0.16),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(metric.icon, color: metric.accentColor, size: 16),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 9),
            if (metric.loading)
              const _ManagementSkeletonBlock(width: 44, height: 20)
            else
              _MetricValueText(
                value: metric.value,
                valueText: metric.valueText ?? unavailableLabel,
                reduceMotion: reduceMotion,
              ),
            const SizedBox(height: 3),
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 11.5,
                height: 1.18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricValueText extends StatelessWidget {
  const _MetricValueText({
    required this.value,
    required this.valueText,
    required this.reduceMotion,
  });

  final int? value;
  final String valueText;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      color: SixMobilePalette.titleText,
      fontSize: 19,
      fontWeight: FontWeight.w900,
      height: 1,
    );

    final int? target = value;
    if (target == null) {
      return Text(
        valueText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(fontSize: 16),
      );
    }

    if (reduceMotion) {
      return Text(target.toString(), maxLines: 1, style: style);
    }

    return TweenAnimationBuilder<int>(
      key: ValueKey<int>(target),
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, int value, Widget? child) {
        return Text(value.toString(), maxLines: 1, style: style);
      },
    );
  }
}

class ManagementActionItemData {
  const ManagementActionItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.maturity,
    required this.emphasis,
    this.onTap,
    this.statusLabel,
    this.disabledHint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final ManagementSettingsMaturity maturity;
  final ManagementActionEmphasis emphasis;
  final VoidCallback? onTap;
  final String? statusLabel;
  final String? disabledHint;

  bool get isEnabled =>
      maturity != ManagementSettingsMaturity.comingSoon && onTap != null;
}

class ManagementActionGroup extends StatelessWidget {
  const ManagementActionGroup({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ManagementActionItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ),
        Column(
          children: items
              .map(
                (ManagementActionItemData item) => Padding(
                  padding: EdgeInsets.only(bottom: item == items.last ? 0 : 9),
                  child: ManagementActionTile(item: item),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class ManagementActionTile extends StatelessWidget {
  const ManagementActionTile({super.key, required this.item});

  final ManagementActionItemData item;

  @override
  Widget build(BuildContext context) {
    final double opacity = item.isEnabled ? 1 : 0.58;
    final Color borderColor =
        item.emphasis == ManagementActionEmphasis.primary && item.isEnabled
            ? item.accentColor.withValues(alpha: 0.34)
            : SixMobilePalette.activeBorder;
    final Color backgroundColor =
        item.emphasis == ManagementActionEmphasis.primary && item.isEnabled
            ? item.accentColor.withValues(alpha: 0.075)
            : SixMobilePalette.surface;
    final String? statusLabel = item.statusLabel;

    return Semantics(
      container: true,
      button: item.isEnabled,
      enabled: item.isEnabled,
      label:
          item.disabledHint == null
              ? '${item.title}. ${item.subtitle}'
              : '${item.title}. ${item.subtitle}. ${item.disabledHint}',
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: item.isEnabled ? item.onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(12, 12, 11, 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: borderColor, width: 0.8),
                boxShadow:
                    item.emphasis == ManagementActionEmphasis.primary &&
                            item.isEnabled
                        ? const <BoxShadow>[
                          BoxShadow(
                            color: SixMobilePalette.navigationShadow,
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          item.isEnabled
                              ? item.accentColor.withValues(alpha: 0.12)
                              : SixMobilePalette.softNeutralSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.icon,
                      color:
                          item.isEnabled
                              ? item.accentColor
                              : SixMobilePalette.secondary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SixMobilePalette.titleText,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (statusLabel != null &&
                                statusLabel.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(width: 8),
                              ManagementSettingsMaturityBadge(
                                maturity: item.maturity,
                                label: statusLabel,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 12.2,
                            height: 1.32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    item.isEnabled
                        ? Icons.chevron_right_rounded
                        : Icons.lock_outline_rounded,
                    color:
                        item.isEnabled
                            ? item.accentColor
                            : SixMobilePalette.mutedText,
                    size: item.isEnabled ? 23 : 17,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManagementAttentionBlock extends StatelessWidget {
  const ManagementAttentionBlock({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.toneColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color toneColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final bool hasAction =
        actionLabel != null &&
        actionLabel!.trim().isNotEmpty &&
        onAction != null;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: toneColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: toneColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: SixMobilePalette.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: toneColor, size: 19),
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
                    style: const TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 13.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 12,
                      height: 1.32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasAction) ...<Widget>[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: toneColor,
                        ),
                        onPressed: onAction,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                        label: Text(
                          actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagementOverviewStatusMessage extends StatelessWidget {
  const ManagementOverviewStatusMessage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.toneColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color toneColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ManagementAttentionBlock(
      title: title,
      message: message,
      icon: icon,
      toneColor: toneColor,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _ManagementSkeletonBlock extends StatelessWidget {
  const _ManagementSkeletonBlock({
    required this.width,
    required this.height,
    this.light = false,
  });

  final double width;
  final double height;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            light
                ? SixMobilePalette.onPrimary.withValues(alpha: 0.30)
                : SixMobilePalette.border.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(9),
      ),
    );
  }
}
