import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../pdv_page_web.dart' as legacy;
import '../admin/admin_dashboard_metrics.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebDashboardState();
}

class _PDVWebDashboardState extends State<PDVWeb> {
  final AuthService _authService = AuthService();

  String? _userName;
  bool _dashboardVisivel = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;

    setState(() {
      _userName = _nomeExibicaoPorEmail(email);
    });
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalizado = email?.trim() ?? '';
    if (normalizado.isEmpty || !normalizado.contains('@')) return null;

    final String prefixo = normalizado
        .split('@')
        .first
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .trim();
    if (prefixo.isEmpty) return null;

    return prefixo
        .split(RegExp(r'\s+'))
        .where((String parte) => parte.isNotEmpty)
        .map((String parte) {
          if (parte.length == 1) return parte.toUpperCase();
          return '${parte[0].toUpperCase()}${parte.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  void _ocultarDashboardAoInteragir(PointerDownEvent event) {
    if (!_dashboardVisivel) return;
    setState(() => _dashboardVisivel = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _ocultarDashboardAoInteragir,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const legacy.PDVWeb(),
          Positioned.fill(
            top: 84,
            left: 16,
            right: 16,
            bottom: 16,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _dashboardVisivel ? 1 : 0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _PdvAdminDashboard(userName: _userName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdvAdminDashboard extends StatelessWidget {
  const _PdvAdminDashboard({required this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final AdminPortalTexts texts = AdminPortalTexts.of(context);
    final AdminCompaniesMetrics metrics = AdminCompaniesMetrics.fromValues(
      total: 4,
      active: 4,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: AdminPalette.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: AdminStaggeredColumn(
            children: <Widget>[
              AdminDashboardHeader(texts: texts, userName: userName),
              AdminMetricsGrid(texts: texts, metrics: metrics),
            ],
          ),
        ),
      ),
    );
  }
}
