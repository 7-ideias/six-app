import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/management/management_area_components.dart';
import 'package:sixpos/presentation/components/mobile/management/management_admin_header.dart';
import 'package:sixpos/presentation/components/mobile/management/management_section_selector.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_group.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_app_bar_profile_action.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';
import 'package:sixpos/presentation/screens/catalog_health_mobile_screen.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_mobile_screen.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_mobile_screen.dart';
import 'package:sixpos/presentation/screens/estoque_mobile_screen.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operational_procedures_mobile_screen.dart';
import 'package:sixpos/presentation/screens/regionalizacao_mobile_screen.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/management_overview_provider.dart';

import '../components/nav_bar_mobile.dart';
import 'empresa_configuracao_mobile.dart';

typedef ManagementMobileNavigate =
    void Function(BuildContext context, Widget page);

class GestaoMobileScreen extends StatefulWidget {
  const GestaoMobileScreen({
    super.key,
    this.overviewProvider,
    this.onNavigate,
    @visibleForTesting this.initialSectionIndex = 0,
    @visibleForTesting this.showBottomNavigationBar = true,
  });

  final ManagementOverviewProvider? overviewProvider;
  final ManagementMobileNavigate? onNavigate;
  final int initialSectionIndex;
  final bool showBottomNavigationBar;

  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
  static const double _horizontalPadding = 16;
  static const double _sectionContentBottomPadding = 24;
  static const Duration _sectionTransitionDuration = Duration(
    milliseconds: 380,
  );
  static const Color _catalogAccent = SixMobilePalette.accent;
  static const Color _peopleAccent = Color(0xFF059669);
  static const Color _financeAccent = Color(0xFF0891B2);
  static const Color _attentionAccent = Color(0xFFD97706);
  static const Color _lockedAccent = Color(0xFF64748B);

