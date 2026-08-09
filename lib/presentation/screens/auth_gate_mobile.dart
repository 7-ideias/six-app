import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/services/firebase_push_notification_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import 'auth_entry_mobile.dart';
import 'mobile_main_shell.dart';

class AuthGateMobile extends StatefulWidget {
  const AuthGateMobile({super.key});

  @override
  State<AuthGateMobile> createState() => _AuthGateMobileState();
}

class _AuthGateMobileState extends State<AuthGateMobile> {
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
        builder: (_) => const MobileMainShell(initialIndex: 1),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthEntryMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SixMobilePalette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AuthGateLogo(),
                const SizedBox(height: 22),
                Text(
                  'Entrando no Six',
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Validando sua sessão com segurança...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SixMobilePalette.mutedText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: SixMobilePalette.accent,
                    backgroundColor: SixMobilePalette.activeBorder,
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: [
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.lock_open_rounded,
        color: SixMobilePalette.accent,
        size: 34,
      ),
    );
  }
}
