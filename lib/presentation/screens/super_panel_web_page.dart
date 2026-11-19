import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/admin_portal_service.dart';
import '../../l10n/super_panel_texts.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../components/six_backend_loading.dart';
import '../components/web_dashboard_widgets.dart';
import '../components/super_cockpit_chart.dart';
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
    _controller = SuperPanelController(
      service: widget.service ?? AdminPortalService(cockpit: true),
    );
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
                  subtitle: [
                    superPanelText(context, 'scope'),
                    if (resumo?.cockpit != null)
                      '${superPanelText(context, 'collected')} ${cockpitTime(resumo!.cockpit!.collectedAt)} UTC',
                  ].join('  ·  '),
                  actions: [
                    if (allowed)
                      DropdownButton<int>(
                        value:
                            _controller.windowUnit ==
                                    AdminRequestWindowUnit.hours
                                ? _controller.windowValue * 60
                                : _controller.windowValue,
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 min')),
                          DropdownMenuItem(value: 60, child: Text('1 h')),
                          DropdownMenuItem(value: 1440, child: Text('24 h')),
                        ],
                        onChanged:
                            _controller.loading
                                ? null
                                : (minutes) {
                                  if (minutes == null) return;
                                  _controller.changeWindow(
                                    minutes == 15 ? 15 : minutes ~/ 60,
                                    minutes == 15
                                        ? AdminRequestWindowUnit.minutes
                                        : AdminRequestWindowUnit.hours,
                                  );
                                },
                      ),
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
                    if (resumo.cockpit != null)
                      _cockpit(context, resumo)
                    else
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

  Widget _cockpit(BuildContext context, AdminPortalResumo resumo) {
    final snapshot = resumo.cockpit!;
    final health = resumo.actuator;
    final p95 = snapshot.p95;
    final noSamples = superPanelText(context, 'noSamples');
    final cards = [
      (
        superPanelText(context, 'health'),
        health?.status ?? '—',
        Icons.monitor_heart_outlined,
      ),
      (
        superPanelText(context, 'rate'),
        snapshot.observedMs == 0
            ? '—'
            : infrastructureNumber(
              context,
              snapshot.total * 60000 / snapshot.observedMs,
              decimals: 1,
            ),
        Icons.swap_vert,
      ),
      (
        'p95',
        p95 == null ? noSamples : '≈ ${infrastructureNumber(context, p95)} ms',
        Icons.speed,
      ),
      (
        superPanelText(context, 'errors'),
        snapshot.total == 0
            ? '0'
            : '${snapshot.serverErrors} · ${infrastructureNumber(context, 100 * snapshot.serverErrors / snapshot.total, decimals: 1)}%',
        Icons.error_outline,
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 14.0;
        final columns =
            box.maxWidth >= 960
                ? 4
                : box.maxWidth >= 460
                ? 2
                : 1;
        final tileWidth = (box.maxWidth - (columns - 1) * gap) / columns;
        final width =
            box.maxWidth >= 800 ? (box.maxWidth - gap) / 2 : box.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: tileWidth,
                    child: SixWebSectionCard(
                      title: card.$1,
                      icon: card.$3,
                      child: Text(
                        card.$2,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              card.$3 == Icons.error_outline &&
                                      snapshot.serverErrors > 0
                                  ? Colors.red
                                  : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final latency in [false, true])
                  SizedBox(
                    width: width,
                    child: SuperCockpitChart(snapshot, latency: latency),
                  ),
                SizedBox(
                  width: width,
                  child: SixWebSectionCard(
                    title: superPanelText(context, 'databases'),
                    icon: Icons.storage,
                    child: Column(
                      children: [
                        for (final db in resumo.bancosDeDados)
                          ExpansionTile(
                            title: Text(db.nome),
                            subtitle: Text(
                              db.available == false
                                  ? superPanelText(context, 'UNAVAILABLE')
                                  : [
                                    if (db.available == true)
                                      superPanelText(context, 'available'),
                                    infrastructureBytes(
                                      context,
                                      db.tamanhoTotalBytes,
                                    ),
                                  ].join(' · '),
                            ),
                            enabled: db.available != false,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _metric(
                                    superPanelText(context, 'data'),
                                    infrastructureBytes(
                                      context,
                                      db.tamanhoDadosBytes,
                                    ),
                                  ),
                                  _metric(
                                    superPanelText(context, 'storage'),
                                    infrastructureBytes(
                                      context,
                                      db.tamanhoArmazenadoBytes,
                                    ),
                                  ),
                                  _metric(
                                    superPanelText(context, 'indexes'),
                                    infrastructureBytes(
                                      context,
                                      db.tamanhoIndicesBytes,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SixWebSectionCard(
                    title: superPanelText(context, 'events'),
                    icon: Icons.history,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (snapshot.events.isEmpty)
                          Text(superPanelText(context, 'none')),
                        for (final event in snapshot.events.take(5))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              [
                                '${cockpitTime(event.time)} UTC',
                                if (event.source != null) event.source!,
                                superPanelText(context, event.type),
                              ].join(' · '),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (health != null)
              ExpansionTile(
                title: Text(superPanelText(context, 'details')),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _metric(
                        'Uptime',
                        infrastructureDuration(health.uptimeSegundos),
                      ),
                      _metric(
                        'Heap',
                        '${infrastructureBytes(context, health.memoriaHeapUsadaBytes)} / ${infrastructureBytes(context, health.memoriaHeapMaxBytes)}',
                      ),
                      _metric('Threads', '${health.threadsAtivas}'),
                      _metric('CPU', '${health.processadoresDisponiveis}'),
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
                ],
              ),
          ],
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
