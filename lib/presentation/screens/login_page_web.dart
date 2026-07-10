import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import '../components/web_auth_logout_splash_scene.dart';
import '../components/web_auth_shell.dart';
import '../components/web_google_sign_in_button.dart';
import '../components/web_root/web_i18n_gate.dart';
import 'post_login_splash_web_page.dart';
import 'register_page_web.dart';

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  State<LoginPageWeb> createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _checkedLogoutEntry = false;
  bool _showLogoutSplash = false;
  Timer? _logoutSplashTimer;

  late WebRootL10n _l10n;

  @override
  void initState() {
    super.initState();
    _listenGoogleSignIn();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedLogoutEntry) return;

    _checkedLogoutEntry = true;
    final String? routeName = ModalRoute.of(context)?.settings.name;
    final bool abriuDiretoAposLogout = routeName == null || routeName.trim().isEmpty;

    if (abriuDiretoAposLogout) {
      _showLogoutSplash = true;
      _logoutSplashTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _showLogoutSplash = false);
      });
    }
  }

  @override
  void dispose() {
    _logoutSplashTimer?.cancel();
    _loginController.dispose();
    _passwordController.dispose();
    _authService.cancelPendingWebGoogleLogin();
    super.dispose();
  }

  void _listenGoogleSignIn() {
    _authService
        .awaitWebGoogleLogin()
        .then((_) {
          if (!mounted) return;
          _navigateToPostLoginSplash();
        })
        .catchError((error) {
          if (!mounted) return;
          if (error is GoogleAuthException && error.code == GoogleAuthErrorCode.cancelledByUser) {
            return;
          }
          final String msg = error is GoogleAuthException ? error.message : _l10n.authErrGoogleLogin;
          _showSnack(msg);
        });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    final String login = _loginController.text.trim();
    final String senha = _passwordController.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      _showSnack(_l10n.authErrFillEmailPassword);
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

  String? _redirectAfterLogin() {
    final String routeName = ModalRoute.of(context)?.settings.name ?? Uri.base.toString();
    final Uri uri = Uri.parse(routeName);
    final String redirect = uri.queryParameters['redirect'] ?? '';
    if (redirect.trim().isEmpty) return null;

    final String decoded = Uri.decodeComponent(redirect).trim();
    final Uri redirectUri = Uri.parse(decoded);
    final String safePath = redirectUri.hasScheme || redirectUri.hasAuthority ? redirectUri.path : decoded;

    if (!safePath.startsWith('/')) return null;
    return safePath;
  }

  void _navigateToPostLoginSplash() {
    final String nextRoute = _redirectAfterLogin() ?? '/app';

    Navigator.of(context).pushReplacement(
      WebAuthShell.smoothRoute<void>(
        name: '/login/splash',
        builder: (_) => PostLoginSplashWebPage(nextRoute: nextRoute),
      ),
    );
  }

  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  void _createAccount() {
    Navigator.of(context).push(
      WebAuthShell.smoothRoute<void>(
        name: '/register',
        builder: (_) => const RegisterPageWeb(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 760),
      reverseDuration: const Duration(milliseconds: 460),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<double> curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.99, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: _showLogoutSplash
          ? const WebAuthLogoutSplashScene(key: ValueKey<String>('logout-splash'))
          : WebI18nGate(
              key: const ValueKey<String>('login-form'),
              builder: (BuildContext context) {
                _l10n = WebRootL10n.of(context);
                final Color primary = Theme.of(context).colorScheme.primary;

                return WebAuthShell(
                  showBack: Navigator.of(context).canPop(),
                  onBack: () => Navigator.of(context).maybePop(),
                  child: WebAuthStaggeredColumn(
                    children: <Widget>[
                      WebAuthTitle(title: _l10n.authLoginTitle, subtitle: _l10n.authLoginSubtitle),
                      const SizedBox(height: 32),
                      WebAuthTextField(
                        controller: _loginController,
                        hint: _l10n.authEmailHint,
                        label: _l10n.authEmailLabel,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      WebAuthTextField(
                        controller: _passwordController,
                        hint: _l10n.authPasswordHint,
                        label: _l10n.authPasswordLabel,
                        prefixIcon: Icons.shield_outlined,
                        obscure: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: WebAuthShell.labelGrey(),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            _l10n.authForgotPassword,
                            style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      WebAuthPrimaryButton(label: _l10n.authSignInButton, onPressed: _login, isLoading: _isLoading),
                      const SizedBox(height: 24),
                      Row(
                        children: <Widget>[
                          const Expanded(child: Divider(color: Color(0xFFE3E6E5), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _l10n.authOrContinueWith,
                              style: TextStyle(color: WebAuthShell.labelGrey(), fontSize: 13),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE3E6E5), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const WebGoogleSignInButton(),
                      const SizedBox(height: 28),
                      Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _createAccount,
                            behavior: HitTestBehavior.opaque,
                            child: RichText(
                              text: TextSpan(
                                text: _l10n.authNoAccount,
                                style: TextStyle(color: WebAuthShell.labelGrey(), fontSize: 14),
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: _l10n.authCreateAccountLink,
                                    style: TextStyle(color: primary, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
