import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, listEquals, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/management/management_area_components.dart';
import 'package:sixpos/presentation/components/mobile/management/management_admin_header.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_group.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_rotating_intro_card.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_imagem_canetinha.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_app_bar_profile_action.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/navigation/mobile_navigation_controller.dart';
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
import 'package:sixpos/providers/usuario_provider.dart';

import '../components/nav_bar_mobile.dart';
import 'empresa_configuracao_mobile.dart';

typedef ManagementMobileNavigate =
    void Function(BuildContext context, Widget page);

enum GestaoMobileArea { catalogo, pessoas, financeiro, configuracoes }

class GestaoMobileScreen extends StatefulWidget {
  const GestaoMobileScreen({
    super.key,
    this.overviewProvider,
    this.onNavigate,
    this.area,
    @visibleForTesting this.showBottomNavigationBar = true,
  });

  final ManagementOverviewProvider? overviewProvider;
  final ManagementMobileNavigate? onNavigate;
  final GestaoMobileArea? area;
  final bool showBottomNavigationBar;

  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
  static const double _horizontalPadding = 16;
  static const double _sectionContentBottomPadding = 24;
  static const String _catalogAssetContorno =
      'assets/images/gestao mobile/acao-catalogo.webp';
  static const String _catalogAssetAcento =
      'assets/images/gestao mobile/acao-catalogo-acento.webp';
  static const String _peopleAssetContorno =
      'assets/images/gestao mobile/acao-pessoas.webp';
  static const String _peopleAssetAcento =
      'assets/images/gestao mobile/acao-pessoas-acento.webp';
  static const String _financeAssetContorno =
      'assets/images/gestao mobile/acao-financeiro.webp';
  static const String _financeAssetAcento =
      'assets/images/gestao mobile/acao-financeiro-acento.webp';
  static const String _settingsAssetContorno =
      'assets/images/gestao mobile/acao-configuracoes.webp';
  static const String _settingsAssetAcento =
      'assets/images/gestao mobile/acao-configuracoes-acento.webp';
  static const Color _peopleAccent = Color(0xFF059669);
  static const Color _financeAccent = Color(0xFF0891B2);
  static const Color _attentionAccent = Color(0xFFD97706);
  static const Color _lockedAccent = Color(0xFF64748B);

  final NotificacaoService _notificacaoService = NotificacaoService();
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  List<GestaoMobileCardPreferencia> _ordemCardsGestaoMobile =
      List<GestaoMobileCardPreferencia>.of(GestaoMobileCardPreferencia.values);
  bool _ordemAlteradaNestaSessao = false;
  int _totalNotificacoesConhecidas = 0;

  @override
  void initState() {
    super.initState();
    _totalNotificacoesConhecidas = _notificacaoService.total;
    final PreferenciasIndividuaisDoUsuarioModel? preferenciasAtuais =
        _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
    if (preferenciasAtuais != null) {
      _ordemCardsGestaoMobile = List<GestaoMobileCardPreferencia>.of(
        preferenciasAtuais.ordemCardsGestaoMobile,
      );
    }
    _notificacaoService.addListener(_onNotificacoesChanged);
    _usuarioProvider.addListener(_onUsuarioChanged);
    unawaited(_restaurarOrdemCardsGestaoMobile());
    _garantirWebSocketMobile();
  }

  @override
  void dispose() {
    _notificacaoService.removeListener(_onNotificacoesChanged);
    _usuarioProvider.removeListener(_onUsuarioChanged);
    super.dispose();
  }

