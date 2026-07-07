import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/tela_inicial_models.dart';
import 'package:sixpos/data/services/telainicial_web/tela_inicial_api_client.dart';
import 'package:sixpos/pdv_page_web.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart';
import 'package:sixpos/presentation/screens/vendas_nao_liquidadas_mobile_screen.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';
import 'catalogo_disponivel_mobile_screen.dart';
import 'catalogo_nao_disponivel_mobile_screen.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({super.key, required this.title});

  final String title;

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
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
  final TelaInicialWebApiClient _telaInicialApiClient =
      HttpResumoDaEmpresaApiClient(canal: 'mobile');

  TelaInicialModel? _resumoTelaInicial;
  bool _carregandoResumo = true;
  String? _erroResumo;

  @override
  void initState() {
    super.initState();
    _notificacaoService.addListener(_onNotificacoesChanged);
    if (!kIsWeb) {
      _configurarWebSocketMobile();
      _carregarResumoInicio();
    }
  }

  @override
  void dispose() {
    _notificacaoService.removeListener(_onNotificacoesChanged);
    if (!kIsWeb) {
      onMensagemRecebida = null;
      onStompConectado = null;
      onStompDesconectado = null;
      onStompErro = null;
      disconnectStomp();
    }
    super.dispose();
  }

  void _onNotificacoesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _configurarWebSocketMobile() {
    onMensagemRecebida = (Map<String, dynamic> json) {
      if (!mounted) return;

      final String? mensagem = json['mensagem']?.toString().trim();
      if (mensagem == null || mensagem.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    };

    onStompErro = (Object error) {
      debugPrint('[HomePageMobile] Erro no WebSocket: $error');
    };

    connectStomp();
  }

  Future<void> _carregarResumoInicio() async {
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
      debugPrint('[HomePageMobile] Erro ao buscar resumo: $error');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() => _image = File(selected.path));
    }
  }

  String get _totalVendasAReceber =>
      (_resumoTelaInicial?.totalVendasAbertas ?? 0).toString();

  String get _subtituloVendasAReceber => _erroResumo == null
      ? 'Vendas não liquidadas'
      : 'Não foi possível atualizar agora';

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? PDVWeb()
        : Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              title: const Text(
                'Início',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Configurações',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _showFeatureInProgress,
                ),
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
            body: _buildHomeContent(context),
            bottomNavigationBar:
                kIsWeb ? null : const CustomBottomNavBar(initialIndex: 1),
          );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _carregarResumoInicio,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 60),
              child: _buildExecutiveSummary(),
            ),
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 120),
              child: _buildNotificationsOverviewCard(context),
            ),
            const SizedBox(height: 22),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 180),
              child: _buildSectionTitle('Ações rápidas'),
            ),
            const SizedBox(height: 12),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 230),
              child: _buildQuickActions(context),
            ),
            const SizedBox(height: 24),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 290),
              child: _buildSectionTitle('Pendências'),
            ),
            const SizedBox(height: 12),
            ..._buildMetricTiles(context),
          ],
        ),
      ),
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

  Widget _buildExecutiveSummary() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Hoje no Six',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe as prioridades do atendimento sem sair do mobile.',
            style: TextStyle(
              color: Color(0xFFD7E3F5),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryPill(
                  label: 'Período',
                  value: 'Hoje',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryPill(
                  label: 'Vendas a receber',
                  value: _totalVendasAReceber,
                  isLoading: _carregandoResumo,
                  hasError: _erroResumo != null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required String label,
    required String value,
    bool isLoading = false,
    bool hasError = false,
  }) {
    final TextStyle valueStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0x66FCA5A5) : const Color(0x33FFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFBFD0EA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isLoading
                ? Container(
                    key: const ValueKey<String>('summary-loading'),
                    width: 34,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  )
                : int.tryParse(value) == null
                    ? Text(
                        value,
                        key: ValueKey<String>('summary-text-$label-$value'),
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      )
                    : SixAnimatedNumberText(
                        key: ValueKey<String>('summary-number-$label-$value'),
                        value: value,
                        style: valueStyle,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsOverviewCard(BuildContext context) {
    final SixNotificationEvent? ultimaNotificacao =
        _notificacaoService.ultimaNotificacao;
    final int naoLidas = _notificacaoService.naoLidas;
    final bool temNaoLidas = naoLidas > 0;
    final String resumo = ultimaNotificacao?.description ??
        'Aguardando mensagens do backend para esta empresa';

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openNotifications(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      temNaoLidas
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_rounded,
                      color: _accentColor,
                    ),
                  ),
                  if (temNaoLidas)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: SixPulsingBadge(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notificações recentes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resumo,
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
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final List<_QuickAction> actions = [
      _QuickAction(
        label: 'Nova venda',
        icon: Icons.point_of_sale_rounded,
        onTap: () => _navigateTo(context, const PdvMobileScreen()),
      ),
      _QuickAction(
        label: 'Novo orçamento',
        icon: Icons.request_quote_rounded,
        onTap: _showFeatureInProgress,
      ),
      _QuickAction(
        label: 'Nova assistência',
        icon: Icons.handyman_rounded,
        onTap: _showFeatureInProgress,
      ),
      _QuickAction(
        label: 'Clientes',
        icon: Icons.people_alt_rounded,
        onTap: () => _navigateTo(context, const ClientesUsuarioListPage()),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.asMap().entries.map((entry) {
            return SizedBox(
              width: width,
              child: SixStaggeredEntry(
                delay: Duration(milliseconds: 270 + (entry.key * 45)),
                child: _buildQuickActionCard(entry.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: _accentColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                action.label,
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

  List<Widget> _buildMetricTiles(BuildContext context) {
    final List<_DashboardMetric> metrics = [
      _DashboardMetric(
        title: 'Vendas a receber',
        subtitle: _subtituloVendasAReceber,
        count: _totalVendasAReceber,
        icon: Icons.point_of_sale_outlined,
        onTap: () => _navigateTo(context, const VendasNaoLiquidadasMobileScreen()),
        isLoading: _carregandoResumo,
        hasError: _erroResumo != null,
      ),
      _DashboardMetric(
        title: 'Assistências em revisão',
        subtitle: 'Aguardando análise técnica',
        count: '33',
        icon: Icons.fact_check_outlined,
        onTap: _showFeatureInProgress,
      ),
      _DashboardMetric(
        title: 'Assistências em andamento',
        subtitle: 'Serviços em execução',
        count: '27',
        icon: Icons.build_circle_outlined,
        onTap: _showFeatureInProgress,
      ),
      _DashboardMetric(
        title: 'Produtos ativos',
        subtitle: 'Disponíveis no catálogo',
        count: '10',
        icon: Icons.inventory_2_outlined,
        onTap: () => _navigateTo(context, const CatalogoDisponivelMobileScreen()),
      ),
      _DashboardMetric(
        title: 'Produtos inativos',
        subtitle: 'Fora do catálogo ativo',
        count: '0',
        icon: Icons.inventory_2_rounded,
        onTap: () => _navigateTo(context, const MeuCatalogoMobileScreen()),
      ),
    ];

    return metrics.asMap().entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SixStaggeredEntry(
              delay: Duration(milliseconds: 340 + (entry.key * 55)),
              child: _buildMetricTile(entry.value),
            ),
          ),
        )
        .toList();
  }

  Widget _buildMetricTile(_DashboardMetric metric) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: metric.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: metric.hasError
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(metric.icon, color: _primaryColor, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
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
                      metric.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: metric.hasError
                            ? const Color(0xFFB91C1C)
                            : _mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMetricCount(metric),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _mutedTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCount(_DashboardMetric metric) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: metric.isLoading
          ? Container(
              key: const ValueKey<String>('metric-loading'),
              width: 34,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            )
          : SixAnimatedNumberText(
              key: ValueKey<String>('metric-${metric.title}-${metric.count}'),
              value: metric.count,
              style: const TextStyle(
                color: _titleTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
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

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _DashboardMetric {
  const _DashboardMetric({
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
