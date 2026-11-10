import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String interval = 'month';
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
    final colors = context.sixMobileColors;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  style: TextStyle(color: colors.error),
                ),
              ),
            if (state != null) ...[
              if (state.testMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    billingText(context, 'paymentTest'),
                    style: TextStyle(color: colors.accent),
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
                    for (final option in ['month', 'year'])
                      ChoiceChip(
                        label: Text(billingText(context, option)),
                        selected: interval == option,
                        onSelected: controller.busy
                            ? null
                            : (_) => setState(() => interval = option),
                      ),
                  ],
                ),
                if (state.offers.isEmpty) Text(billingText(context, 'noPlans')),
                for (final offer in state.offers.where(
                  (o) => o.interval == interval,
                ))
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          offer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          NumberFormat.currency(
                            locale: Localizations.localeOf(context)
                                .toLanguageTag(),
                            name: offer.currency,
                          ).format(offer.amountMinor / 100),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          billingText(
                            context,
                            interval == 'year' ? 'yearCycle' : 'monthCycle',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: controller.busy
                              ? null
                              : () => controller.open(offer: offer),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(billingText(context, 'purchase')),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(billingText(context, 'paymentTerms')),
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
