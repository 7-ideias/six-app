import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/empresa_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/workspace_home_model.dart';
import '../../domain/services/workspace_home/workspace_home_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/empresa_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/workspace_home_provider.dart';
import '../components/six_backend_loading.dart';
import '../components/web_dashboard_widgets.dart';
import '../navigation/web_navigation_destination_resolver.dart';
import '../navigation/web_navigation_item.dart';
import '../navigation/web_navigation_permission_adapter.dart';

class WorkspaceHomeWeb extends StatelessWidget {
  const WorkspaceHomeWeb({
    super.key,
    required this.compact,
    required this.resolver,
    required this.onNovoAtendimentoTecnico,
    this.service,
  });

  final bool compact;
  final WebNavigationDestinationResolver resolver;
  final VoidCallback onNovoAtendimentoTecnico;
  final WorkspaceHomeService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WorkspaceHomeProvider>(
      create: (_) => WorkspaceHomeProvider(service: service)..load(),
      child: _WorkspaceHomeContent(
        compact: compact,
        resolver: resolver,
        onNovoAtendimentoTecnico: onNovoAtendimentoTecnico,
      ),
    );
  }
}

class _WorkspaceHomeContent extends StatelessWidget {
  const _WorkspaceHomeContent({
    required this.compact,
    required this.resolver,
    required this.onNovoAtendimentoTecnico,
  });

  final bool compact;
  final WebNavigationDestinationResolver resolver;
  final VoidCallback onNovoAtendimentoTecnico;

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    final EmpresaModel? empresa = context.watch<EmpresaProvider>().empresa;
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.watch<ColaboradorAutorizacoesProvider>();

