import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/management/management_admin_header.dart';
import 'package:sixpos/presentation/components/mobile/management/management_section_selector.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_group.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_account_panel_action.dart';
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

import '../components/nav_bar_mobile.dart';
import 'empresa_configuracao_mobile.dart';

class GestaoMobileScreen extends StatefulWidget {
  const GestaoMobileScreen({super.key});

  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
  static const double _horizontalPadding = 16;
  static const double _sectionContentBottomPadding = 24;
  static const Duration _sectionTransitionDuration = Duration(
    milliseconds: 380,
  );

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final NotificacaoService _notificacaoService = NotificacaoService();
  int _totalNotificacoesConhecidas = 0;
  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() => _image = File(selected.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: context.t('gestao.title', fallback: 'Gestão'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      automaticallyImplyLeading: false,
      actions: <Widget>[
        SixMobileAccountPanelAction(image: _image, onPickImage: _pickImage),
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
      bottomNavigationBar: kIsWeb ? null : const NavBarMobile(initialIndex: 0),
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
                    (s) => ManagementSectionTab(title: s.title, icon: s.icon),
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
                transitionKey: 'section-${selectedSection.title}',
                child:
                    selectedSection.isSettingsCentral
                        ? _buildSettingsCentral(context, selectedSection)
                        : _buildStandardSectionDetails(selectedSection),
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

    return Column(
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

  Widget _buildStandardSectionDetails(_ManagementSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.icon,
                color: SixMobilePalette.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SixMobilePalette.titleText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SixMobilePalette.border, width: 0.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children:
                section.items.asMap().entries.map((
                  MapEntry<int, _ManagementItem> entry,
                ) {
                  final int index = entry.key;
                  return _buildManagementTile(
                    entry.value,
                    isFirst: index == 0,
                    isLast: index == section.items.length - 1,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementTile(
    _ManagementItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final bool isDisabled =
        item.maturity == ManagementSettingsMaturity.comingSoon;
    final double opacity = isDisabled ? 0.52 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isFirst ? 20 : 0),
            bottom: Radius.circular(isLast ? 20 : 0),
          ),
          onTap: isDisabled ? null : item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border:
                  isLast
                      ? null
                      : const Border(
                        bottom: BorderSide(
                          color: SixMobilePalette.border,
                          width: 0.5,
                        ),
                      ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softNeutralSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    item.icon,
                    color: SixMobilePalette.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isDisabled
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: SixMobilePalette.mutedText,
                  size: isDisabled ? 16 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Transitions ────────────────────────────────────────────────

  Widget _buildSmoothSectionTransition({
    required String transitionKey,
    required Widget child,
  }) {
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
        title: context.t('gestao.catalog.title', fallback: 'Catálogo'),
        icon: Icons.inventory_2_outlined,
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
            onTap: () => _navigateTo(context, const EstoqueMobileScreen()),
          ),
        ],
      ),
      _ManagementSection(
        title: context.t('gestao.people.title', fallback: 'Pessoas'),
        icon: Icons.groups_2_outlined,
        items: <_ManagementItem>[
          _ManagementItem(
            title: context.t('gestao.people.clients', fallback: 'Clientes'),
            subtitle: context.t(
              'gestao.people.clientsDesc',
              fallback: 'Base de atendimento e relacionamento',
            ),
            icon: Icons.people_alt_outlined,
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
            maturity: ManagementSettingsMaturity.comingSoon,
            onTap: _showFeatureInProgress,
          ),
        ],
      ),
      _ManagementSection(
        title: context.t('gestao.finance.title', fallback: 'Financeiro'),
        icon: Icons.account_balance_wallet_outlined,
        items: <_ManagementItem>[
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
            maturity: ManagementSettingsMaturity.comingSoon,
            onTap: _showFeatureInProgress,
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
            maturity: ManagementSettingsMaturity.comingSoon,
            onTap: _showFeatureInProgress,
          ),
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
            onTap:
                () =>
                    _navigateTo(context, const AgendaFinanceiraMobileScreen()),
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
            maturity: ManagementSettingsMaturity.comingSoon,
            onTap: _showFeatureInProgress,
          ),
        ],
      ),
      _ManagementSection(
        title: context.t('gestao.settings.title', fallback: 'Configurações'),
        icon: Icons.settings_outlined,
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
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (BuildContext context) => page),
    );
  }

  void _showFeatureInProgress() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            'gestao.featureInProgress',
            fallback: 'Fluxo mobile em evolução.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────

class _ManagementSection {
  const _ManagementSection({
    required this.title,
    required this.icon,
    required this.items,
    this.isSettingsCentral = false,
    this.settingsGroups,
  });

  final String title;
  final IconData icon;
  final List<_ManagementItem> items;
  final bool isSettingsCentral;
  final List<ManagementSettingsGroupData>? settingsGroups;
}

class _ManagementItem {
  const _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.maturity = ManagementSettingsMaturity.functional,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final ManagementSettingsMaturity maturity;
}
