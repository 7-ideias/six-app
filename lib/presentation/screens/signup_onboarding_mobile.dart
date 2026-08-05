import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import 'create_account_mobile.dart';
import 'login_mobile.dart';

class SignupOnboardingMobile extends StatefulWidget {
  const SignupOnboardingMobile({super.key});

  @override
  State<SignupOnboardingMobile> createState() => _SignupOnboardingMobileState();
}

class _SignupOnboardingMobileState extends State<SignupOnboardingMobile> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateAccountMobile()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()),
    );
  }

  void _nextPage() {
    if (_currentIndex == 2) {
      _goToCreateAccount();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_SignupOnboardingStep> steps = <_SignupOnboardingStep>[
      _SignupOnboardingStep(
        icon: Icons.assignment_turned_in_rounded,
        title: context.t(
          'auth.onboarding.step1Title',
          fallback: 'Atendimento organizado',
        ),
        subtitle: context.t(
          'auth.onboarding.step1Subtitle',
          fallback:
              'Registre vendas, orçamentos e assistências em um fluxo simples.',
        ),
      ),
      _SignupOnboardingStep(
        icon: Icons.inventory_2_rounded,
        title: context.t(
          'auth.onboarding.step2Title',
          fallback: 'Catálogo e estoque no bolso',
        ),
        subtitle: context.t(
          'auth.onboarding.step2Subtitle',
          fallback:
              'Mantenha produtos, serviços e informações essenciais sempre à mão.',
        ),
      ),
      _SignupOnboardingStep(
        icon: Icons.insights_rounded,
        title: context.t(
          'auth.onboarding.step3Title',
          fallback: 'Gestão para crescer',
        ),
        subtitle: context.t(
          'auth.onboarding.step3Subtitle',
          fallback:
              'Acompanhe indicadores e prepare sua operação para evoluir com o Six.',
        ),
      ),
    ];

    final bool isLastPage = _currentIndex == steps.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: SixMobilePalette.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SixMobilePalette.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: context.t('common.back', fallback: 'Voltar'),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: SixMobilePalette.titleText,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _goToCreateAccount,
                      style: TextButton.styleFrom(
                        foregroundColor: SixMobilePalette.secondary,
                      ),
                      child: Text(
                        context.t('auth.onboarding.skip', fallback: 'Pular'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SixStaggeredEntry(
                  child: _OnboardingHeader(
                    title: context.t(
                      'auth.onboarding.title',
                      fallback: 'Comece pelo essencial',
                    ),
                    subtitle: context.t(
                      'auth.onboarding.subtitle',
                      fallback:
                          'Veja três pontos rápidos antes de criar sua conta.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged:
                      (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: SixStaggeredEntry(
                        key: ValueKey<int>(index),
                        delay: Duration(milliseconds: 60 * index),
                        child: _OnboardingCard(step: steps[index]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _PageDots(count: steps.length, activeIndex: _currentIndex),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SixMobilePalette.accent,
                          foregroundColor: SixMobilePalette.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLastPage
                              ? context.t(
                                'auth.onboarding.createAccountAction',
                                fallback: 'Criar minha conta',
                              )
                              : context.t(
                                'auth.onboarding.next',
                                fallback: 'Avançar',
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        context.t(
                          'auth.onboarding.loginAction',
                          fallback: 'Já tenho uma conta',
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupOnboardingStep {
  const _SignupOnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SixMobilePalette.onPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.16),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: SixMobilePalette.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
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

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.step});

  final _SignupOnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 330),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SixMobilePalette.highlightedBorder),
              ),
              child: Icon(step.icon, color: SixMobilePalette.accent, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              step.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              step.subtitle,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (index) {
        final bool active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? SixMobilePalette.accent : SixMobilePalette.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
