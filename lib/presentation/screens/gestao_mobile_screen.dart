import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_card_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_carousel.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_mobile_screen.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_mobile_screen.dart';
import 'package:sixpos/presentation/screens/configuracoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/estoque_mobile_screen.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';

import '../components/nav_bar_mobile.dart';
import '../components/cores_do_mobile.dart';

class GestaoMobileScreen extends StatefulWidget {
  const GestaoMobileScreen({super.key});

  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
  static const double _sectionCarouselViewportFraction = 0.92;
  static const String _managementParallaxAssetBasePath =
      'assets/images/management/parallax/';
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final NotificacaoService _notificacaoService = NotificacaoService();
  late final PageController _sectionCarouselController;
  int _totalNotificacoesConhecidas = 0;
  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _sectionCarouselController = PageController(
      viewportFraction: _sectionCarouselViewportFraction,
    );
    _totalNotificacoesConhecidas = _notificacaoService.total;
    _notificacaoService.addListener(_onNotificacoesChanged);
    _garantirWebSocketMobile();
  }

  @override
  void dispose() {
    _sectionCarouselController.dispose();
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
      title: 'Gestão',
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      drawer: CoresDoMobile(image: _image, onPickImage: _pickImage),
      actions: <Widget>[
        IconButton(
          tooltip: 'Notificações',
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
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final int selectedIndex =
        _selectedSectionIndex >= sections.length
            ? sections.length - 1
            : _selectedSectionIndex;
    final _ManagementSection selectedSection = sections[selectedIndex];

    return SafeArea(
      top: false,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
        children: <Widget>[
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 130),
            child: _buildSectionCarousel(sections, reduceMotion: reduceMotion),
          ),
          const SizedBox(height: 12),
          _buildCarouselIndicators(sections),
          const SizedBox(height: 18),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 190),
            child: _buildSmoothSectionTransition(
              transitionKey: 'quick-${selectedSection.title}',
              child: _buildSectionQuickActions(selectedSection),
            ),
          ),
          const SizedBox(height: 18),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 250),
            child: _buildSmoothSectionTransition(
              transitionKey: 'details-${selectedSection.title}',
              horizontalOffset: 0,
              verticalOffset: 0.035,
              duration: const Duration(milliseconds: 420),
              child: _buildSelectedSectionDetails(selectedSection),
            ),
          ),
        ],
      ),
    );
  }

  List<_ManagementSection> _managementSections(BuildContext context) {
    return <_ManagementSection>[
      _ManagementSection(
        title: 'Catálogo',
        subtitle: 'Produtos, categorias e estoque sempre à mão.',
        icon: Icons.inventory_2_outlined,
        items: <_ManagementItem>[
          _ManagementItem(
            title: 'Produtos e Serviços',
            subtitle: 'Cadastro, preço, disponibilidade e serviços técnicos',
            icon: Icons.shopping_bag_outlined,
            onTap: () => _navigateTo(context, const ProdutolistMobileScreen()),
          ),
          _ManagementItem(
            title: 'Categorias',
            subtitle: 'Organização do catálogo',
            icon: Icons.category_outlined,
            onTap:
                () => _navigateTo(
                  context,
                  const CategoriasProdutosServicosMobileScreen(),
                ),
          ),
          _ManagementItem(
            title: 'Estoque',
            subtitle: 'Saldos, entradas e ajustes',
            icon: Icons.warehouse_outlined,
            onTap: () => _navigateTo(context, const EstoqueMobileScreen()),
          ),
        ],
      ),
      _ManagementSection(
        title: 'Pessoas',
        subtitle: 'Clientes, equipe e parceiros do comércio.',
        icon: Icons.groups_2_outlined,
        items: <_ManagementItem>[
          _ManagementItem(
            title: 'Clientes',
            subtitle: 'Base de atendimento e relacionamento',
            icon: Icons.people_alt_outlined,
            onTap:
                () => _navigateTo(context, const ClientesUsuarioMobileScreen()),
          ),
          _ManagementItem(
            title: 'Colaboradores',
            subtitle: 'Equipe, acessos e responsabilidades',
            icon: Icons.badge_outlined,
            onTap:
                () => _navigateTo(
                  context,
                  const ColaboradoresUsuarioMobileScreen(),
                ),
          ),
          _ManagementItem(
            title: 'Fornecedores',
            subtitle: 'Parceiros e compras do comércio',
            icon: Icons.local_shipping_outlined,
            onTap: _showFeatureInProgress,
          ),
        ],
      ),
      _ManagementSection(
        title: 'Financeiro',
        subtitle: 'Contas, agenda e formas de recebimento.',
        icon: Icons.account_balance_wallet_outlined,
        items: <_ManagementItem>[
          _ManagementItem(
            title: 'Contas a receber',
            subtitle: 'Recebíveis e cobranças em aberto',
            icon: Icons.south_west_rounded,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Contas a pagar',
            subtitle: 'Despesas e compromissos',
            icon: Icons.north_east_rounded,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Agenda financeira',
            subtitle: 'Previsões, fiado e crediário',
            icon: Icons.event_note_outlined,
            onTap:
                () =>
                    _navigateTo(context, const AgendaFinanceiraMobileScreen()),
          ),
          _ManagementItem(
            title: 'Formas de recebimento',
            subtitle: 'Dinheiro, cartão, Pix e outros meios',
            icon: Icons.payments_outlined,
            onTap: _showFeatureInProgress,
          ),
        ],
      ),
      _ManagementSection(
        title: 'Configurações',
        subtitle: 'Empresa, idioma, notificações e integrações.',
        icon: Icons.settings_outlined,
        items: <_ManagementItem>[
          _ManagementItem(
            title: 'Empresa',
            subtitle: 'Dados do comércio e identidade',
            icon: Icons.storefront_outlined,
            onTap:
                () => _navigateTo(context, const ConfiguracoesMobileScreen()),
          ),
          _ManagementItem(
            title: 'Usuários e permissões',
            subtitle: 'Acessos por perfil e colaborador',
            icon: Icons.admin_panel_settings_outlined,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Regionalização',
            subtitle: 'Idioma, moeda e formato local',
            icon: Icons.language_outlined,
            onTap:
                () => _navigateTo(context, const RegionalizacaoMobileScreen()),
          ),
          _ManagementItem(
            title: 'Notificações',
            subtitle: 'Eventos do backend, webhooks e canais',
            icon: Icons.notifications_active_outlined,
            onTap: () => _openNotifications(context),
          ),
          _ManagementItem(
            title: 'Modelos de PDF',
            subtitle: 'Comprovantes, relatórios e OS',
            icon: Icons.picture_as_pdf_outlined,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Integrações',
            subtitle: 'Serviços externos e automações',
            icon: Icons.hub_outlined,
            onTap: _showFeatureInProgress,
          ),
        ],
      ),
    ];
  }

  Widget _buildSectionCarousel(
    List<_ManagementSection> sections, {
    required bool reduceMotion,
  }) {
    return ManagementParallaxCarousel(
      controller: _sectionCarouselController,
      cards: _managementCarouselCards(sections),
      selectedIndex: _selectedSectionIndex,
      viewportFraction: _sectionCarouselViewportFraction,
      reduceMotion: reduceMotion,
      onPageChanged: (int index) {
        if (!mounted) return;
        setState(() => _selectedSectionIndex = index);
      },
    );
  }

  Widget _buildCarouselIndicators(List<_ManagementSection> sections) {
    return AnimatedBuilder(
      animation: _sectionCarouselController,
      builder: (BuildContext context, Widget? child) {
        double currentPage = _selectedSectionIndex.toDouble();

        if (_sectionCarouselController.hasClients &&
            _sectionCarouselController.position.haveDimensions) {
          currentPage =
              _sectionCarouselController.page ??
              _selectedSectionIndex.toDouble();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              sections.asMap().entries.map((
                MapEntry<int, _ManagementSection> entry,
              ) {
                final double distance =
                    (currentPage - entry.key).abs().clamp(0.0, 1.0).toDouble();
                final double activeStrength =
                    1 - Curves.easeOutCubic.transform(distance);
                final double width = lerpDouble(7, 18, activeStrength)!;
                final Color color =
                    Color.lerp(
                      const Color(0xFFCBD5E1),
                      _accentColor,
                      activeStrength,
                    )!;

                return GestureDetector(
                  onTap: () {
                    _sectionCarouselController.animateToPage(
                      entry.key,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: width,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  List<ManagementParallaxCardData> _managementCarouselCards(
    List<_ManagementSection> sections,
  ) {
    return sections
        .map((section) {
          final String id = _carouselCardId(section.title);
          return ManagementParallaxCardData(
            id: id,
            title: section.title,
            subtitle: section.subtitle,
            badgeText: '${section.items.length} atalhos',
            icon: section.icon,
            imageAssetPath: _carouselImagePathForCard(id),
            fallbackGradient: _carouselFallbackGradientForCard(id),
          );
        })
        .toList(growable: false);
  }

  String _carouselCardId(String title) {
    switch (title) {
      case 'Catálogo':
        return 'catalog';
      case 'Pessoas':
        return 'people';
      case 'Financeiro':
        return 'finance';
      case 'Configurações':
        return 'settings';
      default:
        return title.toLowerCase().replaceAll(' ', '_');
    }
  }

  String _carouselImagePathForCard(String id) {
    switch (id) {
      case 'catalog':
        return '${_managementParallaxAssetBasePath}management_catalog.webp';
      case 'people':
        return '${_managementParallaxAssetBasePath}management_people.webp';
      case 'finance':
        return '${_managementParallaxAssetBasePath}management_finance.webp';
      case 'settings':
      default:
        return '${_managementParallaxAssetBasePath}management_settings.webp';
    }
  }

  Gradient _carouselFallbackGradientForCard(String id) {
    switch (id) {
      case 'catalog':
        return const LinearGradient(
          colors: <Color>[Color(0xFF0E7490), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'people':
        return const LinearGradient(
          colors: <Color>[Color(0xFF0F766E), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'finance':
        return const LinearGradient(
          colors: <Color>[Color(0xFF166534), Color(0xFF0C4A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'settings':
      default:
        return const LinearGradient(
          colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Widget _buildSectionQuickActions(_ManagementSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Acesso rápido',
          style: TextStyle(
            color: _titleTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children:
                section.items.map((_ManagementItem item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _buildQuickActionButton(item),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(_ManagementItem item) {
    return SizedBox(
      width: 78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.border,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD4E0EE)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: SixMobilePalette.navigationShadow,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: _primaryColor, size: 25),
                ),
                const SizedBox(height: 8),
                Text(
                  item.compactTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSectionDetails(_ManagementSection section) {
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
              child: Icon(section.icon, color: _accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _titleTextColor,
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
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SixMobilePalette.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
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

  Widget _buildSmoothSectionTransition({
    required String transitionKey,
    required Widget child,
    double horizontalOffset = 0.03,
    double verticalOffset = 0.025,
    Duration duration = const Duration(milliseconds: 360),
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget transitionChild, Animation<double> animation) {
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: Offset(horizontalOffset, verticalOffset),
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

  Widget _buildManagementTile(
    _ManagementItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isFirst ? 22 : 0),
          bottom: Radius.circular(isLast ? 22 : 0),
        ),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border:
                isLast
                    ? null
                    : const Border(
                      bottom: BorderSide(color: SixMobilePalette.border),
                    ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SixMobilePalette.softNeutralSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: _primaryColor, size: 21),
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
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

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
      const SnackBar(
        content: Text('Fluxo mobile em evolução.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ManagementSection {
  const _ManagementSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_ManagementItem> items;
}

class _ManagementItem {
  const _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  String get compactTitle => _compactTitle(title);

  String _compactTitle(String value) {
    switch (value) {
      case 'Produtos e Serviços':
        return 'Produtos';
      case 'Contas a receber':
        return 'Receber';
      case 'Contas a pagar':
        return 'Pagar';
      case 'Agenda financeira':
        return 'Agenda';
      case 'Formas de recebimento':
        return 'Receber';
      case 'Usuários e permissões':
        return 'Usuários';
      case 'Modelos de PDF':
        return 'PDF';
      default:
        return value;
    }
  }
}
