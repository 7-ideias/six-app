import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_dashboard_metrics.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';

class AdminPortalWebPage extends StatefulWidget {
  const AdminPortalWebPage({super.key});

  @override
  State<AdminPortalWebPage> createState() => _AdminPortalWebPageState();
}

class _AdminPortalWebPageState extends State<AdminPortalWebPage> {
  final AdminPortalService _service = AdminPortalService();
  final AuthService _authService = AuthService();

  bool _carregando = true;
  bool _saindo = false;
  AdminPortalResumo? _resumo;
  String? _erro;
  String? _userName;
  String? _userEmail;
  String? _profileType;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregarResumo();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    final String profileType = await _authService.getUserProfileType();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _profileType = profileType;
      _userName = _nomeExibicaoPorEmail(email);
    });
  }

  Future<void> _carregarResumo() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final AdminPortalResumo resumo = await _service.buscarResumo();
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      final String mensagem = e.toString().replaceAll('Exception: ', '');
      if (_erroDeSessao(mensagem)) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
        return;
      }
      setState(() {
        _erro = mensagem;
        _carregando = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_saindo) return;
    setState(() => _saindo = true);
    try {
      await _authService.logout();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
    }
  }

  bool _erroDeSessao(String mensagem) {
    final String normalized = mensagem.toLowerCase();
    return normalized.contains('login') || normalized.contains('sessão') || normalized.contains('sessao');
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalized = email?.trim() ?? '';
    if (normalized.isEmpty || !normalized.contains('@')) return null;
    final String prefix = normalized.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ').trim();
    if (prefix.isEmpty) return null;
    return prefix
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .map((String part) => '${part.characters.first.toUpperCase()}${part.characters.skip(1).join().toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final AdminPortalTexts texts = AdminPortalTexts.of(context);

    return AdminShell(
      texts: texts,
      userInfo: AdminPortalUserInfo(
        name: _userName,
        email: _userEmail,
        profileType: _profileType,
      ),
      onLogout: _logout,
      onRefresh: _carregarResumo,
      refreshing: _carregando,
      loggingOut: _saindo,
      child: AnimatedSwitcher(
        duration: AdminMotion.medium,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildContent(texts),
      ),
    );
  }

  Widget _buildContent(AdminPortalTexts texts) {
    if (_carregando) {
      return AdminLoadingState(key: const ValueKey<String>('admin-loading'), texts: texts);
    }

    final String? erro = _erro;
    if (erro != null) {
      return AdminErrorState(
        key: const ValueKey<String>('admin-error'),
        texts: texts,
        message: erro,
        onRetry: _carregarResumo,
      );
    }

    final AdminPortalResumo resumo = _resumo ?? const AdminPortalResumo(
      totalEmpresasCadastradas: 0,
      totalEmpresasAtivas: 0,
    );
    final AdminCompaniesMetrics metrics = AdminCompaniesMetrics.fromResumo(resumo);

    return AdminDashboardContent(
      key: ValueKey<String>('admin-dashboard-${metrics.total}-${metrics.active}-${metrics.inactive}'),
      texts: texts,
      userName: _userName,
      resumo: resumo,
      metrics: metrics,
    );
  }
}
