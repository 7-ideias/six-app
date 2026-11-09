import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/storage_plan.dart';
import '../../l10n/storage_texts.dart';
import '../../providers/locale_settings_provider.dart';
import '../controllers/storage_plans_controller.dart';
import '../components/web_dashboard_widgets.dart';
import '../components/six_backend_loading.dart';
import '../theme/web_theme_tokens.dart';

Future<void> showStoragePlansWeb(BuildContext context, {String? companyId}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 920,
          height: MediaQuery.sizeOf(context).height * .85,
          child: StoragePlansWebPage(companyId: companyId),
        ),
      ),
    );

class StoragePlansWebPage extends StatefulWidget {
  const StoragePlansWebPage({super.key, this.companyId});
  final String? companyId;
  @override
  State<StoragePlansWebPage> createState() => _StoragePlansWebPageState();
}

class _StoragePlansWebPageState extends State<StoragePlansWebPage> {
  late final StoragePlansController controller;
  @override
  void initState() {
    super.initState();
    controller = StoragePlansController(companyId: widget.companyId)..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String name(StoragePlan plan) =>
      plan.name(Localizations.localeOf(context).toLanguageTag());
  Future<void> edit(StoragePlan plan) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuotaEditorWeb(plan: plan, controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    context.watch<LocaleSettingsProvider>();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final c = controller;
        final selected = c.plans
            .where((p) => p.id == c.selectedPlanId)
            .firstOrNull;
        return PopScope(
          canPop: !c.saving,
          child: Material(
            color: tokens.workspaceBackground,
            child: Column(
              children: [
                SixWebDashboardHeader(
                  icon: Icons.tune,
                  title: storageText(context, 'plansTitle'),
                  subtitle: storageText(context, 'plansSubtitle'),
                  actions: [
                    IconButton(
                      tooltip: storageText(context, 'refresh'),
                      onPressed: c.loading || c.saving ? null : c.load,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: storageText(context, 'close'),
                      onPressed: c.saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          storageText(context, 'informational'),
                          style: TextStyle(color: tokens.secondaryText),
                        ),
                        const SizedBox(height: 16),
                        if (c.loading)
                          SixBackendLoading(
                            title: storageText(context, 'plansTitle'),
                            subtitle: storageText(context, 'pending'),
                            animation: SixBackendLoadingAnimation.skeletonPulse,
                          ),
                        if (c.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              storageText(context, c.error!),
                              style: TextStyle(color: tokens.danger),
                            ),
                          ),
                        if (c.changed && c.error == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              storageText(context, 'saved'),
                              style: TextStyle(color: tokens.success),
                            ),
                          ),
                        if (c.loaded && widget.companyId != null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: tokens.cardBackground,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: tokens.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  storageText(context, 'assignPlan'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(storageText(context, 'assignmentHint')),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    PopupMenuButton<String>(
                                      enabled: !c.saving,
                                      onSelected: (id) =>
                                          c.selectPlan(id.isEmpty ? null : id),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: '',
                                          child: Text(
                                            storageText(context, 'noPlan'),
                                          ),
                                        ),
                                        for (final plan in c.plans.where(
                                          (p) => p.assignable,
                                        ))
                                          PopupMenuItem(
                                            value: plan.id,
                                            child: Text(name(plan)),
                                          ),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tokens.inputBackground,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: tokens.cardBorder,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 280,
                                              ),
                                              child: Text(
                                                selected == null
                                                    ? storageText(
                                                        context,
                                                        'noPlan',
                                                      )
                                                    : name(selected),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.expand_more),
                                          ],
                                        ),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed:
                                          c.saving ||
                                              c.selectedPlanId ==
                                                  c.current.planId
                                          ? null
                                          : () => c.assign(c.selectedPlanId),
                                      child: Text(
                                        storageText(
                                          context,
                                          c.saving ? 'saving' : 'applyPlan',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        if (c.loaded && c.plans.isEmpty)
                          Text(storageText(context, 'emptyPlans')),
                        if (c.loaded)
                          for (final plan in c.plans)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: tokens.cardBackground,
                                border: Border.all(color: tokens.cardBorder),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 16,
                                    runSpacing: 12,
                                    children: [
                                      Text(
                                        name(plan),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        storageText(
                                          context,
                                          plan.status == 'PUBLICADO'
                                              ? 'published'
                                              : plan.status == 'ARQUIVADO'
                                              ? 'archived'
                                              : 'draft',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: c.saving || !plan.editable
                                            ? null
                                            : () => edit(plan),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: Text(
                                          storageText(context, 'configure'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${storageText(context, 'database')}: ${plan.limits.databaseLimitBytes == null ? storageText(context, 'quotaNotConfigured') : storageBytes(context, plan.limits.databaseLimitBytes!)}',
                                  ),
                                  Text(
                                    '${storageText(context, 'files')}: ${plan.limits.fileLimitBytes == null ? storageText(context, 'quotaNotConfigured') : storageBytes(context, plan.limits.fileLimitBytes!)}',
                                  ),
                                  Text(
                                    '${storageText(context, 'uploadConfigured')}: ${plan.limits.maxUploadBytes == null ? storageText(context, 'quotaNotConfigured') : storageBytes(context, plan.limits.maxUploadBytes!)}',
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuotaEditorWeb extends StatefulWidget {
  const _QuotaEditorWeb({required this.plan, required this.controller});
  final StoragePlan plan;
  final StoragePlansController controller;
  @override
  State<_QuotaEditorWeb> createState() => _QuotaEditorWebState();
}

class _QuotaEditorWebState extends State<_QuotaEditorWeb> {
  final database = TextEditingController();
  final files = TextEditingController();
  final upload = TextEditingController();
  bool initialized = false;
  late String separator;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    separator = context.read<LocaleSettingsProvider>().decimalSeparator;
    database.text = storageBytesToMegabytes(
      widget.plan.limits.databaseLimitBytes,
      separator,
    );
    files.text = storageBytesToMegabytes(
      widget.plan.limits.fileLimitBytes,
      separator,
    );
    upload.text = storageBytesToMegabytes(
      widget.plan.limits.maxUploadBytes,
      separator,
    );
  }

  @override
  void dispose() {
    database.dispose();
    files.dispose();
    upload.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final success = await widget.controller.save(
      widget.plan,
      database.text,
      files.text,
      upload.text,
      separator,
    );
    if (mounted && success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final tokens = WebThemeTokens.of(context);
      return PopScope(
        canPop: !c.saving,
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: MediaQuery.sizeOf(context).height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.plan.name(
                      Localizations.localeOf(context).toLanguageTag(),
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(storageText(context, 'limitsHint')),
                  const SizedBox(height: 12),
                  Text(
                    storageText(context, 'limitsScope'),
                    style: TextStyle(color: tokens.warning),
                  ),
                  const SizedBox(height: 20),
                  for (final entry in [
                    ('databaseQuota', database),
                    ('filesQuota', files),
                    ('uploadLimit', upload),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: entry.$2,
                        enabled: !c.saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: storageText(context, entry.$1),
                          filled: true,
                          fillColor: tokens.inputBackground,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  if (c.error != null)
                    Text(
                      storageText(context, c.error!),
                      style: TextStyle(color: tokens.danger),
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: c.saving
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(storageText(context, 'cancel')),
                      ),
                      FilledButton(
                        onPressed: c.saving || !c.loaded ? null : save,
                        child: Text(
                          storageText(context, c.saving ? 'saving' : 'save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
