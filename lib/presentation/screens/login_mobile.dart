import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/google_account_link_mobile_sheet.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';
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
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
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
      _navigateToPostLoginSplash();
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
      await _googleAuthService.signIn(
        intent: GoogleAuthIntent.login,
        idioma: _languageTag,
        persistSession: true,
      );
      if (!mounted) return;
      _navigateToPostLoginSplash();
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

  Future<void> _linkGoogleAccount() async {
    final String? password = await showGoogleAccountLinkMobileSheet(
      context,
      creatingAccount: false,
    );
    if (!mounted || password == null) return;

    setState(() => _isLoading = true);
    try {
      await _googleAuthService.linkPendingAccount(
        senha: password,
        intent: GoogleAuthIntent.login,
        aceiteTermos: false,
        idioma: _languageTag,
        persistSession: true,
      );
      if (!mounted) return;
      _navigateToPostLoginSplash();
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