    return Consumer<WorkspaceHomeProvider>(
      builder: (
        BuildContext context,
        WorkspaceHomeProvider provider,
        Widget? _,
      ) {
        final WorkspaceHomeModel? home = provider.home;
        final bool initialLoading = provider.loading && home == null;
        final bool initialError = provider.hasError && home == null;

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool narrow = compact || constraints.maxWidth < 900;
            final double horizontalPadding = narrow ? 14 : 24;

            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  narrow ? 14 : 20,
                  horizontalPadding,
                  narrow ? 18 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _WorkspaceHomeHeader(
                          userName: _resolveUserName(context),
                          companyName: _resolveCompanyName(context, empresa),
                          home: home,
                          regionalizacao: regionalizacao,
                          loading: provider.loading,
                          onRefresh: provider.reload,
                        ),
                        const SizedBox(height: 18),
                        if (initialLoading)
                          _WorkspaceHomeLoading(compact: narrow)
                        else if (initialError)
                          _WorkspaceHomeError(onRetry: provider.reload)
                        else if (home != null) ...<Widget>[
                          _WorkspaceHomeSection(
                            title: _text(
                              context,
                              'workspaceHome.section.today',
                              'Situação de hoje',
                            ),
                            icon: Icons.today_outlined,
                            child: _TodaySituationGrid(
                              home: home,
                              regionalizacao: regionalizacao,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _WorkspaceHomeSection(
                            title: _text(
                              context,
                              'workspaceHome.section.attention',
                              'Precisa da sua atenção',
                            ),
                            icon: Icons.priority_high_rounded,
                            child: _AttentionList(
                              home: home,
                              regionalizacao: regionalizacao,
                              onOpenTechnicalServices:
                                  () => _resolve(
                                    context,
                                    WebNavigationDestination
                                        .operationsTechnicalServices,
                                  ),
                              onOpenFinancial:
                                  () => _resolve(
                                    context,
                                    WebNavigationDestination.financialAgenda,
                                  ),
                              onOpenStock:
                                  () => _resolve(
                                    context,
                                    WebNavigationDestination.catalogStock,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _WorkspaceHomeSection(
                            title: _text(
                              context,
                              'workspaceHome.section.quickActions',
                              'Ações rápidas',
                            ),
                            icon: Icons.flash_on_outlined,
                            child: _QuickActions(
                              permissions:
                                  WebNavigationPermissionAdapter.permissionsFor(
                                    autorizacoes,
                                  ),
                              onNewSale:
                                  () => _resolve(
                                    context,
                                    WebNavigationDestination
                                        .operationsPointOfSale,
                                  ),
                              onNewTechnicalService: onNovoAtendimentoTecnico,
                              onOpenCash:
                                  () => _resolve(
                                    context,
                                    WebNavigationDestination.cash,
                                  ),
                              onOpenFinancialAgenda:
                                  () => _resolve(
                                    context,
                                    WebNavigationDestination.financialAgenda,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _resolve(BuildContext context, WebNavigationDestination destination) {
    final WebNavigationResolutionResult result = resolver.resolve(destination);
    if (result.handled) {
      return;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          _text(
            context,
            'web.navigation.unavailable',
            'Destino indisponível nesta versão.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _WorkspaceHomeHeader extends StatelessWidget {
  const _WorkspaceHomeHeader({
    required this.userName,
    required this.companyName,
    required this.home,
    required this.regionalizacao,
    required this.loading,
    required this.onRefresh,
  });

  final String userName;
  final String companyName;
  final WorkspaceHomeModel? home;
  final LocaleSettingsProvider regionalizacao;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final WorkspaceHomeModel? currentHome = home;
    final String? operationalDate =
        currentHome == null
            ? null
            : regionalizacao.formatDate(currentHome.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 720;

          final Widget title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _text(context, 'workspaceHome.title', 'Meu dia no SixApp'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _template(
                  context,
                  'workspaceHome.greeting',
                  'Olá, {name}',
                  <String, String>{'name': userName},
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final Widget meta = Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: stack ? WrapAlignment.start : WrapAlignment.end,
            children: <Widget>[
              if (operationalDate != null)
                _WorkspaceHomeMetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: _template(
                    context,
                    'workspaceHome.operationalDate',
                    'Hoje: {date}',
                    <String, String>{'date': operationalDate},
                  ),
                ),
              Tooltip(
                message: _text(
                  context,
                  'workspaceHome.refreshTooltip',
                  'Atualizar resumo do dia',
                ),
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onRefresh,
                  icon:
                      loading
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                          : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_text(context, 'common.refresh', 'Atualizar')),
                ),
              ),
            ],
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[title, const SizedBox(height: 14), meta],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: 18),
              Flexible(
                child: Align(alignment: Alignment.centerRight, child: meta),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkspaceHomeMetaChip extends StatelessWidget {
  const _WorkspaceHomeMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHomeLoading extends StatelessWidget {
  const _WorkspaceHomeLoading({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SixBackendLoading(
          title: _text(
            context,
            'workspaceHome.loading.title',
            'Carregando resumo do dia',
          ),
          subtitle: _text(
            context,
            'workspaceHome.loading.subtitle',
            'Buscando a situação atual desta empresa.',
          ),
          animation: SixBackendLoadingAnimation.skeletonPulse,
          leadingIcon: Icons.dashboard_customize_outlined,
        ),
        const SizedBox(height: 16),
        _ResponsiveCardGrid(
          minCardWidth: compact ? 240 : 220,
          children: const <Widget>[
            SixWebLoadingBlock(height: 112),
            SixWebLoadingBlock(height: 112),
            SixWebLoadingBlock(height: 112),
          ],
        ),
      ],
    );
  }
}

class _WorkspaceHomeError extends StatelessWidget {
  const _WorkspaceHomeError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _text(
                    context,
                    'workspaceHome.error.title',
                    'Não foi possível carregar o resumo do dia.',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _text(context, 'common.tryAgain', 'Tentar novamente'),
                    ),
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

class _WorkspaceHomeSection extends StatelessWidget {
  const _WorkspaceHomeSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SixWebSectionCard(title: title, icon: icon, child: child);
  }
}

class _TodaySituationGrid extends StatelessWidget {
  const _TodaySituationGrid({required this.home, required this.regionalizacao});

  final WorkspaceHomeModel home;
  final LocaleSettingsProvider regionalizacao;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[
      if (home.cash.available) _cashCard(context),
      if (home.technicalServices.available) _technicalServicesCard(context),
      if (home.financial.available && home.financial.receivableToday != null)
        _financialCard(
          context,
          icon: Icons.south_west_rounded,
          title: _text(
            context,
            'workspaceHome.financial.receivableToday',
            'A receber hoje',
          ),
          summary: home.financial.receivableToday!,
        ),
      if (home.financial.available && home.financial.payableToday != null)
        _financialCard(
          context,
          icon: Icons.north_east_rounded,
          title: _text(
            context,
            'workspaceHome.financial.payableToday',
            'A pagar hoje',
          ),
          summary: home.financial.payableToday!,
        ),
      if (home.stock.available) _stockCard(context),
    ];

    if (cards.isEmpty) {
      return SixWebNoData(
        height: 128,
        text: _text(
          context,
          'workspaceHome.empty.today',
          'Nenhum bloco do resumo está disponível para suas permissões.',
        ),
      );
    }

    return _ResponsiveCardGrid(children: cards);
  }

  Widget _cashCard(BuildContext context) {
    final bool aberto = home.cash.open == true;
    final List<String> details = <String>[];

    if (aberto && home.cash.openedAt != null) {
      details.add(_formatCashOpenedAt(context, home.cash.openedAt!));
    }

    final String responsavel = home.cash.responsibleName?.trim() ?? '';
    if (aberto && responsavel.isNotEmpty) {
      details.add(
        _template(
          context,
          'workspaceHome.cash.responsible',
          'Aberto por {name}',
          <String, String>{'name': responsavel},
        ),
      );
    }

    return _SituationCard(
      icon: Icons.payments_outlined,
      title: _text(context, 'workspaceHome.cash.title', 'Caixa'),
      value:
          aberto
              ? _text(context, 'workspaceHome.cash.open', 'Aberto')
              : _text(context, 'workspaceHome.cash.closed', 'Fechado'),
      details: details,
    );
  }

  Widget _technicalServicesCard(BuildContext context) {
    final int active = home.technicalServices.active ?? 0;
    return _SituationCard(
      icon: Icons.engineering_outlined,
      title: _text(context, 'workspaceHome.technical.title', 'Assistências'),
      value: _plural(
        context,
        count: active,
        oneKey: 'workspaceHome.technical.active.one',
        otherKey: 'workspaceHome.technical.active.other',
        oneFallback: '1 em andamento',
        otherFallback: '{count} em andamento',
      ),
    );
  }

  String _formatCashOpenedAt(BuildContext context, DateTime openedAt) {
    final DateTime localOpenedAt = openedAt.toLocal();
    final bool sameOperationalDay =
        localOpenedAt.year == home.date.year &&
        localOpenedAt.month == home.date.month &&
        localOpenedAt.day == home.date.day;
    final String time = regionalizacao.formatTime(localOpenedAt);

    if (sameOperationalDay) {
      return _template(
        context,
        'workspaceHome.cash.openedAt',
        'desde {time}',
        <String, String>{'time': time},
      );
    }

    return _template(
      context,
      'workspaceHome.cash.openedAtWithDate',
      'desde {date} às {time}',
      <String, String>{
        'date': regionalizacao.formatDate(localOpenedAt),
        'time': time,
      },
    );
  }

  Widget _financialCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required WorkspaceHomeFinancialSummary summary,
  }) {
    return _SituationCard(
      icon: icon,
      title: title,
      value: regionalizacao.formatCurrency(summary.amount),
      details: <String>[
        _plural(
          context,
          count: summary.count,
          oneKey: 'workspaceHome.financial.count.one',
          otherKey: 'workspaceHome.financial.count.other',
          oneFallback: '1 conta',
          otherFallback: '{count} contas',
        ),
      ],
    );
  }

  Widget _stockCard(BuildContext context) {
    final int belowMinimum = home.stock.belowMinimum ?? 0;
    final int withoutStock = home.stock.withoutStock ?? 0;
    final int negative = home.stock.negative ?? 0;
    final List<String> details = <String>[
      if (withoutStock > 0)
        _plural(
          context,
          count: withoutStock,
          oneKey: 'workspaceHome.stock.withoutStock.one',
          otherKey: 'workspaceHome.stock.withoutStock.other',
          oneFallback: '1 sem estoque',
          otherFallback: '{count} sem estoque',
        ),
      if (negative > 0)
        _plural(
          context,
          count: negative,
          oneKey: 'workspaceHome.stock.negative.one',
          otherKey: 'workspaceHome.stock.negative.other',
          oneFallback: '1 negativo',
          otherFallback: '{count} negativos',
        ),
    ];

    return _SituationCard(
      icon: Icons.warehouse_outlined,
      title: _text(context, 'workspaceHome.stock.title', 'Estoque'),
      value:
          belowMinimum > 0
              ? _plural(
                context,
                count: belowMinimum,
                oneKey: 'workspaceHome.stock.belowMinimum.one',
                otherKey: 'workspaceHome.stock.belowMinimum.other',
                oneFallback: '1 abaixo do mínimo',
                otherFallback: '{count} abaixo do mínimo',
              )
              : _text(
                context,
                'workspaceHome.stock.noCritical',
                'Sem alertas críticos',
              ),
      details: details,
    );
  }
}

class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.icon,
    required this.title,
    required this.value,
    this.details = const <String>[],
  });

  final IconData icon;
  final String title;
  final String value;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          if (details.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final String detail in details)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({
    required this.home,
    required this.regionalizacao,
    required this.onOpenTechnicalServices,
    required this.onOpenFinancial,
    required this.onOpenStock,
  });

  final WorkspaceHomeModel home;
  final LocaleSettingsProvider regionalizacao;
  final VoidCallback onOpenTechnicalServices;
  final VoidCallback onOpenFinancial;
  final VoidCallback onOpenStock;

  @override
  Widget build(BuildContext context) {
    final List<_AttentionEntry> entries = _entries(context);

    if (entries.isEmpty) {
      return SixWebNoData(
        height: 132,
        text: _text(
          context,
          'workspaceHome.empty.attention',
          'Nenhuma pendência importante agora.',
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int index = 0; index < entries.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 10),
          _AttentionCard(entry: entries[index]),
        ],
      ],
    );
  }

  List<_AttentionEntry> _entries(BuildContext context) {
    final List<_AttentionEntry> entries = <_AttentionEntry>[];

    if (home.technicalServices.available) {
      final int late = home.technicalServices.late ?? 0;
      final int waitingApproval = home.technicalServices.waitingApproval ?? 0;
      final int readyForPickup = home.technicalServices.readyForPickup ?? 0;

      if (late > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.critical,
            icon: Icons.warning_amber_rounded,
            title: _plural(
              context,
              count: late,
              oneKey: 'workspaceHome.attention.lateServices.one',
              otherKey: 'workspaceHome.attention.lateServices.other',
              oneFallback: '1 serviço atrasado',
              otherFallback: '{count} serviços atrasados',
            ),
            actionLabel: _text(
              context,
              'workspaceHome.action.openTechnicalServices',
              'Abrir assistências',
            ),
            onAction: onOpenTechnicalServices,
          ),
        );
      }

      if (waitingApproval > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.warning,
            icon: Icons.rate_review_outlined,
            title: _plural(
              context,
              count: waitingApproval,
              oneKey: 'workspaceHome.attention.waitingApproval.one',
              otherKey: 'workspaceHome.attention.waitingApproval.other',
              oneFallback: '1 orçamento aguardando aprovação',
              otherFallback: '{count} orçamentos aguardando aprovação',
            ),
            actionLabel: _text(
              context,
              'workspaceHome.action.openTechnicalServices',
              'Abrir assistências',
            ),
            onAction: onOpenTechnicalServices,
          ),
        );
      }

      if (readyForPickup > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.info,
            icon: Icons.inventory_outlined,
            title: _plural(
              context,
              count: readyForPickup,
              oneKey: 'workspaceHome.attention.readyForPickup.one',
              otherKey: 'workspaceHome.attention.readyForPickup.other',
              oneFallback: '1 equipamento pronto para retirada',
              otherFallback: '{count} equipamentos prontos para retirada',
            ),
            actionLabel: _text(
              context,
              'workspaceHome.action.openTechnicalServices',
              'Abrir assistências',
            ),
            onAction: onOpenTechnicalServices,
          ),
        );
      }
    }

    if (home.financial.available) {
      final WorkspaceHomeFinancialSummary? overdueReceivable =
          home.financial.overdueReceivable;
      final WorkspaceHomeFinancialSummary? overduePayable =
          home.financial.overduePayable;

      if (overdueReceivable != null && overdueReceivable.count > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.critical,
            icon: Icons.account_balance_wallet_outlined,
            title: _plural(
              context,
              count: overdueReceivable.count,
              oneKey: 'workspaceHome.attention.overdueReceivable.one',
              otherKey: 'workspaceHome.attention.overdueReceivable.other',
              oneFallback: '1 conta a receber vencida',
              otherFallback: '{count} contas a receber vencidas',
            ),
            subtitle: regionalizacao.formatCurrency(overdueReceivable.amount),
            actionLabel: _text(
              context,
              'workspaceHome.action.openFinancial',
              'Abrir financeiro',
            ),
            onAction: onOpenFinancial,
          ),
        );
      }

      if (overduePayable != null && overduePayable.count > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.warning,
            icon: Icons.request_quote_outlined,
            title: _plural(
              context,
              count: overduePayable.count,
              oneKey: 'workspaceHome.attention.overduePayable.one',
              otherKey: 'workspaceHome.attention.overduePayable.other',
              oneFallback: '1 conta a pagar vencida',
              otherFallback: '{count} contas a pagar vencidas',
            ),
            subtitle: regionalizacao.formatCurrency(overduePayable.amount),
            actionLabel: _text(
              context,
              'workspaceHome.action.openFinancial',
              'Abrir financeiro',
            ),
            onAction: onOpenFinancial,
          ),
        );
      }
    }

    if (home.stock.available) {
      final int negative = home.stock.negative ?? 0;
      final int withoutStock = home.stock.withoutStock ?? 0;
      final int belowMinimum = home.stock.belowMinimum ?? 0;

      if (negative > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.critical,
            icon: Icons.remove_circle_outline,
            title: _plural(
              context,
              count: negative,
              oneKey: 'workspaceHome.attention.stockNegative.one',
              otherKey: 'workspaceHome.attention.stockNegative.other',
              oneFallback: '1 produto com estoque negativo',
              otherFallback: '{count} produtos com estoque negativo',
            ),
            actionLabel: _text(
              context,
              'workspaceHome.action.openStock',
              'Abrir estoque',
            ),
            onAction: onOpenStock,
          ),
        );
      }

      if (withoutStock > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.warning,
            icon: Icons.inventory_2_outlined,
            title: _plural(
              context,
              count: withoutStock,
              oneKey: 'workspaceHome.attention.stockWithout.one',
              otherKey: 'workspaceHome.attention.stockWithout.other',
              oneFallback: '1 produto sem estoque',
              otherFallback: '{count} produtos sem estoque',
            ),
            actionLabel: _text(
              context,
              'workspaceHome.action.openStock',
              'Abrir estoque',
            ),
            onAction: onOpenStock,
          ),
        );
      }

      if (belowMinimum > 0) {
        entries.add(
          _AttentionEntry(
            severity: _AttentionSeverity.info,
            icon: Icons.low_priority_outlined,
            title: _plural(
              context,
              count: belowMinimum,
              oneKey: 'workspaceHome.attention.stockBelow.one',
              otherKey: 'workspaceHome.attention.stockBelow.other',
              oneFallback: '1 produto abaixo do estoque mínimo',
              otherFallback: '{count} produtos abaixo do estoque mínimo',
            ),
            actionLabel: _text(
              context,
              'workspaceHome.action.openStock',
              'Abrir estoque',
            ),
            onAction: onOpenStock,
          ),
        );
      }
    }

    return entries;
  }
}

