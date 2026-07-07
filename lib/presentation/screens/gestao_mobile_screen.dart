import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/six_mobile_animated_gradient_background.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_mobile_screen.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_mobile_screen.dart';
import 'package:sixpos/presentation/screens/configuracoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/estoque_mobile_screen.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';

class GestaoMobileScreen extends StatefulWidget {
  const GestaoMobileScreen({super.key});

  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final NotificacaoService _notificacaoService = NotificacaoService();
  late final PageController _sectionCarouselController;
  int _totalNotificacoesConhecidas = 0;
  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _sectionCarouselController = PageController(viewportFraction: 0.86);
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Gestão',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notificações',
            icon: _buildNotificationIcon(),
            onPressed: () => _openNotifications(context),
          ),
        ],
      ),
      drawer: AppDrawerDoMobile(image: _image, onPickImage: _pickImage),
      body: SixMobileAnimatedGradientBackground(
        baseColor: _backgroundColor,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        accentColor: _accentColor,
        child: _buildContent(context),
      ),
      bottomNavigationBar:
          kIsWeb ? null : const CustomBottomNavBar(initialIndex: 0),
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
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  _badgeText(naoLidas),
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildContent(BuildContext context) {
    final List<_ManagementSection> sections = _managementSections(context);
    final int selectedIndex =
        _selectedSectionIndex >= sections.length
            ? sections.length - 1
            : _selectedSectionIndex;
    final _ManagementSection selectedSection = sections[selectedIndex];

    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 70),
            child: _buildManagementHeader(),
          ),
          const SizedBox(height: 18),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 130),
            child: _buildSectionCarousel(sections),
          ),
          const SizedBox(height: 12),
          _buildCarouselIndicators(sections),
          const SizedBox(height: 18),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 190),
            child: _buildSectionQuickActions(selectedSection),
          ),
          const SizedBox(height: 18),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 250),
            child: _buildSelectedSectionDetails(selectedSection),
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
                () => _navigateTo(
                  context,
                  const AgendaFinanceiraMobileScreen(),
                ),
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

  Widget _buildManagementHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(
              Icons.business_center_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Administração do negócio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Organize catálogo, pessoas, financeiro e configurações do comércio.',
                  style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCarousel(List<_ManagementSection> sections) {
    return SizedBox(
      height: 156,
      child: PageView.builder(
        controller: _sectionCarouselController,
        clipBehavior: Clip.none,
        itemCount: sections.length,
        onPageChanged: (int index) {
          setState(() => _selectedSectionIndex = index);
        },
        itemBuilder: (BuildContext context, int index) {
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

              final double distance = (currentPage - index).abs().clamp(
                0.0,
                1.0,
              );
              final double scale = 1 - (distance * 0.04);

              return Transform.scale(scale: scale, child: child);
            },
            child: _buildSectionCarouselCard(sections[index], index),
          );
        },
      ),
    );
  }

  Widget _buildSectionCarouselCard(_ManagementSection section, int index) {
    final bool isActive = index == _selectedSectionIndex;
    final Color iconBackground =
        isActive ? const Color(0x1AFFFFFF) : const Color(0xFFEFF6FF);
    final Color iconColor = isActive ? Colors.white : _accentColor;
    final Color titleColor = isActive ? Colors.white : _titleTextColor;
    final Color subtitleColor =
        isActive ? const Color(0xFFD7E3F5) : _mutedTextColor;
    final BoxBorder border = Border.all(
      color: isActive ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0),
    );

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isActive ? null : _surfaceColor,
        gradient:
            isActive
                ? const LinearGradient(
                  colors: <Color>[_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        borderRadius: BorderRadius.circular(26),
        border: border,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140B1F3A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color:
                        isActive
                            ? const Color(0x33FFFFFF)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(section.icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? const Color(0x17FFFFFF)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.items.length} atalhos',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            section.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtitleColor, fontSize: 12.5, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselIndicators(List<_ManagementSection> sections) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          sections.asMap().entries.map((MapEntry<int, _ManagementSection> entry) {
            final bool isActive = entry.key == _selectedSectionIndex;

            return GestureDetector(
              onTap: () {
                _sectionCarouselController.animateToPage(
                  entry.key,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? _accentColor : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }).toList(),
    );
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
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD4E0EE)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x0F0B1F3A),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                color: const Color(0xFFEFF6FF),
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
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
    this.shortTitle,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? shortTitle;

  String get compactTitle => shortTitle ?? _compactTitle(title);

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
