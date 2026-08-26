import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import '../../core/services/nova_empresa_service.dart';
import 'conta_criada_mobile.dart';
import 'login_mobile.dart';

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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _passwordMismatchError;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearPasswordMismatchError(String _) {
    if (_passwordMismatchError == null) return;
    setState(() => _passwordMismatchError = null);
  }

  Future<void> _signUp() async {
    if (!_agreeTerms) {
      _showSnack(
        context.t(
          'auth.mobileCreate.acceptTermsError',
          fallback: 'Aceite os Termos e Condições para continuar.',
        ),
      );
      return;
    }

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
      _showSnack(
        context.t(
          'auth.mobileCreate.passwordMismatchError',
          fallback:
              'As senhas informadas não são iguais. Verifique e tente novamente.',
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _passwordMismatchError = null;
      _isLoading = true;
    });
    try {
      await _novaEmpresaService.criarNovaEmpresa(
        login: login,
        senha: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const ContaCriadaMobile(),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      _showSnack(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final String backLabel = context.t('common.back', fallback: 'Voltar');

    return SixoAppAuthMobileScaffold(
      title: context.t(
        'auth.mobileCreate.title',
        fallback: 'Crie seu espaço',
      ),
      subtitle: context.t(
        'auth.mobileCreate.subtitle',
        fallback: 'Comece simples. O SixoApp cresce junto com seu negócio.',
      ),
      compactHeader: true,
      onBack: () => Navigator.of(context).maybePop(),
      backSemanticLabel: backLabel,
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SixStaggeredEntry(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.brandBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: SixMobilePalette.brandBlue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.t(
                            'auth.mobileCreate.formTitle',
                            fallback: 'Sua conta começa aqui',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.titleText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.t(
                            'auth.mobileCreate.formNote',
                            fallback: 'Leva menos de um minuto.',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 50),
              child: SixoAppAuthField(
                controller: _loginController,
                label: context.t(
                  'auth.mobileCreate.loginLabel',
                  fallback: 'Login',
                ),
                hint: context.t(
                  'auth.mobileCreate.loginHint',
                  fallback: 'Escolha seu login de acesso',
                ),
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newUsername],
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 14),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 90),
              child: SixoAppAuthField(
                controller: _passwordController,
                label: context.t(
                  'auth.mobileCreate.passwordLabel',
                  fallback: 'Senha',
                ),
                hint: context.t(
                  'auth.mobileCreate.passwordHint',
                  fallback: 'Mínimo de 8 caracteres',
                ),
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.next,
                onChanged: _clearPasswordMismatchError,
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
            ),
            const SizedBox(height: 14),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 130),
              child: SixoAppAuthField(
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
                onChanged: _clearPasswordMismatchError,
                autofillHints: const <String>[AutofillHints.newPassword],
                enableSuggestions: false,
                autocorrect: false,
                onSubmitted: (_) => _signUp(),
                suffix: _PasswordVisibilityButton(
                  obscure: _obscureConfirmPassword,
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword =
                          !_obscureConfirmPassword,
                    );
                  },
                ),
              ),
            ),
            if (_passwordMismatchError != null) ...<Widget>[
              const SizedBox(height: 7),
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _passwordMismatchError!,
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 170),
              child: Semantics(
                checked: _agreeTerms,
                button: true,
                child: InkWell(
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox.square(
                          dimension: 32,
                          child: Checkbox(
                            value: _agreeTerms,
                            onChanged: (bool? value) {
                              setState(() => _agreeTerms = value ?? false);
                            },
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
                                  'Concordo com os Termos e a Política de Privacidade.',
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
              ),
            ),
            const SizedBox(height: 18),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 210),
              child: SixoAppAuthPrimaryButton(
                label: context.t(
                  'auth.mobileCreate.submit',
                  fallback: 'Criar conta',
                ),
                onPressed: _signUp,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _goToLogin,
                child: Text(
                  context.t(
                    'auth.mobileCreate.loginPrompt',
                    fallback: 'Já tem uma conta? Entrar',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SixMobilePalette.brandBlue,
                    fontWeight: FontWeight.w800,
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
