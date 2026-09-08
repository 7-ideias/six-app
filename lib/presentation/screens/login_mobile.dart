import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/google_account_link_mobile_sheet.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/mobile_session_restoration_service.dart';
import 'create_account_mobile.dart';
import 'esqueceu_senha_mobile.dart';
import 'post_login_splash_mobile_page.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  State<LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final GlobalKey _submitButtonKey = GlobalKey();
  final AuthService _authService = AuthService();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();
  final MobileSessionRestorationService _sessionRestorationService =
      MobileSessionRestorationService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricEnabled = false;
  bool _hasProtectedSession = false;
  MobileBiometricAvailability _biometricAvailability =
      const MobileBiometricAvailability.unavailable();

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBiometricState();
    });
  }

  @override
  void dispose() {
    _passwordFocusNode
      ..removeListener(_handlePasswordFocusChange)
      ..dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handlePasswordFocusChange() {
    if (!_passwordFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 280),
        _ensureSubmitButtonVisible,
      );
    });
  }

  Future<void> _ensureSubmitButtonVisible() async {
    if (!mounted || !_passwordFocusNode.hasFocus) return;
    final BuildContext? buttonContext = _submitButtonKey.currentContext;
    if (buttonContext == null || !buttonContext.mounted) return;
    await Scrollable.ensureVisible(
      buttonContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.86,
    );
  }

  String get _languageTag => Localizations.localeOf(context).toLanguageTag();

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

  String _biometricName([MobileBiometricAvailability? availability]) {
    final MobileBiometricAvailability current =
        availability ?? _biometricAvailability;
    return switch (current.kind) {
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

  IconData _biometricIcon([MobileBiometricAvailability? availability]) {
    final MobileBiometricAvailability current =
        availability ?? _biometricAvailability;
    return switch (current.kind) {
      MobileBiometricKind.fingerprint || MobileBiometricKind.touchId =>
        Icons.fingerprint_rounded,
      MobileBiometricKind.faceId || MobileBiometricKind.face =>
        Icons.face_retouching_natural_rounded,
      MobileBiometricKind.generic => Icons.shield_outlined,
    };
  }

  Future<void> _loadBiometricState() async {
    final MobileBiometricAvailability availability =
        await _biometricAuthService.availability();
    final String? userId = await _authService.getUserId();
    final bool enabled = await _biometricAuthService.isEnabled();
    final bool protectedSession =
        enabled &&
        await _biometricAuthService.hasProtectedSessionForUser(userId);

    if (!mounted) return;
    setState(() {
      _biometricAvailability = availability;
      _biometricEnabled = enabled;
      _hasProtectedSession = protectedSession;
    });
  }

  Future<void> _login() async {
    final String login = _loginController.text.trim();
    final String senha = _passwordController.text;
    if (login.isEmpty || senha.isEmpty) {
      _showSnack(
        context.t(
          'auth.loginRequiredFields',
          fallback: 'Por favor, preencha o e-mail e a senha.',
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _authService.login(login, senha);
      if (!mounted) return;
      await _afterInteractiveLogin();
    } catch (error) {
      _showSnack(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.loginWithGoogle(
        intent: GoogleAuthIntent.login,
        idioma: _languageTag,
      );
      if (!mounted) return;
      await _afterInteractiveLogin();
    } on GoogleAuthException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleAuthErrorCode.cancelledByUser) return;
      if (error.code == GoogleAuthErrorCode.registrationRequired) {
        _openCreateAccount();
        return;
      }
      if (error.code == GoogleAuthErrorCode.linkRequired) {
        await _linkGoogleAccount();
        return;
      }
      _showSnack(_googleMessage(error));
    } catch (_) {
      if (mounted) {
        _showSnack(
          context.t(
            'auth.googleLoginError',
            fallback: 'Não foi possível concluir o login com Google.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_isLoading || !_hasProtectedSession) return;

    setState(() => _isLoading = true);
    try {
      final String? userId = await _authService.getUserId();
      if (!await _biometricAuthService.hasProtectedSessionForUser(userId)) {
        await _loadBiometricState();
        if (mounted) {
          _showSnack(
            _localized(
              pt: 'A sessão biométrica não está mais disponível. Entre com sua senha.',
              en: 'The biometric session is no longer available. Sign in with your password.',
              es: 'La sesión biométrica ya no está disponible. Entra con tu contraseña.',
            ),
          );
        }
        return;
      }

      final bool authenticated = await _biometricAuthService.authenticate(
        localizedReason: _localized(
          pt: 'Confirme sua identidade para acessar o SixoApp.',
          en: 'Confirm your identity to access SixoApp.',
          es: 'Confirma tu identidad para acceder a SixoApp.',
        ),
      );
      if (!authenticated) return;

      final MobileSessionRestorationResult restoration =
          await _sessionRestorationService.restore();
      if (!mounted) return;

      switch (restoration.status) {
        case MobileSessionRestorationStatus.restored:
          _navigateToPostLoginSplash();
          return;
        case MobileSessionRestorationStatus.noStoredSession:
        case MobileSessionRestorationStatus.invalidSession:
          await _loadBiometricState();
          if (mounted) {
            _showSnack(
              _localized(
                pt: 'Sua sessão expirou. Entre novamente para continuar.',
                en: 'Your session expired. Sign in again to continue.',
                es: 'Tu sesión expiró. Vuelve a entrar para continuar.',
              ),
            );
          }
          return;
        case MobileSessionRestorationStatus.temporaryFailure:
          _showSnack(
            _localized(
              pt: 'Não foi possível validar sua sessão agora. Verifique sua conexão.',
              en: 'We could not validate your session right now. Check your connection.',
              es: 'No pudimos validar tu sesión ahora. Revisa tu conexión.',
            ),
          );
          return;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _afterInteractiveLogin() async {
    final String? userId = await _authService.getUserId();
    await _biometricAuthService.reconcileAuthenticatedUser(userId);
    if (!mounted) return;

    await _maybeOfferBiometricEnrollment(userId);
    if (!mounted) return;
    _navigateToPostLoginSplash();
  }

  Future<void> _maybeOfferBiometricEnrollment(String? userId) async {
    final String normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isEmpty || await _biometricAuthService.isEnabled()) {
      return;
    }

    final MobileBiometricAvailability availability =
        await _biometricAuthService.availability();
    if (!availability.canAuthenticate || !mounted) {
      return;
    }

    final bool? wantsToEnable = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: SixMobilePalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext sheetContext) {
        final String biometricName = _biometricName(availability);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softAccentSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _biometricIcon(availability),
                    color: SixMobilePalette.accent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _localized(
                    pt: 'Ativar $biometricName?',
                    en: 'Enable $biometricName?',
                    es: '¿Activar $biometricName?',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _localized(
                    pt: 'Na próxima abertura, você poderá acessar sua sessão sem digitar a senha. A biometria é validada somente pelo aparelho e não é enviada ao SixoApp.',
                    en: 'Next time you open the app, you can access your session without typing your password. Biometrics are validated only by your device and are never sent to SixoApp.',
                    es: 'La próxima vez que abras la app, podrás acceder a tu sesión sin escribir la contraseña. La biometría se valida solo en tu dispositivo y nunca se envía a SixoApp.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SixMobilePalette.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    icon: Icon(_biometricIcon(availability), size: 20),
                    label: Text(
                      _localized(
                        pt: 'Ativar $biometricName',
                        en: 'Enable $biometricName',
                        es: 'Activar $biometricName',
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(
                    _localized(
                      pt: 'Agora não',
                      en: 'Not now',
                      es: 'Ahora no',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (wantsToEnable != true || !mounted) {
      return;
    }

    final bool enabled = await _biometricAuthService.enableForUser(
      userId: normalizedUserId,
      localizedReason: _localized(
        pt: 'Confirme sua identidade para ativar o acesso biométrico ao SixoApp.',
        en: 'Confirm your identity to enable biometric access to SixoApp.',
        es: 'Confirma tu identidad para activar el acceso biométrico a SixoApp.',
      ),
    );

    if (!mounted) return;
    if (enabled) {
      _showSnack(
        _localized(
          pt: '${_biometricName(availability)} ativado neste aparelho.',
          en: '${_biometricName(availability)} enabled on this device.',
          es: '${_biometricName(availability)} activado en este dispositivo.',
        ),
      );
    } else {
      _showSnack(
        _localized(
          pt: 'Não foi possível ativar a biometria. Você poderá tentar novamente depois.',
          en: 'Biometrics could not be enabled. You can try again later.',
          es: 'No se pudo activar la biometría. Podrás intentarlo de nuevo más tarde.',
        ),
      );
    }
  }

  Future<void> _linkGoogleAccount() async {
    final String? password = await showGoogleAccountLinkMobileSheet(
      context,
      creatingAccount: false,
    );
    if (!mounted || password == null) return;

    setState(() => _isLoading = true);
    try {
      await _authService.linkPendingGoogleAccount(
        senha: password,
        intent: GoogleAuthIntent.login,
        aceiteTermos: false,
        idioma: _languageTag,
      );
      if (!mounted) return;
      await _afterInteractiveLogin();
    } on GoogleAuthException catch (error) {
      if (mounted) _showSnack(_googleMessage(error));
    }
  }

  String _googleMessage(GoogleAuthException error) {
    return switch (error.code) {
      GoogleAuthErrorCode.invalidExistingPassword => context.t(
          'auth.googleLink.invalidPassword',
          fallback: 'A senha atual informada não foi aceita.',
        ),
      GoogleAuthErrorCode.unavailable => context.t(
          'auth.googleUnavailable',
          fallback: 'O login com Google está temporariamente indisponível.',
        ),
      GoogleAuthErrorCode.network => context.t(
          'auth.googleNetworkError',
          fallback: 'Falha de conexão. Verifique sua internet e tente novamente.',
        ),
      _ => error.message,
    };
  }

  void _navigateToPostLoginSplash() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PostLoginSplashMobilePage(),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const EsqueceuSenhaMobile()),
    );
  }

  void _openCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CreateAccountMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool showBiometricLogin =
        _biometricEnabled &&
        _hasProtectedSession &&
        _biometricAvailability.canAuthenticate;

    return SixoAppAuthMobileScaffold(
      title: context.t(
        'auth.mobileLogin.title',
        fallback: 'Bem-vindo de volta',
      ),
      subtitle: context.t(
        'auth.mobileLogin.subtitle',
        fallback: 'Entre para continuar de onde parou.',
      ),
      compactHeader: true,
      onBack: () => Navigator.of(context).maybePop(),
      backSemanticLabel: context.t('common.back', fallback: 'Voltar'),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SixStaggeredEntry(
              child: Text(
                context.t(
                  'auth.mobileLogin.formTitle',
                  fallback: 'Acesse seu espaço',
                ),
                style: TextStyle(
                  color: colors.titleText,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (showBiometricLogin) ...<Widget>[
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 35),
                child: SixoAppAuthSecondaryButton(
                  label: _localized(
                    pt: 'Entrar com ${_biometricName()}',
                    en: 'Sign in with ${_biometricName()}',
                    es: 'Entrar con ${_biometricName()}',
                  ),
                  onPressed: _isLoading ? null : _loginWithBiometrics,
                  leading: Icon(
                    _biometricIcon(),
                    color: colors.titleText,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 50),
              child: SixoAppAuthSecondaryButton(
                label: context.t(
                  'auth.signInWithGoogle',
                  fallback: 'Entrar com Google',
                ),
                onPressed: _isLoading ? null : _loginWithGoogle,
                leading: const _GoogleGlyph(),
              ),
            ),
            const SizedBox(height: 18),
            SixoAppAuthDivider(
              label: context.t(
                'auth.mobileLogin.socialDivider',
                fallback: 'ou entre com e-mail e senha',
              ),
            ),
            const SizedBox(height: 18),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 80),
              child: SixoAppAuthField(
                controller: _loginController,
                hint: context.t(
                  'auth.mobileLogin.emailHint',
                  fallback: 'voce@empresa.com',
                ),
                label: context.t('auth.email', fallback: 'E-mail'),
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 14),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 110),
              child: SixoAppAuthField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hint: context.t(
                  'auth.mobileLogin.passwordHint',
                  fallback: 'Digite sua senha',
                ),
                label: context.t('auth.password', fallback: 'Senha'),
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                enableSuggestions: false,
                autocorrect: false,
                onSubmitted: (_) => _login(),
                suffix: IconButton(
                  tooltip: context.t(
                    _obscurePassword
                        ? 'auth.mobileLogin.showPassword'
                        : 'auth.mobileLogin.hidePassword',
                    fallback:
                        _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.mutedText,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: SixMobilePalette.brandBlue,
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  context.t(
                    'auth.forgotPassword',
                    fallback: 'Esqueceu a senha?',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: _submitButtonKey,
              child: SixoAppAuthPrimaryButton(
                label: context.t(
                  'auth.mobileLogin.submit',
                  fallback: 'Entrar',
                ),
                onPressed: _login,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  context.t(
                    'auth.mobileLogin.createPrompt',
                    fallback: 'Primeira vez no SixoApp?',
                  ),
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _openCreateAccount,
                  child: Text(
                    context.t(
                      'auth.mobileEntry.createAction',
                      fallback: 'Criar minha conta',
                    ),
                    style: const TextStyle(
                      color: SixMobilePalette.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.t(
                  'auth.mobileLogin.googleNote',
                  fallback:
                      'O Google não altera sua senha existente. Se o e-mail já estiver cadastrado, o vínculo será confirmado uma única vez.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      semanticsLabel: 'Google',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
