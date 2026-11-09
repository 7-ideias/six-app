import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/services/firebase_push_notification_service.dart';
import '../../core/services/mobile_session_restoration_service.dart';
import '../../core/services/mobile_session_bootstrap_service.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../navigation/mobile_navigation_controller.dart';
import 'auth_entry_mobile.dart';
import 'mobile_main_shell.dart';
import 'onboarding_inicial_mobile_screen.dart';

class AuthGateMobile extends StatefulWidget {
  const AuthGateMobile({super.key});

  @override
  State<AuthGateMobile> createState() => _AuthGateMobileState();
}

enum _AuthGateMobileStatus { validating, biometricLocked, temporaryError }

class _AuthGateMobileState extends State<AuthGateMobile>
    with WidgetsBindingObserver {
  final MobileSessionRestorationService _sessionRestorationService =
      MobileSessionRestorationService();
  final AuthService _authService = AuthService();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();
  final UsuarioService _usuarioService = UsuarioService();
  final MobileSessionBootstrapService _bootstrapService =
      const MobileSessionBootstrapService();
  final MobileSessionRecoveryPolicy _recoveryPolicy =
      const MobileSessionRecoveryPolicy();

  Timer? _retryTimer;
  int _consecutiveFailures = 0;
  bool _biometricUnlocked = false;
  bool _retrying = false;

  _AuthGateMobileStatus _status = _AuthGateMobileStatus.validating;
  MobileBiometricAvailability _biometricAvailability =
      const MobileBiometricAvailability.unavailable();
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_restoreSession());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _status == _AuthGateMobileStatus.temporaryError &&
        !_restoring) {
      // iOS/Android: tentar imediatamente ao retornar ao primeiro plano.
      _retryTimer?.cancel();
      unawaited(_restoreSession());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Nao consumir bateria nem renovar token com a tela em background.
      _retryTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleAutomaticRetry() {
    _retryTimer?.cancel();
    if (!mounted) return;
    final Duration delay = _recoveryPolicy.delayForFailure(
      _consecutiveFailures,
    );
    _retryTimer = Timer(delay, () {
      if (mounted &&
          !_restoring &&
          _status == _AuthGateMobileStatus.temporaryError) {
        unawaited(_restoreSession());
      }
    });
  }

  void _showTemporaryFailure(Object error, {required String phase}) {
    debugPrint('[AuthGateMobile] Falha temporaria em $phase: $error');
    if (!mounted) return;
    _consecutiveFailures++;
    setState(() => _status = _AuthGateMobileStatus.temporaryError);
    _scheduleAutomaticRetry();
  }

  Future<void> _restoreSession() async {
    if (!mounted || _restoring) return;
    _restoring = true;
    _retryTimer?.cancel();

    final bool retryFromError =
        _status == _AuthGateMobileStatus.temporaryError;
    setState(() {
      // Mantem a tela estavel durante novas tentativas automaticas.
      _retrying = retryFromError;
      if (!retryFromError) {
        _status = _AuthGateMobileStatus.validating;
      }
    });

    try {
      final bool unlocked = await _unlockBiometricSessionIfNeeded();
      if (!unlocked || !mounted) return;

      final MobileSessionRestorationResult restoration =
          await _sessionRestorationService.restore();

      switch (restoration.status) {
        case MobileSessionRestorationStatus.noStoredSession:
        case MobileSessionRestorationStatus.invalidSession:
          if (mounted) _goToLogin();
          return;
        case MobileSessionRestorationStatus.temporaryFailure:
          _showTemporaryFailure(
            restoration.error ?? StateError('Restauracao indisponivel'),
            phase: 'restauracao da sessao',
          );
          return;
        case MobileSessionRestorationStatus.restored:
          break;
      }

      // Somente as consultas essenciais impedem a entrada. Falhas de
      // notificacoes e regionalizacao nao invalidam a sessao autenticada.
      await _bootstrapService.prepare(
        loadCompany: () async {
          await EmpresaService().buscarDadosDaEmpresa();
        },
        loadPermissions: () async {
          if (!mounted) return;
          final ColaboradorAutorizacoesProvider permissions = context
              .read<ColaboradorAutorizacoesProvider>();
          await permissions.carregarAutorizacoesDoUsuarioLogado(force: true);
          if (!permissions.autorizacoesCarregadasComSucesso) {
            throw StateError(
              'Permissoes indisponiveis: ${permissions.erro ?? "sem detalhes"}',
            );
          }
        },
        loadOnboarding: () async {
          if (!mounted) return;
          await context.read<OnboardingInicialProvider>().carregar(force: true);
        },
      );

      if (!mounted) return;
      await _applyAuthenticatedLocale();
      if (!mounted) return;

      _consecutiveFailures = 0;
      if (context.read<OnboardingInicialProvider>().precisaFazerOnboarding) {
        _goToOnboarding();
      } else {
        _goToHome();
      }
    } catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      if (_recoveryPolicy.isInvalidSession(error)) {
        // Somente uma invalidacao confirmada no refresh derruba a sessao.
        try {
          await _authService.clearLocalSession();
          if (mounted) _goToLogin();
        } catch (cleanupError) {
          _showTemporaryFailure(
            cleanupError,
            phase: 'limpeza de sessao invalida',
          );
        }
      } else {
        _showTemporaryFailure(error, phase: 'preparacao da conta');
      }
    } finally {
      _restoring = false;
      if (mounted && _retrying) {
        setState(() => _retrying = false);
      }
    }
  }

  Future<bool> _unlockBiometricSessionIfNeeded() async {
    // Repetir uma consulta de rede nao deve exigir outro Face ID.
    if (_biometricUnlocked) return true;

    final String refreshToken =
        (await _authService.getRefreshToken())?.trim() ?? '';
    if (refreshToken.isEmpty || !await _biometricAuthService.isEnabled()) {
      _biometricUnlocked = true;
      return true;
    }

    final String ownerId =
        (await _biometricAuthService.enabledUserId())?.trim() ?? '';
    final String currentUserId = (await _authService.getUserId())?.trim() ?? '';

    // A biometria é somente uma camada local. Se os metadados biométricos
    // estiverem inconsistentes, desabilitamos apenas a biometria e preservamos
    // a sessão Keycloak para que a restauração normal decida sua validade.
    if (ownerId.isEmpty ||
        (currentUserId.isNotEmpty && ownerId != currentUserId)) {
      await _biometricAuthService.disable();
      _biometricUnlocked = true;
      return true;
    }

    _biometricAvailability = await _biometricAuthService.availability();
    if (!_biometricAvailability.canAuthenticate) {
      if (mounted) {
        setState(() => _status = _AuthGateMobileStatus.biometricLocked);
      }
      return false;
    }

    final bool authenticated = await _biometricAuthService.authenticate(
      localizedReason: _biometricReason(),
    );
    if (!authenticated) {
      if (mounted) {
        setState(() => _status = _AuthGateMobileStatus.biometricLocked);
      }
      return false;
    }

    _biometricUnlocked = true;
    return true;
  }

  String _biometricReason() {
    return _localized(
      pt: 'Confirme sua identidade para acessar o SixoApp.',
      en: 'Confirm your identity to access SixoApp.',
      es: 'Confirma tu identidad para acceder a SixoApp.',
    );
  }

  String _localized({
    required String pt,
    required String en,
    required String es,
  }) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
  }

  String _biometricName() {
    return switch (_biometricAvailability.kind) {
      MobileBiometricKind.faceId => 'Face ID',
      MobileBiometricKind.touchId => 'Touch ID',
      MobileBiometricKind.face => _localized(
          pt: 'reconhecimento facial',
          en: 'face recognition',
          es: 'reconocimiento facial',
        ),
      MobileBiometricKind.fingerprint => _localized(
          pt: 'impressão digital',
          en: 'fingerprint',
          es: 'huella digital',
        ),
      MobileBiometricKind.generic => _localized(
          pt: 'biometria',
          en: 'biometrics',
          es: 'biometría',
        ),
    };
  }

  IconData _biometricIcon() {
    return switch (_biometricAvailability.kind) {
      MobileBiometricKind.fingerprint || MobileBiometricKind.touchId =>
        Icons.fingerprint_rounded,
      MobileBiometricKind.faceId || MobileBiometricKind.face =>
        Icons.face_retouching_natural_rounded,
      MobileBiometricKind.generic => Icons.shield_outlined,
    };
  }

  Future<void> _applyAuthenticatedLocale() async {
    try {
      final String? idiomaDePreferencia = await _usuarioService
          .buscarDadosDoUsuario_atualizaProviders()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final regionalizacaoService = RegionalizacaoService(
        apiClient: HttpRegionalizacaoApiClient(),
      );
      final regionalizacao = await regionalizacaoService
          .buscarRegionalizacao()
          .timeout(const Duration(seconds: 8));
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

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingInicialMobileScreen(
          onCompleted: _replaceWithHome,
        ),
      ),
    );
  }

  void _replaceWithHome(BuildContext onboardingContext) {
    Navigator.of(onboardingContext).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MobileMainShell(
          initialIndex: MobileNavigationController.dashIndex,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _goToLogin() {
    _retryTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthEntryMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _AuthGateMobileStatus.validating) {
      return Scaffold(
        body: SixoAppMobileLoadingScene.themed(
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
            child:
                _status == _AuthGateMobileStatus.biometricLocked
                    ? _buildBiometricLockedState(context)
                    : _buildTemporaryErrorState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricLockedState(BuildContext context) {
    final bool available = _biometricAvailability.canAuthenticate;
    final String biometricName = _biometricName();

    return Semantics(
      key: const ValueKey<String>('auth-gate-mobile-biometric-locked'),
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _biometricIcon(),
                color: SixMobilePalette.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _localized(
                pt: 'Desbloqueie o SixoApp',
                en: 'Unlock SixoApp',
                es: 'Desbloquea SixoApp',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              available
                  ? _localized(
                    pt: 'Use $biometricName para liberar sua sessão com segurança. Sua biometria permanece somente neste aparelho.',
                    en: 'Use $biometricName to securely unlock your session. Your biometric data stays on this device.',
                    es: 'Usa $biometricName para desbloquear tu sesión de forma segura. Tus datos biométricos permanecen en este dispositivo.',
                  )
                  : _localized(
                    pt: 'A biometria configurada para esta sessão não está disponível neste aparelho. Você ainda pode entrar com e-mail e senha.',
                    en: 'The biometric method configured for this session is not available on this device. You can still sign in with email and password.',
                    es: 'La biometría configurada para esta sesión no está disponible en este dispositivo. Aún puedes entrar con correo y contraseña.',
                  ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (available)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _restoring ? null : _restoreSession,
                  icon: Icon(_biometricIcon(), size: 20),
                  label: Text(
                    _localized(
                      pt: 'Usar $biometricName',
                      en: 'Use $biometricName',
                      es: 'Usar $biometricName',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: SixMobilePalette.accent,
                    foregroundColor: SixMobilePalette.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            if (available) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _goToLogin,
                icon: const Icon(Icons.password_rounded, size: 19),
                label: Text(
                  _localized(
                    pt: 'Entrar com e-mail e senha',
                    en: 'Sign in with email and password',
                    es: 'Entrar con correo y contraseña',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SixMobilePalette.titleText,
                  side: BorderSide(color: SixMobilePalette.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
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
            const SizedBox(height: 10),
            Text(
              _localized(
                pt: 'Tentaremos reconectar automaticamente. Voce tambem pode tentar agora.',
                en: 'We will reconnect automatically. You can also try now.',
                es: 'Intentaremos reconectar automaticamente. Tambien puedes intentarlo ahora.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _restoring ? null : _restoreSession,
                icon: _retrying
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 19),
                label: Text(
                  _retrying
                      ? _localized(
                          pt: 'Reconectando...',
                          en: 'Reconnecting...',
                          es: 'Reconectando...',
                        )
                      : context.t('common.tryAgain', fallback: 'Tentar novamente'),
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
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _restoring ? null : _goToLogin,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                _localized(
                  pt: 'Entrar novamente',
                  en: 'Sign in again',
                  es: 'Iniciar sesion de nuevo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