enum _AttentionSeverity { critical, warning, info }

class _AttentionEntry {
  const _AttentionEntry({
    required this.severity,
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  final _AttentionSeverity severity;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.entry});

  final _AttentionEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color accent = _accentColor(colorScheme, entry.severity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 620;
          final Widget leading = Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, color: accent, size: 20),
          );
          final Widget text = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (entry.subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          );
          final Widget action = Align(
            alignment: stack ? Alignment.centerLeft : Alignment.centerRight,
            child: TextButton.icon(
              onPressed: entry.onAction,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(entry.actionLabel),
            ),
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[leading, const SizedBox(width: 12), text],
                ),
                const SizedBox(height: 10),
                action,
              ],
            );
          }

          return Row(
            children: <Widget>[
              leading,
              const SizedBox(width: 12),
              text,
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }

  Color _accentColor(ColorScheme colorScheme, _AttentionSeverity severity) {
    switch (severity) {
      case _AttentionSeverity.critical:
        return colorScheme.error;
      case _AttentionSeverity.warning:
        return colorScheme.tertiary;
      case _AttentionSeverity.info:
        return colorScheme.primary;
    }
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.permissions,
    required this.onNewSale,
    required this.onNewTechnicalService,
    required this.onOpenCash,
    required this.onOpenFinancialAgenda,
  });

  final Set<WebNavigationPermission> permissions;
  final VoidCallback onNewSale;
  final VoidCallback onNewTechnicalService;
  final VoidCallback onOpenCash;
  final VoidCallback onOpenFinancialAgenda;

  @override
  Widget build(BuildContext context) {
    final List<_QuickActionEntry> actions = <_QuickActionEntry>[
      if (permissions.contains(WebNavigationPermission.podeFazerVenda))
        _QuickActionEntry(
          icon: Icons.point_of_sale_outlined,
          label: _text(
            context,
            'workspaceHome.quickAction.newSale',
            'Nova venda',
          ),
          onPressed: onNewSale,
          primary: true,
        ),
      if (permissions.contains(
        WebNavigationPermission.podeLancarAssistenciaTecnica,
      ))
        _QuickActionEntry(
          icon: Icons.add_task_outlined,
          label: _text(
            context,
            'workspaceHome.quickAction.newTechnicalService',
            'Novo atendimento',
          ),
          onPressed: onNewTechnicalService,
        ),
      if (permissions.contains(WebNavigationPermission.podeReceberNoCaixa) ||
          permissions.contains(WebNavigationPermission.podeAcessarFinanceiro))
        _QuickActionEntry(
          icon: Icons.payments_outlined,
          label: _text(context, 'workspaceHome.quickAction.cash', 'Caixa'),
          onPressed: onOpenCash,
        ),
      if (permissions.contains(WebNavigationPermission.podeAcessarFinanceiro))
        _QuickActionEntry(
          icon: Icons.event_note_outlined,
          label: _text(
            context,
            'workspaceHome.quickAction.financialAgenda',
            'Agenda financeira',
          ),
          onPressed: onOpenFinancialAgenda,
        ),
    ];

    if (actions.isEmpty) {
      return SixWebNoData(
        height: 112,
        text: _text(
          context,
          'workspaceHome.empty.quickActions',
          'Nenhuma ação rápida disponível para suas permissões.',
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final _QuickActionEntry action in actions)
          _QuickActionButton(action: action),
      ],
    );
  }
}

