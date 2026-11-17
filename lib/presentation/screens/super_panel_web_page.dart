import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/admin_portal_service.dart';
import '../../l10n/super_panel_texts.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../components/six_backend_loading.dart';
import '../components/web_dashboard_widgets.dart';
import '../controllers/super_panel_controller.dart';
import '../layouts/six_web_page_shell.dart';
import '../theme/web_theme_tokens.dart';
import '../utils/infrastructure_formatters.dart';

class SuperPanelWebPage extends StatefulWidget {
  const SuperPanelWebPage({super.key, this.service});
  final AdminPortalService? service;

  @override
  State<SuperPanelWebPage> createState() => _SuperPanelWebPageState();
}

class _SuperPanelWebPageState extends State<SuperPanelWebPage> {
  late final SuperPanelController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SuperPanelController(service: widget.service);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setAuthorized(
      context.watch<ColaboradorAutorizacoesProvider>().ehSuperUsuario,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowed =
        context.watch<ColaboradorAutorizacoesProvider>().ehSuperUsuario;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final tokens = WebThemeTokens.of(context);
        final resumo = _controller.resumo;
        return SixWebPageShell(
          child: SingleChildScrollView(
            padding: SixWebPageShell.scrollPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SixWebDashboardHeader(
                  icon: Icons.admin_panel_settings_outlined,
                  title: superPanelText(context, 'title'),
                  subtitle: superPanelText(context, 'subtitle'),
                  actions: [
                    if (allowed)
                      OutlinedButton.icon(
                        onPressed:
                            _controller.loading ? null : _controller.reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(superPanelText(context, 'refresh')),
                      ),
                  ],
                ),
                SixWebPageShell.sectionGap,
                if (!allowed)
                  SixWebNoData(
                    key: const Key('super-panel-restricted'),
                    text: superPanelText(context, 'restricted'),
                  )
                else ...[
                  if (_controller.loading)
                    SixBackendLoading(
                      title: superPanelText(context, 'loading'),
                      subtitle: superPanelText(context, 'subtitle'),
                      backgroundColor: tokens.cardBackground,
                      borderColor: tokens.cardBorder,
                      leadingIcon: Icons.monitor_heart_outlined,
                      animation: SixBackendLoadingAnimation.skeletonPulse,
                    ),
                  if (_controller.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SixWebNoData(
                        text: superPanelText(context, 'error'),
                      ),
                    ),
                  if (resumo != null) ...[
                    SixWebPageShell.sectionGap,
                    _infrastructure(context, resumo),
                  ] else if (!_controller.loading && !_controller.hasError)
                    SixWebNoData(text: superPanelText(context, 'empty')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infrastructure(BuildContext context, AdminPortalResumo resumo) {
    final health = resumo.actuator;
    if (health == null &&
        resumo.bancosDeDados.isEmpty &&
        resumo.requestsHttp == null) {
      return SixWebNoData(text: superPanelText(context, 'empty'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < 920
                ? constraints.maxWidth
                : (constraints.maxWidth - 20) / 2;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            if (health != null)
              SizedBox(
                width: width,
                child: SixWebSectionCard(
                  title: superPanelText(context, 'health'),
                  icon: Icons.monitor_heart_outlined,
                  trailing: Chip(label: Text(health.status)),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metric(
                        'Uptime',
                        infrastructureDuration(health.uptimeSegundos),
                      ),
                      _metric(
                        'Heap',
                        '${infrastructureBytes(context, health.memoriaHeapUsadaBytes)} / ${infrastructureBytes(context, health.memoriaHeapMaxBytes)}',
                      ),
                      _metric(
                        'Threads',
                        infrastructureNumber(context, health.threadsAtivas),
                      ),
                      _metric(
                        'CPU',
                        infrastructureNumber(
                          context,
                          health.processadoresDisponiveis,
                        ),
                      ),
                      _metric(
                        superPanelText(context, 'load'),
                        infrastructureNumber(
                          context,
                          health.cargaSistema,
                          decimals: 2,
                        ),
                      ),
                      _metric('Java', health.versaoJava),
                    ],
                  ),
                ),
              ),
            if (resumo.requestsHttp != null)
              SizedBox(
                width: width,
                child: SixWebSectionCard(
                  title: superPanelText(context, 'requests'),
                  icon: Icons.http_rounded,
                  subtitle:
                      '${infrastructureNumber(context, _controller.windowValue)} ${_controller.windowUnit == AdminRequestWindowUnit.hours ? 'h' : 'min'}',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metric(
                        'HTTP 200',
                        infrastructureNumber(
                          context,
                          resumo.requestsHttp!.status200,
                        ),
                      ),
                      _metric(
                        'HTTP 400',
                        infrastructureNumber(
                          context,
                          resumo.requestsHttp!.status400,
                        ),
                      ),
                      _metric(
                        'HTTP 500',
                        infrastructureNumber(
                          context,
                          resumo.requestsHttp!.status500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (resumo.bancosDeDados.isNotEmpty)
              SizedBox(
                width: width,
                child: SixWebSectionCard(
                  title: superPanelText(context, 'databases'),
                  icon: Icons.storage_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final banco in resumo.bancosDeDados)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banco.nome,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _metric(
                                    superPanelText(context, 'data'),
                                    infrastructureBytes(
                                      context,
                                      banco.tamanhoDadosBytes,
                                    ),
                                  ),
                                  _metric(
                                    superPanelText(context, 'storage'),
                                    infrastructureBytes(
                                      context,
                                      banco.tamanhoArmazenadoBytes,
                                    ),
                                  ),
                                  _metric(
                                    superPanelText(context, 'indexes'),
                                    infrastructureBytes(
                                      context,
                                      banco.tamanhoIndicesBytes,
                                    ),
                                  ),
                                  _metric(
                                    superPanelText(context, 'total'),
                                    infrastructureBytes(
                                      context,
                                      banco.tamanhoTotalBytes,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _metric(String label, String value) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
