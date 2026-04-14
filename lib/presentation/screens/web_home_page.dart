import 'package:appplanilha/presentation/screens/web_marketing_localization.dart';
import 'package:appplanilha/providers/locale_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final copy = WebMarketingLocalizer.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/web/atendente_login_web.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.70),
                    const Color(0xFF09131A).withValues(alpha: 0.88),
                    const Color(0xFF081018).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(copy: copy),
                      const SizedBox(height: 30),
                      _HeroSection(copy: copy)
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 24),
                      _FeatureSection(copy: copy)
                          .animate(delay: 120.ms)
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 24),
                      _DemoSection(copy: copy)
                          .animate(delay: 180.ms)
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 24),
                      _PricingSection(copy: copy)
                          .animate(delay: 260.ms)
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 24),
                      _FooterCta(copy: copy),
                      const SizedBox(height: 14),
                      Text(
                        copy.t('checkout.badge'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
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
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 420,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C2FF), Color(0xFF0B72FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        copy.t('nav.aiErp'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        copy.t('nav.subtitle'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LanguageSelector(copy: copy),
              FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(copy.t('nav.login')),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(copy.t('nav.testNow')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.09),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 0 : 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B72FF).withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        copy.t('hero.badge'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      copy.t('hero.title'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.t('hero.subtitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              () => Navigator.pushNamed(context, '/onboarding'),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(copy.t('hero.ctaTrial')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              () => Navigator.pushNamed(context, '/login'),
                          icon: const Icon(Icons.login_rounded),
                          label: Text(copy.t('hero.ctaLogin')),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              () => Navigator.pushNamed(context, '/checkout'),
                          icon: const Icon(
                            Icons.shopping_cart_checkout_rounded,
                          ),
                          label: Text(copy.t('hero.ctaPlans')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 16),
              Expanded(
                flex: compact ? 0 : 4,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _KpiCard(
                      label: copy.t('hero.kpi1Label'),
                      value: copy.t('hero.kpi1Value'),
                    ),
                    _KpiCard(
                      label: copy.t('hero.kpi2Label'),
                      value: copy.t('hero.kpi2Value'),
                    ),
                    _KpiCard(
                      label: copy.t('hero.kpi3Label'),
                      value: copy.t('hero.kpi3Value'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = copy.list('featureTitles');
    final descriptions = copy.list('featureDescriptions');
    final icons = <IconData>[
      Icons.point_of_sale_rounded,
      Icons.request_quote_rounded,
      Icons.build_circle_rounded,
      Icons.insights_rounded,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('features.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.t('features.subtitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(titles.length, (index) {
              return Container(
                width: 270,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0D1F2D).withValues(alpha: 0.76),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icons[index],
                      color: const Color(0xFF4CC9FF),
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      titles[index],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descriptions[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DemoSection extends StatelessWidget {
  const _DemoSection({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = copy.list('demoSteps');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('demo.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.t('demo.subtitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF56E39F),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(
                      text: WebMarketingLocalizer.demoYoutubeUrl,
                    ),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(copy.t('demo.opened'))),
                  );
                },
                icon: const Icon(Icons.smart_display_rounded),
                label: Text(copy.t('demo.watch')),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/checkout'),
                icon: const Icon(Icons.shopping_bag_rounded),
                label: Text(copy.t('nav.buy')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF122638),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB14A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    copy.t('demo.warning'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StoreBadge(
                assetPath: 'assets/images/stores/google_play_badge.png',
                label: copy.t('download.android'),
              ),
              _StoreBadge(
                assetPath: 'assets/images/stores/app_store_badge.png',
                label: copy.t('download.ios'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({required this.assetPath, required this.label});

  final String assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(assetPath, height: 44, fit: BoxFit.contain),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('pricing.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.t('pricing.subtitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PlanCard(
                title: copy.t('pricing.cardStarter'),
                price: 'R\$ 199${copy.t('pricing.month')}',
                features: copy.list('planStarterFeatures'),
                onBuy:
                    () =>
                        Navigator.pushNamed(context, '/checkout?plan=starter'),
                onTrial: () => Navigator.pushNamed(context, '/onboarding'),
                copy: copy,
              ),
              _PlanCard(
                title: copy.t('pricing.cardPro'),
                price: 'R\$ 349${copy.t('pricing.month')}',
                features: copy.list('planProFeatures'),
                featured: true,
                onBuy: () => Navigator.pushNamed(context, '/checkout?plan=pro'),
                onTrial: () => Navigator.pushNamed(context, '/onboarding'),
                copy: copy,
              ),
              _PlanCard(
                title: copy.t('pricing.cardEnterprise'),
                price: copy.t('pricing.contact'),
                features: copy.list('planEnterpriseFeatures'),
                onBuy:
                    () => Navigator.pushNamed(
                      context,
                      '/checkout?plan=enterprise',
                    ),
                onTrial: () => Navigator.pushNamed(context, '/onboarding'),
                copy: copy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.onBuy,
    required this.onTrial,
    required this.copy,
    this.featured = false,
  });

  final String title;
  final String price;
  final List<String> features;
  final VoidCallback onBuy;
  final VoidCallback onTrial;
  final WebMarketingLocalizer copy;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color:
            featured
                ? const Color(0xFF0B72FF).withValues(alpha: 0.24)
                : const Color(0xFF10283A).withValues(alpha: 0.68),
        border: Border.all(
          color:
              featured
                  ? const Color(0xFF59CCFF)
                  : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF65F0B0),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBuy,
              child: Text(copy.t('pricing.buyNow')),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTrial,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Text(copy.t('pricing.testNow')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterCta extends StatelessWidget {
  const _FooterCta({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2B45), Color(0xFF003A66)],
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 690,
            child: Text(
              copy.t('footer.cta'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                icon: const Icon(Icons.bolt_rounded),
                label: Text(copy.t('footer.ctaButton')),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(copy.t('footer.loginButton')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleSettingsProvider>();
    final selected = localeProvider.currentLocale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: _normalizeSelected(selected),
          dropdownColor: const Color(0xFF123047),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          onChanged: (locale) {
            if (locale == null) {
              return;
            }
            context.read<LocaleSettingsProvider>().setUserLocale(locale);
          },
          items: [
            DropdownMenuItem(
              value: const Locale('pt', 'BR'),
              child: Text(
                '${copy.t('common.language')}: ${copy.t('language.pt')}',
              ),
            ),
            DropdownMenuItem(
              value: const Locale('en', 'US'),
              child: Text(
                '${copy.t('common.language')}: ${copy.t('language.en')}',
              ),
            ),
            DropdownMenuItem(
              value: const Locale('es', 'ES'),
              child: Text(
                '${copy.t('common.language')}: ${copy.t('language.es')}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Locale _normalizeSelected(Locale locale) {
    if (locale.languageCode == 'pt') {
      return const Locale('pt', 'BR');
    }
    if (locale.languageCode == 'es') {
      return const Locale('es', 'ES');
    }
    return const Locale('en', 'US');
  }
}
