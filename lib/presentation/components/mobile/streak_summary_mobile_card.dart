import 'package:flutter/material.dart';

import '../../../data/models/streak_models.dart';
import '../../../design_system/themes/six_mobile_palette.dart';
import '../../../l10n/six_i18n.dart';
import '../../utils/streak_texts.dart';
import '../mobile_motion.dart';
import '../six_backend_loading.dart';

class StreakSummaryMobileCard extends StatelessWidget {
  const StreakSummaryMobileCard({
    super.key,
    required this.streaks,
    required this.loading,
    required this.hasError,
    this.onRetry,
  });

  final UserStreaksModel? streaks;
  final bool loading;
  final bool hasError;
  final VoidCallback? onRetry;

  static const Color _fireColor = Color(0xFFEA580C);
  static const Color _fireSurface = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    if (loading && streaks == null) {
      return SixBackendLoading(
        title: context.t('streak.title', fallback: 'Ofensiva'),
        subtitle: context.t(
          'streak.loading',
          fallback: 'Carregando seus dias de ofensiva.',
        ),
        compact: true,
        leadingIcon: Icons.local_fire_department_rounded,
        animation: SixBackendLoadingAnimation.waveDots,
        backgroundColor: SixMobilePalette.surface,
        borderColor: SixMobilePalette.border,
      );
    }

    if (hasError && streaks == null) {
      return _ErrorCard(onRetry: onRetry);
    }

    final UserStreaksModel data = streaks ?? UserStreaksModel.empty();
    final UserStreakScopeModel destaque =
        data.shared.currentDays >= data.mobile.currentDays
            ? data.shared
            : data.mobile;

    return SixStaggeredEntry(
      delay: const Duration(milliseconds: 70),
      beginOffset: const Offset(0, 0.035),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow.withValues(alpha: 0.7),
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
                    color: _fireSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _fireColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: _fireColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t('streak.title', fallback: 'Ofensiva'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        streakCurrentMessage(context, destaque),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SixMobilePalette.mutedText,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricTile(
                    label: context.t('streak.mobile', fallback: 'Mobile'),
                    scope: data.mobile,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: context.t('streak.shared', fallback: 'Geral'),
                    scope: data.shared,
                    emphasized: true,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.scope,
    this.emphasized = false,
  });

  final String label;
  final UserStreakScopeModel scope;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        emphasized
            ? SixMobilePalette.highlightedBorder
            : SixMobilePalette.border;
    final Color background =
        emphasized
            ? SixMobilePalette.softAccentSurface
            : SixMobilePalette.softNeutralSurface;

    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: SixMobilePalette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SixAnimatedNumberText(
            value: scope.currentDays.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            streakDaysLabel(context, scope.currentDays),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: SixMobilePalette.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.local_fire_department_rounded,
            color: SixMobilePalette.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t(
                'streak.loadError',
                fallback: 'Não foi possível carregar sua ofensiva.',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SixMobilePalette.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.t(
                'common.tryAgain',
                fallback: 'Tentar novamente',
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
    );
  }
}
