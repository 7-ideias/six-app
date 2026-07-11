import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../pdv_page_web.dart';
import '../../presentation/admin/admin_dashboard_metrics.dart';
import '../../presentation/admin/admin_portal_components.dart';
import '../../presentation/admin/admin_portal_texts.dart';
import '../../presentation/components/ai_assistant/ai_assistant_host.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';

class PdvPageWebAutorizado extends StatefulWidget {
  const PdvPageWebAutorizado({super.key});

  @override
  State<PdvPageWebAutorizado> createState() => _PdvPageWebAutorizadoState();
}

class _PdvPageWebAutorizadoState extends State<PdvPageWebAutorizado> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ColaboradorAutorizacoesProvider>()
          .carregarAutorizacoesDoUsuarioLogado();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool podeFazerVenda = context
        .select<ColaboradorAutorizacoesProvider, bool>(
          (ColaboradorAutorizacoesProvider provider) => provider.podeFazerVenda,
        );
    final bool loading = context.select<ColaboradorAutorizacoesProvider, bool>(
      (ColaboradorAutorizacoesProvider provider) => provider.loading,
    );

    if (loading) {
      return const _PdvAutorizacoesLoading();
    }

    if (podeFazerVenda) {
      return const AiAssistantHost(
        modulo: 'geral',
        telaAtual: 'inicio_web',
        child: _WebBrandWatermark(
          child: _PdvWebComDashboard(child: PDVWeb()),
        ),
      );
    }

    return const AiAssistantHost(
      modulo: 'geral',
      telaAtual: 'inicio_web_sem_vendas',
      child: _WebBrandWatermark(child: _PdvSemVendasWeb()),
    );
  }
}

class _PdvWebComDashboard extends StatefulWidget {
  const _PdvWebComDashboard({required this.child});

  final Widget child;

  @override
  State<_PdvWebComDashboard> createState() => _PdvWebComDashboardState();
}

class _PdvWebComDashboardState extends State<_PdvWebComDashboard> {
  final AuthService _authService = AuthService();
  Timer? _retornoDashboardTimer;
  bool _dashboardVisivel = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  @override
  void dispose() {
    _retornoDashboardTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;
    setState(() => _userName = _nomeExibicaoPorEmail(email));
  }

  void _registrarInteracao(PointerDownEvent event) {
    _retornoDashboardTimer?.cancel();
    if (_dashboardVisivel) {
      setState(() => _dashboardVisivel = false);
    }
    _retornoDashboardTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _dashboardVisivel = true);
      }
    });
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalized = email?.trim() ?? '';
    if (normalized.isEmpty || !normalized.contains('@')) return null;

    final String prefix = normalized
        .split('@')
        .first
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .trim();
    if (prefix.isEmpty) return null;

    return prefix
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              '${part.characters.first.toUpperCase()}${part.characters.skip(1).join().toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _registrarInteracao,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          Positioned.fill(
            top: 82,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _dashboardVisivel ? 1 : 0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: _dashboardVisivel
                      ? Offset.zero
                      : const Offset(0, -0.015),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: _DashboardAdministrativoInicial(userName: _userName),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAdministrativoInicial extends StatelessWidget {
  const _DashboardAdministrativoInicial({this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final AdminPortalTexts texts = AdminPortalTexts.of(context);
    const AdminCompaniesMetrics metrics = AdminCompaniesMetrics(
      total: 4,
      active: 4,
      inactive: 0,
      activePercent: 100,
    );

    return ColoredBox(
      color: AdminPalette.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AdminDashboardHeader(texts: texts, userName: userName),
                AdminMetricsGrid(texts: texts, metrics: metrics),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebBrandWatermark extends StatelessWidget {
  const _WebBrandWatermark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 720;
            final double size =
                (isCompact
                        ? constraints.maxWidth * 0.42
                        : constraints.maxWidth * 0.16)
                    .clamp(isCompact ? 140.0 : 190.0, isCompact ? 240.0 : 300.0)
                    .toDouble();

            return IgnorePointer(
              child: Align(
                alignment: isCompact
                    ? const Alignment(0.80, 0.86)
                    : const Alignment(0.88, 0.80),
                child: Opacity(
                  opacity: 0.045,
                  child: Image.asset(
                    'assets/images/six-logo-flecha.png',
                    width: size,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PdvAutorizacoesLoading extends StatelessWidget {
  const _PdvAutorizacoesLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F8FB),
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class _PdvSemVendasWeb extends StatelessWidget {
  const _PdvSemVendasWeb();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F8FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'O módulo de vendas não está disponível para este usuário.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF596579),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
