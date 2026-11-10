import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/billing_texts.dart';
import '../../l10n/storage_texts.dart';
import '../controllers/subscription_billing_controller.dart';
import '../theme/web_theme_tokens.dart';

class SubscriptionWebPage extends StatelessWidget {
  const SubscriptionWebPage({super.key, this.selection});
  final Uri? selection;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(billingText(context, 'plans'))),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: SubscriptionWebPanel(selection: selection),
        ),
      ),
    ),
  );
}

class SubscriptionWebPanel extends StatefulWidget {
  const SubscriptionWebPanel({super.key, this.companyId, this.selection});
  final Uri? selection;
  final String? companyId;
  @override
  State<SubscriptionWebPanel> createState() => _SubscriptionWebPanelState();
}

class _SubscriptionWebPanelState extends State<SubscriptionWebPanel> {
  late final controller = SubscriptionBillingController(
    companyId: widget.companyId,
    selection: widget.selection,
  );
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = WebThemeTokens.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              billingText(context, 'plans'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (controller.busy) const LinearProgressIndicator(),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  billingText(context, controller.error!),
                  style: TextStyle(color: colors.danger),
                ),
              ),
            if (state != null) ...[
              if (state.testMode)
                Chip(
                  avatar: const Icon(Icons.science_outlined, size: 18),
                  label: Text(billingText(context, 'paymentTest')),
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
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final option in controller.intervals)
                      ChoiceChip(
                        label: Text(billingText(context, option)),
                        selected: controller.selectedInterval == option,
                        onSelected: controller.busy
                            ? null
                            : (_) => controller.selectInterval(option),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.offers.isEmpty) Text(billingText(context, 'noPlans')),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final offer in controller.visibleOffers)
                      SizedBox(
                        width: 270,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                if (offer.planId == controller.selectedPlanId)
                                  Text(billingText(context, 'selectedPlan')),
                                const SizedBox(height: 12),
                                Text(
                                  NumberFormat.currency(
                                    locale: Localizations.localeOf(context)
                                        .toLanguageTag(),
                                    name: offer.currency,
                                  ).format(offer.amountMinor / 100),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                Text(
                                  billingText(
                                    context,
                                    offer.interval == 'year'
                                        ? 'yearCycle'
                                        : 'monthCycle',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: controller.busy
                                      ? null
                                      : () => controller.open(offer: offer),
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: Text(billingText(context, 'purchase')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(billingText(context, 'paymentTerms')),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (state.canManage &&
                      state.hasSubscription &&
                      state.available)
                    FilledButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => controller.open(),
                      icon: const Icon(Icons.credit_card),
                      label: Text(billingText(context, 'portal')),
                    ),
                  OutlinedButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () => controller.load(sync: true),
                    icon: const Icon(Icons.refresh),
                    label: Text(billingText(context, 'sync')),
                  ),
                ],
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
