import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_dashboard_metrics.dart';
import '../admin/admin_navigation_shell.dart';
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
  AdminAiFeedbackResumo? _feedbackIa;
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
      final List<dynamic> resultados = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.buscarResumo(),
        _service.buscarResumoFeedbackIa(),
      ]);
      if (!mounted) return;
      setState(() {
        _resumo = resultados[0] as AdminPortalResumo;
        _feedbackIa = resultados[1] as AdminAiFeedbackResumo;
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
    return AdminNavigationShell(
      texts: texts,
      userInfo: AdminPortalUserInfo(name: _userName, email: _userEmail, profileType: _profileType),
      currentRoute: '/admin/dashboard',
      pageTitle: texts.currentPage,
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
    if (_carregando) return AdminLoadingState(key: const ValueKey<String>('admin-loading'), texts: texts);
    final String? erro = _erro;
    if (erro != null) {
      return AdminErrorState(key: const ValueKey<String>('admin-error'), texts: texts, message: erro, onRetry: _carregarResumo);
    }

    final AdminPortalResumo resumo = _resumo ?? const AdminPortalResumo(totalEmpresasCadastradas: 0, totalEmpresasAtivas: 0);
    final AdminCompaniesMetrics metrics = AdminCompaniesMetrics.fromResumo(resumo);
    return Column(
      key: ValueKey<String>('admin-dashboard-${metrics.total}-${_feedbackIa?.total ?? 0}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AdminDashboardContent(texts: texts, userName: _userName, resumo: resumo, metrics: metrics),
        const SizedBox(height: 24),
        _AiFeedbackDashboardCard(
          resumo: _feedbackIa ?? const AdminAiFeedbackResumo(total: 0, ajudou: 0, naoAjudou: 0, aderenciaPercentual: 0),
          onOpenIdeas: () => Navigator.of(context).pushReplacementNamed('/admin/novas-ideias'),
        ),
      ],
    );
  }
}

class _AiFeedbackDashboardCard extends StatelessWidget {
  const _AiFeedbackDashboardCard({required this.resumo, required this.onOpenIdeas});
  final AdminAiFeedbackResumo resumo;
  final VoidCallback onOpenIdeas;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final String title = language == 'en' ? 'AI assistant adoption' : language == 'es' ? 'Adopción del asistente de IA' : 'Aderência ao assistente de IA';
    final String subtitle = language == 'en'
        ? 'Measure how users rate the answers generated by Six.'
        : language == 'es'
            ? 'Mide cómo los usuarios evalúan las respuestas generadas por Six.'
            : 'Meça como os usuários avaliam as respostas geradas pelo Six.';
    final String totalLabel = language == 'en' ? 'Ratings' : language == 'es' ? 'Evaluaciones' : 'Avaliações';
    final String helpedLabel = language == 'en' ? 'Helped' : language == 'es' ? 'Ayudó' : 'Ajudou';
    final String notHelpedLabel = language == 'en' ? 'Did not help' : language == 'es' ? 'No ayudó' : 'Não ajudou';
    final String adherenceLabel = language == 'en' ? 'Positive rate' : language == 'es' ? 'Tasa positiva' : 'Taxa positiva';
    final String ideasLabel = language == 'en' ? 'View new ideas' : language == 'es' ? 'Ver nuevas ideas' : 'Ver novas ideias';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome_rounded, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                OutlinedButton.icon(onPressed: onOpenIdeas, icon: const Icon(Icons.lightbulb_outline_rounded), label: Text(ideasLabel)),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _MetricPill(label: totalLabel, value: resumo.total.toString()),
                _MetricPill(label: helpedLabel, value: resumo.ajudou.toString()),
                _MetricPill(label: notHelpedLabel, value: resumo.naoAjudou.toString()),
                _MetricPill(label: adherenceLabel, value: '${resumo.aderenciaPercentual.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
