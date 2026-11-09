import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/storage_texts.dart';
import '../../providers/empresa_provider.dart';
import '../controllers/storage_usage_controller.dart';
import '../components/six_backend_loading.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';

Future<void> showStorageUsageWeb(
  BuildContext context, {
  String? companyId,
  String? companyLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 880,
        height: MediaQuery.sizeOf(dialogContext).height * .8,
        child: StorageUsageWebPage(
          adminCompanyId: companyId,
          companyLabel: companyLabel,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    ),
  );
}

class StorageUsageWebPage extends StatefulWidget {
  const StorageUsageWebPage({
    super.key,
    this.adminCompanyId,
    this.companyLabel,
    this.onClose,
  });
  final String? adminCompanyId;
  final String? companyLabel;
  final VoidCallback? onClose;
  @override
  State<StorageUsageWebPage> createState() => _StorageUsageWebPageState();
}

class _StorageUsageWebPageState extends State<StorageUsageWebPage> {
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
  void didUpdateWidget(covariant StorageUsageWebPage oldWidget) {
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
    final tokens = WebThemeTokens.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final usage = _controller.usage;
        return Material(
          color: tokens.workspaceBackground,
          child: Column(
            children: [
              SixWebDashboardHeader(
                icon: Icons.cloud_outlined,
                title: storageText(context, 'title'),
                subtitle:
                    widget.companyLabel ?? storageText(context, 'subtitle'),
                actions: [
                  OutlinedButton.icon(
                    onPressed: _controller.loading
                        ? null
                        : () => _controller.load(),
                    icon: const Icon(Icons.refresh),
                    label: Text(storageText(context, 'refresh')),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                      tooltip: storageText(context, 'close'),
                    ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth < 600
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 2;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: width,
                                child: _metric(
                                  context,
                                  Icons.storage_outlined,
                                  'database',
                                  usage?.databaseBytes,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _metric(
                                  context,
                                  Icons.folder_outlined,
                                  'files',
                                  usage?.fileBytes,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      if (_controller.loading &&
                          usage == null &&
                          _controller.error == null)
                        SixBackendLoading(
                          title: storageText(context, 'pending'),
                          subtitle: storageText(context, 'subtitle'),
                          animation: SixBackendLoadingAnimation.skeletonPulse,
                        ),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _controller.error != null
                              ? storageText(context, _controller.error!)
                              : usage == null
                              ? storageText(context, 'pending')
                              : storageText(
                                  context,
                                  storageStatusKey(usage.status),
                                ),
                          style: TextStyle(
                            color:
                                _controller.error != null ||
                                    usage?.status == 'ERRO'
                                ? tokens.danger
                                : tokens.secondaryText,
                          ),
                        ),
                      ),
                      if (usage?.measuredAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${storageText(context, 'measuredAt')}: ${storageTimestamp(context, usage!.measuredAt!)}',
                            style: TextStyle(color: tokens.secondaryText),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        storageText(context, 'scope'),
                        style: TextStyle(color: tokens.secondaryText),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        storageText(context, 'observation'),
                        style: TextStyle(color: tokens.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metric(
    BuildContext context,
    IconData icon,
    String label,
    int? bytes,
  ) {
    if (bytes != null)
      return SixWebKpiCard(
        icon: icon,
        label: storageText(context, label),
        value: bytes.toDouble(),
        formatter: (value) => storageBytes(context, value),
      );
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tokens.info),
          const SizedBox(height: 12),
          Text(storageText(context, label)),
          const SizedBox(height: 8),
          Text(
            storageText(context, 'noMeasurement'),
            style: TextStyle(color: tokens.secondaryText),
          ),
        ],
      ),
    );
  }
}
