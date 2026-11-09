import '../../data/models/storage_plan.dart';
import '../../providers/locale_settings_provider.dart';
import 'storage_plans_mobile_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/storage_texts.dart';
import '../../providers/empresa_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';
import '../controllers/storage_usage_controller.dart';

class StorageUsageMobileScreen extends StatefulWidget {
  const StorageUsageMobileScreen({
    super.key,
    this.adminCompanyId,
    this.companyLabel,
  });
  final String? adminCompanyId;
  final String? companyLabel;
  @override
  State<StorageUsageMobileScreen> createState() =>
      _StorageUsageMobileScreenState();
}

class _StorageUsageMobileScreenState extends State<StorageUsageMobileScreen> {
  late StorageUsageController _controller;
  Object? _company;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _controller = StorageUsageController(adminCompanyId: widget.adminCompanyId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final company = widget.adminCompanyId == null
        ? context.watch<EmpresaProvider>().empresa
        : widget.adminCompanyId;
    if (!_started || !identical(company, _company)) {
      _started = true;
      _company = company;
      _controller.load(reset: true);
    }
  }

  @override
  void didUpdateWidget(covariant StorageUsageMobileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adminCompanyId != widget.adminCompanyId) {
      _controller.dispose();
      _controller = StorageUsageController(
        adminCompanyId: widget.adminCompanyId,
      )..load(reset: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final usage = _controller.usage;
        return SixMobilePageShell(
          title: storageText(context, 'title'),
          backgroundColor: colors.background,
          primaryColor: SixMobilePalette.primary,
          secondaryColor: SixMobilePalette.secondary,
          accentColor: colors.accent,
          actions: [
            IconButton(
              onPressed: _controller.loading ? null : () => _controller.load(),
              tooltip: storageText(context, 'refresh'),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bodyBuilder: (context, scrollController, topInset) => RefreshIndicator(
            onRefresh: () => _controller.load(),
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 32),
              children: [
                Text(
                  widget.companyLabel ?? storageText(context, 'subtitle'),
                  style: TextStyle(color: colors.mutedText),
                ),
                const SizedBox(height: 16),
                Text(
                  '${storageText(context, 'plan')}: ${usage == null
                      ? storageText(context, 'noMeasurement')
                      : usage.plan.planId == null
                      ? storageText(context, 'noPlan')
                      : usage.plan.name(Localizations.localeOf(context).toLanguageTag())}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.adminCompanyId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accent,
                        backgroundColor: colors.softAccentSurface,
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StoragePlansMobileScreen(
                              companyId: widget.adminCompanyId!,
                            ),
                          ),
                        );
                        if (mounted) await _controller.load();
                      },
                      icon: const Icon(Icons.tune),
                      label: Text(storageText(context, 'managePlans')),
                    ),
                  ),
                const SizedBox(height: 12),
                _usageCard(
                  context,
                  Icons.storage_outlined,
                  'database',
                  usage?.databaseBytes,
                ),
                const SizedBox(height: 12),
                _usageCard(
                  context,
                  Icons.folder_outlined,
                  'files',
                  usage?.fileBytes,
                ),
                const SizedBox(height: 16),
                if (_controller.loading &&
                    usage == null &&
                    _controller.error == null)
                  SixBackendLoading(
                    title: storageText(context, 'pending'),
                    subtitle: storageText(context, 'subtitle'),
                    compact: true,
                    animation: SixBackendLoadingAnimation.skeletonPulse,
                  ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _controller.error != null
                        ? storageText(context, _controller.error!)
                        : usage == null
                        ? storageText(context, 'pending')
                        : storageText(context, storageStatusKey(usage.status)),
                    style: TextStyle(
                      color:
                          _controller.error != null || usage?.status == 'ERRO'
                          ? colors.error
                          : colors.mutedText,
                    ),
                  ),
                ),
                if (usage?.measuredAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '${storageText(context, 'measuredAt')}: ${storageTimestamp(context, usage!.measuredAt!)}',
                      style: TextStyle(color: colors.mutedText, fontSize: 12),
                    ),
                  ),
                if (usage?.plan.limits.maxUploadBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${storageText(context, 'uploadConfigured')}: ${storageBytes(context, usage!.plan.limits.maxUploadBytes!)}',
                    ),
                  ),
                if (usage?.status == 'PARCIAL')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(storageText(context, 'partialQuota')),
                  ),
                const SizedBox(height: 24),
                Text(
                  storageText(context, 'scope'),
                  style: TextStyle(color: colors.mutedText, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  storageText(context, 'informational'),
                  style: TextStyle(color: colors.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _usageCard(
    BuildContext context,
    IconData icon,
    String label,
    int? bytes,
  ) {
    final colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  storageText(context, label),
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bytes == null)
            Text(
              storageText(context, 'noMeasurement'),
              style: TextStyle(color: colors.mutedText),
            )
          else
            TweenAnimationBuilder<double>(
              key: ValueKey('$label:$bytes'),
              tween: Tween(begin: 0, end: bytes.toDouble()),
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              builder: (context, value, _) => Text(
                storageBytes(context, value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.titleText,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 14),
          ..._quota(context, label, bytes),
        ],
      ),
    );
  }

  List<Widget> _quota(BuildContext context, String label, int? bytes) {
    final limits = _controller.usage?.plan.limits;
    final limit = label == 'database'
        ? limits?.databaseLimitBytes
        : limits?.fileLimitBytes;
    final status = storageQuotaStatus(bytes, limit);
    final colors = context.sixMobileColors;
    final color = status == 'quotaExceeded' || status == 'quotaReached'
        ? colors.error
        : colors.accent;
    final ratio = bytes == null || limit == null ? null : bytes / limit;
    return [
      if (limit != null)
        Text(
          '${bytes == null ? storageText(context, 'noMeasurement') : storageBytes(context, bytes)} ${storageText(context, 'of')} ${storageBytes(context, limit)}',
        ),
      if (ratio != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0).toDouble(),
            color: color,
            backgroundColor: colors.softSurface,
            semanticsLabel: storageText(context, label),
            semanticsValue: context
                .read<LocaleSettingsProvider>()
                .formatPercent(ratio * 100),
          ),
        ),
      if (ratio != null)
        Text(
          context.read<LocaleSettingsProvider>().formatPercent(ratio * 100),
          style: TextStyle(color: colors.mutedText),
        ),
      Text(storageText(context, status), style: TextStyle(color: color)),
    ];
  }
}
