import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/storage_plan.dart';
import '../../l10n/storage_texts.dart';
import '../../providers/locale_settings_provider.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';
import '../controllers/storage_plans_controller.dart';

class StoragePlansMobileScreen extends StatefulWidget {
  const StoragePlansMobileScreen({
    super.key,
    required this.companyId,
    this.controller,
  });
  final String companyId;
  final StoragePlansController? controller;
  @override
  State<StoragePlansMobileScreen> createState() =>
      _StoragePlansMobileScreenState();
}

class _StoragePlansMobileScreenState extends State<StoragePlansMobileScreen> {
  late final StoragePlansController controller;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ??
        StoragePlansController(companyId: widget.companyId);
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String name(StoragePlan plan) =>
      plan.name(Localizations.localeOf(context).toLanguageTag());
  Future<void> pickPlan() async {
    String search = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.sixMobileColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .7,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        storageText(sheet, 'assignPlan'),
                        style: Theme.of(sheet).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheet),
                      tooltip: storageText(sheet, 'cancel'),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: storageText(sheet, 'searchPlans'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: sheet.sixMobileColors.softSurface,
                  ),
                  onChanged: (value) =>
                      update(() => search = value.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.remove_circle_outline),
                        title: Text(storageText(sheet, 'noPlan')),
                        onTap: () {
                          controller.selectPlan(null);
                          Navigator.pop(sheet);
                        },
                      ),
                      for (final plan in controller.plans.where(
                        (p) =>
                            p.assignable &&
                            name(p).toLowerCase().contains(search),
                      ))
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          selected: plan.id == controller.selectedPlanId,
                          selectedTileColor:
                              sheet.sixMobileColors.softAccentSurface,
                          leading: Icon(
                            plan.id == controller.selectedPlanId
                                ? Icons.check_circle
                                : Icons.layers_outlined,
                            color: sheet.sixMobileColors.accent,
                          ),
                          title: Text(name(plan)),
                          onTap: () {
                            controller.selectPlan(plan.id);
                            Navigator.pop(sheet);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
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
          child: SixMobilePageShell(
            title: storageText(context, 'plansTitle'),
            backgroundColor: colors.background,
            primaryColor: colors.primary,
            secondaryColor: colors.secondary,
            accentColor: colors.accent,
            actions: [
              IconButton(
                onPressed: c.loading || c.saving ? null : c.load,
                tooltip: storageText(context, 'refresh'),
                icon: const Icon(Icons.refresh),
              ),
            ],
            bodyBuilder: (context, scroll, topInset) => ListView(
              controller: scroll,
              padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 32),
              children: [
                Text(
                  storageText(context, 'informational'),
                  style: TextStyle(color: colors.mutedText),
                ),
                const SizedBox(height: 16),
                if (c.loading)
                  SixBackendLoading(
                    title: storageText(context, 'plansTitle'),
                    subtitle: storageText(context, 'pending'),
                    compact: true,
                    animation: SixBackendLoadingAnimation.skeletonPulse,
                  ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      storageText(context, c.error!),
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                if (c.changed && c.error == null)
                  Text(
                    storageText(context, 'saved'),
                    style: TextStyle(color: colors.accent),
                  ),
                if (c.loaded) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          storageText(context, 'assignPlan'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          storageText(context, 'assignmentHint'),
                          style: TextStyle(color: colors.mutedText),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.accent,
                            backgroundColor: colors.softAccentSurface,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: c.saving ? null : pickPlan,
                          icon: const Icon(Icons.layers_outlined),
                          label: Text(
                            selected == null
                                ? storageText(context, 'noPlan')
                                : name(selected),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                          ),
                          onPressed:
                              c.saving || c.selectedPlanId == c.current.planId
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
                  ),
                  if (c.plans.isEmpty) Text(storageText(context, 'emptyPlans')),
                  for (final plan in c.plans)
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            name(plan),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            storageText(
                              context,
                              plan.status == 'PUBLICADO'
                                  ? 'published'
                                  : plan.status == 'ARQUIVADO'
                                  ? 'archived'
                                  : 'draft',
                            ),
                            style: TextStyle(color: colors.mutedText),
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
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.accent,
                              backgroundColor: colors.softAccentSurface,
                            ),
                            onPressed: c.saving || !plan.editable
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => _QuotaEditorMobile(
                                        plan: plan,
                                        controller: c,
                                      ),
                                    ),
                                  ),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(storageText(context, 'configure')),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuotaEditorMobile extends StatefulWidget {
  const _QuotaEditorMobile({required this.plan, required this.controller});
  final StoragePlan plan;
  final StoragePlansController controller;
  @override
  State<_QuotaEditorMobile> createState() => _QuotaEditorMobileState();
}

class _QuotaEditorMobileState extends State<_QuotaEditorMobile> {
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
    FocusScope.of(context).unfocus();
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
      final colors = context.sixMobileColors;
      return PopScope(
        canPop: !c.saving,
        child: SixMobilePageShell(
          title: storageText(context, 'configure'),
          backgroundColor: colors.background,
          primaryColor: colors.primary,
          secondaryColor: colors.secondary,
          accentColor: colors.accent,
          bodyBuilder: (context, scroll, topInset) => ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 32),
            children: [
              Text(
                widget.plan.name(
                  Localizations.localeOf(context).toLanguageTag(),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                storageText(context, 'limitsHint'),
                style: TextStyle(color: colors.mutedText),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.softAccentSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  storageText(context, 'limitsScope'),
                  style: TextStyle(color: colors.titleText),
                ),
              ),
              const SizedBox(height: 20),
              for (final entry in [
                ('databaseQuota', database),
                ('filesQuota', files),
                ('uploadLimit', upload),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: TextField(
                    controller: entry.$2,
                    enabled: !c.saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: colors.titleText),
                    decoration: InputDecoration(
                      labelText: storageText(context, entry.$1),
                      filled: true,
                      fillColor: colors.softSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (c.error != null)
                Text(
                  storageText(context, c.error!),
                  style: TextStyle(color: colors.error),
                ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: c.saving || !c.loaded ? null : save,
                child: Text(storageText(context, c.saving ? 'saving' : 'save')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
