import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_or_divider.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import 'create_account_mobile.dart';
import 'esqueceu_senha_mobile.dart';
import 'home_page_mobile_screen.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  State<LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final login = _loginController.text.trim();
    final senha = _passwordController.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      _showSnack('Por favor, preencha o e-mail e a senha');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.login(login, senha);
      _navigateToHome();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePageMobile(title: 'Home')),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.loginWithGoogle();
      if (!mounted) return;
      _navigateToHome();
    } on GoogleAuthException catch (e) {
      if (e.code == GoogleAuthErrorCode.cancelledByUser) return;
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível concluir o login com Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginWithApple() {
    _showSnack('Login com Apple (mocked)');
    _navigateToHome();
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EsqueceuSenhaMobile()),
    );
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAccountMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: SixAuthTokens.colorShellBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: SixAuthTokens.formPanePaddingMobile,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Título ──────────────────────────────────────────
                      const SixAuthTitle(
                        title: 'Entrar',
                        subtitle:
                            'Para entrar em sua conta, informe\nseu e-mail e senha',
                      ),
                      const SizedBox(height: 28),

                      // ── E-mail ──────────────────────────────────────────
                      SixAuthInput(
                        controller: _loginController,
                        hint: 'E-mail',
                        label: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // ── Senha ───────────────────────────────────────────
                      SixAuthInput(
                        controller: _passwordController,
                        hint: 'Senha',
                        label: 'Senha',
                        obscure: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: SixAuthTokens.colorDividerText,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Esqueceu a senha ────────────────────────────────
                      Center(
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: primary,
                              fontWeight:
                                  SixAuthTokens.fontWeightForgotPassword,
                              fontSize: SixAuthTokens.fontSizeForgotPassword,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Botão Continuar ─────────────────────────────────
                      SixAuthPrimaryButton(
                        label: 'Continuar',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // ── Divider ─────────────────────────────────────────
                      const SixAuthOrDivider(
                        text: 'Ainda não tem uma conta?',
                      ),
                      const SizedBox(height: 16),

                      // ── Criar conta ─────────────────────────────────────
                      _SocialButton(
                        label: 'Criar conta',
                        onPressed: _createAccount,
                      ),
                      const SizedBox(height: 12),

                      // ── Apple ───────────────────────────────────────────
                      _SocialButton(
                        label: 'Entrar com Apple',
                        onPressed: _loginWithApple,
                        leading: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Google ──────────────────────────────────────────
                      _SocialButton(
                        label: 'Entrar com Google',
                        onPressed: _loginWithGoogle,
                        leading: const _GoogleGlyph(),
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),

                      // ── Disclaimer ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: SixAuthTokens.colorDividerText,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'Ao clicar em "Continuar", declaro ter lido e concordo com os ',
                              ),
                              TextSpan(
                                text: 'Termos de Uso e Política de Privacidade',
                                style: TextStyle(
                                  color: SixAuthTokens.colorTextPrimary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Botão secundário (outline) ──────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SixAuthTokens.heightButtonGoogle,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: SixAuthTokens.colorButtonGoogleBg,
          foregroundColor: SixAuthTokens.colorTextPrimary,
          elevation: 0,
          side: const BorderSide(color: SixAuthTokens.colorButtonGoogleBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SixAuthTokens.radiusButtonGoogle,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: SixAuthTokens.fontSizeBody,
                fontWeight: FontWeight.w600,
                color: SixAuthTokens.colorTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google "G" glyph ────────────────────────────────────────────────────────

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
