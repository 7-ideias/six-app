import 'subscription_web_page.dart';

import 'package:flutter/material.dart';

import '../../core/services/billing_http_client.dart';
import '../../l10n/billing_texts.dart';
import '../../l10n/storage_texts.dart';
import '../controllers/billing_access_controller.dart';
import '../components/six_backend_loading.dart';
import '../theme/web_theme_tokens.dart';

Future<void> showBillingAccessWeb(
  BuildContext context,
  String companyId,
  String companyName,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => Dialog(
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 680,
      height: MediaQuery.sizeOf(context).height * .8,
      child: BillingAccessWebPage(
        companyId: companyId,
        companyName: companyName,
        admin: true,
      ),
    ),
  ),
);

class BillingAccessWebPage extends StatefulWidget {
  const BillingAccessWebPage({
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
  State<BillingAccessWebPage> createState() => _BillingAccessWebPageState();
}

class _BillingAccessWebPageState extends State<BillingAccessWebPage> {
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
    final colors = WebThemeTokens.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => PopScope(
        canPop: widget.admin && !controller.busy,
        child: Material(
          color: colors.workspaceBackground,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(28),
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: colors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          billingText(
                            context,
                            widget.admin ? 'title' : 'blocked',
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (widget.admin)
                        IconButton(
                          tooltip: billingText(context, 'close'),
                          onPressed: controller.busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  if (widget.companyName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(widget.companyName),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    billingText(
                      context,
                      widget.admin ? 'adminMessage' : 'message',
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (controller.busy)
                    SixBackendLoading(
                      title: billingText(context, 'loading'),
                      subtitle: '',
                      compact: true,
                    ),
                  if (controller.value != null) ...[
                    Text(
                      billingText(context, controller.value!.status),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: controller.value!.allowed
                            ? colors.success
                            : colors.danger,
                      ),
                    ),
                    if (controller.value!.validUntil != null)
                      Text(
                        '${billingText(context, 'until')}: ${storageTimestamp(context, controller.value!.validUntil!)}',
                      ),
                  ],
                  if (controller.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        billingText(context, controller.error!),
                        style: TextStyle(color: colors.danger),
                      ),
                    ),
                  if (!widget.admin) ...[
                    const SizedBox(height: 24),
                    SubscriptionWebPanel(companyId: widget.companyId),
                  ],
                  if (widget.admin) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: reason,
                      enabled: !controller.busy,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: billingText(context, 'reason'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: controller.busy || controller.value == null
                          ? null
                          : () => controller.release(reason.text),
                      child: Text(
                        billingText(
                          context,
                          controller.value?.manualRelease == true
                              ? 'revoke'
                              : 'release',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
