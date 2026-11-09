import 'package:flutter/material.dart';

import '../../core/services/billing_http_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../l10n/billing_texts.dart';
import '../../l10n/storage_texts.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';
import '../controllers/billing_access_controller.dart';

class BillingAccessMobileScreen extends StatefulWidget {
  const BillingAccessMobileScreen({
    super.key,
    required this.companyId,
    this.companyName = '',
    this.admin = false,
    this.onExit,
  });
  final String companyId;
  final String companyName;
  final bool admin;
  final Future<void> Function()? onExit;
  @override
  State<BillingAccessMobileScreen> createState() =>
      _BillingAccessMobileScreenState();
}

class _BillingAccessMobileScreenState extends State<BillingAccessMobileScreen> {
  late final controller = BillingAccessController(
    widget.companyId,
    admin: widget.admin,
  );
  final reason = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
    controller.load();
  }

  void _changed() {
    if (!widget.admin &&
        controller.value?.allowed == true &&
        controller.error == null &&
        paymentRequiredCompany.value == widget.companyId)
      paymentRequiredCompany.value = null;
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    controller.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => PopScope(
        canPop: widget.admin && !controller.busy,
        child: SixMobilePageShell(
          title: billingText(context, 'title'),
          automaticallyImplyLeading: widget.admin,
          backgroundColor: colors.background,
          primaryColor: colors.primary,
          secondaryColor: colors.secondary,
          accentColor: colors.accent,
          bodyBuilder: (context, scroll, topInset) => ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 32),
            children: [
              Icon(Icons.lock_outline, size: 36, color: colors.accent),
              const SizedBox(height: 16),
              Text(
                widget.companyName.isEmpty
                    ? billingText(context, 'blocked')
                    : widget.companyName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                billingText(context, widget.admin ? 'adminMessage' : 'message'),
              ),
              const SizedBox(height: 20),
              if (controller.busy)
                SixBackendLoading(
                  title: billingText(context, 'loading'),
                  subtitle: '',
                  compact: true,
                ),
              if (controller.value != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        billingText(context, controller.value!.status),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: controller.value!.allowed
                              ? colors.accent
                              : colors.error,
                        ),
                      ),
                      if (controller.value!.validUntil != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${billingText(context, 'until')}: ${storageTimestamp(context, controller.value!.validUntil!)}',
                          ),
                        ),
                    ],
                  ),
                ),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    billingText(context, controller.error!),
                    style: TextStyle(color: colors.error),
                  ),
                ),
              if (widget.admin) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: reason,
                  enabled: !controller.busy,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: billingText(context, 'reason'),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: controller.busy || controller.value == null
                      ? null
                      : () => controller.release(reason.text),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      billingText(
                        context,
                        controller.value?.manualRelease == true
                            ? 'revoke'
                            : 'release',
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: controller.busy ? null : controller.load,
                icon: const Icon(Icons.refresh),
                label: Text(billingText(context, 'refresh')),
              ),
              if (!widget.admin)
                TextButton(
                  onPressed: widget.onExit,
                  child: Text(billingText(context, 'exit')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
