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
import '../navigation/web_navigation_destination_resolver.dart';
import '../navigation/web_navigation_item.dart';
import '../navigation/web_navigation_permission_adapter.dart';
import '../theme/web_theme_tokens.dart';

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
    final ThemeData webTheme = WebThemeTokens.applyTo(Theme.of(context));

    return AnimatedTheme(
      data: webTheme,
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      child: Consumer<WorkspaceHomeProvider>(
        builder: (
          BuildContext context,
          WorkspaceHomeProvider provider,
          Widget? _,
        ) {
          final WebThemeTokens tokens = WebThemeTokens.of(context);
          final WorkspaceHomeModel? home = provider.home;
          final bool initialLoading = provider.loading && home == null;
          final bool initialError = provider.hasError && home == null;

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool narrow = compact || constraints.maxWidth < 900;
              final double horizontalPadding = narrow ? 14 : 24;

              return AnimatedContainer(
                key: const Key('workspace-home-root'),
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                decoration: BoxDecoration(color: tokens.workspaceBackground),
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
                              id: 'today',
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
                              id: 'attention',
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
                              id: 'quick-actions',
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
      ),
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final WorkspaceHomeModel? currentHome = home;
    final String? operationalDate =
        currentHome == null
            ? null
            : regionalizacao.formatDate(currentHome.date);

    return AnimatedContainer(
      key: const Key('workspace-home-header'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 720;

          final Widget title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _text(context, 'workspaceHome.title', 'Meu dia no SixoApp'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tokens.info,
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
                  color: tokens.primaryText,
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
                  color: tokens.secondaryText,
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
                  style: _homeOutlinedButtonStyle(tokens: tokens),
                  onPressed: loading ? null : onRefresh,
                  icon:
                      loading
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.info,
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tokens.secondaryText),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Column(
      children: <Widget>[
        SixBackendLoading(
          backgroundColor: tokens.cardBackground,
          borderColor: tokens.cardBorder,
          presentation: SixBackendLoadingPresentation.updateBanner,
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _HomeToneStyle tone = _homeToneStyle(
      context,
      tokens,
      _HomeTone.danger,
      baseBackground: tokens.cardBackground,
    );

    return AnimatedContainer(
      key: const Key('workspace-home-error'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: tone.accent,
              size: 20,
            ),
          ),
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
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
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
    required this.id,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String id;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return AnimatedContainer(
      key: Key('workspace-home-section-$id'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _homeTint(
                    tokens.info,
                    tokens.surface,
                    Theme.of(context).brightness,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tokens.info, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WorkspaceHomeNoData extends StatelessWidget {
  const _WorkspaceHomeNoData({
    required this.keySuffix,
    required this.text,
    this.height = 180,
    this.tone = _HomeTone.statusNeutral,
  });

  final String keySuffix;
  final String text;
  final double height;
  final _HomeTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _HomeToneStyle toneStyle = _homeToneStyle(
      context,
      tokens,
      tone,
      baseBackground: tokens.surfaceMuted,
    );

    return AnimatedContainer(
      key: Key('workspace-home-empty-$keySuffix'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: toneStyle.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toneStyle.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            tone == _HomeTone.success
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: toneStyle.accent,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
          keySuffix: 'receivable-today',
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
          keySuffix: 'payable-today',
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
      return _WorkspaceHomeNoData(
        keySuffix: 'today',
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
      keySuffix: 'cash',
      icon: Icons.payments_outlined,
      title: _text(context, 'workspaceHome.cash.title', 'Caixa'),
      value:
          aberto
              ? _text(context, 'workspaceHome.cash.open', 'Aberto')
              : _text(context, 'workspaceHome.cash.closed', 'Fechado'),
      details: details,
      tone: aberto ? _HomeTone.success : _HomeTone.statusNeutral,
    );
  }

  Widget _technicalServicesCard(BuildContext context) {
    final int active = home.technicalServices.active ?? 0;
    return _SituationCard(
      keySuffix: 'technical-services',
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
    required String keySuffix,
    required IconData icon,
    required String title,
    required WorkspaceHomeFinancialSummary summary,
  }) {
    return _SituationCard(
      keySuffix: keySuffix,
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
      keySuffix: 'stock',
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
      tone: _stockSituationTone(
        negative: negative,
        withoutStock: withoutStock,
        belowMinimum: belowMinimum,
      ),
    );
  }
}

class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.keySuffix,
    required this.icon,
    required this.title,
    required this.value,
    this.details = const <String>[],
    this.tone = _HomeTone.neutral,
  });

  final String keySuffix;
  final IconData icon;
  final String title;
  final String value;
  final List<String> details;
  final _HomeTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _HomeToneStyle toneStyle = _homeToneStyle(
      context,
      tokens,
      tone,
      neutralAccent: tokens.info,
      baseBackground: tokens.cardBackground,
    );

    return AnimatedContainer(
      key: Key('workspace-home-situation-$keySuffix'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toneStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: toneStyle.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: toneStyle.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
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
              color: tokens.primaryText,
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
                      color: tokens.mutedText,
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
      return _WorkspaceHomeNoData(
        keySuffix: 'attention',
        height: 132,
        text: _text(
          context,
          'workspaceHome.empty.attention',
          'Nenhuma pendência importante agora.',
        ),
        tone: _HomeTone.success,
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
            keySuffix: 'late-services',
            tone: _HomeTone.danger,
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
            keySuffix: 'waiting-approval',
            tone: _HomeTone.warning,
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
            keySuffix: 'ready-for-pickup',
            tone: _HomeTone.info,
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
            keySuffix: 'overdue-receivable',
            tone: _HomeTone.financialNegative,
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
            keySuffix: 'overdue-payable',
            tone: _HomeTone.financialNegative,
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
            keySuffix: 'stock-negative',
            tone: _HomeTone.stockCritical,
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
            keySuffix: 'stock-without',
            tone: _HomeTone.stockCritical,
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
            keySuffix: 'stock-below',
            tone: _HomeTone.stockWarning,
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

class _AttentionEntry {
  const _AttentionEntry({
    required this.keySuffix,
    required this.tone,
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  final String keySuffix;
  final _HomeTone tone;
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _HomeToneStyle tone = _homeToneStyle(
      context,
      tokens,
      entry.tone,
      baseBackground: tokens.cardBackground,
    );

    return AnimatedContainer(
      key: Key('workspace-home-attention-${entry.keySuffix}'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.border),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 620;
          final Widget leading = Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, color: tone.accent, size: 20),
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
                    color: tokens.primaryText,
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
                      color: tokens.secondaryText,
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
              key: Key('workspace-home-attention-action-${entry.keySuffix}'),
              style: _homeTextButtonStyle(tokens: tokens),
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
          keySuffix: 'new-sale',
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
          keySuffix: 'new-technical-service',
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
          keySuffix: 'cash',
          icon: Icons.payments_outlined,
          label: _text(context, 'workspaceHome.quickAction.cash', 'Caixa'),
          onPressed: onOpenCash,
        ),
      if (permissions.contains(WebNavigationPermission.podeAcessarFinanceiro))
        _QuickActionEntry(
          keySuffix: 'financial-agenda',
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
      return _WorkspaceHomeNoData(
        keySuffix: 'quick-actions',
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
    required this.keySuffix,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String keySuffix;
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ButtonStyle style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 42)),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      side: WidgetStatePropertyAll<BorderSide>(
        BorderSide(
          color: action.primary ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      backgroundColor: WidgetStatePropertyAll<Color>(
        action.primary ? colorScheme.primary : tokens.surfaceMuted,
      ),
      foregroundColor: WidgetStatePropertyAll<Color>(
        action.primary ? colorScheme.onPrimary : tokens.primaryText,
      ),
      overlayColor:
          action.primary
              ? WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (!_hasInteractiveState(states)) return null;
                return colorScheme.onPrimary.withValues(alpha: 0.12);
              })
              : _homeOverlay(tokens),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );

    if (action.primary) {
      return FilledButton.icon(
        key: Key('workspace-home-quick-action-${action.keySuffix}'),
        style: style,
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
      );
    }

    return FilledButton.tonalIcon(
      key: Key('workspace-home-quick-action-${action.keySuffix}'),
      style: style,
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18, color: tokens.info),
      label: Text(action.label),
    );
  }
}

enum _HomeTone {
  neutral,
  statusNeutral,
  success,
  warning,
  danger,
  info,
  financialNegative,
  stockCritical,
  stockWarning,
}

@immutable
class _HomeToneStyle {
  const _HomeToneStyle({
    required this.accent,
    required this.background,
    required this.border,
    required this.iconBackground,
  });

  final Color accent;
  final Color background;
  final Color border;
  final Color iconBackground;
}

_HomeToneStyle _homeToneStyle(
  BuildContext context,
  WebThemeTokens tokens,
  _HomeTone tone, {
  Color? neutralAccent,
  Color? baseBackground,
}) {
  final Brightness brightness = Theme.of(context).brightness;
  final Color base = baseBackground ?? tokens.cardBackground;
  final Color accent = _homeAccentFor(
    context,
    tokens,
    tone,
    neutralAccent: neutralAccent,
  );
  final bool neutral =
      tone == _HomeTone.neutral || tone == _HomeTone.statusNeutral;

  return _HomeToneStyle(
    accent: accent,
    background:
        neutral
            ? base
            : _homeTint(
              accent,
              base,
              brightness,
              lightAlpha: 0.045,
              darkAlpha: 0.075,
            ),
    border:
        neutral
            ? tokens.cardBorder
            : _homeTint(
              accent,
              tokens.cardBorder,
              brightness,
              lightAlpha: 0.18,
              darkAlpha: 0.26,
            ),
    iconBackground: _homeTint(
      accent,
      base,
      brightness,
      lightAlpha: 0.09,
      darkAlpha: 0.16,
    ),
  );
}

Color _homeAccentFor(
  BuildContext context,
  WebThemeTokens tokens,
  _HomeTone tone, {
  Color? neutralAccent,
}) {
  switch (tone) {
    case _HomeTone.neutral:
      return neutralAccent ?? Theme.of(context).colorScheme.primary;
    case _HomeTone.statusNeutral:
      return tokens.statusNeutral;
    case _HomeTone.success:
      return tokens.success;
    case _HomeTone.warning:
      return tokens.warning;
    case _HomeTone.danger:
      return tokens.danger;
    case _HomeTone.info:
      return tokens.info;
    case _HomeTone.financialNegative:
      return tokens.financialNegative;
    case _HomeTone.stockCritical:
      return tokens.stockCritical;
    case _HomeTone.stockWarning:
      return tokens.stockWarning;
  }
}

Color _homeTint(
  Color accent,
  Color base,
  Brightness brightness, {
  double lightAlpha = 0.08,
  double darkAlpha = 0.14,
}) {
  return Color.alphaBlend(
    accent.withValues(
      alpha: brightness == Brightness.dark ? darkAlpha : lightAlpha,
    ),
    base,
  );
}

_HomeTone _stockSituationTone({
  required int negative,
  required int withoutStock,
  required int belowMinimum,
}) {
  if (negative > 0 || withoutStock > 0) {
    return _HomeTone.stockCritical;
  }

  if (belowMinimum > 0) {
    return _HomeTone.stockWarning;
  }

  return _HomeTone.success;
}

ButtonStyle _homeOutlinedButtonStyle({required WebThemeTokens tokens}) {
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      return states.contains(WidgetState.disabled)
          ? tokens.disabledBackground
          : tokens.surfaceMuted;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      return states.contains(WidgetState.disabled)
          ? tokens.disabledForeground
          : tokens.info;
    }),
    side: WidgetStateProperty.resolveWith<BorderSide>((
      Set<WidgetState> states,
    ) {
      return BorderSide(
        color:
            states.contains(WidgetState.disabled)
                ? tokens.cardBorder
                : tokens.selectedBorder,
      );
    }),
    overlayColor: _homeOverlay(tokens),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textStyle: const WidgetStatePropertyAll<TextStyle>(
      TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

ButtonStyle _homeTextButtonStyle({required WebThemeTokens tokens}) {
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll<Color>(tokens.info),
    overlayColor: _homeOverlay(tokens),
    textStyle: const WidgetStatePropertyAll<TextStyle>(
      TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

WidgetStateProperty<Color?> _homeOverlay(WebThemeTokens tokens) {
  return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
    if (!_hasInteractiveState(states)) {
      return null;
    }

    return tokens.hoverBackground.withValues(alpha: 0.72);
  });
}

bool _hasInteractiveState(Set<WidgetState> states) {
  return states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused) ||
      states.contains(WidgetState.pressed);
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = (maxWidth / 220).floor().clamp(1, 5);
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
