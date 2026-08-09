import 'package:flutter/material.dart';

import '../../../data/models/streak_models.dart';
import '../../../l10n/six_i18n.dart';
import '../../utils/streak_texts.dart';

class StreakSummaryWebCard extends StatelessWidget {
  const StreakSummaryWebCard({
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (hasError && streaks == null) {
      return _ErrorState(onRetry: onRetry);
    }

    final UserStreaksModel data = streaks ?? UserStreaksModel.empty();
    final UserStreakScopeModel destaque =
        data.shared.currentDays >= data.web.currentDays
            ? data.shared
            : data.web;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.86),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _fireColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _fireColor.withValues(alpha: 0.16)),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? context.t(
                            'streak.loading',
                            fallback: 'Carregando seus dias de ofensiva.',
                          )
                          : streakCurrentMessage(context, destaque),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 520;
              final List<Widget> metrics = <Widget>[
                _MetricTile(
                  label: context.t('streak.web', fallback: 'Web'),
                  scope: data.web,
                ),
                _MetricTile(
                  label: context.t('streak.shared', fallback: 'Geral'),
                  scope: data.shared,
                  emphasized: true,
                ),
              ];

              if (compact) {
                return Column(
                  children: metrics
                      .map(
                        (Widget item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: item,
                        ),
                      )
                      .toList(growable: false),
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: metrics[0]),
                  const SizedBox(width: 12),
                  Expanded(child: metrics[1]),
                ],
              );
            },
          ),
        ],
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            emphasized
                ? colorScheme.primary.withValues(alpha: 0.06)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              emphasized
                  ? colorScheme.primary.withValues(alpha: 0.24)
                  : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  streakDaysLabel(context, scope.currentDays),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            scope.currentDays.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: emphasized ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.local_fire_department_rounded,
            color: colorScheme.error,
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
