import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/data/models/workspace_home_insights.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/workspace_home_provider.dart';
import '../../theme/web_theme_tokens.dart';
import '../six_backend_loading.dart';

class WorkspaceTodayWeb extends StatelessWidget {
  const WorkspaceTodayWeb({
    super.key,
    required this.provider,
    required this.companyName,
    required this.onOpen,
  });
  final WorkspaceHomeProvider provider;
  final String companyName;
  final ValueChanged<WorkspaceHomeSection> onOpen;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: provider,
    builder:
        (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('homeToday.title'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${context.t('homeToday.company')}: $companyName',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(context.t('homeToday.subtitle')),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.t('homeToday.refresh'),
                  onPressed: provider.loading ? null : provider.reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 1100
                        ? 3
                        : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final section in WorkspaceHomeSection.values)
                      if (provider.block(section).data == null ||
                          provider.block(section).available(section))
                        SizedBox(
                          width: width,
                          child: _TodayCard(
                            key: ValueKey(section),
                            section: section,
                            state: provider.block(section),
                            onRetry:
                                provider.loading
                                    ? null
                                    : () => provider.reloadSection(section),
                            onOpen: () => onOpen(section),
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

class _TodayCard extends StatefulWidget {
  const _TodayCard({
    super.key,
    required this.section,
    required this.state,
    required this.onRetry,
    required this.onOpen,
  });
  final WorkspaceHomeSection section;
  final WorkspaceHomeBlock state;
  final VoidCallback? onRetry;
  final VoidCallback onOpen;
  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final locale = context.watch<LocaleSettingsProvider>();
    final state = widget.state;
    final section = widget.section;
    final home = state.data;
    final icon = switch (section) {
      WorkspaceHomeSection.financial => Icons.account_balance_wallet_outlined,
      WorkspaceHomeSection.technicalServices => Icons.handyman_outlined,
      WorkspaceHomeSection.cash => Icons.point_of_sale_outlined,
      WorkspaceHomeSection.stock => Icons.inventory_2_outlined,
      WorkspaceHomeSection.reservations => Icons.shopping_bag_outlined,
    };
    final action = switch (section) {
      WorkspaceHomeSection.financial => 'openFinancial',
      WorkspaceHomeSection.technicalServices => 'openServices',
      WorkspaceHomeSection.cash => 'openCash',
      WorkspaceHomeSection.stock => 'openStock',
      WorkspaceHomeSection.reservations => 'openReservations',
    };
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Card(
        margin: EdgeInsets.zero,
        color: tokens.cardBackground,
        elevation: _hover ? 5 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: tokens.primaryText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.t('homeToday.${section.jsonKey}'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (home == null && !state.failed)
                SixBackendLoading(
                  title: context.t('homeToday.loading'),
                  subtitle: context.t('homeToday.loadingHint'),
                  animation: SixBackendLoadingAnimation.skeletonPulse,
                  compact: true,
                )
              else if (home != null) ...[
                if (section == WorkspaceHomeSection.cash)
                  Text(
                    context.t(
                      home.cash.open == true
                          ? 'homeToday.cashOpen'
                          : home.cash.open == false
                          ? 'homeToday.cashClosed'
                          : 'homeToday.unknown',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                for (final metric in workspaceHomeInsights(section, home))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            context.t('homeToday.${metric.key}'),
                            style: TextStyle(color: tokens.secondaryText),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(metric.key),
                            tween: Tween<double>(
                              begin: 0,
                              end: metric.value?.toDouble() ?? 0,
                            ),
                            duration:
                                MediaQuery.disableAnimationsOf(context) ||
                                        MediaQuery.accessibleNavigationOf(
                                          context,
                                        )
                                    ? Duration.zero
                                    : const Duration(milliseconds: 350),
                            builder:
                                (context, value, _) => Text(
                                  metric.value == null
                                      ? '—'
                                      : metric.money
                                      ? locale.formatCurrency(value)
                                      : locale.formatInteger(value.round()),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color:
                                        metric.attention &&
                                                (metric.value ?? 0) > 0
                                            ? tokens.danger
                                            : tokens.primaryText,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (state.failed) ...[
                const SizedBox(height: 10),
                Text(
                  context.t('homeToday.error'),
                  style: TextStyle(color: tokens.danger),
                ),
                if (home != null)
                  Text(
                    context.t('homeToday.retained'),
                    style: TextStyle(color: tokens.secondaryText),
                  ),
                TextButton.icon(
                  onPressed: state.loading ? null : widget.onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.t('homeToday.retry')),
                ),
              ],
              if (state.loading && home != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    context.t('homeToday.updating'),
                    style: TextStyle(color: tokens.mutedText),
                  ),
                ),
              if (state.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${context.t('homeToday.updated')}: ${locale.formatDateTime(state.updatedAt!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: tokens.mutedText),
                  ),
                ),
              if (home != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onOpen,
                  child: Text(context.t('homeToday.$action')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
