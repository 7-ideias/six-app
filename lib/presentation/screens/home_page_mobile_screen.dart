import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/pdv_page_web.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _notificacaoService.addListener(_onNotificacoesChanged);
    if (!kIsWeb) {
      _configurarWebSocketMobile();
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
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _configurarWebSocketMobile() {
    onMensagemRecebida = (Map<String, dynamic> json) {
      if (!mounted) {
        return;
      }

      final String? mensagem = json['mensagem']?.toString().trim();
      if (mensagem == null || mensagem.isEmpty) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    };

    onStompErro = (Object error) {
      debugPrint('[HomePageMobile] Erro no WebSocket: $error');
    };

    connectStomp();
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
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SixLiquidHeaderDelegate(
              minHeight: 76,
              maxHeight: 214,
              builder: _buildLiquidExecutiveSummary,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
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
              ]),
            ),
          ),
        ],
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

  Widget _buildLiquidExecutiveSummary(double progress) {
    final double easedProgress = Curves.easeOutCubic.transform(progress);
    final double contentOpacity = (1 - (progress * 1.45)).clamp(0.0, 1.0);
    final double waveProgress = (1 - ((progress * 2) - 1).abs()).clamp(0.0, 1.0);
    final double horizontalMargin = _lerp(16, 0, easedProgress);
    final double topMargin = _lerp(14, 0, easedProgress);
    final double bottomMargin = _lerp(16, 0, easedProgress);
    final double borderRadius = _lerp(24, 0, easedProgress);
    final double verticalPadding = _lerp(20, 8, easedProgress);
    final double horizontalPadding = _lerp(20, 16, easedProgress);

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _backgroundColor),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalMargin,
            topMargin,
            horizontalMargin,
            bottomMargin,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    const Color(0x260B1F3A),
                    Colors.transparent,
                    easedProgress,
                  )!,
                  blurRadius: _lerp(22, 0, easedProgress),
                  offset: Offset(0, _lerp(12, 0, easedProgress)),
                ),
              ],
            ),
            child: ClipPath(
              clipper: _SixLiquidHeaderClipper(
                radius: borderRadius,
                waveHeight: _lerp(0, 12, waveProgress),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Opacity(
                    opacity: contentOpacity,
                    child: IgnorePointer(
                      ignoring: contentOpacity < 0.2,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          heightFactor: contentOpacity,
                          child: Transform.translate(
                            offset: Offset(0, _lerp(0, -14, easedProgress)),
                            child: _buildExecutiveSummaryContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                label: 'Vendas em aberto',
                value: '33',
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _lerp(double begin, double end, double progress) {
    return begin + ((end - begin) * progress);
  }

  Widget _buildSummaryPill({required String label, required String value}) {
    final TextStyle valueStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
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
          if (int.tryParse(value) == null)
            Text(value, overflow: TextOverflow.ellipsis, style: valueStyle)
          else
            SixAnimatedNumberText(value: value, style: valueStyle),
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
        title: 'Vendas em aberto',
        subtitle: 'Aguardando pagamento',
        count: '33',
        icon: Icons.payments_outlined,
        onTap: _showFeatureInProgress,
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
                      style: const TextStyle(
                        color: _mutedTextColor,
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
                  SixAnimatedNumberText(
                    value: metric.count,
                    style: const TextStyle(
                      color: _titleTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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

class _SixLiquidHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SixLiquidHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  final double minHeight;
  final double maxHeight;
  final Widget Function(double progress) builder;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double availableRange = maxExtent - minExtent;
    final double progress = availableRange <= 0
        ? 1
        : (shrinkOffset / availableRange).clamp(0.0, 1.0);

    return builder(progress);
  }

  @override
  bool shouldRebuild(covariant _SixLiquidHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        builder != oldDelegate.builder;
  }
}

class _SixLiquidHeaderClipper extends CustomClipper<Path> {
  const _SixLiquidHeaderClipper({
    required this.radius,
    required this.waveHeight,
  });

  final double radius;
  final double waveHeight;

  @override
  Path getClip(Size size) {
    final double effectiveRadius = radius.clamp(0.0, size.shortestSide / 2);
    final double effectiveWave = waveHeight.clamp(0.0, 16.0);
    final double bottom = size.height - effectiveWave;
    final Path path = Path()
      ..moveTo(effectiveRadius, 0)
      ..lineTo(size.width - effectiveRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, effectiveRadius)
      ..lineTo(size.width, bottom - effectiveRadius)
      ..quadraticBezierTo(
        size.width,
        bottom,
        size.width - effectiveRadius,
        bottom,
      )
      ..cubicTo(
        size.width * 0.76,
        bottom + effectiveWave,
        size.width * 0.58,
        bottom - (effectiveWave * 0.55),
        size.width * 0.43,
        bottom + (effectiveWave * 0.2),
      )
      ..cubicTo(
        size.width * 0.27,
        bottom + (effectiveWave * 0.9),
        size.width * 0.12,
        bottom - (effectiveWave * 0.35),
        effectiveRadius,
        bottom,
      )
      ..quadraticBezierTo(0, bottom, 0, bottom - effectiveRadius)
      ..lineTo(0, effectiveRadius)
      ..quadraticBezierTo(0, 0, effectiveRadius, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _SixLiquidHeaderClipper oldClipper) {
    return radius != oldClipper.radius || waveHeight != oldClipper.waveHeight;
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
  });

  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final VoidCallback onTap;
}