  Future<void> _restaurarOrdemCardsGestaoMobile() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferenciasCache =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || _ordemAlteradaNestaSessao) return;

    final PreferenciasIndividuaisDoUsuarioModel? preferenciasRemotas =
        _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        preferenciasRemotas ?? preferenciasCache;
    if (preferencias == null) return;

    _aplicarOrdemCardsGestaoMobile(preferencias.ordemCardsGestaoMobile);
  }

  void _onUsuarioChanged() {
    if (!mounted || _ordemAlteradaNestaSessao) return;
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
    if (preferencias == null) return;
    _aplicarOrdemCardsGestaoMobile(preferencias.ordemCardsGestaoMobile);
  }

  void _aplicarOrdemCardsGestaoMobile(List<GestaoMobileCardPreferencia> ordem) {
    final List<GestaoMobileCardPreferencia> ordemNormalizada =
        GestaoMobileCardPreferenciaApi.normalizarOrdem(ordem);
    if (listEquals(_ordemCardsGestaoMobile, ordemNormalizada)) return;
    setState(() {
      _ordemCardsGestaoMobile = List<GestaoMobileCardPreferencia>.of(
        ordemNormalizada,
      );
    });
  }

  void _reordenarCardsGestaoMobile(
    GestaoMobileCardPreferencia movido,
    GestaoMobileCardPreferencia destino,
  ) {
    final int indiceOrigem = _ordemCardsGestaoMobile.indexOf(movido);
    final int indiceDestino = _ordemCardsGestaoMobile.indexOf(destino);
    if (indiceOrigem < 0 ||
        indiceDestino < 0 ||
        indiceOrigem == indiceDestino) {
      return;
    }

    final List<GestaoMobileCardPreferencia> novaOrdem =
        List<GestaoMobileCardPreferencia>.of(_ordemCardsGestaoMobile);
    novaOrdem.removeAt(indiceOrigem);
    final int indiceInsercao =
        indiceDestino > novaOrdem.length ? novaOrdem.length : indiceDestino;
    novaOrdem.insert(indiceInsercao, movido);

    setState(() {
      _ordemAlteradaNestaSessao = true;
      _ordemCardsGestaoMobile = novaOrdem;
    });
    unawaited(_salvarOrdemCardsGestaoMobile(novaOrdem));
  }

  Future<void> _salvarOrdemCardsGestaoMobile(
    List<GestaoMobileCardPreferencia> ordem,
  ) async {
    try {
      await _usuarioService.atualizarPreferenciasIndividuais(
        ordemCardsGestaoMobile: ordem
            .map((GestaoMobileCardPreferencia item) => item.codigo)
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao salvar ordem dos cards da Gestao Mobile: $error\n$stackTrace',
      );
    }
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
      Future<void>.delayed(Duration(milliseconds: 180), () {
        if (mounted) connectStomp();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final GestaoMobileArea? area = widget.area;
    final bool isHub = area == null;

    final Widget shell = SixMobilePageShell(
      title:
          isHub
              ? context.t('gestao.title', fallback: 'Gestão')
              : _areaTitle(context, area),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      automaticallyImplyLeading: !isHub,
      leading: isHub ? SixMobileAppBarProfileAction() : null,
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
      bodyBuilder: isHub ? _buildHubContent : _buildAreaContent,
      bottomNavigationBar:
          !isHub || kIsWeb || !widget.showBottomNavigationBar
              ? null
              : NavBarMobile(
                initialIndex: MobileNavigationController.managementIndex,
              ),
    );

    if (isHub || area == GestaoMobileArea.configuracoes) {
      return shell;
    }

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

  String _areaTitle(BuildContext context, GestaoMobileArea area) {
    return switch (area) {
      GestaoMobileArea.catalogo => context.t(
        'gestao.catalog.title',
        fallback: 'Catálogo',
      ),
      GestaoMobileArea.pessoas => context.t(
        'gestao.people.title',
        fallback: 'Pessoas',
      ),
      GestaoMobileArea.financeiro => context.t(
        'gestao.finance.title',
        fallback: 'Financeiro',
      ),
      GestaoMobileArea.configuracoes => context.t(
        'gestao.settings.title',
        fallback: 'Configurações',
      ),
    };
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
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                  style: TextStyle(
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

  Widget _buildHubContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final List<_GestaoHubActionData> actions = _hubActions(context);
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double cardHeight = 204 + ((textScale - 1).clamp(0.0, 0.8) * 72);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding,
          topInset + 10,
          _horizontalPadding,
          _sectionContentBottomPadding,
        ),
        children: <Widget>[
          SixStaggeredEntry(
            key: const ValueKey<String>('gestao-hub-intro'),
            delay: Duration(milliseconds: 40),
            child: _GestaoHubIntroCard(
              title: context.t(
                'gestao.hub.title',
                fallback: 'O que você quer gerenciar?',
              ),
              subtitles: <String>[
                context.t(
                  'gestao.hub.terminal.products',
                  fallback: 'Gerencie seus produtos e colaboradores',
                ),
                context.t(
                  'gestao.hub.terminal.finance',
                  fallback: 'Gerencie seu financeiro',
                ),
                context.t(
                  'gestao.hub.terminal.preferences',
                  fallback: 'Ajuste suas preferências e configurações',
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints gridConstraints) {
              const double gap = 12;
              final double itemWidth = (gridConstraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (int index = 0; index < actions.length; index += 1)
                    SizedBox(
                      width: itemWidth,
                      height: cardHeight,
                      child: _buildReorderableHubCard(
                        action: actions[index],
                        index: index,
                        itemWidth: itemWidth,
                        cardHeight: cardHeight,
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

  Widget _buildReorderableHubCard({
    required _GestaoHubActionData action,
    required int index,
    required double itemWidth,
    required double cardHeight,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Widget buildCard() {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _GestaoHubActionCard(data: action),
          Positioned(
            top: 8,
            right: 8,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: action.accentColor.withAlpha(isDark ? 150 : 112),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final Widget card = buildCard();

    return DragTarget<GestaoMobileCardPreferencia>(
      key: ValueKey<String>('gestao-hub-reorder-${action.id}'),
      onWillAcceptWithDetails:
          (DragTargetDetails<GestaoMobileCardPreferencia> details) =>
              details.data != action.preferencia,
      onAcceptWithDetails: (
        DragTargetDetails<GestaoMobileCardPreferencia> details,
      ) {
        _reordenarCardsGestaoMobile(details.data, action.preferencia);
      },
      builder: (
        BuildContext context,
        List<GestaoMobileCardPreferencia?> candidateData,
        List<dynamic> rejectedData,
      ) {
        final bool isDestino = candidateData.isNotEmpty;
        return AnimatedScale(
          scale: isDestino ? 1.025 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: LongPressDraggable<GestaoMobileCardPreferencia>(
            data: action.preferencia,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            maxSimultaneousDrags: 1,
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.025,
                child: SizedBox(
                  width: itemWidth,
                  height: cardHeight,
                  child: buildCard(),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.28, child: card),
            child: SixStaggeredEntry(
              delay: Duration(milliseconds: 90 + (index * 45)),
              child: card,
            ),
          ),
        );
      },
    );
  }

  List<_GestaoHubActionData> _hubActions(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color catalogAccent =
        isDark ? SixMobilePalette.brandCyan : SixMobilePalette.brandBlue;
    final Color peopleAccent =
        isDark
            ? Color.lerp(SixMobilePalette.brandViolet, colors.titleText, 0.34)!
            : SixMobilePalette.brandViolet;
    final Color financeAccent =
        isDark
            ? SixMobilePalette.brandCyan
            : Color.lerp(
              SixMobilePalette.brandCyan,
              SixMobilePalette.brandNavyDeep,
              0.48,
            )!;
    final Color settingsAccent = isDark ? colors.accent : colors.primary;

    final Map<GestaoMobileCardPreferencia, _GestaoHubActionData> actions =
        <GestaoMobileCardPreferencia, _GestaoHubActionData>{
          GestaoMobileCardPreferencia.catalogo: _GestaoHubActionData(
            preferencia: GestaoMobileCardPreferencia.catalogo,
            id: 'catalog',
            title: _areaTitle(context, GestaoMobileArea.catalogo),
            subtitle: context.t(
              'gestao.catalog.subtitle',
              fallback: 'Produtos, categorias e estoque',
            ),
            assetContorno: _catalogAssetContorno,
            assetAcento: _catalogAssetAcento,
            accentColor: catalogAccent,
            brandStart: SixMobilePalette.brandCyan,
            brandEnd: SixMobilePalette.brandBlue,
            onTap: () => _openArea(GestaoMobileArea.catalogo),
          ),
          GestaoMobileCardPreferencia.pessoas: _GestaoHubActionData(
            preferencia: GestaoMobileCardPreferencia.pessoas,
            id: 'people',
            title: _areaTitle(context, GestaoMobileArea.pessoas),
            subtitle: context.t(
              'gestao.people.subtitle',
              fallback: 'Clientes, equipe e parceiros',
            ),
            assetContorno: _peopleAssetContorno,
            assetAcento: _peopleAssetAcento,
            accentColor: peopleAccent,
            brandStart: SixMobilePalette.brandBlue,
            brandEnd: SixMobilePalette.brandViolet,
            onTap: () => _openArea(GestaoMobileArea.pessoas),
          ),
          GestaoMobileCardPreferencia.financeiro: _GestaoHubActionData(
            preferencia: GestaoMobileCardPreferencia.financeiro,
            id: 'finance',
            title: _areaTitle(context, GestaoMobileArea.financeiro),
            subtitle: context.t(
              'gestao.finance.subtitle',
              fallback: 'Contas, agenda e recebimentos',
            ),
            assetContorno: _financeAssetContorno,
            assetAcento: _financeAssetAcento,
            accentColor: financeAccent,
            brandStart: SixMobilePalette.brandCyan,
            brandEnd: SixMobilePalette.brandBlue,
            onTap: () => _openArea(GestaoMobileArea.financeiro),
          ),
          GestaoMobileCardPreferencia.configuracoes: _GestaoHubActionData(
            preferencia: GestaoMobileCardPreferencia.configuracoes,
            id: 'settings',
            title: _areaTitle(context, GestaoMobileArea.configuracoes),
            subtitle: context.t(
              'gestao.settings.subtitle',
              fallback: 'Empresa, idioma e integrações',
            ),
            assetContorno: _settingsAssetContorno,
            assetAcento: _settingsAssetAcento,
            accentColor: settingsAccent,
            brandStart: SixMobilePalette.brandBlue,
            brandEnd: SixMobilePalette.brandViolet,
            onTap: () => _openArea(GestaoMobileArea.configuracoes),
          ),
        };
    return _ordemCardsGestaoMobile
        .map((GestaoMobileCardPreferencia item) => actions[item]!)
        .toList(growable: false);
  }

  Widget _buildAreaContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final List<_ManagementSection> sections = _managementSections(context);
    final GestaoMobileArea area = widget.area!;
    final int selectedIndex = switch (area) {
      GestaoMobileArea.catalogo => 0,
      GestaoMobileArea.pessoas => 1,
      GestaoMobileArea.financeiro => 2,
      GestaoMobileArea.configuracoes => 3,
    };
    final _ManagementSection selectedSection = sections[selectedIndex];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding,
          topInset + 10,
          _horizontalPadding,
          _sectionContentBottomPadding,
        ),
        children: <Widget>[
          SixStaggeredEntry(
            delay: Duration(milliseconds: 80),
            child:
                selectedSection.isSettingsCentral
                    ? _buildSettingsCentral(context, selectedSection)
                    : _buildStandardSectionDetails(context, selectedSection),
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
      key: ValueKey<String>('management-area-settings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Admin header
          SixStaggeredEntry(
            delay: Duration(milliseconds: 60),
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
          SizedBox(height: 20),

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
          padding: EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            context.t('gestao.overview.generalTitle', fallback: 'Visão geral'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.sixMobileColors.titleText,
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
          SizedBox(height: 12),
          stateMessage,
        ],
        SizedBox(height: 18),
        ManagementActionGroup(
          title: section.actionGroupTitle,
          items: _actionDataForSection(context, section),
        ),
        if (contextualBlock != null) ...<Widget>[
          SizedBox(height: 14),
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
    final SixMobileColorScheme colors = context.sixMobileColors;

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
              accentColor: colors.accent,
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
            accentColor: colors.accent,
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
        return <ManagementMetricData>[];
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
          onAction: () => _navigateTo(context, AgendaFinanceiraMobileScreen()),
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
        return null;
      case _ManagementSectionType.people:
        return null;
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
                () => _navigateTo(context, AgendaFinanceiraMobileScreen()),
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
              item.statusLabel ??
              (item.maturity == ManagementSettingsMaturity.functional
                  ? null
                  : _maturityLabel(context, item.maturity));

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

  // ─── Section definitions ────────────────────────────────────────

  List<_ManagementSection> _managementSections(BuildContext context) {
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.watch<ColaboradorAutorizacoesProvider>();
    final bool podeAcessarCatalogo = autorizacoes.podeAcessarCatalogo;
    final SixMobileColorScheme colors = context.sixMobileColors;

    return <_ManagementSection>[
      _ManagementSection(
        type: _ManagementSectionType.catalog,
        title: context.t('gestao.catalog.title', fallback: 'Catálogo'),
        accentColor: colors.accent,
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
              accentColor: colors.accent,
              emphasis: ManagementActionEmphasis.secondary,
              onTap: () => _navigateTo(context, CatalogHealthMobileScreen()),
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
                  CategoriasProdutosServicosMobileScreen(),
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
            onTap: () => _navigateTo(context, EstoqueMobileScreen()),
          ),
          _ManagementItem(
            title: context.t(
              'gestao.catalog.webCatalog',
              fallback: 'Catálogo web',
            ),
            subtitle: context.t(
              'gestao.catalog.webCatalogDesc',
              fallback: 'Experiência completa do catálogo no navegador',
            ),
            icon: Icons.language_outlined,
            accentColor: _lockedAccent,
            emphasis: ManagementActionEmphasis.secondary,
            maturity: ManagementSettingsMaturity.comingSoon,
            statusLabel: context.t(
              'gestao.catalog.webCatalogBadge',
              fallback: 'WEB',
            ),
          ),
        ],
      ),
      _ManagementSection(
        type: _ManagementSectionType.people,
        title: context.t('gestao.people.title', fallback: 'Pessoas'),
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
            accentColor: colors.accent,
            emphasis: ManagementActionEmphasis.secondary,
            onTap: () => _navigateTo(context, ClientesUsuarioMobileScreen()),
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
                () => _navigateTo(context, ColaboradoresUsuarioMobileScreen()),
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
            onTap: () => _navigateTo(context, AgendaFinanceiraMobileScreen()),
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
        accentColor: colors.primary,
        actionGroupTitle: '',
        isSettingsCentral: true,
        settingsGroups: _settingsGroups(context),
        items: <_ManagementItem>[],
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
            onTap: () => _navigateTo(context, EmpresaConfiguracaoMobile()),
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
            onTap: () => _navigateTo(context, RegionalizacaoMobileScreen()),
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
              fallback: 'Guias para vendas, atendimentos técnicos e caixa',
            ),
            icon: Icons.fact_check_outlined,
            maturity: ManagementSettingsMaturity.functional,
            onTap:
                () => _navigateTo(context, OperationalProceduresMobileScreen()),
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

  void _openArea(GestaoMobileArea area) {
    _navigateTo(
      context,
      GestaoMobileScreen(
        area: area,
        overviewProvider: widget.overviewProvider,
        onNavigate: widget.onNavigate,
        showBottomNavigationBar: false,
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    _navigateTo(context, NotificacoesMobileScreen());
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

class _GestaoHubIntroCard extends StatelessWidget {
  const _GestaoHubIntroCard({required this.title, required this.subtitles});

  final String title;
  final List<String> subtitles;

  @override
  Widget build(BuildContext context) {
    return SixMobileRotatingIntroCard(
      title: title,
      subtitles: subtitles,
      markChild: const _GestaoHubMark(),
    );
  }
}

class _GestaoHubMark extends StatelessWidget {
  const _GestaoHubMark();

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return SizedBox(
      width: 36,
      height: 36,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (int index = 0; index < 4; index += 1)
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color:
                    index == 0 || index == 3 ? colors.accent : colors.titleText,
                borderRadius: BorderRadius.circular(index == 0 ? 5 : 4),
              ),
            ),
        ],
      ),
    );
  }
}

class _GestaoHubActionCard extends StatelessWidget {
  const _GestaoHubActionCard({required this.data});

  final _GestaoHubActionData data;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: '${data.title}. ${data.subtitle}',
      child: Container(
        key: ValueKey<String>('gestao-hub-card-${data.id}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: data.brandEnd.withAlpha(isDark ? 30 : 17),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    data.brandStart.withAlpha(isDark ? 28 : 14),
                    colors.surface,
                  ),
                  Color.alphaBlend(
                    data.brandEnd.withAlpha(isDark ? 20 : 8),
                    colors.surface,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: data.accentColor.withAlpha(isDark ? 82 : 54),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: data.onTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 11, 10, 10),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                data.brandStart.withAlpha(isDark ? 92 : 54),
                                data.brandEnd.withAlpha(isDark ? 58 : 34),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: data.accentColor.withAlpha(
                                isDark ? 108 : 82,
                              ),
                            ),
                            boxShadow:
                                isDark
                                    ? <BoxShadow>[
                                      BoxShadow(
                                        color: data.brandStart.withAlpha(64),
                                        blurRadius: 20,
                                      ),
                                    ]
                                    : const <BoxShadow>[],
                          ),
                          child: Center(
                            child: SixImagemCanetinha(
                              assetContorno: data.assetContorno,
                              assetAcento: data.assetAcento,
                              largura: 88,
                              altura: 88,
                              fit: BoxFit.contain,
                              corContorno: colors.titleText,
                              corAcento: data.accentColor,
                              gradienteContorno: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  Color.lerp(
                                    data.brandStart,
                                    colors.titleText,
                                    isDark ? 0.28 : 0.08,
                                  )!,
                                  Color.lerp(
                                    data.brandEnd,
                                    colors.titleText,
                                    isDark ? 0.48 : 0.20,
                                  )!,
                                ],
                              ),
                              gradienteAcento: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  data.accentColor,
                                  data.brandEnd,
                                ],
                              ),
                              reforcoContorno: 0.58,
                              reforcoAcento: 0.72,
                              opacidadeReforco: isDark ? 0.52 : 0.42,
                              opacidadeBrilho: isDark ? 0.48 : 0.16,
                              desfoqueBrilho: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: data.accentColor,
                        fontSize: 14.5,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 10.7,
                        height: 1.16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    ExcludeSemantics(
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: data.accentColor.withAlpha(isDark ? 34 : 20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: data.accentColor.withAlpha(isDark ? 74 : 48),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: data.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GestaoHubActionData {
  const _GestaoHubActionData({
    required this.preferencia,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetContorno,
    required this.assetAcento,
    required this.accentColor,
    required this.brandStart,
    required this.brandEnd,
    required this.onTap,
  });

  final GestaoMobileCardPreferencia preferencia;
  final String id;
  final String title;
  final String subtitle;
  final String assetContorno;
  final String assetAcento;
  final Color accentColor;
  final Color brandStart;
  final Color brandEnd;
  final VoidCallback onTap;
}

// ─── Data classes ─────────────────────────────────────────────────

enum _ManagementSectionType { catalog, people, finance, settings }

class _ManagementSection {
  const _ManagementSection({
    required this.type,
    required this.title,
    required this.accentColor,
    required this.actionGroupTitle,
    required this.items,
    this.isSettingsCentral = false,
    this.settingsGroups,
  });

  final _ManagementSectionType type;
  final String title;
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
    this.statusLabel,
    this.visualGroupId,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accentColor;
  final ManagementActionEmphasis emphasis;
  final ManagementSettingsMaturity maturity;
  final String? statusLabel;
  final String? visualGroupId;
}
