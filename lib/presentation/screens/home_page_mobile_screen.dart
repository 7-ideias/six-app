import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/dashboard_inicio_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/pagina_principal_web.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/ai_assistant/ai_assistant_host.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_account_panel_action.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/utils/profile_image_payload.dart';
import 'package:sixpos/providers/dashboard_inicio_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

import '../components/nav_bar_mobile.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({super.key, required this.title});

  final String title;

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;

  // Formatters
  final NumberFormat _compactFmt = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 1,
  );
  final DateFormat _dateFmt = DateFormat('dd/MM', 'pt_BR');

  final ImagePicker _picker = ImagePicker();
  final NotificacaoService _notificacaoService = NotificacaoService();
  final UsuarioService _usuarioService = UsuarioService();
  final DashboardInicioProvider _dashboardProvider = DashboardInicioProvider(
    initialPeriod: DashboardPeriod.last30Days,
  );
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  bool _salvandoFotoPerfil = false;
  bool _sincronizandoPerfilInicial = false;
  String? _fotoPerfilSincronizada;

  @override
  void initState() {
    super.initState();
    _notificacaoService.addListener(_onNotificacoesChanged);
    _dashboardProvider.addListener(_onDashboardChanged);
    _usuarioProvider.addListener(_onUsuarioChanged);
    if (!kIsWeb) {
      _configurarWebSocketMobile();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sincronizarPerfilInicial();
      });
    }
  }

  @override
  void dispose() {
    _notificacaoService.removeListener(_onNotificacoesChanged);
    _dashboardProvider.removeListener(_onDashboardChanged);
    _usuarioProvider.removeListener(_onUsuarioChanged);
    _dashboardProvider.dispose();
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

  void _onDashboardChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onUsuarioChanged() {
    if (!mounted) return;
    final String foto = _usuarioProvider.usuario?.foto.trim() ?? '';
    if (foto.isEmpty) {
      return;
    }

    setState(() => _fotoPerfilSincronizada = foto);
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

  Future<void> _onRefresh() async {
    await Future.wait([
      _dashboardProvider.reload(),
      _atualizarDadosPessoaisNoRefresh(),
    ]);
  }

  Future<void> _atualizarDadosPessoaisNoRefresh() async {
    try {
      await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      final String foto = _usuarioProvider.usuario?.foto.trim() ?? '';
      if (mounted) {
        setState(() {
          if (foto.isNotEmpty) {
            _fotoPerfilSincronizada = foto;
          }
        });
      }
    } catch (error) {
      debugPrint(
        '[HomePageMobile] Falha ao atualizar dados pessoais no refresh: $error',
      );
    }
  }

  Future<void> _sincronizarPerfilInicial() async {
    if (_sincronizandoPerfilInicial) {
      return;
    }

    if (mounted) {
      setState(() => _sincronizandoPerfilInicial = true);
    } else {
      _sincronizandoPerfilInicial = true;
    }
    try {
      await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      final String foto = _usuarioProvider.usuario?.foto.trim() ?? '';
      if (mounted) {
        setState(() {
          if (foto.isNotEmpty) {
            _fotoPerfilSincronizada = foto;
          }
        });
      } else {
        if (foto.isNotEmpty) {
          _fotoPerfilSincronizada = foto;
        }
      }
    } catch (error) {
      debugPrint(
        '[HomePageMobile] Falha ao sincronizar perfil inicial: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _sincronizandoPerfilInicial = false);
      } else {
        _sincronizandoPerfilInicial = false;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_salvandoFotoPerfil) {
      return;
    }

    final XFile? selected = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (selected == null) {
      return;
    }

    setState(() => _salvandoFotoPerfil = true);
    try {
      final String imageDataUrl = await buildProfileImageDataUrl(selected);
      await _usuarioService.atualizarFotoDoUsuario(imageDataUrl);
      if (mounted) {
        setState(() => _fotoPerfilSincronizada = imageDataUrl);
      } else {
        _fotoPerfilSincronizada = imageDataUrl;
      }
    } catch (error) {
      debugPrint('[HomePageMobile] Falha ao atualizar foto do perfil: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'perfil.mobile.photoSaveError',
              fallback:
                  'Não foi possível atualizar a foto do perfil. Tente novamente.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoFotoPerfil = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const AiAssistantHost(
        modulo: 'geral',
        telaAtual: 'inicio_web',
        child: PaginaPrincipalWeb(),
      );
    }

    return AiAssistantHost(
      modulo: 'geral',
      telaAtual: 'inicio_mobile',
      child: SixMobilePageShell(
        title: 'Início',
        backgroundColor: _backgroundColor,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        accentColor: _accentColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: context.t(
              'gestao.settings.item.notifications.title',
              fallback: 'Notificações',
            ),
            icon: _buildNotificationIcon(),
            onPressed: () => _openNotifications(context),
          ),
          const SizedBox(width: 6),
        ],
        bodyBuilder: _buildHomeContent,
        bottomNavigationBar:
            kIsWeb ? null : const NavBarMobile(initialIndex: 1),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final DashboardInicioModel data = _dashboardProvider.data;
    final bool loading = _dashboardProvider.isLoading;

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
          children: [
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 40),
              child: _buildGreetingHeader(context),
            ),
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 80),
              child: _buildPeriodFilter(),
            ),
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 130),
              child: _buildKpiGrid(data, loading),
            ),
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 190),
              child: _buildDashboardChart(data),
            ),
            if (data.alerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 240),
                child: _buildAlertasSection(data, context),
              ),
            ],
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 290),
              child: _buildUpcomingSection(data),
            ),
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 340),
              child: _buildOperationsSection(data),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NOTIFICATION ICON ─────────────────────────────────────────────────────

  Widget _buildGreetingHeader(BuildContext context) {
    final String nome = _resolveGreetingName();
    final String? profileImage =
        _fotoPerfilSincronizada ?? _usuarioProvider.usuario?.foto;

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SixMobileAccountPanelAction(
              profileImage: profileImage,
              onPickImage: _pickImage,
              isUpdatingImage:
                  _salvandoFotoPerfil || _sincronizandoPerfilInicial,
              size: 44,
              borderColor: SixMobilePalette.onPrimary.withValues(alpha: 0.36),
              backgroundColor: SixMobilePalette.onPrimary.withValues(
                alpha: 0.10,
              ),
              iconColor: SixMobilePalette.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .t(
                        'dashboardInicio.mobileGreeting',
                        fallback: 'Olá, {nome}!',
                      )
                      .replaceAll('{nome}', nome),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 28,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t(
                    'dashboardInicio.mobileGreetingSubtitle',
                    fallback: 'Veja os principais movimentos do comércio hoje.',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveGreetingName() {
    final usuario = _usuarioProvider.usuario;
    final String nomeDeGuerra = usuario?.nomeDeGuerra.trim() ?? '';
    if (nomeDeGuerra.isNotEmpty) return nomeDeGuerra;

    final String nome = usuario?.nome.trim() ?? '';
    if (nome.isNotEmpty) return nome.split(RegExp(r'\s+')).first;

    return 'bem-vindo';
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

  // ─── PERIOD FILTER ─────────────────────────────────────────────────────────

  Widget _buildPeriodFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            DashboardPeriod.values.map((DashboardPeriod period) {
              final bool selected = _dashboardProvider.period == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _dashboardProvider.setPeriod(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _accentColor : _surfaceColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            selected ? _accentColor : SixMobilePalette.border,
                      ),
                    ),
                    child: Text(
                      _periodLabel(period),
                      style: TextStyle(
                        color:
                            selected
                                ? SixMobilePalette.onPrimary
                                : _titleTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ─── KPI GRID ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(DashboardInicioModel data, bool loading) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                kpi: data.vendasRealizadas,
                label: 'Vendas',
                loading: loading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                kpi: data.valorRecebido,
                label: 'Recebido',
                loading: loading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                kpi: data.valorAReceber,
                label: 'A receber',
                loading: loading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                kpi: data.resultado,
                label: 'Resultado',
                loading: loading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required DashboardKpi kpi,
    required String label,
    required bool loading,
  }) {
    final Color borderColor =
        kpi.highlight
            ? SixMobilePalette.highlightedBorder
            : SixMobilePalette.border;
    final Color iconBg =
        kpi.highlight
            ? const Color(0xFFEFF6FF)
            : SixMobilePalette.softNeutralSurface;

    return AnimatedOpacity(
      opacity: loading ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: kpi.highlight ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(kpi.icon, size: 17, color: _accentColor),
                ),
                const Spacer(),
                _buildDeltaBadge(kpi),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              key: ValueKey<String>('kpi-$label-${kpi.value}'),
              tween: Tween<double>(begin: 0, end: kpi.value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (BuildContext ctx, double v, Widget? _) {
                return Text(
                  _compactFmt.format(v),
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaBadge(DashboardKpi kpi) {
    final double? delta = kpi.deltaPercent;
    final bool? positive = kpi.isPositive;
    if (delta == null || positive == null) return const SizedBox.shrink();

    final Color color =
        positive ? const Color(0xFF16A34A) : SixMobilePalette.error;
    final IconData arrow =
        positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(arrow, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          '${delta.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── CHART ─────────────────────────────────────────────────────────────────

  Widget _buildDashboardChart(DashboardInicioModel data) {
    if (data.chartData.isEmpty) return const SizedBox.shrink();

    final List<FlSpot> vendaSpots =
        data.chartData
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.vendas))
            .toList();
    final List<FlSpot> recebSpots =
        data.chartData
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.recebimentos))
            .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Evolução no período',
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _chartLegend(_accentColor, 'Vendas', dashed: false),
              const SizedBox(width: 10),
              _chartLegend(const Color(0xFF16A34A), 'Recebido', dashed: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: _surfaceColor,
                    getTooltipItems: (List<LineBarSpot> spots) {
                      return spots.map((LineBarSpot spot) {
                        return LineTooltipItem(
                          _compactFmt.format(spot.y),
                          TextStyle(
                            color: spot.bar.color ?? _accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (double v) => FlLine(
                        color: SixMobilePalette.border.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (double v, TitleMeta meta) {
                        final int idx = v.round();
                        if (idx < 0 || idx >= data.chartData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data.chartData[idx].label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _mutedTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: vendaSpots,
                    color: _accentColor,
                    barWidth: 2.5,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _accentColor.withValues(alpha: 0.07),
                    ),
                  ),
                  LineChartBarData(
                    spots: recebSpots,
                    color: const Color(0xFF16A34A),
                    barWidth: 2,
                    isCurved: true,
                    dashArray: <int>[5, 3],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label, {required bool dashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 2, color: color),
              const SizedBox(width: 3, height: 2),
              Container(width: 5, height: 2, color: color),
            ],
          )
        else
          Container(width: 16, height: 2.5, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _mutedTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── ALERTS ────────────────────────────────────────────────────────────────

  Widget _buildAlertasSection(DashboardInicioModel data, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SixMobilePalette.errorBorder.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: SixMobilePalette.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Atenção necessária',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SixMobilePalette.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${data.alerts.length}',
                    style: TextStyle(
                      color: SixMobilePalette.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...data.alerts.asMap().entries.map((entry) {
            final int idx = entry.key;
            final DashboardAlertItem alert = entry.value;
            return Column(
              children: [
                _buildAlertRow(alert, context),
                if (idx < data.alerts.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 16),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAlertRow(DashboardAlertItem alert, BuildContext context) {
    final Color color;
    switch (alert.severity) {
      case DashboardAlertSeverity.critical:
        color = SixMobilePalette.error;
      case DashboardAlertSeverity.warning:
        color = const Color(0xFFF59E0B);
      case DashboardAlertSeverity.info:
        color = _accentColor;
    }

    return InkWell(
      onTap: alert.routeHint != null ? _showFeatureInProgress : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.titulo,
                    style: const TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.descricao,
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (alert.valor != null && alert.valor! > 0) ...[
              const SizedBox(width: 8),
              Text(
                _compactFmt.format(alert.valor),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── UPCOMING ──────────────────────────────────────────────────────────────

  Widget _buildUpcomingSection(DashboardInicioModel data) {
    if (data.upcoming.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.upcoming_outlined, size: 18, color: _accentColor),
                SizedBox(width: 8),
                Text(
                  'Próximos 7 dias',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...data.upcoming.asMap().entries.map((entry) {
            final int idx = entry.key;
            final DashboardUpcomingItem item = entry.value;
            return Column(
              children: [
                _buildUpcomingRow(item),
                if (idx < data.upcoming.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 16),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(DashboardUpcomingItem item) {
    final Color color;
    final IconData icon;
    switch (item.tipo) {
      case 'receber':
        color = const Color(0xFF16A34A);
        icon = Icons.arrow_downward_rounded;
      case 'pagar':
        color = SixMobilePalette.error;
        icon = Icons.arrow_upward_rounded;
      default:
        color = _accentColor;
        icon = Icons.build_circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descricao,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFmt.format(item.dataPrevista),
                  style: const TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.valor > 0) ...[
            const SizedBox(width: 8),
            Text(
              _compactFmt.format(item.valor),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── OPERATIONS ────────────────────────────────────────────────────────────

  Widget _buildOperationsSection(DashboardInicioModel data) {
    final DashboardOperationSummary ops = data.operations;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.business_center_outlined,
                size: 18,
                color: _accentColor,
              ),
              SizedBox(width: 8),
              Text(
                'Operação atual',
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildOpChip(
                  icon: Icons.build_circle_outlined,
                  label: 'Em andamento',
                  count: ops.atendimentosEmAndamento,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOpChip(
                  icon: Icons.description_outlined,
                  label: 'Orçamentos',
                  count: ops.orcamentosAguardando,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOpChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'Para retirada',
                  count: ops.equipamentosParaRetirada,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOpChip(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Caixas abertos',
                  count: ops.caixasAbertos,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpChip({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SixMobilePalette.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _accentColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _periodLabel(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.today:
        return 'Hoje';
      case DashboardPeriod.last7Days:
        return '7 dias';
      case DashboardPeriod.last30Days:
        return '30 dias';
      case DashboardPeriod.currentMonth:
        return 'Mês atual';
    }
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
