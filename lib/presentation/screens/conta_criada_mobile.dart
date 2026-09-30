import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';

import 'login_mobile.dart';

class ContaCriadaMobile extends StatelessWidget {
  const ContaCriadaMobile({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPageMobile()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return PopScope(
      canPop: false,
      child: SixoAppAuthMobileScaffold(
        title: context.t(
          'auth.mobileAccountCreated.heroTitle',
          fallback: 'Conta criada',
        ),
        subtitle: context.t(
          'auth.mobileAccountCreated.heroSubtitle',
          fallback: 'Seu espaço no SixoApp está pronto para começar.',
        ),
        compactHeader: true,
        minimumSurfaceHeight: 430,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 6),
            _SuccessIllustration(
              primary: SixMobilePalette.brandBlue,
              secondary: SixMobilePalette.brandCyan,
              foreground: SixMobilePalette.onPrimary,
            ),
            const SizedBox(height: 28),
            Text(
              context.t(
                'auth.mobileAccountCreated.title',
                fallback: 'Tudo certo!',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                height: 1.12,
                fontWeight: FontWeight.w800,
                color: colors.titleText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t(
                'auth.mobileAccountCreated.message',
                fallback:
                    'Sua conta foi criada com sucesso. Faça login para começar a usar o SixoApp.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: colors.mutedText,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 34),
            SixoAppAuthPrimaryButton(
              label: context.t(
                'auth.mobileAccountCreated.loginAction',
                fallback: 'Ir para o login',
              ),
              icon: Icons.login_rounded,
              onPressed: () => _goToLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessIllustration extends StatefulWidget {
  const _SuccessIllustration({
    required this.primary,
    required this.secondary,
    required this.foreground,
  });

  final Color primary;
  final Color secondary;
  final Color foreground;

  @override
  State<_SuccessIllustration> createState() => _SuccessIllustrationState();
}

class _SuccessIllustrationState extends State<_SuccessIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = widget.primary;
    final Color secondary = widget.secondary;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final double t = reduceMotion ? 0 : _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.5 + 0.10 * t,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08 - 0.05 * t),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.3 + 0.06 * t,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12 - 0.05 * t),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + 0.03 * t,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[secondary, primary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25 + 0.10 * t),
                        blurRadius: 20 + 8 * t,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: widget.foreground,
                    size: 56,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 24,
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: primary.withValues(alpha: 0.55),
                ),
              ),
              Positioned(
                top: 36,
                right: 18,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: primary.withValues(alpha: 0.4),
                ),
              ),
              Positioned(
                bottom: 28,
                left: 18,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: primary.withValues(alpha: 0.4),
                ),
              ),
              Positioned(
                bottom: 14,
                right: 30,
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: primary.withValues(alpha: 0.55),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
