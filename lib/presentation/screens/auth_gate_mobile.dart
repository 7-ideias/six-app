import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/services/firebase_push_notification_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import 'home_page_mobile_screen.dart';
import 'login_mobile.dart';

class AuthGateMobile extends StatefulWidget {
  const AuthGateMobile({super.key});

  @override
  State<AuthGateMobile> createState() => _AuthGateMobileState();
}

class _AuthGateMobileState extends State<AuthGateMobile> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _mutedTextColor = Color(0xFF64748B);

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    final String? refreshToken = await _authService.getRefreshToken();

    if (refreshToken == null || refreshToken.trim().isEmpty) {
      _goToLogin();
      return;
    }

    try {
      await _authService.refreshToken();

      try {
        await EmpresaService().buscarDadosDaEmpresa();
        if (mounted) {
          await context
              .read<ColaboradorAutorizacoesProvider>()
              .carregarAutorizacoesDoUsuarioLogado(force: true);
        }
        await FirebasePushNotificationService().syncTokenForLoggedUser();
      } catch (e) {
        debugPrint('[AuthGateMobile] Erro ao restaurar dados da empresa: $e');
      }

      if (!mounted) return;
      _goToHome();
    } catch (e) {
      debugPrint('[AuthGateMobile] Sessão expirada ou inválida: $e');
      await _authService.logout();
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const HomePageMobile(title: 'Início'),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AuthGateLogo(),
                SizedBox(height: 22),
                Text(
                  'Entrando no Six',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Validando sua sessão com segurança...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mutedTextColor,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGateLogo extends StatelessWidget {
  const _AuthGateLogo();

  static const Color _accentColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_open_rounded,
        color: _accentColor,
        size: 34,
      ),
    );
  }
}
