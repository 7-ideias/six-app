import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/admin_portal_service.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../../l10n/super_panel_texts.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';
import '../controllers/super_panel_controller.dart';
import '../utils/infrastructure_formatters.dart';
import 'usuarios_sixo_mobile_screen.dart';

class SuperPanelMobileScreen extends StatefulWidget {
  const SuperPanelMobileScreen({super.key, this.service});
  final AdminPortalService? service;
  @override
  State<SuperPanelMobileScreen> createState() => _SuperPanelMobileScreenState();
}

class _InfrastructureRequestsFilterSelection {
  const _InfrastructureRequestsFilterSelection({
    required this.value,
    required this.unit,
  });

  final int value;
  final AdminRequestWindowUnit unit;
}

class _SuperPanelMobileScreenState extends State<SuperPanelMobileScreen> {
  late final SuperPanelController _controller;
  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _surfaceColor => _colors.surface;
  Color get _accentColor => _colors.accent;
  Color get _titleTextColor => _colors.titleText;
  Color get _mutedTextColor => _colors.mutedText;
  Color get _borderColor => _colors.border;
  Color get _softSurface => _colors.softSurface;
  AdminPortalResumo? get _resumoInfraestrutura => _controller.resumo;
  bool get _carregandoInfraestrutura => _controller.loading;
  int get _infrastructureRequestsWindowValue => _controller.windowValue;
  AdminRequestWindowUnit get _infrastructureRequestsWindowUnit =>
      _controller.windowUnit;

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

  Future<void> _carregarInfraestrutura() => _controller.reload();
  String _formatInfrastructureBytes(int bytes) =>
      infrastructureBytes(context, bytes);
  String _formatInfrastructureDuration(int seconds) =>
      infrastructureDuration(seconds);
  String _formatInfrastructureLoad(double load) =>
      infrastructureNumber(context, load, decimals: load >= 10 ? 1 : 2);

