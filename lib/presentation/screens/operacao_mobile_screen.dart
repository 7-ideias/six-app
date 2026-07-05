import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/tela_inicial_models.dart';
import 'package:sixpos/data/services/telainicial_web/tela_inicial_api_client.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_web_page.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart';
import 'package:sixpos/presentation/screens/vendas_nao_liquidadas_mobile_screen.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';

class OperacaoMobileScreen extends StatefulWidget {
  const OperacaoMobileScreen({super.key});

  @override
  State<OperacaoMobileScreen> createState() => _OperacaoMobileScreenState();
}

class _OperacaoMobileScreenState extends State<OperacaoMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TelaInicialWebApiClient _telaInicialApiClient =
      HttpResumoDaEmpresaApiClient(canal: 'mobile');
  final NotificacaoService _notificacaoService = NotificacaoService();

  TelaInicialModel? _resumoTelaInicial;
  bool _carregandoResumo = true;
  String? _erroResumo;
  int _totalNotificacoesConhecidas = 0;

  @override
  void initState() {
    super.initState();
    _totalNotificacoesConhecidas = _notificacaoService.total;
    _notificacaoService.addListener(_onNotificacoesChanged);
    _garantirWebSocketMobile();
    _carregarResumoAtendimento();
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

  Future<void> _carregarResumoAtendimento() async {
    if (mounted) {
      setState(() {
        _carregandoResumo = true;
        _erroResumo = null;
      });
    }

    try {
      final TelaInicialModel resumo = await _telaInicialApiClient.getResumo();
      if (!mounted) return;

      setState(() {
        _resumoTelaInicial = resumo;
        _carregandoResumo = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _erroResumo = error.toString();
        _carregandoResumo = false;
      });

      debugPrint('[OperacaoMobileScreen] Erro ao buscar resumo: $error');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected == null) return;
    setState(() => _image = File(selected.path));
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
          'Atendimento',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            icon: _buildNotificationIcon(),
            onPressed: () => _openNotifications(context),
          ),
        ],
      ),
      drawer: AppDrawerDoMobile(image: _image, onPickImage: _pickImage),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarResumoAtendimento,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 70),
                child: _buildQuickServiceHeader(),
              ),
              const SizedBox(height: 18),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 120),
                child: _buildSectionTitle('Atendimento rápido'),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 170),
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 230),
                child: _buildSectionTitle('Acompanhamento'),
              ),
              const SizedBox(height: 12),
              ..._buildTrackingTiles(context),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 420),
                child: _buildSectionTitle('Caixa'),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 470),
                child: _buildCashTile(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          kIsWeb ? null : const CustomBottomNavBar(initialIndex: 2),
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

  Widget _buildQuickServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
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
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Balcão digital',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Venda, orçamento e assistência técnica em poucos passos.',
                  style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildPrimaryActionCard(
          title: 'Nova venda',
          subtitle: 'Abrir atendimento no caixa',
          icon: Icons.point_of_sale_rounded,
          onTap: () => _navigateTo(context, const PdvMobileScreen()),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 360;
            final double width = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: width,
                  child: _buildSecondaryActionCard(
                    title: 'Atendimento técnico',
                    icon: Icons.build_circle_rounded,
                    onTap: () => _navigateTo(
                      context,
                      const AtendimentosTecnicosWebPage(),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildSecondaryActionCard(
                    title: 'Novo orçamento',
                    icon: Icons.request_quote_rounded,
                    onTap: () => _showFeatureInProgress(context),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildSecondaryActionCard(
                    title: 'Nova assistência',
                    icon: Icons.handyman_rounded,
                    onTap: () => _navigateTo(
                      context,
                      const AtendimentosTecnicosWebPage(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildTrackingTiles(BuildContext context) {
    final String totalVendasAReceber =
        (_resumoTelaInicial?.totalVendasAbertas ?? 0).toString();

    final List<_TrackingItem> items = <_TrackingItem>[
      _TrackingItem(
        title: 'Vendas a receber',
        subtitle: _erroResumo == null
            ? 'Vendas não liquidadas'
            : 'Não foi possível atualizar agora',
        count: totalVendasAReceber,
        icon: Icons.point_of_sale_outlined,
        isLoading: _carregandoResumo,
        hasError: _erroResumo != null,
        onTap: () => _navigateTo(context, const VendasNaoLiquidadasMobileScreen()),
      ),
      _TrackingItem(
        title: 'Atendimentos técnicos',
        subtitle: 'Diagnóstico, orçamento e execução',
        count: '0',
        icon: Icons.build_circle_outlined,
        onTap: () => _navigateTo(context, const AtendimentosTecnicosWebPage()),
      ),
      _TrackingItem(
        title: 'Orçamentos pendentes',
        subtitle: 'Aguardando retorno do cliente',
        count: '9',
        icon: Icons.description_outlined,
        onTap: () => _showFeatureInProgress(context),
      ),
      _TrackingItem(
        title: 'Assistências em execução',
        subtitle: 'Serviços técnicos em andamento',
        count: '27',
        icon: Icons.engineering_outlined,
        onTap: () => _navigateTo(context, const AtendimentosTecnicosWebPage()),
      ),
    ];

    return items
        .asMap()
        .entries
        .map((MapEntry<int, _TrackingItem> entry) {
          final int delay = 280 + (entry.key * 45);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SixStaggeredEntry(
              delay: Duration(milliseconds: delay),
              child: _buildTrackingTile(entry.value),
            ),
          );
        })
        .toList(growable: false);
  }

  Widget _buildPrimaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
          child: Row(
            children: <Widget>[
              _iconBox(
                icon,
                background: const Color(0xFFEFF6FF),
                color: _accentColor,
                size: 50,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(
                icon,
                background: const Color(0xFFEFF6FF),
                color: _accentColor,
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingTile(_TrackingItem item) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.hasError
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _iconBox(
                item.icon,
                background: const Color(0xFFF1F5F9),
                color: _primaryColor,
                size: 46,
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.hasError
                            ? const Color(0xFFB91C1C)
                            : _mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildTrackingCount(item),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingCount(_TrackingItem item) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: item.isLoading
          ? Container(
              key: const ValueKey<String>('loading-count'),
              width: 34,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            )
          : SixAnimatedNumberText(
              key: ValueKey<String>('count-${item.title}-${item.count}'),
              value: item.count,
              style: const TextStyle(
                color: _titleTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  Widget _buildCashTile(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateTo(context, const VendasNaoLiquidadasMobileScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: <Widget>[
              _iconBox(
                Icons.point_of_sale_outlined,
                background: const Color(0xFFEFF6FF),
                color: _accentColor,
                size: 46,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Caixa a receber',
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Liquidar vendas deixadas para depois',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(
    IconData icon, {
    required Color background,
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14),
      ),
      child: Icon(icon, color: color, size: size >= 48 ? 24 : 22),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _titleTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }

  String _badgeText(int count) {
    if (count > 9) return '+9';
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

  void _showFeatureInProgress(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fluxo mobile em evolução.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TrackingItem {
  const _TrackingItem({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
    this.hasError = false,
  });

  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final bool hasError;
}