class _QuickActionEntry {
  const _QuickActionEntry({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickActionEntry action;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 42)),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 14),
      ),
    );

    if (action.primary) {
      return FilledButton.icon(
        style: style,
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
      );
    }

    return FilledButton.tonalIcon(
      style: style,
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({required this.children, this.minCardWidth = 220});

  final List<Widget> children;
  final double minCardWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = (maxWidth / minCardWidth).floor().clamp(1, 5);
        final double itemWidth = (maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

String _resolveUserName(BuildContext context) {
  final UsuarioModel? usuario = UsuarioProvider().usuario;
  final String nomeDeGuerra = usuario?.nomeDeGuerra.trim() ?? '';
  if (nomeDeGuerra.isNotEmpty) return nomeDeGuerra;

  final String nome = usuario?.nome.trim() ?? '';
  if (nome.isNotEmpty) return nome;

  final String email = usuario?.email.trim() ?? '';
  if (email.isNotEmpty) return email;

  return _text(context, 'workspaceHome.unknownUser', 'usuário');
}

String _resolveCompanyName(BuildContext context, EmpresaModel? empresa) {
  final String nomeFantasia = empresa?.nomeFantasia.trim() ?? '';
  if (nomeFantasia.isNotEmpty) return nomeFantasia;

  final String nomeEmpresa = empresa?.nomeEmpresa.trim() ?? '';
  if (nomeEmpresa.isNotEmpty) return nomeEmpresa;

  return _text(context, 'workspaceHome.companyFallback', 'Comércio atual');
}

String _text(BuildContext context, String key, String fallback) {
  return context.t(key, fallback: fallback);
}

String _template(
  BuildContext context,
  String key,
  String fallback,
  Map<String, String> values,
) {
  String text = _text(context, key, fallback);
  for (final MapEntry<String, String> entry in values.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}

String _plural(
  BuildContext context, {
  required int count,
  required String oneKey,
  required String otherKey,
  required String oneFallback,
  required String otherFallback,
}) {
  return _template(
    context,
    count == 1 ? oneKey : otherKey,
    count == 1 ? oneFallback : otherFallback,
    <String, String>{'count': count.toString()},
  );
}
