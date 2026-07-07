import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/tela_inicial_models.dart';
import 'package:sixpos/data/services/telainicial_web/tela_inicial_api_client.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_mobile_screen.dart';
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
  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _primary = Color(0xFF0B1F3A);
  static const Color _secondary = Color(0xFF123B69);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF64748B);
  static const Color _title = Color(0xFF0F172A);

  final TelaInicialWebApiClient _api =
      HttpResumoDaEmpresaApiClient(canal: 'mobile');
  final NotificacaoService _notificacoes = NotificacaoService();
  final ImagePicker _picker = ImagePicker();

  TelaInicialModel? _resumo;
  File? _image;
  bool _loading = true;
  String? _erro;
  int _totalNotificacoesConhecidas = 0;

  @override
  void initState() {
    super.initState();
    _totalNotificacoesConhecidas = _notificacoes.total;
    _notificacoes.addListener(_onNotificacoesChanged);
    _garantirWebSocketMobile();
    _carregarResumo();
  }

  @override
  void dispose() {
    _notificacoes.removeListener(_onNotificacoesChanged);
    super.dispose();
  }

  void _onNotificacoesChanged() {
    if (!mounted) return;
    final int totalAtual = _notificacoes.total;
    final bool recebeuNova = totalAtual > _totalNotificacoesConhecidas;
    _totalNotificacoesConhecidas = totalAtual;
    setState(() {});

    final String? mensagem = _notificacoes.ultimaNotificacao?.description.trim();
    if (!recebeuNova || mensagem == null || mensagem.isEmpty) return;

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

  Future<void> _carregarResumo() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final TelaInicialModel resumo = await _api.getResumo();
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = error.toString());
      debugPrint('[OperacaoMobileScreen] Erro ao buscar resumo: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Atendimento',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notificações',
            icon: _notificationIcon(),
            onPressed: () => _go(const NotificacoesMobileScreen()),
          ),
        ],
      ),
      drawer: AppDrawerDoMobile(image: _image, onPickImage: _pickImage),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarResumo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 70),
                child: _hero(),
              ),
              const SizedBox(height: 18),
              _section('Atendimento rápido'),
              const SizedBox(height: 12),
              _primaryAction(
                title: 'Nova venda',
                subtitle: 'Abrir atendimento no caixa',
                icon: Icons.point_of_sale_rounded,
                onTap: () => _go(const PdvMobileScreen()),
              ),
              const SizedBox(height: 12),
              _primaryAction(
                title: 'Atendimento técnico',
                subtitle: 'Iniciar diagnóstico, orçamento e execução',
                icon: Icons.build_circle_rounded,
                onTap: () => _go(const AtendimentoTecnicoMobileScreen()),
              ),
              const SizedBox(height: 24),
              _section('Acompanhamento'),
              const SizedBox(height: 12),
              ..._trackingCards(),
              const SizedBox(height: 12),
              _section('Caixa'),
              const SizedBox(height: 12),
              _trackingCard(
                title: 'Caixa a receber',
                subtitle: 'Liquidar vendas deixadas para depois',
                value: null,
                icon: Icons.point_of_sale_outlined,
                onTap: () => _go(const VendasNaoLiquidadasMobileScreen()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: kIsWeb ? null : const CustomBottomNavBar(initialIndex: 2),
    );
  }

  Widget _notificationIcon() {
    final int naoLidas = _notificacoes.naoLidas;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          naoLidas > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
        ),
        if (naoLidas > 0)
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
                  naoLidas > 9 ? '+9' : naoLidas.toString(),
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

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[_primary, _secondary],
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
          _iconBox(
            Icons.support_agent_rounded,
            bg: const Color(0x1AFFFFFF),
            fg: Colors.white,
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
                  'Venda e atendimento técnico em poucos passos.',
                  style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _trackingCards() {
    final bool hasError = _erro != null;
    final String subtitleErro = 'Não foi possível atualizar agora';
    final List<_TrackingCardData> cards = <_TrackingCardData>[
      _TrackingCardData(
        title: 'Vendas a receber',
        subtitle: hasError ? subtitleErro : 'Vendas não liquidadas',
        value: (_resumo?.totalVendasAbertas ?? 0).toString(),
        icon: Icons.point_of_sale_outlined,
        onTap: () => _go(const VendasNaoLiquidadasMobileScreen()),
      ),
      _TrackingCardData(
        title: 'Atendimentos Técnicos',
        subtitle: hasError ? subtitleErro : 'Dashboard executivo do fluxo técnico',
        value: (_resumo?.totalAtendimentoTecnicosNaoEntregues ?? 0).toString(),
        icon: Icons.fact_check_outlined,
        onTap: () => _go(const AtendimentosTecnicosMobileScreen()),
      ),
    ];

    return cards.asMap().entries.map((MapEntry<int, _TrackingCardData> entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SixStaggeredEntry(
          delay: Duration(milliseconds: 230 + entry.key * 45),
          child: _trackingCard(
            title: entry.value.title,
            subtitle: entry.value.subtitle,
            value: entry.value.value,
            icon: entry.value.icon,
            hasError: hasError,
            onTap: entry.value.onTap,
          ),
        ),
      );
    }).toList(growable: false);
  }

  Widget _primaryAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _card(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          _iconBox(icon, bg: const Color(0xFFEFF6FF), fg: _accent),
          const SizedBox(width: 14),
          Expanded(child: _texts(title, subtitle, titleSize: 16)),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }

  Widget _trackingCard({
    required String title,
    required String subtitle,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return _card(
      onTap: onTap,
      borderColor: hasError ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
      child: Row(
        children: <Widget>[
          _iconBox(icon, bg: const Color(0xFFF1F5F9), fg: _primary, size: 46),
          const SizedBox(width: 14),
          Expanded(child: _texts(title, subtitle, error: hasError)),
          const SizedBox(width: 12),
          if (value != null)
            _loading
                ? Container(
                    width: 34,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  )
                : SixAnimatedNumberText(
                    key: ValueKey<String>('inicio-$title-$value'),
                    value: value,
                    style: const TextStyle(
                      color: _title,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    required VoidCallback onTap,
    Color borderColor = const Color(0xFFE2E8F0),
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _texts(
    String title,
    String subtitle, {
    bool error = false,
    double titleSize = 15,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _title,
            fontWeight: FontWeight.w900,
            fontSize: titleSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: error ? const Color(0xFFB91C1C) : _muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _iconBox(
    IconData icon, {
    required Color bg,
    required Color fg,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14),
      ),
      child: Icon(icon, color: fg, size: size >= 48 ? 24 : 22),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _title,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _TrackingCardData {
  const _TrackingCardData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
}
