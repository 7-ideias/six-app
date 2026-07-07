import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_or_divider.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import '../../l10n/six_i18n.dart';
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
      _showSnack(context.t('auth.loginRequiredFields'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.login(login, senha);
      if (!mounted) return;
      _navigateToPostLoginSplash();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToPostLoginSplash() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PostLoginSplashMobilePage(),
      ),
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
      _navigateToPostLoginSplash();
    } on GoogleAuthException catch (e) {
      if (e.code == GoogleAuthErrorCode.cancelledByUser) return;
      _showSnack(e.message);
    } catch (_) {
      _showSnack(context.t('auth.googleLoginError'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginWithApple() {
    _showSnack(context.t('auth.appleLoginMock'));
    _navigateToPostLoginSplash();
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
                      SixAuthTitle(
                        title: context.t('auth.loginTitleMobile'),
                        subtitle: context.t('auth.loginSubtitleMobile'),
                      ),
                      const SizedBox(height: 28),
                      SixAuthInput(
                        controller: _loginController,
                        hint: context.t('auth.email'),
                        label: context.t('auth.email'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      SixAuthInput(
                        controller: _passwordController,
                        hint: context.t('auth.password'),
                        label: context.t('auth.password'),
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
                            context.t('auth.forgotPassword'),
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
                      SixAuthPrimaryButton(
                        label: context.t('auth.continue'),
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      SixAuthOrDivider(
                        text: context.t('auth.noAccount'),
                      ),
                      const SizedBox(height: 16),
                      _SocialButton(
                        label: context.t('auth.createAccount'),
                        onPressed: _createAccount,
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        label: context.t('auth.signInWithApple'),
                        onPressed: _loginWithApple,
                        leading: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        label: context.t('auth.signInWithGoogle'),
                        onPressed: _loginWithGoogle,
                        leading: const _GoogleGlyph(),
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: SixAuthTokens.colorDividerText,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: context.t('auth.termsPrefix')),
                              TextSpan(
                                text: context.t('auth.terms'),
                                style: const TextStyle(
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
          side: const BorderSide(color: SixAuthTokens.colorButtonGoogleBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SixAuthTokens.radiusButtonGoogle),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: SixAuthTokens.fontSizeBody,
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
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
