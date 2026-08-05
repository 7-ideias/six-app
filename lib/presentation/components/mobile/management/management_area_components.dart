import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_maturity_badge.dart';

enum ManagementActionEmphasis { primary, secondary, operational }

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
    required this.label,
    required this.icon,
    required this.accentColor,
    this.value,
    this.valueText,
    this.semanticValue,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final int? value;
  final String? valueText;
  final String? semanticValue;
  final bool loading;
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
  const _ManagementSkeletonBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SixMobilePalette.border.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(9),
      ),
    );
  }
}