  @override
  Widget build(BuildContext context) {
    final allowed =
        context.watch<ColaboradorAutorizacoesProvider>().ehSuperUsuario;
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, _) => SixMobilePageShell(
            title: superPanelText(context, 'title'),
            backgroundColor: _colors.background,
            primaryColor: _colors.primary,
            secondaryColor: _colors.secondary,
            accentColor: _colors.accent,
            actions: [
              if (allowed)
                IconButton(
                  tooltip: superPanelText(context, 'refresh'),
                  onPressed: _controller.loading ? null : _controller.reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
            bodyBuilder:
                (context, scrollController, topInset) => SafeArea(
                  top: false,
                  child: RefreshIndicator(
                    onRefresh: _controller.reload,
                    child: ListView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 24),
                      children: [
                        if (!allowed)
                          Text(
                            superPanelText(context, 'restricted'),
                            key: const Key('super-panel-restricted'),
                          )
                        else ...[
                          Text(
                            superPanelText(context, 'subtitle'),
                            style: TextStyle(color: _mutedTextColor),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: Text(
                              context.t(
                                'usuariosSixo.title',
                                fallback: 'Usuários do Sixo',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _colors.accent,
                              side: BorderSide(color: _colors.border),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed:
                                () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => UsuariosSixoMobileScreen(
                                          service: widget.service,
                                        ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (_controller.hasError &&
                              _controller.resumo != null) ...[
                            _buildInfrastructureErrorCard(context),
                            const SizedBox(height: 12),
                          ],
                          if (_controller.loading && _controller.resumo != null)
                            const LinearProgressIndicator(),
                          _buildSuperInfrastructureBlock(context),
                        ],
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildSuperInfrastructureBlock(BuildContext context) {
    final AdminPortalResumo? resumo = _resumoInfraestrutura;

    if (_carregandoInfraestrutura && resumo == null) {
      return _buildInfrastructureLoadingCard(context);
    }

    if (_controller.hasError && resumo == null) {
      return _buildInfrastructureErrorCard(context);
    }

    if (resumo == null ||
        (resumo.bancosDeDados.isEmpty &&
            resumo.actuator == null &&
            resumo.requestsHttp == null)) {
      return _buildInfrastructureEmptyCard(context);
    }

    return Column(
      children: <Widget>[
        if (resumo.bancosDeDados.isNotEmpty)
          _buildInfrastructurePanel(
            context,
            icon: Icons.storage_rounded,
            title: context.t(
              'dashboardInicio.mobileInfrastructureDatabasesTitle',
              fallback: 'Bancos monitorados',
            ),
            child: Column(
              children: resumo.bancosDeDados
                  .map((AdminBancoDadosResumo banco) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: banco == resumo.bancosDeDados.last ? 0 : 10,
                      ),
                      child: _buildDatabaseSummary(context, banco),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        if (resumo.bancosDeDados.isNotEmpty &&
            (resumo.requestsHttp != null || resumo.actuator != null))
          SizedBox(height: 12),
        if (resumo.requestsHttp != null)
          _buildInfrastructurePanel(
            context,
            icon: Icons.http_rounded,
            title: context.t(
              'dashboardInicio.mobileInfrastructureRequestsTitle',
              fallback: 'Requests do backend',
            ),
            trailing: _buildInfrastructureRequestsFilterButton(context),
            child: _buildInfrastructureRequestsContent(
              context,
              resumo.requestsHttp!,
            ),
          ),
        if (resumo.requestsHttp != null && resumo.actuator != null)
          SizedBox(height: 12),
        if (resumo.actuator != null)
          _buildInfrastructurePanel(
            context,
            icon: Icons.monitor_heart_rounded,
            title: context.t(
              'dashboardInicio.mobileInfrastructureHealthTitle',
              fallback: 'Saúde do backend',
            ),
            trailing: _buildInfrastructureStatusBadge(resumo.actuator!),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildInfrastructurePill(
                  context,
                  label: 'Uptime',
                  value: _formatInfrastructureDuration(
                    resumo.actuator!.uptimeSegundos,
                  ),
                ),
                _buildInfrastructurePill(
                  context,
                  label: 'Heap',
                  value:
                      '${_formatInfrastructureBytes(resumo.actuator!.memoriaHeapUsadaBytes)} / ${_formatInfrastructureBytes(resumo.actuator!.memoriaHeapMaxBytes)}',
                ),
                _buildInfrastructurePill(
                  context,
                  label: 'Threads',
                  value: infrastructureNumber(
                    context,
                    resumo.actuator!.threadsAtivas,
                  ),
                ),
                _buildInfrastructurePill(
                  context,
                  label: 'CPU',
                  value: infrastructureNumber(
                    context,
                    resumo.actuator!.processadoresDisponiveis,
                  ),
                ),
                _buildInfrastructurePill(
                  context,
                  label: superPanelText(context, 'load'),
                  value: _formatInfrastructureLoad(
                    resumo.actuator!.cargaSistema,
                  ),
                ),
                _buildInfrastructurePill(
                  context,
                  label: 'Java',
                  value: resumo.actuator!.versaoJava,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfrastructureRequestsContent(
    BuildContext context,
    AdminRequestStatusResumo resumo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'dashboardInicio.mobileInfrastructureRequestsSubtitle',
            fallback: 'Respostas monitoradas na janela selecionada do backend.',
          ),
          style: TextStyle(
            color: _mutedTextColor,
            fontSize: 11.5,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double itemWidth =
                constraints.maxWidth < 320
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  width: itemWidth,
                  child: _buildInfrastructureRequestMetricCard(
                    context,
                    statusCode: 200,
                    count: resumo.status200,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildInfrastructureRequestMetricCard(
                    context,
                    statusCode: 400,
                    count: resumo.status400,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildInfrastructureRequestMetricCard(
                    context,
                    statusCode: 500,
                    count: resumo.status500,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfrastructurePanel(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(title),
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: _accentColor,
        collapsedIconColor: _mutedTextColor,
        leading: Icon(icon, color: _accentColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: _titleTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle:
            trailing == null
                ? null
                : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: trailing,
                  ),
                ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [child],
      ),
    );
  }

  Widget _buildInfrastructureRequestMetricCard(
    BuildContext context, {
    required int statusCode,
    required int count,
  }) {
    final Color color = _requestStatusColor(statusCode);
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            statusCode.toString(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            infrastructureNumber(context, count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseSummary(
    BuildContext context,
    AdminBancoDadosResumo banco,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                banco.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _titleTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 8),
            _buildInfrastructureCompactMetric(
              label: superPanelText(context, 'total'),
              value: _formatInfrastructureBytes(banco.tamanhoTotalBytes),
              emphasisColor: _accentColor,
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _buildInfrastructureCompactMetric(
              label: superPanelText(context, 'data'),
              value: _formatInfrastructureBytes(banco.tamanhoDadosBytes),
            ),
            _buildInfrastructureCompactMetric(
              label: superPanelText(context, 'storage'),
              value: _formatInfrastructureBytes(banco.tamanhoArmazenadoBytes),
            ),
            _buildInfrastructureCompactMetric(
              label: superPanelText(context, 'indexes'),
              value: _formatInfrastructureBytes(banco.tamanhoIndicesBytes),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfrastructureCompactMetric({
    required String label,
    required String value,
    Color? emphasisColor,
  }) {
    final Color accent = emphasisColor ?? _titleTextColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (emphasisColor ?? _borderColor).withValues(alpha: 0.68),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color:
                  emphasisColor == null
                      ? _mutedTextColor
                      : accent.withValues(alpha: 0.92),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructurePill(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor.withValues(alpha: 0.72)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: _titleTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfrastructureStatusBadge(AdminActuatorResumo actuator) {
    final bool ok = actuator.status.toUpperCase() == 'UP';
    final Color color = ok ? _requestStatusColor(200) : _colors.error;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        actuator.status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfrastructureRequestsFilterButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _carregandoInfraestrutura ? null : _abrirFiltroInfraestrutura,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _softSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _borderColor.withValues(alpha: 0.82)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.schedule_rounded, size: 14, color: _accentColor),
              SizedBox(width: 6),
              Text(
                _formatInfrastructureWindowLabel(
                  context,
                  value: _infrastructureRequestsWindowValue,
                  unit: _infrastructureRequestsWindowUnit,
                ),
                style: TextStyle(
                  color: _titleTextColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFiltroInfraestrutura() async {
    final selection =
        await showModalBottomSheet<_InfrastructureRequestsFilterSelection>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.44),
          builder:
              (_) => _InfrastructureRequestsFilterSheet(
                value: _infrastructureRequestsWindowValue,
                unit: _infrastructureRequestsWindowUnit,
              ),
        );
    if (selection == null || !mounted) {
      return;
    }
    await _controller.changeWindow(selection.value, selection.unit);
  }

  Widget _buildInfrastructureLoadingCard(BuildContext context) =>
      SixBackendLoading(
        title: superPanelText(context, 'loading'),
        subtitle: superPanelText(context, 'subtitle'),
        backgroundColor: _surfaceColor,
        borderColor: _borderColor,
        leadingIcon: Icons.monitor_heart_outlined,
        animation: SixBackendLoadingAnimation.skeletonPulse,
      );

  Widget _buildInfrastructureErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _colors.errorBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline_rounded, color: _colors.error, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t(
                    'dashboardInicio.mobileInfrastructureErrorTitle',
                    fallback: 'Não foi possível carregar a infraestrutura.',
                  ),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _carregarInfraestrutura,
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureEmptyCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: _mutedTextColor, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'dashboardInicio.mobileInfrastructureEmpty',
                fallback:
                    'Nenhuma informação de infraestrutura está disponível agora.',
              ),
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatInfrastructureWindowLabel(
    BuildContext context, {
    required int value,
    required AdminRequestWindowUnit unit,
  }) {
    final bool singular = value == 1;
    switch (unit) {
      case AdminRequestWindowUnit.hours:
        return '$value ${context.t(singular ? 'dashboardInicio.mobileInfrastructureRequestsHourSingular' : 'dashboardInicio.mobileInfrastructureRequestsHourPlural', fallback: singular ? 'hora' : 'horas')}';
      case AdminRequestWindowUnit.minutes:
        return '$value ${context.t(singular ? 'dashboardInicio.mobileInfrastructureRequestsMinuteSingular' : 'dashboardInicio.mobileInfrastructureRequestsMinutePlural', fallback: singular ? 'minuto' : 'minutos')}';
    }
  }

  Color _requestStatusColor(int statusCode) {
    switch (statusCode) {
      case 200:
        return Theme.of(context).brightness == Brightness.dark
            ? SixMobilePalette.successDark
            : SixMobilePalette.successLight;
      case 400:
        return Theme.of(context).brightness == Brightness.dark
            ? SixMobilePalette.warningDark
            : SixMobilePalette.warningLight;
      case 500:
      default:
        return _colors.error;
    }
  }
}

class _InfrastructureRequestsFilterSheet extends StatefulWidget {
  const _InfrastructureRequestsFilterSheet({
    required this.value,
    required this.unit,
  });

  final int value;
  final AdminRequestWindowUnit unit;

  @override
  State<_InfrastructureRequestsFilterSheet> createState() =>
      _InfrastructureRequestsFilterSheetState();
}

class _InfrastructureRequestsFilterSheetState
    extends State<_InfrastructureRequestsFilterSheet> {
  static const int _defaultInfrastructureRequestsWindowValue = 15;
  late final TextEditingController controller;
  late AdminRequestWindowUnit stagedUnit;
  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _surfaceColor => _colors.surface;
  Color get _accentColor => _colors.accent;
  Color get _titleTextColor => _colors.titleText;
  Color get _mutedTextColor => _colors.mutedText;
  Color get _borderColor => _colors.border;
  Color get _softSurface => _colors.softSurface;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value.toString());
    stagedUnit = widget.unit;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + keyboardInset),
        child: Material(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.t(
                              'dashboardInicio.mobileInfrastructureRequestsFilterTitle',
                              fallback: 'Filtrar requests do backend',
                            ),
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            context.t(
                              'dashboardInicio.mobileInfrastructureRequestsFilterSubtitle',
                              fallback:
                                  'Informe a janela que entra na contagem dos status 200, 400 e 500.',
                            ),
                            style: TextStyle(
                              color: _mutedTextColor,
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('common.close', fallback: 'Fechar'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: _titleTextColor),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  context.t(
                    'dashboardInicio.mobileInfrastructureRequestsFilterValueLabel',
                    fallback: 'Quantidade',
                  ),
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        _defaultInfrastructureRequestsWindowValue.toString(),
                    filled: true,
                    fillColor: _softSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  context.t(
                    'dashboardInicio.mobileInfrastructureRequestsFilterUnitLabel',
                    fallback: 'Unidade',
                  ),
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildInfrastructureUnitOption(
                        context,
                        label: context.t(
                          'dashboardInicio.mobileInfrastructureRequestsFilterMinutes',
                          fallback: 'Minutos',
                        ),
                        selected: stagedUnit == AdminRequestWindowUnit.minutes,
                        onTap: () {
                          setState(() {
                            stagedUnit = AdminRequestWindowUnit.minutes;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildInfrastructureUnitOption(
                        context,
                        label: context.t(
                          'dashboardInicio.mobileInfrastructureRequestsFilterHours',
                          fallback: 'Horas',
                        ),
                        selected: stagedUnit == AdminRequestWindowUnit.hours,
                        onTap: () {
                          setState(() {
                            stagedUnit = AdminRequestWindowUnit.hours;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          context.t('common.cancel', fallback: 'Cancelar'),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final int value = _sanitizeInfrastructureWindowValue(
                            int.tryParse(controller.text.trim()),
                            stagedUnit,
                          );
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop(
                            _InfrastructureRequestsFilterSelection(
                              value: value,
                              unit: stagedUnit,
                            ),
                          );
                        },
                        child: Text(
                          context.t(
                            'dashboardInicio.mobileInfrastructureRequestsFilterApply',
                            fallback: 'Aplicar janela',
                          ),
                        ),
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
  }

  Widget _buildInfrastructureUnitOption(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _accentColor : _softSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _accentColor : _borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _colors.onAccent : _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _sanitizeInfrastructureWindowValue(
    int? rawValue,
    AdminRequestWindowUnit unit,
  ) {
    final int value =
        rawValue == null || rawValue < 1
            ? _defaultInfrastructureRequestsWindowValue
            : rawValue;
    final int maxValue = unit == AdminRequestWindowUnit.hours ? 72 : 72 * 60;
    return value.clamp(1, maxValue);
  }
}
