import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/data/models/workspace_home_insights.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/workspace_home_provider.dart';
import '../six_backend_loading.dart';

class WorkspaceTodayMobile extends StatelessWidget {
  const WorkspaceTodayMobile({
    super.key,
    required this.provider,
    required this.companyName,
    required this.onOpen,
    required this.onSale,
    required this.onService,
    required this.onReceive,
  });
  final WorkspaceHomeProvider provider;
  final String companyName;
  final ValueChanged<WorkspaceHomeSection> onOpen;
  final VoidCallback onSale;
  final VoidCallback onService;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: provider,
    builder: (context, _) {
      final colors = context.sixMobileColors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('homeToday.title'),
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: colors.titleText,
                  ),
                ),
              ),
              IconButton(
                onPressed: provider.loading ? null : provider.reload,
                tooltip: context.t('homeToday.refresh'),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Text(
            '${context.t('homeToday.company')}: $companyName',
            style: TextStyle(color: colors.mutedText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(context.t('homeToday.sale')),
                onPressed: onSale,
              ),
              ActionChip(
                avatar: const Icon(Icons.build_outlined, size: 18),
                label: Text(context.t('homeToday.service')),
                onPressed: onService,
              ),
              ActionChip(
                avatar: const Icon(Icons.south_west, size: 18),
                label: Text(context.t('homeToday.receive')),
                onPressed: onReceive,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final section in WorkspaceHomeSection.values)
            if (provider.block(section).data == null ||
                provider.block(section).available(section))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MobileBlock(
                  key: ValueKey(section),
                  section: section,
                  state: provider.block(section),
                  onRetry:
                      provider.loading
                          ? null
                          : () => provider.reloadSection(section),
                  onOpen:
                      section == WorkspaceHomeSection.reservations
                          ? null
                          : () => onOpen(section),
                ),
              ),
        ],
      );
    },
  );
}

class _MobileBlock extends StatelessWidget {
  const _MobileBlock({
    super.key,
    required this.section,
    required this.state,
    required this.onRetry,
    this.onOpen,
  });
  final WorkspaceHomeSection section;
  final WorkspaceHomeBlock state;
  final VoidCallback? onRetry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    final locale = context.watch<LocaleSettingsProvider>();
    final home = state.data;
    final financial = section == WorkspaceHomeSection.financial;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('homeToday.${section.jsonKey}'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.titleText,
            ),
          ),
          const SizedBox(height: 14),
          if (home == null && !state.failed)
            SixBackendLoading(
              title: context.t('homeToday.loading'),
              subtitle: context.t('homeToday.loadingHint'),
              animation: SixBackendLoadingAnimation.skeletonPulse,
              compact: true,
            )
          else if (home != null) ...[
            if (section == WorkspaceHomeSection.cash)
              Row(
                children: [
                  Icon(Icons.point_of_sale, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t(
                        home.cash.open == true
                            ? 'homeToday.cashOpen'
                            : home.cash.open == false
                            ? 'homeToday.cashClosed'
                            : 'homeToday.unknown',
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.titleText,
                      ),
                    ),
                  ),
                ],
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    financial &&
                    constraints.maxWidth >= 300 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metric in workspaceHomeInsights(section, home))
                      SizedBox(
                        width:
                            twoColumns
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth,
                        child: Container(
                          padding: EdgeInsets.all(financial ? 12 : 0),
                          decoration:
                              financial
                                  ? BoxDecoration(
                                    color: colors.softSurface,
                                    borderRadius: BorderRadius.circular(14),
                                  )
                                  : null,
                          child:
                              financial
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.t('homeToday.${metric.key}'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _value(context, metric, locale),
                                    ],
                                  )
                                  : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          context.t('homeToday.${metric.key}'),
                                          style: TextStyle(
                                            color: colors.mutedText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      _value(context, metric, locale),
                                    ],
                                  ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (state.failed) ...[
            const SizedBox(height: 10),
            Text(
              context.t('homeToday.error'),
              style: TextStyle(color: colors.error),
            ),
            if (home != null)
              Text(
                context.t('homeToday.retained'),
                style: TextStyle(color: colors.mutedText),
              ),
            TextButton.icon(
              onPressed: state.loading ? null : onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.t('homeToday.retry')),
            ),
          ],
          if (state.loading && home != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                context.t('homeToday.updating'),
                style: TextStyle(color: colors.mutedText),
              ),
            ),
          if (state.updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${context.t('homeToday.updated')}: ${locale.formatTime(state.updatedAt!)}',
                style: TextStyle(fontSize: 11, color: colors.mutedText),
              ),
            ),
          if (onOpen != null && home != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpen,
              child: Text(
                context.t(
                  'homeToday.${switch (section) {
                    WorkspaceHomeSection.financial => 'openFinancial',
                    WorkspaceHomeSection.technicalServices => 'openServices',
                    WorkspaceHomeSection.stock => 'openStock',
                    WorkspaceHomeSection.cash => 'openCash',
                    WorkspaceHomeSection.reservations => 'openReservations',
                  }}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _value(
    BuildContext context,
    WorkspaceHomeInsight metric,
    LocaleSettingsProvider locale,
  ) => TweenAnimationBuilder<double>(
    key: ValueKey(metric.key),
    tween: Tween<double>(begin: 0, end: metric.value?.toDouble() ?? 0),
    duration:
        MediaQuery.disableAnimationsOf(context) ||
                MediaQuery.accessibleNavigationOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
    builder:
        (context, value, _) => Text(
          metric.value == null
              ? '—'
              : metric.money
              ? locale.formatCurrency(value)
              : locale.formatInteger(value.round()),
          style: TextStyle(
            fontSize: metric.money ? 18 : 20,
            fontWeight: FontWeight.w700,
            color:
                metric.attention && (metric.value ?? 0) > 0
                    ? context.sixMobileColors.error
                    : context.sixMobileColors.titleText,
          ),
        ),
  );
}