  final NotificacaoService _notificacaoService = NotificacaoService();
  int _totalNotificacoesConhecidas = 0;
  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = widget.initialSectionIndex;
    _totalNotificacoesConhecidas = _notificacaoService.total;
    _notificacaoService.addListener(_onNotificacoesChanged);
    _garantirWebSocketMobile();
  }

  @override
  void dispose() {
    _notificacaoService.removeListener(_onNotificacoesChanged);
    super.dispose();
  }

  void _onNotificacoesChanged() {
    if (!mounted) return;

    final int totalAtual = _notificacaoService.total;
    final bool recebeuNovaNotificacao =
        totalAtual > _totalNotificacoesConhecidas;
    _totalNotificacoesConhecidas = totalAtual;

    setState(() {});

    if (!recebeuNovaNotificacao) return;

    final String? mensagem =
        _notificacaoService.ultimaNotificacao?.description.trim();
    if (mensagem == null || mensagem.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    });
  }

  void _garantirWebSocketMobile() {
    if (kIsWeb) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) connectStomp();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget shell = SixMobilePageShell(
      title: context.t('gestao.title', fallback: 'Gestão'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      automaticallyImplyLeading: false,
      leading: const SixMobileAppBarProfileAction(),
      actions: <Widget>[
        IconButton(
          tooltip: context.t(
            'gestao.settings.item.notifications.title',
            fallback: 'Notificações',
          ),
          icon: _buildNotificationIcon(),
          onPressed: () => _openNotifications(context),
        ),
      ],
      bodyBuilder: _buildContent,
      bottomNavigationBar:
          kIsWeb || !widget.showBottomNavigationBar
              ? null
              : const NavBarMobile(initialIndex: 0),
    );

    final ManagementOverviewProvider? injectedProvider =
        widget.overviewProvider;
    if (injectedProvider != null) {
      return ChangeNotifierProvider<ManagementOverviewProvider>.value(
        value: injectedProvider,
        child: shell,
      );
    }

    return ChangeNotifierProvider<ManagementOverviewProvider>(
      create: (_) => ManagementOverviewProvider()..load(),
      child: shell,
    );
  }

  Widget _buildNotificationIcon() {
    final int naoLidas = _notificacaoService.naoLidas;
    final bool temNaoLidas = naoLidas > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          temNaoLidas
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
        ),
        if (temNaoLidas)
          Positioned(
            right: -6,
            top: -6,
            child: SixPulsingBadge(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: SixMobilePalette.notificationBadge,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SixMobilePalette.onPrimary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _badgeText(naoLidas),
                  style: const TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final List<_ManagementSection> sections = _managementSections(context);
    final int selectedIndex =
        _selectedSectionIndex >= sections.length
            ? sections.length - 1
            : _selectedSectionIndex;
    final _ManagementSection selectedSection = sections[selectedIndex];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          0,
          topInset,
          0,
          _sectionContentBottomPadding,
        ),
        children: <Widget>[
          // Compact section selector
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 80),
            child: ManagementSectionSelector(
              sections: sections
                  .map(
                    (s) => ManagementSectionTab(
                      title: s.selectorTitle,
                      icon: s.icon,
                    ),
                  )
                  .toList(growable: false),
              selectedIndex: selectedIndex,
              onSectionSelected: (int index) {
                if (!mounted) return;
                setState(() => _selectedSectionIndex = index);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Section content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: SixStaggeredEntry(
              delay: const Duration(milliseconds: 180),
              child: _buildSmoothSectionTransition(
                context,
                transitionKey: 'section-${selectedSection.title}',
                child:
                    selectedSection.isSettingsCentral
                        ? _buildSettingsCentral(context, selectedSection)
                        : _buildStandardSectionDetails(
                          context,
                          selectedSection,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Settings Central (Configurações) ───────────────────────────

  Widget _buildSettingsCentral(
    BuildContext context,
    _ManagementSection section,
  ) {
    final String? companyName = _resolveCompanyName(context);

    return KeyedSubtree(
      key: const ValueKey<String>('management-area-settings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Admin header
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 60),
            child: ManagementAdminHeader(
              title: context.t(
                'gestao.settings.adminHeader.title',
                fallback: 'Configurações da empresa',
              ),
              subtitle: context.t(
                'gestao.settings.adminHeader.subtitle',
                fallback: 'Organize empresa, equipe, operação e comunicação.',
              ),
              companyName: companyName,
            ),
          ),
          const SizedBox(height: 20),

          // Settings groups
          ...section.settingsGroups!.asMap().entries.map((
            MapEntry<int, ManagementSettingsGroupData> entry,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < section.settingsGroups!.length - 1 ? 20 : 0,
              ),
              child: SixStaggeredEntry(
                delay: Duration(milliseconds: 120 + entry.key * 60),
                child: ManagementSettingsGroup(group: entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  String? _resolveCompanyName(BuildContext context) {
    try {
      final empresaProvider = context.watch<EmpresaProvider>();
      final empresa = empresaProvider.empresa;
      if (empresa == null) return null;
      final String nome =
          empresa.nomeFantasia.isNotEmpty
              ? empresa.nomeFantasia
              : empresa.nomeEmpresa;
      if (nome.trim().isEmpty) return null;
      return nome.trim();
    } catch (_) {
      return null;
    }
  }

  // ─── Standard section details (Catálogo, Pessoas, Financeiro) ───

  Widget _buildStandardSectionDetails(
    BuildContext context,
    _ManagementSection section,
  ) {
    final ManagementOverviewSnapshot snapshot =
        context.watch<ManagementOverviewProvider>().snapshot;
    final bool podeAcessarCatalogo =
        context.watch<ColaboradorAutorizacoesProvider>().podeAcessarCatalogo;
    final List<ManagementMetricData> metrics = _metricsForSection(
      context,
      section,
      snapshot,
      podeAcessarCatalogo: podeAcessarCatalogo,
    );
    final Widget? stateMessage = _stateMessageForSection(
      context,
      section,
      snapshot,
    );
    final Widget? contextualBlock = _contextualBlockForSection(
      context,
      section,
      snapshot,
      podeAcessarCatalogo: podeAcessarCatalogo,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            context.t('gestao.overview.generalTitle', fallback: 'Visão geral'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ManagementSummaryCard(
          key: ValueKey<String>('management-area-${section.type.name}'),
          title: _summaryTitleForSection(context, section),
          metrics: metrics,
          unavailableLabel: context.t(
            'gestao.overview.valueUnavailable',
            fallback: '--',
          ),
          variant: _summaryVariantForSection(section),
        ),
        if (stateMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          stateMessage,
        ],
        const SizedBox(height: 18),
        ManagementActionGroup(
          title: section.actionGroupTitle,
          items: _actionDataForSection(context, section),
        ),
        if (contextualBlock != null) ...<Widget>[
          const SizedBox(height: 14),
          contextualBlock,
        ],
      ],
    );
  }

  String _summaryTitleForSection(
    BuildContext context,
    _ManagementSection section,
  ) {
    return switch (section.type) {
      _ManagementSectionType.catalog => context.t(
        'gestao.catalog.summaryTitle',
        fallback: 'Resumo do catálogo',
      ),
      _ManagementSectionType.people => context.t(
        'gestao.people.summaryTitle',
        fallback: 'Resumo de pessoas',
      ),
      _ManagementSectionType.finance => context.t(
        'gestao.finance.summaryTitle',
        fallback: 'Resumo financeiro',
      ),
      _ManagementSectionType.settings => section.title,
    };
  }

  ManagementSummaryCardVariant _summaryVariantForSection(
    _ManagementSection section,
  ) {
    return switch (section.type) {
      _ManagementSectionType.catalog => ManagementSummaryCardVariant.catalog,
      _ManagementSectionType.people => ManagementSummaryCardVariant.people,
      _ManagementSectionType.finance => ManagementSummaryCardVariant.finance,
      _ManagementSectionType.settings => ManagementSummaryCardVariant.catalog,
    };
  }

  List<ManagementMetricData> _metricsForSection(
    BuildContext context,
    _ManagementSection section,
    ManagementOverviewSnapshot snapshot, {
    required bool podeAcessarCatalogo,
  }) {
    switch (section.type) {
      case _ManagementSectionType.catalog:
        final ManagementSectionLoadState<ManagementCatalogOverview> state =
            snapshot.catalog;
        final ManagementCatalogOverview? data = state.data;
        return <ManagementMetricData>[
          if (podeAcessarCatalogo)
            ManagementMetricData(
              id: 'catalog-products',
              label: context.t(
                'gestao.catalog.metric.products',
                fallback: 'Produtos',
              ),
              icon: Icons.shopping_bag_outlined,
              accentColor: _catalogAccent,
              value: data?.productServiceCount,
              loading: state.isLoading,
            ),
          ManagementMetricData(
            label: context.t(
              'gestao.catalog.metric.lowStock',
              fallback: 'Estoque baixo',
            ),
            id: 'catalog-low-stock',
            icon: Icons.warning_amber_rounded,
            accentColor: _attentionAccent,
            value: data?.lowStockItems,
            loading: state.isLoading,
            showAttentionDot: (data?.lowStockItems ?? 0) > 0,
            attentionSemanticLabel: context.t(
              'gestao.catalog.lowStockAlertSemantic',
              fallback: 'Indicador de atenção para estoque baixo',
            ),
          ),
          ManagementMetricData(
            id: 'catalog-categories',
            label: context.t(
              'gestao.catalog.metric.categories',
              fallback: 'Categorias',
            ),
            icon: Icons.category_outlined,
            accentColor: _peopleAccent,
            value: data?.categoryCount,
            loading: state.isLoading,
          ),
        ];
      case _ManagementSectionType.people:
        final ManagementSectionLoadState<ManagementPeopleOverview> state =
            snapshot.people;
        final ManagementPeopleOverview? data = state.data;
        return <ManagementMetricData>[
          ManagementMetricData(
            id: 'people-clients',
            label: context.t(
              'gestao.people.metric.clients',
              fallback: 'Clientes',
            ),
            icon: Icons.people_alt_outlined,
            accentColor: _catalogAccent,
            value: data?.clientCount,
            loading: state.isLoading,
          ),
          ManagementMetricData(
            id: 'people-collaborators',
            label: context.t(
              'gestao.people.metric.collaborators',
              fallback: 'Colaboradores',
            ),
            icon: Icons.badge_outlined,
            accentColor: _peopleAccent,
            value: data?.collaboratorCount,
            loading: state.isLoading,
          ),
          ManagementMetricData(
            id: 'people-suppliers',
            label: context.t(
              'gestao.people.metric.suppliers',
              fallback: 'Fornecedores',
            ),
            icon: Icons.local_shipping_outlined,
            accentColor: _lockedAccent,
            valueText: _maturityLabel(
              context,
              ManagementSettingsMaturity.comingSoon,
            ),
            semanticValue: context.t(
              'gestao.people.suppliersUnavailableSemantic',
              fallback: 'Recurso em breve',
            ),
          ),
        ];
      case _ManagementSectionType.finance:
        final ManagementSectionLoadState<ManagementFinanceOverview> state =
            snapshot.finance;
        final ManagementFinanceOverview? data = state.data;
        return <ManagementMetricData>[
          ManagementMetricData(
            id: 'finance-events',
            label: context.t(
              'gestao.finance.metric.events',
              fallback: 'Próximos eventos',
            ),
            icon: Icons.event_note_outlined,
            accentColor: _financeAccent,
            value: data?.totalEvents,
            loading: state.isLoading,
          ),
          ManagementMetricData(
            id: 'finance-receivable',
            label: context.t(
              'gestao.finance.metric.receivableEvents',
              fallback: 'A receber',
            ),
            icon: Icons.south_west_rounded,
            accentColor: _peopleAccent,
            value: data?.receivableEvents,
            loading: state.isLoading,
          ),
          ManagementMetricData(
            id: 'finance-payable',
            label: context.t(
              'gestao.finance.metric.payableEvents',
              fallback: 'A pagar',
            ),
            icon: Icons.north_east_rounded,
            accentColor: _attentionAccent,
            value: data?.payableEvents,
            loading: state.isLoading,
          ),
        ];
      case _ManagementSectionType.settings:
        return const <ManagementMetricData>[];
    }
  }

  Widget? _stateMessageForSection(
    BuildContext context,
    _ManagementSection section,
    ManagementOverviewSnapshot snapshot,
  ) {
    switch (section.type) {
      case _ManagementSectionType.catalog:
        return _stateMessage(
          context,
          snapshot.catalog,
          emptyTitleKey: 'gestao.catalog.emptyTitle',
          emptyTitleFallback: 'Catálogo sem dados para exibir',
          emptyMessageKey: 'gestao.catalog.emptyMessage',
          emptyMessageFallback:
              'Cadastre produtos, serviços ou categorias para preencher os indicadores.',
        );
      case _ManagementSectionType.people:
        return _stateMessage(
          context,
          snapshot.people,
          emptyTitleKey: 'gestao.people.emptyTitle',
          emptyTitleFallback: 'Nenhum contato carregado',
          emptyMessageKey: 'gestao.people.emptyMessage',
          emptyMessageFallback:
              'Clientes e colaboradores aparecerão aqui quando estiverem cadastrados.',
        );
      case _ManagementSectionType.finance:
        return _stateMessage(
          context,
          snapshot.finance,
          emptyTitleKey: 'gestao.finance.emptyTitle',
          emptyTitleFallback: 'Agenda sem lançamentos próximos',
          emptyMessageKey: 'gestao.finance.emptyMessage',
          emptyMessageFallback:
              'Abra a agenda financeira para criar previsões e acompanhar vencimentos.',
          actionLabel: context.t(
            'gestao.finance.openSchedule',
            fallback: 'Abrir agenda',
          ),
          onAction:
              () => _navigateTo(context, const AgendaFinanceiraMobileScreen()),
        );
      case _ManagementSectionType.settings:
        return null;
    }
  }

  Widget? _stateMessage<T>(
    BuildContext context,
    ManagementSectionLoadState<T> state, {
    required String emptyTitleKey,
    required String emptyTitleFallback,
    required String emptyMessageKey,
    required String emptyMessageFallback,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (state.isLoading || state.hasData) return null;

    if (state.hasError) {
      return ManagementOverviewStatusMessage(
        title: context.t(
          state.errorKey!,
          fallback: 'Não foi possível carregar os indicadores.',
        ),
        message: context.t(
          'gestao.overview.errorMessage',
          fallback:
              'As ações continuam disponíveis. Tente atualizar os dados em instantes.',
        ),
        icon: Icons.cloud_off_outlined,
        toneColor: SixMobilePalette.error,
        actionLabel: context.t('common.refresh', fallback: 'Atualizar'),
        onAction: () => context.read<ManagementOverviewProvider>().reload(),
      );
    }

    if (state.isEmpty) {
      return ManagementOverviewStatusMessage(
        title: context.t(emptyTitleKey, fallback: emptyTitleFallback),
        message: context.t(emptyMessageKey, fallback: emptyMessageFallback),
        icon: Icons.info_outline_rounded,
        toneColor: _lockedAccent,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }

    return null;
  }

  Widget? _contextualBlockForSection(
    BuildContext context,
    _ManagementSection section,
    ManagementOverviewSnapshot snapshot, {
    required bool podeAcessarCatalogo,
  }) {
    switch (section.type) {
      case _ManagementSectionType.catalog:
        if (!podeAcessarCatalogo) {
          return ManagementAttentionBlock(
            title: context.t(
              'gestao.catalog.permissionRestrictedTitle',
              fallback: 'Catálogo restrito para este usuário',
            ),
            message: context.t(
              'gestao.catalog.permissionRestrictedMessage',
              fallback:
                  'A ação de produtos e serviços respeita as permissões atuais.',
            ),
            icon: Icons.lock_outline_rounded,
            toneColor: _lockedAccent,
          );
        }

        final int lowStockItems = snapshot.catalog.data?.lowStockItems ?? 0;
        if (lowStockItems <= 0) return null;

        return ManagementAttentionBlock(
          title: context.t(
            'gestao.catalog.lowStockTitle',
            fallback: 'Estoque precisa de atenção',
          ),
          message: context
              .t(
                'gestao.catalog.lowStockMessage',
                fallback:
                    '{count} item(ns) abaixo do limite configurado no catálogo.',
              )
              .replaceAll('{count}', lowStockItems.toString()),
          icon: Icons.warning_amber_rounded,
          toneColor: _attentionAccent,
          actionLabel: context.t(
            'gestao.catalog.lowStockAction',
            fallback: 'Ver itens',
          ),
          onAction: () => _navigateTo(context, const EstoqueMobileScreen()),
        );
      case _ManagementSectionType.people:
        return ManagementAttentionBlock(
          title: context.t(
            'gestao.people.suppliersBlockedTitle',
            fallback: 'Fornecedores ainda não disponível',
          ),
          message: context.t(
            'gestao.people.suppliersBlockedMessage',
            fallback:
                'O recurso segue marcado como Em breve e não possui navegação mobile ativa.',
          ),
          icon: Icons.lock_outline_rounded,
          toneColor: _lockedAccent,
        );
      case _ManagementSectionType.finance:
        final int attentionEvents = snapshot.finance.data?.attentionEvents ?? 0;
        if (attentionEvents > 0) {
          return ManagementAttentionBlock(
            title: context.t(
              'gestao.finance.attentionTitle',
              fallback: 'Agenda com vencimentos próximos',
            ),
            message: context
                .t(
                  'gestao.finance.attentionMessage',
                  fallback:
                      '{count} evento(s) vencido(s) ou vencendo hoje na agenda.',
                )
                .replaceAll('{count}', attentionEvents.toString()),
            icon: Icons.event_busy_outlined,
            toneColor: _attentionAccent,
            actionLabel: context.t(
              'gestao.finance.openSchedule',
              fallback: 'Abrir agenda',
            ),
            onAction:
                () =>
                    _navigateTo(context, const AgendaFinanceiraMobileScreen()),
          );
        }
        return null;
      case _ManagementSectionType.settings:
        return null;
    }
  }

  List<ManagementActionItemData> _actionDataForSection(
    BuildContext context,
    _ManagementSection section,
  ) {
    return section.items
        .map((_ManagementItem item) {
          final String? statusLabel =
              item.maturity == ManagementSettingsMaturity.functional
                  ? null
                  : _maturityLabel(context, item.maturity);

          return ManagementActionItemData(
            title: item.title,
            subtitle: item.subtitle,
            icon: item.icon,
            accentColor: item.accentColor ?? section.accentColor,
            maturity: item.maturity,
            emphasis: item.emphasis,
            onTap: item.onTap,
            statusLabel: statusLabel,
            visualGroupId: item.visualGroupId,
            disabledHint:
                item.maturity == ManagementSettingsMaturity.comingSoon
                    ? statusLabel
                    : null,
          );
        })
        .toList(growable: false);
  }

  String _maturityLabel(
    BuildContext context,
    ManagementSettingsMaturity maturity,
  ) {
    return switch (maturity) {
      ManagementSettingsMaturity.experimental => context.t(
        'gestao.settings.badge.experimental',
        fallback: 'Experimental',
      ),
      ManagementSettingsMaturity.comingSoon => context.t(
        'gestao.settings.badge.comingSoon',
        fallback: 'Em breve',
      ),
      ManagementSettingsMaturity.functional => '',
    };
  }

  // ─── Transitions ────────────────────────────────────────────────

  Widget _buildSmoothSectionTransition(
    BuildContext context, {
    required String transitionKey,
    required Widget child,
  }) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return KeyedSubtree(key: ValueKey<String>(transitionKey), child: child);
    }

    return AnimatedSwitcher(
      duration: _sectionTransitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget transitionChild, Animation<double> animation) {
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: transitionChild,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<String>(transitionKey), child: child),
    );
  }

  // ─── Section definitions ────────────────────────────────────────

  List<_ManagementSection> _managementSections(BuildContext context) {
    final bool podeAcessarCatalogo =
        context.watch<ColaboradorAutorizacoesProvider>().podeAcessarCatalogo;

    return <_ManagementSection>[
      _ManagementSection(
        type: _ManagementSectionType.catalog,
        title: context.t('gestao.catalog.title', fallback: 'Catálogo'),
        selectorTitle: context.t('gestao.catalog.title', fallback: 'Catálogo'),
        subtitle: context.t(
          'gestao.catalog.subtitle',
          fallback: 'Produtos, categorias e estoque',
        ),
        icon: Icons.inventory_2_outlined,
        accentColor: _catalogAccent,
        actionGroupTitle:
            context
                .t('gestao.overview.mainActions', fallback: 'Ações principais')
                .toUpperCase(),
        items: <_ManagementItem>[
          if (podeAcessarCatalogo)
            _ManagementItem(
              title: context.t(
                'gestao.catalog.productsServices',
                fallback: 'Produtos e Serviços',
              ),
              subtitle: context.t(
                'gestao.catalog.productsServicesDesc',
                fallback: 'Saúde, cadastro e revisão do catálogo',
              ),
              icon: Icons.shopping_bag_outlined,
              accentColor: _catalogAccent,
              emphasis: ManagementActionEmphasis.primary,
              onTap:
                  () => _navigateTo(context, const CatalogHealthMobileScreen()),
            ),
          _ManagementItem(
            title: context.t(
              'gestao.catalog.categories',
              fallback: 'Categorias',
            ),
            subtitle: context.t(
              'gestao.catalog.categoriesDesc',
              fallback: 'Organização do catálogo',
            ),
            icon: Icons.category_outlined,
            accentColor: _peopleAccent,
            emphasis: ManagementActionEmphasis.secondary,
            onTap:
                () => _navigateTo(
                  context,
                  const CategoriasProdutosServicosMobileScreen(),
                ),
          ),
          _ManagementItem(
            title: context.t('gestao.catalog.inventory', fallback: 'Estoque'),
            subtitle: context.t(
              'gestao.catalog.inventoryDesc',
              fallback: 'Saldos, entradas e ajustes',
            ),
            icon: Icons.warehouse_outlined,
            accentColor: _attentionAccent,
            emphasis: ManagementActionEmphasis.operational,
            onTap: () => _navigateTo(context, const EstoqueMobileScreen()),
          ),
        ],
      ),
      _ManagementSection(
        type: _ManagementSectionType.people,
        title: context.t('gestao.people.title', fallback: 'Pessoas'),
        selectorTitle: context.t('gestao.people.title', fallback: 'Pessoas'),
        subtitle: context.t(
          'gestao.people.subtitle',
          fallback: 'Clientes, equipe e parceiros',
        ),
        icon: Icons.groups_2_outlined,
        accentColor: _peopleAccent,
        actionGroupTitle:
            context
                .t('gestao.overview.mainActions', fallback: 'Ações principais')
                .toUpperCase(),
        items: <_ManagementItem>[
          _ManagementItem(
            title: context.t('gestao.people.clients', fallback: 'Clientes'),
            subtitle: context.t(
              'gestao.people.clientsDesc',
              fallback: 'Base de atendimento e relacionamento',
            ),
            icon: Icons.people_alt_outlined,
            accentColor: _catalogAccent,
            emphasis: ManagementActionEmphasis.primary,
            onTap:
                () => _navigateTo(context, const ClientesUsuarioMobileScreen()),
          ),
          _ManagementItem(
            title: context.t(
              'gestao.people.collaborators',
              fallback: 'Colaboradores',
            ),
            subtitle: context.t(
              'gestao.people.collaboratorsDesc',
              fallback: 'Equipe, acessos e responsabilidades',
            ),
            icon: Icons.badge_outlined,
            accentColor: _peopleAccent,
            emphasis: ManagementActionEmphasis.secondary,
            onTap:
                () => _navigateTo(
                  context,
                  const ColaboradoresUsuarioMobileScreen(),
                ),
          ),
          _ManagementItem(
            title: context.t(
              'gestao.people.suppliers',
              fallback: 'Fornecedores',
            ),
            subtitle: context.t(
              'gestao.people.suppliersDesc',
              fallback: 'Parceiros e compras do comércio',
            ),
            icon: Icons.local_shipping_outlined,
            accentColor: _lockedAccent,
            emphasis: ManagementActionEmphasis.operational,
            maturity: ManagementSettingsMaturity.comingSoon,
          ),
        ],
      ),
      _ManagementSection(
        type: _ManagementSectionType.finance,
        title: context.t('gestao.finance.title', fallback: 'Financeiro'),
        selectorTitle: context.t(
          'gestao.finance.title',
          fallback: 'Financeiro',
        ),
        subtitle: context.t(
          'gestao.finance.subtitle',
          fallback: 'Contas, agenda e recebimentos',
        ),
        icon: Icons.account_balance_wallet_outlined,
        accentColor: _financeAccent,
        actionGroupTitle:
            context
                .t('gestao.finance.actionGroup', fallback: 'Agenda e recursos')
                .toUpperCase(),
        items: <_ManagementItem>[
          _ManagementItem(
            title: context.t(
              'gestao.finance.schedule',
              fallback: 'Agenda financeira',
            ),
            subtitle: context.t(
              'gestao.finance.scheduleDesc',
              fallback: 'Previsões, fiado e crediário',
            ),
            icon: Icons.event_note_outlined,
            accentColor: _financeAccent,
            emphasis: ManagementActionEmphasis.primary,
            onTap:
                () =>
                    _navigateTo(context, const AgendaFinanceiraMobileScreen()),
          ),
          _ManagementItem(
            title: context.t(
              'gestao.finance.receivable',
              fallback: 'Contas a receber',
            ),
            subtitle: context.t(
              'gestao.finance.receivableDesc',
              fallback: 'Recebíveis e cobranças em aberto',
            ),
            icon: Icons.south_west_rounded,
            accentColor: _peopleAccent,
            emphasis: ManagementActionEmphasis.secondary,
            maturity: ManagementSettingsMaturity.comingSoon,
            visualGroupId: 'finance-receivable-payable',
          ),
          _ManagementItem(
            title: context.t(
              'gestao.finance.payable',
              fallback: 'Contas a pagar',
            ),
            subtitle: context.t(
              'gestao.finance.payableDesc',
              fallback: 'Despesas e compromissos',
            ),
            icon: Icons.north_east_rounded,
            accentColor: _attentionAccent,
            emphasis: ManagementActionEmphasis.secondary,
            maturity: ManagementSettingsMaturity.comingSoon,
            visualGroupId: 'finance-receivable-payable',
          ),
          _ManagementItem(
            title: context.t(
              'gestao.finance.paymentMethods',
              fallback: 'Formas de recebimento',
            ),
            subtitle: context.t(
              'gestao.finance.paymentMethodsDesc',
              fallback: 'Dinheiro, cartão, Pix e outros meios',
            ),
            icon: Icons.payments_outlined,
            accentColor: _lockedAccent,
            emphasis: ManagementActionEmphasis.operational,
            maturity: ManagementSettingsMaturity.comingSoon,
          ),
        ],
      ),
      _ManagementSection(
        type: _ManagementSectionType.settings,
        title: context.t('gestao.settings.title', fallback: 'Configurações'),
        selectorTitle: context.t(
          'gestao.settings.selectorTitle',
          fallback: 'Geral',
        ),
        subtitle: context.t(
          'gestao.settings.subtitle',
          fallback: 'Empresa, idioma e integrações',
        ),
        icon: Icons.settings_outlined,
        accentColor: SixMobilePalette.primary,
        actionGroupTitle: '',
        isSettingsCentral: true,
        settingsGroups: _settingsGroups(context),
        items: const <_ManagementItem>[],
      ),
    ];
  }

  List<ManagementSettingsGroupData> _settingsGroups(BuildContext context) {
    return <ManagementSettingsGroupData>[
      // Empresa
      ManagementSettingsGroupData(
        title: context.t('gestao.settings.group.company', fallback: 'Empresa'),
        items: <ManagementSettingsItemData>[
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.company.title',
              fallback: 'Empresa',
            ),
            subtitle: context.t(
              'gestao.settings.item.company.subtitle',
              fallback: 'Dados cadastrais e identidade do comércio',
            ),
            icon: Icons.storefront_outlined,
            maturity: ManagementSettingsMaturity.functional,
            onTap:
                () => _navigateTo(context, const EmpresaConfiguracaoMobile()),
          ),
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.regionalization.title',
              fallback: 'Regionalização',
            ),
            subtitle: context.t(
              'gestao.settings.item.regionalization.subtitle',
              fallback: 'Idioma, moeda, país e formatos locais',
            ),
            icon: Icons.language_outlined,
            maturity: ManagementSettingsMaturity.functional,
            onTap:
                () => _navigateTo(context, const RegionalizacaoMobileScreen()),
          ),
        ],
      ),

      // Equipe e acesso
      ManagementSettingsGroupData(
        title: context.t(
          'gestao.settings.group.teamAccess',
          fallback: 'Equipe e acesso',
        ),
        items: <ManagementSettingsItemData>[
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.users.title',
              fallback: 'Usuários e permissões',
            ),
            subtitle: context.t(
              'gestao.settings.item.users.subtitle',
              fallback: 'Acessos, perfis e segurança da equipe',
            ),
            icon: Icons.admin_panel_settings_outlined,
            maturity: ManagementSettingsMaturity.comingSoon,
          ),
        ],
      ),

      // Operação
      ManagementSettingsGroupData(
        title: context.t(
          'gestao.settings.group.operation',
          fallback: 'Operação',
        ),
        items: <ManagementSettingsItemData>[
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.procedures.title',
              fallback: 'Procedimentos',
            ),
            subtitle: context.t(
              'gestao.settings.item.procedures.subtitle',
              fallback: 'Guias para vendas, atendimentos e entregas',
            ),
            icon: Icons.fact_check_outlined,
            maturity: ManagementSettingsMaturity.experimental,
            onTap:
                () => _navigateTo(
                  context,
                  const OperationalProceduresMobileScreen(),
                ),
          ),
        ],
      ),

      // Comunicação
      ManagementSettingsGroupData(
        title: context.t(
          'gestao.settings.group.communication',
          fallback: 'Comunicação',
        ),
        items: <ManagementSettingsItemData>[
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.notifications.title',
              fallback: 'Notificações',
            ),
            subtitle: context.t(
              'gestao.settings.item.notifications.subtitle',
              fallback: 'Eventos recebidos e alertas do sistema',
            ),
            icon: Icons.notifications_active_outlined,
            maturity: ManagementSettingsMaturity.functional,
            onTap: () => _openNotifications(context),
          ),
        ],
      ),

      // Documentos e integrações
      ManagementSettingsGroupData(
        title: context.t(
          'gestao.settings.group.docsIntegrations',
          fallback: 'Documentos e integrações',
        ),
        items: <ManagementSettingsItemData>[
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.pdfTemplates.title',
              fallback: 'Modelos de PDF',
            ),
            subtitle: context.t(
              'gestao.settings.item.pdfTemplates.subtitle',
              fallback: 'Orçamentos, OS, recibos e documentos',
            ),
            icon: Icons.picture_as_pdf_outlined,
            maturity: ManagementSettingsMaturity.comingSoon,
          ),
          ManagementSettingsItemData(
            title: context.t(
              'gestao.settings.item.integrations.title',
              fallback: 'Integrações',
            ),
            subtitle: context.t(
              'gestao.settings.item.integrations.subtitle',
              fallback: 'Serviços externos e automações',
            ),
            icon: Icons.hub_outlined,
            maturity: ManagementSettingsMaturity.comingSoon,
          ),
        ],
      ),
    ];
  }

  // ─── Helpers ────────────────────────────────────────────────────

  String _badgeText(int count) => count > 9 ? '+9' : count.toString();

  void _openNotifications(BuildContext context) {
    _navigateTo(context, const NotificacoesMobileScreen());
  }

  void _navigateTo(BuildContext context, Widget page) {
    final ManagementMobileNavigate? customNavigate = widget.onNavigate;
    if (customNavigate != null) {
      customNavigate(context, page);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (BuildContext context) => page),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────

enum _ManagementSectionType { catalog, people, finance, settings }

class _ManagementSection {
  const _ManagementSection({
    required this.type,
    required this.title,
    required this.selectorTitle,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.actionGroupTitle,
    required this.items,
    this.isSettingsCentral = false,
    this.settingsGroups,
  });

  final _ManagementSectionType type;
  final String title;
  final String selectorTitle;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String actionGroupTitle;
  final List<_ManagementItem> items;
  final bool isSettingsCentral;
  final List<ManagementSettingsGroupData>? settingsGroups;
}

class _ManagementItem {
  const _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.accentColor,
    this.emphasis = ManagementActionEmphasis.secondary,
    this.maturity = ManagementSettingsMaturity.functional,
    this.visualGroupId,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accentColor;
  final ManagementActionEmphasis emphasis;
  final ManagementSettingsMaturity maturity;
  final String? visualGroupId;
}
