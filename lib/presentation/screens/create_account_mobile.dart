import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/google_account_link_mobile_sheet.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/nova_empresa_service.dart';
import 'conta_criada_mobile.dart';
import 'login_mobile.dart';
import 'post_login_splash_mobile_page.dart';

class CreateAccountMobile extends StatefulWidget {
  const CreateAccountMobile({super.key});

  @override
  State<CreateAccountMobile> createState() => _CreateAccountMobileState();
}

class _CreateAccountMobileState extends State<CreateAccountMobile> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final NovaEmpresaService _novaEmpresaService = NovaEmpresaService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _showTraditional = false;
  String? _passwordMismatchError;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _languageTag => Localizations.localeOf(context).toLanguageTag();

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateTerms() {
    if (_agreeTerms) return true;
    _showSnack(
      context.t(
        'auth.mobileCreate.acceptTermsError',
        fallback: 'Aceite os Termos e a Política de Privacidade para continuar.',
      ),
    );
    return false;
  }

  Future<void> _signUpWithGoogle() async {
    if (_isLoading || !_validateTerms()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _googleAuthService.signIn(
        intent: GoogleAuthIntent.registration,
        aceiteTermos: true,
        idioma: _languageTag,
        persistSession: true,
      );
      if (!mounted) return;
      _navigateToPostLoginSplash();
    } on GoogleAuthException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleAuthErrorCode.cancelledByUser) return;
      if (error.code == GoogleAuthErrorCode.linkRequired) {
        await _linkGoogleAccount();
        return;
      }
      _showSnack(_googleMessage(error));
    } catch (_) {
      if (mounted) {
        _showSnack(
          context.t(
            'auth.googleCreateError',
            fallback: 'Não foi possível criar sua conta com Google.',
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
      creatingAccount: true,
    );
    if (!mounted || password == null) return;

    setState(() => _isLoading = true);
    try {
      await _googleAuthService.linkPendingAccount(
        senha: password,
        intent: GoogleAuthIntent.registration,
        aceiteTermos: true,
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
      GoogleAuthErrorCode.termsRequired => context.t(
          'auth.mobileCreate.acceptTermsError',
          fallback: 'Aceite os Termos e a Política de Privacidade para continuar.',
        ),
      GoogleAuthErrorCode.unavailable => context.t(
          'auth.googleUnavailable',
          fallback: 'O cadastro com Google está temporariamente indisponível.',
        ),
      GoogleAuthErrorCode.network => context.t(
          'auth.googleNetworkError',
          fallback: 'Falha de conexão. Verifique sua internet e tente novamente.',
        ),
      _ => error.message,
    };
  }

  Future<void> _signUpTraditional() async {
    if (_isLoading || !_validateTerms()) return;

    final String login = _loginController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (login.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack(
        context.t(
          'auth.mobileCreate.requiredFieldsError',
          fallback: 'Preencha todos os campos.',
        ),
      );
      return;
    }
    if (password.length < 8) {
      _showSnack(
        context.t(
          'auth.mobileCreate.passwordLengthError',
          fallback: 'A senha precisa ter ao menos 8 caracteres.',
        ),
      );
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _passwordMismatchError = context.t(
          'auth.mobileCreate.passwordMismatchInline',
          fallback: 'As senhas não coincidem.',
        );
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _passwordMismatchError = null;
      _isLoading = true;
    });
    try {
      await _novaEmpresaService.criarNovaEmpresa(login: login, senha: password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ContaCriadaMobile()),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      _showSnack(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToPostLoginSplash() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const PostLoginSplashMobilePage(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return SixoAppAuthMobileScaffold(
      title: context.t('auth.mobileCreate.title', fallback: 'Crie seu espaço'),
      subtitle: context.t(
        'auth.mobileCreate.subtitle',
        fallback: 'Comece simples. O SixoApp cresce junto com seu negócio.',
      ),
      compactHeader: true,
      onBack: () => Navigator.of(context).maybePop(),
      backSemanticLabel: context.t('common.back', fallback: 'Voltar'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SixStaggeredEntry(
            child: Text(
              context.t(
                'auth.mobileCreate.formTitle',
                fallback: 'Sua conta começa aqui',
              ),
              style: TextStyle(
                color: colors.titleText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              'auth.mobileCreate.googleIntro',
              fallback:
                  'Crie sua conta com Google sem definir uma senha do SixoApp.',
            ),
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _TermsAgreement(
            value: _agreeTerms,
            onChanged: _isLoading
                ? null
                : (bool value) => setState(() => _agreeTerms = value),
          ),
          const SizedBox(height: 18),
          SixoAppAuthSecondaryButton(
            label: context.t(
              'auth.createWithGoogle',
              fallback: 'Criar conta com Google',
            ),
            onPressed: _isLoading ? null : _signUpWithGoogle,
            leading: const _GoogleGlyph(),
          ),
          const SizedBox(height: 10),
          Text(
            context.t(
              'auth.mobileCreate.googleNoPassword',
              fallback:
                  'O Google será seu método de acesso. Nenhuma senha do SixoApp será solicitada.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SixoAppAuthDivider(
            label: context.t(
              'auth.mobileCreate.traditionalDivider',
              fallback: 'ou use login e senha',
            ),
          ),
          const SizedBox(height: 14),
          SixoAppAuthSecondaryButton(
            label: context.t(
              _showTraditional
                  ? 'auth.mobileCreate.hideTraditional'
                  : 'auth.mobileCreate.showTraditional',
              fallback: _showTraditional
                  ? 'Ocultar cadastro com login e senha'
                  : 'Criar com login e senha',
            ),
            onPressed: _isLoading
                ? null
                : () => setState(() => _showTraditional = !_showTraditional),
            leading: Icon(
              _showTraditional
                  ? Icons.expand_less_rounded
                  : Icons.person_outline_rounded,
              color: SixMobilePalette.brandBlue,
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showTraditional
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: AutofillGroup(child: _traditionalForm(colors)),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: _goToLogin,
              child: Text(
                context.t(
                  'auth.mobileCreate.loginPrompt',
                  fallback: 'Já tem uma conta? Entrar',
                ),
                style: const TextStyle(
                  color: SixMobilePalette.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _traditionalForm(SixMobileColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SixoAppAuthField(
          controller: _loginController,
          label: context.t('auth.mobileCreate.loginLabel', fallback: 'Login'),
          hint: context.t(
            'auth.mobileCreate.loginHint',
            fallback: 'Escolha seu login de acesso',
          ),
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.newUsername],
          autocorrect: false,
        ),
        const SizedBox(height: 14),
        SixoAppAuthField(
          controller: _passwordController,
          label: context.t('auth.mobileCreate.passwordLabel', fallback: 'Senha'),
          hint: context.t(
            'auth.mobileCreate.passwordHint',
            fallback: 'Mínimo de 8 caracteres',
          ),
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_passwordMismatchError != null) {
              setState(() => _passwordMismatchError = null);
            }
          },
          autofillHints: const <String>[AutofillHints.newPassword],
          enableSuggestions: false,
          autocorrect: false,
          suffix: _PasswordVisibilityButton(
            obscure: _obscurePassword,
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
        const SizedBox(height: 14),
        SixoAppAuthField(
          controller: _confirmPasswordController,
          label: context.t(
            'auth.mobileCreate.confirmPasswordLabel',
            fallback: 'Confirme a senha',
          ),
          hint: context.t(
            'auth.mobileCreate.confirmPasswordHint',
            fallback: 'Repita sua senha',
          ),
          icon: Icons.verified_user_outlined,
          obscure: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_passwordMismatchError != null) {
              setState(() => _passwordMismatchError = null);
            }
          },
          onSubmitted: (_) => _signUpTraditional(),
          autofillHints: const <String>[AutofillHints.newPassword],
          enableSuggestions: false,
          autocorrect: false,
          suffix: _PasswordVisibilityButton(
            obscure: _obscureConfirmPassword,
            onPressed: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
        ),
        if (_passwordMismatchError != null) ...<Widget>[
          const SizedBox(height: 7),
          Text(
            _passwordMismatchError!,
            style: TextStyle(
              color: colors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 18),
        SixoAppAuthPrimaryButton(
          label: context.t(
            'auth.mobileCreate.submit',
            fallback: 'Criar conta com login e senha',
          ),
          onPressed: _signUpTraditional,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      checked: value,
      button: true,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox.square(
                dimension: 32,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged == null
                      ? null
                      : (bool? checked) => onChanged!(checked ?? false),
                  activeColor: SixMobilePalette.brandBlue,
                  checkColor: SixMobilePalette.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t(
                    'auth.mobileCreate.acceptTerms',
                    fallback:
                        'Concordo com os Termos de Serviço e a Política de Privacidade.',
                  ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.obscure,
    required this.onPressed,
  });

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return IconButton(
      tooltip: context.t(
        obscure
            ? 'auth.mobileLogin.showPassword'
            : 'auth.mobileLogin.hidePassword',
        fallback: obscure ? 'Mostrar senha' : 'Ocultar senha',
      ),
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: colors.mutedText,
        size: 20,
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
