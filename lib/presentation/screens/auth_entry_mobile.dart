import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import 'login_mobile.dart';
import 'signup_onboarding_mobile.dart';

class AuthEntryMobile extends StatelessWidget {
  const AuthEntryMobile({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()));
  }

  void _goToOnboarding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignupOnboardingMobile()),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SixStaggeredEntry(
                        child: _EntryHero(
                          title: context.t(
                            'auth.entry.title',
                            fallback: 'Bem-vindo ao Six',
                          ),
                          subtitle: context.t(
                            'auth.entry.subtitle',
                            fallback:
                                'Antes de continuar, diga como deseja acessar o app.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 70),
                        child: _ChoiceCard(
                          icon: Icons.login_rounded,
                          title: context.t(
                            'auth.entry.hasAccountTitle',
                            fallback: 'Já tenho uma conta',
                          ),
                          subtitle: context.t(
                            'auth.entry.hasAccountSubtitle',
                            fallback:
                                'Entre com seu e-mail e senha para acessar sua empresa.',
                          ),
                          buttonLabel: context.t(
                            'auth.entry.loginAction',
                            fallback: 'Entrar',
                          ),
                          onPressed: () => _goToLogin(context),
                          primary: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 120),
                        child: _ChoiceCard(
                          icon: Icons.storefront_rounded,
                          title: context.t(
                            'auth.entry.newAccountTitle',
                            fallback: 'Sou novo por aqui',
                          ),
                          subtitle: context.t(
                            'auth.entry.newAccountSubtitle',
                            fallback:
                                'Veja um resumo rápido e crie sua conta para começar.',
                          ),
                          buttonLabel: context.t(
                            'auth.entry.newAccountAction',
                            fallback: 'Conhecer o Six',
                          ),
                          onPressed: () => _goToOnboarding(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _EntryHero extends StatelessWidget {
  const _EntryHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: SixMobilePalette.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SixMobilePalette.onPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/six-logo-flecha.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.onPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.heroSupportingText,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  primary
                      ? SixMobilePalette.highlightedBorder
                      : SixMobilePalette.border,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.softAccentSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SixMobilePalette.border),
                    ),
                    child: Icon(
                      icon,
                      color:
                          primary
                              ? SixMobilePalette.accent
                              : SixMobilePalette.secondary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SixMobilePalette.mutedText,
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child:
                    primary
                        ? ElevatedButton(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SixMobilePalette.accent,
                            foregroundColor: SixMobilePalette.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _ChoiceButtonLabel(label: buttonLabel),
                        )
                        : OutlinedButton(
                          onPressed: onPressed,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SixMobilePalette.titleText,
                            side: const BorderSide(
                              color: SixMobilePalette.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _ChoiceButtonLabel(label: buttonLabel),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButtonLabel extends StatelessWidget {
  const _ChoiceButtonLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}
