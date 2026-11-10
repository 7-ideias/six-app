import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_settings_provider.dart';
import '../../data/models/subscription_billing.dart';
import '../components/six_backend_loading.dart';
import '../theme/subscription_visuals.dart';

import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../l10n/billing_texts.dart';
import '../../l10n/storage_texts.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../controllers/subscription_billing_controller.dart';

class SubscriptionMobileScreen extends StatelessWidget {
  const SubscriptionMobileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    return SixMobilePageShell(
      title: billingText(context, 'plans'),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      bodyBuilder: (context, scroll, topInset) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 32),
        children: const [SubscriptionMobilePanel()],
      ),
    );
  }
}

class SubscriptionOfferMobileCard extends StatelessWidget {
  const SubscriptionOfferMobileCard({
    super.key,
    required this.offer,
    required this.selected,
    this.onSubscribe,
  });
  final BillingOffer offer;
  final bool selected;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: offer.featured || selected
            ? SubscriptionVisuals.highlightedSurface
            : SubscriptionVisuals.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: offer.featured || selected
              ? SubscriptionVisuals.cyan
              : SubscriptionVisuals.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offer.featured || selected)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                billingText(context, selected ? 'selectedPlan' : 'popular'),
                style: const TextStyle(
                  color: SubscriptionVisuals.cyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          Text(
            offer.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (offer.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                offer.description,
                style: const TextStyle(
                  color: SubscriptionVisuals.muted,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            NumberFormat.currency(
              locale: context
                  .watch<LocaleSettingsProvider>()
                  .currentLocale
                  .toLanguageTag(),
              name: offer.currency,
            ).format(offer.amountMinor / 100),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            billingText(
              context,
              offer.interval == 'year' ? 'yearCycle' : 'monthCycle',
            ),
            style: const TextStyle(
              color: SubscriptionVisuals.muted,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          if (offer.benefits.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final benefit in offer.benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: SubscriptionVisuals.cyan,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: SubscriptionVisuals.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onSubscribe,
            child: Text(
              billingText(context, 'purchase'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionMobilePanel extends StatefulWidget {
  const SubscriptionMobilePanel({super.key, this.companyId});
  final String? companyId;
  @override
  State<SubscriptionMobilePanel> createState() =>
      _SubscriptionMobilePanelState();
}

class _SubscriptionMobilePanelState extends State<SubscriptionMobilePanel> {
  late final controller = SubscriptionBillingController(
    companyId: widget.companyId,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.setEffectiveLocale(
      context.watch<LocaleSettingsProvider>().currentLocale,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SubscriptionVisuals.theme(context),
      child: Builder(
        builder: (context) => Material(
          color: SubscriptionVisuals.background,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _content(context),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              billingText(context, 'plans'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              billingText(context, 'plansIntro'),
              style: const TextStyle(
                color: SubscriptionVisuals.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (controller.busy)
              SixBackendLoading(
                title: billingText(context, 'loading'),
                subtitle: '',
                compact: true,
                backgroundColor: SubscriptionVisuals.surface,
                borderColor: SubscriptionVisuals.border,
              ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  billingText(context, controller.error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (state != null) ...[
              if (state.testMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    billingText(context, 'paymentTest'),
                    style: const TextStyle(color: SubscriptionVisuals.cyan),
                  ),
                ),
              if (state.status != null)
                Text(billingText(context, state.status!)),
              if (state.paidUntil != null)
                Text(
                  '${billingText(context, 'until')}: ${storageTimestamp(context, state.paidUntil!)}',
                ),
              if (state.cancelAtPeriodEnd)
                Text(billingText(context, 'cancelScheduled')),
              if (!state.available)
                Text(billingText(context, 'paymentUnavailable')),
              if (!state.canManage) Text(billingText(context, 'ownerOnly')),
              if (state.available &&
                  state.canManage &&
                  !state.hasSubscription) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in controller.intervals)
                      ChoiceChip(
                        label: Text(billingText(context, option)),
                        labelStyle: TextStyle(
                          color: controller.selectedInterval == option
                              ? SubscriptionVisuals.background
                              : SubscriptionVisuals.foreground,
                        ),
                        selected: controller.selectedInterval == option,
                        onSelected: controller.busy
                            ? null
                            : (_) => controller.selectInterval(option),
                      ),
                  ],
                ),
                if (state.offers.isEmpty) Text(billingText(context, 'noPlans')),
                for (final offer in controller.visibleOffers)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SubscriptionOfferMobileCard(
                      offer: offer,
                      selected: offer.planId == controller.selectedPlanId,
                      onSubscribe: controller.busy
                          ? null
                          : () => controller.open(offer: offer),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  billingText(context, 'paymentTerms'),
                  style: const TextStyle(
                    color: SubscriptionVisuals.muted,
                    height: 1.6,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (state.canManage && state.hasSubscription && state.available)
                FilledButton.icon(
                  onPressed: controller.busy ? null : () => controller.open(),
                  icon: const Icon(Icons.credit_card),
                  label: Text(billingText(context, 'portal')),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => controller.load(sync: true),
                icon: const Icon(Icons.refresh),
                label: Text(billingText(context, 'sync')),
              ),
            ] else if (!controller.busy)
              OutlinedButton(
                onPressed: () => controller.load(),
                child: Text(billingText(context, 'refresh')),
              ),
          ],
        );
      },
    );
  }
}
