import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import '../../core/services/auth_service.dart';
import '../components/six_backend_loading.dart';

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

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

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
      if (mensagem.toLowerCase().contains('login') || mensagem.toLowerCase().contains('sessão')) {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AdminBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _HeaderCard(
                        saindo: _saindo,
                        onLogout: _logout,
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildContent(theme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_carregando) {
      return const _AdminGlassCard(
        key: ValueKey<String>('loading'),
        child: SixBackendLoading(
          title: 'Carregando portal administrativo',
          subtitle: 'Buscando indicadores gerais do sistema.',
          animation: SixBackendLoadingAnimation.skeletonPulse,
        ),
      );
    }

    if (_erro != null) {
      return _AdminGlassCard(
        key: const ValueKey<String>('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 42),
            const SizedBox(height: 12),
            Text('Não foi possível carregar o resumo.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _carregarResumo,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final AdminPortalResumo resumo = _resumo ?? const AdminPortalResumo(totalEmpresasCadastradas: 0, totalEmpresasAtivas: 0);

    return Column(
      key: const ValueKey<String>('dashboard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compacto = constraints.maxWidth < 760;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: <Widget>[
                SizedBox(
                  width: compacto ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                  child: _AdminMetricCard(
                    icon: Icons.business_rounded,
                    title: 'Empresas cadastradas',
                    value: resumo.totalEmpresasCadastradas.toString(),
                    subtitle: 'Total de empresas existentes no sistema.',
                  ),
                ),
                SizedBox(
                  width: compacto ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                  child: _AdminMetricCard(
                    icon: Icons.verified_rounded,
                    title: 'Empresas ativas',
                    value: resumo.totalEmpresasAtivas.toString(),
                    subtitle: 'Empresas atualmente marcadas como ativas.',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const _AdminGlassCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.construction_rounded, color: Color(0xFF123B69)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Novas configurações administrativas serão adicionadas aqui conforme forem definidas.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.saindo, required this.onLogout});

  final bool saindo;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _AdminGlassCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0B1F3A), Color(0xFF2563EB)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Portal administrativo', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF0B1F3A))),
                const SizedBox(height: 4),
                const Text('Área inicial para manutenção e configurações globais do Six.'),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: saindo ? null : onLogout,
            icon: saindo
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _AdminGlassCard(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double progress, Widget? child) {
          return Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - progress)),
              child: child,
            ),
          );
        },
        child: Row(
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF123B69).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: const Color(0xFF123B69)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF152033))),
                  const SizedBox(height: 6),
                  Text(value, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF0B1F3A), letterSpacing: -1.2)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.58), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminGlassCard extends StatelessWidget {
  const _AdminGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: const Color(0xFF0B1F3A).withOpacity(0.08), blurRadius: 34, offset: const Offset(0, 18)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _AdminBackground extends StatelessWidget {
  const _AdminBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF4F7FB), Color(0xFFE7F0FA), Color(0xFFF8FAFC)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(top: -170, right: -120, child: _Orb(size: 390, color: const Color(0xFF2563EB).withOpacity(0.12))),
          Positioned(bottom: -180, left: -130, child: _Orb(size: 430, color: const Color(0xFF0B1F3A).withOpacity(0.08))),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
