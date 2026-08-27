import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';

import '../../core/services/empresa_service.dart';
import '../../core/services/firebase_push_notification_service.dart';
import '../../core/services/mobile_session_restoration_service.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../navigation/mobile_navigation_controller.dart';
import 'auth_entry_mobile.dart';
import 'mobile_main_shell.dart';

class AuthGateMobile extends StatefulWidget {
  const AuthGateMobile({super.key});

  @override
  State<AuthGateMobile> createState() => _AuthGateMobileState();
}

enum _AuthGateMobileStatus { validating, temporaryError }

class _AuthGateMobileState extends State<AuthGateMobile> {
  final MobileSessionRestorationService _sessionRestorationService =
      MobileSessionRestorationService();
  final UsuarioService _usuarioService = UsuarioService();
  _AuthGateMobileStatus _status = _AuthGateMobileStatus.validating;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    if (_restoring) {
      return;
    }
    _restoring = true;
    if (mounted) {
      setState(() => _status = _AuthGateMobileStatus.validating);
    }

    try {
      final MobileSessionRestorationResult restoration =
          await _sessionRestorationService.restore();

      switch (restoration.status) {
        case MobileSessionRestorationStatus.noStoredSession:
        case MobileSessionRestorationStatus.invalidSession:
          if (!mounted) return;
          _goToLogin();
          return;
        case MobileSessionRestorationStatus.temporaryFailure:
          debugPrint(
            '[AuthGateMobile] Falha temporária ao restaurar sessão: '
            '${restoration.error}',
          );
          if (mounted) {
            setState(() => _status = _AuthGateMobileStatus.temporaryError);
          }
          return;
        case MobileSessionRestorationStatus.restored:
          break;
      }

      try {
        await EmpresaService().buscarDadosDaEmpresa();
        if (mounted) {
          await context
              .read<ColaboradorAutorizacoesProvider>()
              .carregarAutorizacoesDoUsuarioLogado(force: true);
          await _applyAuthenticatedLocale();
        }
        await FirebasePushNotificationService().syncTokenForLoggedUser();
      } catch (e) {
        debugPrint('[AuthGateMobile] Erro ao restaurar dados da empresa: $e');
      }

      if (!mounted) return;
      _goToHome();
    } catch (error) {
      debugPrint('[AuthGateMobile] Falha temporária inesperada: $error');
      if (mounted) {
        setState(() => _status = _AuthGateMobileStatus.temporaryError);
      }
    } finally {
      _restoring = false;
    }
  }

  Future<void> _applyAuthenticatedLocale() async {
    try {
      final String? idiomaDePreferencia = await _usuarioService
          .buscarDadosDoUsuario_atualizaProviders();
      if (!mounted) return;

      final regionalizacaoService = RegionalizacaoService(
        apiClient: HttpRegionalizacaoApiClient(),
      );
      final regionalizacao = await regionalizacaoService.buscarRegionalizacao();
      if (!mounted) return;

      await context.read<LocaleSettingsProvider>().applyAuthenticatedLocale(
        idiomaDePreferencia: idiomaDePreferencia,
        regionalizacao: regionalizacao,
      );
    } catch (error) {
      debugPrint(
        '[AuthGateMobile] Erro ao aplicar idioma/regionalizacao: $error',
      );
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const MobileMainShell(
          initialIndex: MobileNavigationController.dashIndex,
        ),
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
    if (_status == _AuthGateMobileStatus.validating) {
      return Scaffold(
        body: SixoAppMobileLoadingScene(
          message: context.t(
            'splash.validatingSession',
            fallback: 'Validando sua sessão...',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SixMobilePalette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildTemporaryErrorState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTemporaryErrorState(BuildContext context) {
    return Semantics(
      key: const ValueKey<String>('auth-gate-mobile-temporary-error'),
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: SixMobilePalette.accent,
                size: 27,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.t(
                'auth.session.temporaryErrorTitle',
                fallback: 'Não foi possível validar sua sessão',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                'auth.session.temporaryErrorMessage',
                fallback:
                    'Sua sessão foi preservada. Verifique sua conexão e tente novamente.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: SixMobilePalette.mutedText, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _restoreSession,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: Text(
                  context.t('common.tryAgain', fallback: 'Tentar novamente'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: SixMobilePalette.accent,
                  foregroundColor: SixMobilePalette.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
