import 'dart:convert';

import 'package:appplanilha/presentation/screens/web_marketing_localization.dart';
import 'package:appplanilha/providers/locale_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class WebCheckoutPage extends StatefulWidget {
  const WebCheckoutPage({super.key, this.initialUri});

  static const String routeName = '/checkout';

  final Uri? initialUri;

  @override
  State<WebCheckoutPage> createState() => _WebCheckoutPageState();
}

class _WebCheckoutPageState extends State<WebCheckoutPage> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  late String _selectedPlan;
  String _billingCycle = 'monthly';
  String _paymentMethod = 'card';

  @override
  void initState() {
    super.initState();
    _selectedPlan = _sanitizePlan(widget.initialUri?.queryParameters['plan']);
  }

  String _sanitizePlan(String? value) {
    if (value == 'starter') {
      return 'starter';
    }
    if (value == 'enterprise') {
      return 'enterprise';
    }
    return 'pro';
  }

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = WebMarketingLocalizer.of(context);

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
                    Colors.black.withValues(alpha: 0.72),
                    const Color(0xFF0A1420).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CheckoutTopBar(copy: copy),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 980;
                          return Flex(
                            direction:
                                compact ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: compact ? 0 : 7,
                                child: _buildCheckoutForm(copy)
                                    .animate()
                                    .fadeIn(duration: 380.ms)
                                    .slideY(begin: 0.04, end: 0),
                              ),
                              if (!compact) const SizedBox(width: 16),
                              Expanded(
                                flex: compact ? 0 : 5,
                                child: _buildSummary(copy)
                                    .animate(delay: 120.ms)
                                    .fadeIn(duration: 380.ms)
                                    .slideY(begin: 0.06, end: 0),
                              ),
                            ],
                          );
                        },
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

  Widget _buildCheckoutForm(WebMarketingLocalizer copy) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('checkout.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.t('checkout.subtitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _buildPlanSelector(copy),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _companyController,
            label: copy.t('checkout.company'),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _nameController,
            label: copy.t('checkout.name'),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _emailController,
            label: copy.t('checkout.email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _couponController,
            label: copy.t('checkout.coupon'),
          ),
          const SizedBox(height: 16),
          Text(
            copy.t('checkout.billingCycle'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(copy.t('checkout.monthly')),
                selected: _billingCycle == 'monthly',
                onSelected: (_) => setState(() => _billingCycle = 'monthly'),
              ),
              ChoiceChip(
                label: Text(copy.t('checkout.yearly')),
                selected: _billingCycle == 'yearly',
                onSelected: (_) => setState(() => _billingCycle = 'yearly'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            copy.t('checkout.payment'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PaymentCard(
                title: copy.t('checkout.card'),
                icon: Icons.credit_card,
                selected: _paymentMethod == 'card',
                onTap: () => setState(() => _paymentMethod = 'card'),
              ),
              _PaymentCard(
                title: copy.t('checkout.pix'),
                icon: Icons.pix,
                selected: _paymentMethod == 'pix',
                onTap: () => setState(() => _paymentMethod = 'pix'),
              ),
              _PaymentCard(
                title: copy.t('checkout.invoice'),
                icon: Icons.receipt_long,
                selected: _paymentMethod == 'invoice',
                onTap: () => setState(() => _paymentMethod = 'invoice'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finishCheckout,
              icon: const Icon(Icons.lock_rounded),
              label: Text(copy.t('checkout.integrate')),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.t('checkout.nextStep'),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(WebMarketingLocalizer copy) {
    final theme = Theme.of(context);

    final plans = [
      _PlanViewData(
        id: 'starter',
        title: copy.t('pricing.cardStarter'),
        monthlyPrice: 199,
        yearlyPrice: 169,
        features: copy.list('planStarterFeatures'),
      ),
      _PlanViewData(
        id: 'pro',
        title: copy.t('pricing.cardPro'),
        monthlyPrice: 349,
        yearlyPrice: 299,
        features: copy.list('planProFeatures'),
      ),
      _PlanViewData(
        id: 'enterprise',
        title: copy.t('pricing.cardEnterprise'),
        monthlyPrice: null,
        yearlyPrice: null,
        features: copy.list('planEnterpriseFeatures'),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          plans.map((plan) {
            final selected = _selectedPlan == plan.id;
            final price = _formatPlanPrice(plan, copy);

            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = plan.id),
              child: Container(
                width: 230,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(0xFF0B72FF).withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        selected
                            ? const Color(0xFF59CCFF)
                            : Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSummary(WebMarketingLocalizer copy) {
    final theme = Theme.of(context);
    final selectedPlan = _getPlanData(copy, _selectedPlan);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('checkout.summary'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10283A).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedPlan.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPlanPrice(selectedPlan, copy),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                ...selectedPlan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check,
                            color: Color(0xFF6CF0B6),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2435),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              copy.t('checkout.badge'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed:
                () => Navigator.pushReplacementNamed(context, '/onboarding'),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(copy.t('nav.testNow')),
          ),
        ],
      ),
    );
  }

  _PlanViewData _getPlanData(WebMarketingLocalizer copy, String planId) {
    if (planId == 'starter') {
      return _PlanViewData(
        id: 'starter',
        title: copy.t('pricing.cardStarter'),
        monthlyPrice: 199,
        yearlyPrice: 169,
        features: copy.list('planStarterFeatures'),
      );
    }
    if (planId == 'enterprise') {
      return _PlanViewData(
        id: 'enterprise',
        title: copy.t('pricing.cardEnterprise'),
        monthlyPrice: null,
        yearlyPrice: null,
        features: copy.list('planEnterpriseFeatures'),
      );
    }

    return _PlanViewData(
      id: 'pro',
      title: copy.t('pricing.cardPro'),
      monthlyPrice: 349,
      yearlyPrice: 299,
      features: copy.list('planProFeatures'),
    );
  }

  String _formatPlanPrice(_PlanViewData plan, WebMarketingLocalizer copy) {
    if (plan.monthlyPrice == null) {
      return copy.t('pricing.contact');
    }

    final value =
        _billingCycle == 'monthly' ? plan.monthlyPrice : plan.yearlyPrice;
    if (value == null) {
      return copy.t('pricing.contact');
    }

    final cycleLabel =
        _billingCycle == 'monthly'
            ? copy.t('checkout.monthly')
            : copy.t('checkout.yearly');

    return 'R\$ $value - $cycleLabel';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4CC9FF)),
        ),
      ),
    );
  }

  void _finishCheckout() {
    final copy = WebMarketingLocalizer.of(context);

    if (_companyController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.t('checkout.required'))));
      return;
    }

    final payload = {
      'plan': _selectedPlan,
      'billingCycle': _billingCycle,
      'paymentMethod': _paymentMethod,
      'company': _companyController.text.trim(),
      'owner': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'coupon': _couponController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.t('checkout.simulated')),
          content: SizedBox(
            width: 520,
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(payload),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Home'),
          ),
          Wrap(
            spacing: 10,
            children: [
              _LanguageDropdown(copy: copy),
              FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(copy.t('nav.login')),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                child: Text(copy.t('nav.testNow')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleSettingsProvider>();
    final selected = localeProvider.currentLocale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: _normalize(selected),
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
              child: Text(copy.t('language.pt')),
            ),
            DropdownMenuItem(
              value: const Locale('en', 'US'),
              child: Text(copy.t('language.en')),
            ),
            DropdownMenuItem(
              value: const Locale('es', 'ES'),
              child: Text(copy.t('language.es')),
            ),
          ],
        ),
      ),
    );
  }

  Locale _normalize(Locale locale) {
    if (locale.languageCode == 'pt') {
      return const Locale('pt', 'BR');
    }
    if (locale.languageCode == 'es') {
      return const Locale('es', 'ES');
    }
    return const Locale('en', 'US');
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              selected
                  ? const Color(0xFF0B72FF).withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color:
                selected
                    ? const Color(0xFF59CCFF)
                    : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanViewData {
  const _PlanViewData({
    required this.id,
    required this.title,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
  });

  final String id;
  final String title;
  final int? monthlyPrice;
  final int? yearlyPrice;
  final List<String> features;
}
