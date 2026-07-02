import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_list_page.dart';
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
  int _totalNotificacoesConhecidas = 0;

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
    if (!mounted) {
      return;
    }

    final int totalAtual = _notificacaoService.total;
    final bool recebeuNovaNotificacao =
        totalAtual > _totalNotificacoesConhecidas;
    _totalNotificacoesConhecidas = totalAtual;

    setState(() {});

    if (!recebeuNovaNotificacao) {
      return;
    }

    final String? mensagem =
        _notificacaoService.ultimaNotificacao?.description.trim();
    if (mensagem == null || mensagem.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    });
  }

  void _garantirWebSocketMobile() {
    if (kIsWeb) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) {
          connectStomp();
        }
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() {
        _image = File(selected.path);
      });
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            icon: _buildNotificationIcon(),
            onPressed: () => _openNotifications(context),
          ),
        ],
      ),
      drawer: AppDrawerDoMobile(
        image: _image,
        onPickImage: _pickImage,
      ),
      body: _buildContent(context),
      bottomNavigationBar:
          kIsWeb ? null : const CustomBottomNavBar(initialIndex: 0),
    );
  }

  Widget _buildNotificationIcon() {
    final int naoLidas = _notificacaoService.naoLidas;
    final bool temNaoLidas = naoLidas > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
    final List<_ManagementSection> sections = [
      _ManagementSection(
        title: 'Catálogo',
        icon: Icons.inventory_2_outlined,
        items: [
          _ManagementItem(
            title: 'Produtos',
            subtitle: 'Cadastro, preço e disponibilidade',
            icon: Icons.shopping_bag_outlined,
            onTap: () => _navigateTo(context, const ProdutolistMobileScreen()),
          ),
          _ManagementItem(
            title: 'Serviços',
            subtitle: 'Mão de obra e serviços técnicos',
            icon: Icons.design_services_outlined,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Categorias',
            subtitle: 'Organização do catálogo',
            icon: Icons.category_outlined,
            onTap: _showFeatureInProgress,
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
        icon: Icons.groups_2_outlined,
        items: [
          _ManagementItem(
            title: 'Clientes',
            subtitle: 'Base de atendimento e relacionamento',
            icon: Icons.people_alt_outlined,
            onTap: () => _navigateTo(context, const ClientesUsuarioListPage()),
          ),
          _ManagementItem(
            title: 'Colaboradores',
            subtitle: 'Equipe, acessos e responsabilidades',
            icon: Icons.badge_outlined,
            onTap: () => _navigateTo(context, const ColaboradoresUsuarioListPage()),
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
        icon: Icons.account_balance_wallet_outlined,
        items: [
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
            onTap: () => _navigateTo(context, const AgendaFinanceiraMobileScreen()),
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
        title: 'Relatórios',
        icon: Icons.analytics_outlined,
        items: [
          _ManagementItem(
            title: 'Vendas',
            subtitle: 'Resultados e histórico comercial',
            icon: Icons.bar_chart_rounded,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Assistências',
            subtitle: 'Ordens, prazos e produtividade',
            icon: Icons.handyman_outlined,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Caixa',
            subtitle: 'Aberturas, fechamentos e movimentações',
            icon: Icons.point_of_sale_outlined,
            onTap: _showFeatureInProgress,
          ),
          _ManagementItem(
            title: 'Financeiro',
            subtitle: 'Receitas, despesas e fluxo de caixa',
            icon: Icons.query_stats_rounded,
            onTap: _showFeatureInProgress,
          ),
        ],
      ),
      _ManagementSection(
        title: 'Configurações',
        icon: Icons.settings_outlined,
        items: [
          _ManagementItem(
            title: 'Empresa',
            subtitle: 'Dados do comércio e identidade',
            icon: Icons.storefront_outlined,
            onTap: () => _navigateTo(context, const ConfiguracoesMobileScreen()),
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
            onTap: _showFeatureInProgress,
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

    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 70),
            child: _buildManagementHeader(),
          ),
          const SizedBox(height: 22),
          ...sections.asMap().entries.map((entry) {
            final int delay = 130 + (entry.key * 65);
            return SixStaggeredEntry(
              delay: Duration(milliseconds: delay),
              child: _buildManagementSection(entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildManagementHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.business_center_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Organize cadastros, financeiro, relatórios e configurações do comércio.',
                  style: TextStyle(
                    color: Color(0xFFD7E3F5),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection(_ManagementSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              Text(
                section.title,
                style: const TextStyle(
                  color: _titleTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: section.items.asMap().entries.map((entry) {
                final int index = entry.key;
                final _ManagementItem item = entry.value;
                final bool isFirst = index == 0;
                final bool isLast = index == section.items.length - 1;

                return _buildManagementTile(
                  item,
                  isFirst: isFirst,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
          ),
          child: Row(
            children: [
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
                  children: [
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

  String _badgeText(int count) {
    if (count > 9) {
      return '+9';
    }

    return count.toString();
  }

  void _openNotifications(BuildContext context) {
    _navigateTo(context, const NotificacoesMobileScreen());
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => page),
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
    required this.icon,
    required this.items,
  });

  final String title;
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
}
