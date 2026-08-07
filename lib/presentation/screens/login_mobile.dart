import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/core/constants/six_animation_assets.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import '../../l10n/six_i18n.dart';
import 'esqueceu_senha_mobile.dart';
import 'post_login_splash_mobile_page.dart';
import 'signup_onboarding_mobile.dart';

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
      MaterialPageRoute(builder: (_) => const PostLoginSplashMobilePage()),
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
      MaterialPageRoute(builder: (_) => const SignupOnboardingMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: SixMobilePalette.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SixMobilePalette.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SixStaggeredEntry(
                          child: const _MobileLoginLoopAnimation(),
                        ),
                        const SizedBox(height: 18),
                        SixStaggeredEntry(
                          delay: const Duration(milliseconds: 70),
                          child: _MobileAuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MobileAuthField(
                                  controller: _loginController,
                                  hint: context.t('auth.email'),
                                  label: context.t('auth.email'),
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                _MobileAuthField(
                                  controller: _passwordController,
                                  hint: context.t('auth.password'),
                                  label: context.t('auth.password'),
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _login(),
                                  suffix: IconButton(
                                    tooltip: context.t('auth.password'),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: SixMobilePalette.mutedText,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              _obscurePassword =
                                                  !_obscurePassword,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                      foregroundColor: SixMobilePalette.accent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      context.t('auth.forgotPassword'),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _MobilePrimaryButton(
                                  label: context.t('auth.continue'),
                                  onPressed: _login,
                                  isLoading: _isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SixStaggeredEntry(
                          delay: const Duration(milliseconds: 120),
                          child: _MobileDivider(
                            text: context.t('auth.noAccount'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SixStaggeredEntry(
                          delay: const Duration(milliseconds: 160),
                          child: _SocialButton(
                            label: context.t('auth.createAccount'),
                            onPressed: _createAccount,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SixStaggeredEntry(
                          delay: const Duration(milliseconds: 190),
                          child: _SocialButton(
                            label: context.t('auth.signInWithApple'),
                            onPressed: _loginWithApple,
                            leading: const Icon(
                              Icons.apple,
                              color: SixMobilePalette.titleText,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SixStaggeredEntry(
                          delay: const Duration(milliseconds: 220),
                          child: _SocialButton(
                            label: context.t('auth.signInWithGoogle'),
                            onPressed: _loginWithGoogle,
                            leading: const _GoogleGlyph(),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 18),
                        _TermsText(
                          prefix: context.t('auth.termsPrefix'),
                          terms: context.t('auth.terms'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileLoginLoopAnimation extends StatefulWidget {
  const _MobileLoginLoopAnimation();

  @override
  State<_MobileLoginLoopAnimation> createState() =>
      _MobileLoginLoopAnimationState();
}

class _MobileLoginLoopAnimationState extends State<_MobileLoginLoopAnimation>
    with SingleTickerProviderStateMixin {
  static const Duration _loopDuration = Duration(milliseconds: 2400);
  static const Duration _frameFadeDuration = Duration(milliseconds: 120);
  static const double _aspectRatio = 1916 / 821;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _loopDuration)
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in SixAnimationAssets.loginFrames) {
      unawaited(precacheImage(AssetImage(asset), context));
    }
    _syncMotionPreference();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _currentFrameIndex() {
    final index =
        (_controller.value * SixAnimationAssets.loginFrames.length).floor();
    return index.clamp(0, SixAnimationAssets.loginFrames.length - 1).toInt();
  }

  void _syncMotionPreference() {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true;

    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    return Semantics(
      container: true,
      image: true,
      label: 'SixApp',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SixMobilePalette.primary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SixMobilePalette.primary),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.heroShadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final frameAsset =
                  SixAnimationAssets.loginFrames[reduceMotion
                      ? 0
                      : _currentFrameIndex()];

              return AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : _frameFadeDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Image.asset(
                  frameAsset,
                  key: ValueKey<String>(frameAsset),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileAuthCard extends StatelessWidget {
  const _MobileAuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MobileAuthField extends StatelessWidget {
  const _MobileAuthField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: SixMobilePalette.titleText,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: SixMobilePalette.secondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: SixMobilePalette.softNeutralSurface,
        labelStyle: const TextStyle(
          color: SixMobilePalette.secondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: SixMobilePalette.accent,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: SixMobilePalette.mutedText,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SixMobilePalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SixMobilePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: SixMobilePalette.highlightedBorder,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _MobilePrimaryButton extends StatelessWidget {
  const _MobilePrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SixMobilePalette.accent,
          foregroundColor: SixMobilePalette.onPrimary,
          disabledBackgroundColor: SixMobilePalette.accent.withValues(
            alpha: 0.58,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: SixMobilePalette.onPrimary,
                    strokeWidth: 2.4,
                  ),
                )
                : Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      ),
    );
  }
}

class _MobileDivider extends StatelessWidget {
  const _MobileDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: SixMobilePalette.border)),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.52,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: SixMobilePalette.border)),
      ],
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText({required this.prefix, required this.terms});

  final String prefix;
  final String terms;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: SixMobilePalette.mutedText,
            height: 1.5,
          ),
          children: <InlineSpan>[
            TextSpan(text: prefix),
            TextSpan(
              text: terms,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: SixMobilePalette.surface,
          foregroundColor: SixMobilePalette.titleText,
          side: const BorderSide(color: SixMobilePalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
