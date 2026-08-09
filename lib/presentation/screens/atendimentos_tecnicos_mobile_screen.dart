import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as sharing;

import '../../core/config/app_config.dart';
import '../../core/services/pdf_file_share_service.dart';
import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/dominio_models.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/atendimento_tecnico/atendimento_pdf_share_service.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import '../components/mobile_motion.dart';
import 'atendimento_tecnico_editar_mobile_screen.dart';
import 'atendimento_tecnico_mobile_screen.dart';

class AtendimentosTecnicosMobileListContext {
  const AtendimentosTecnicosMobileListContext({
    required this.titleKey,
    required this.titleFallback,
    required this.heroTitleKey,
    required this.heroTitleFallback,
    required this.descriptionKey,
    required this.descriptionFallback,
    required this.emptyTitleKey,
    required this.emptyTitleFallback,
    required this.emptyMessageKey,
    required this.emptyMessageFallback,
    required this.errorTitleKey,
    required this.errorTitleFallback,
    required this.loadingLabelKey,
    required this.loadingLabelFallback,
    this.statusFilter,
    this.sectionTitleKey,
    this.sectionTitleFallback,
    this.filteredSectionTitleKey,
    this.filteredSectionTitleFallback,
  });

  const AtendimentosTecnicosMobileListContext.standard()
    : this(
        titleKey: 'atendimentoTecnico.mobile.listTitle',
        titleFallback: 'Atendimentos técnicos',
        heroTitleKey: 'atendimentoTecnico.mobile.dashboardTitle',
        heroTitleFallback: 'Dashboard técnico',
        descriptionKey: 'atendimentoTecnico.mobile.dashboardDescription',
        descriptionFallback: '',
        emptyTitleKey: 'atendimentoTecnico.mobile.emptyTitle',
        emptyTitleFallback: 'Nenhum atendimento encontrado',
        emptyMessageKey: 'atendimentoTecnico.mobile.emptyMessage',
        emptyMessageFallback:
            'Tente buscar por cliente, equipamento, status ou número.',
        errorTitleKey: 'atendimentoTecnico.mobile.errorTitle',
        errorTitleFallback: 'Não foi possível carregar os atendimentos',
        loadingLabelKey: 'atendimentoTecnico.mobile.loading',
        loadingLabelFallback: 'Carregando atendimentos técnicos',
        sectionTitleKey: 'atendimentoTecnico.mobile.recentSection',
        sectionTitleFallback: 'Atendimentos recentes',
        filteredSectionTitleKey: 'atendimentoTecnico.mobile.filteredSection',
        filteredSectionTitleFallback: 'Resultado do filtro',
      );

  const AtendimentosTecnicosMobileListContext.waitingCustomerApproval()
    : this(
        titleKey: 'atendimentoTecnico.mobile.waitingApprovalTitle',
        titleFallback: 'Orçamentos aguardando aprovação',
        heroTitleKey: 'atendimentoTecnico.mobile.waitingApprovalTitle',
        heroTitleFallback: 'Orçamentos aguardando aprovação',
        descriptionKey: 'atendimentoTecnico.mobile.waitingApprovalDescription',
        descriptionFallback:
            'Serviços enviados ao cliente que ainda precisam de aprovação.',
        emptyTitleKey: 'atendimentoTecnico.mobile.waitingApprovalEmptyTitle',
        emptyTitleFallback: 'Nenhum orçamento aguardando aprovação no momento.',
        emptyMessageKey:
            'atendimentoTecnico.mobile.waitingApprovalEmptyMessage',
        emptyMessageFallback:
            'Quando um orçamento for enviado e estiver aguardando a decisão do cliente, ele aparecerá aqui.',
        errorTitleKey: 'atendimentoTecnico.mobile.waitingApprovalErrorTitle',
        errorTitleFallback:
            'Não foi possível consultar os orçamentos. Tente novamente.',
        loadingLabelKey: 'atendimentoTecnico.mobile.waitingApprovalLoading',
        loadingLabelFallback: 'Carregando orçamentos aguardando aprovação',
        statusFilter: 'WAITING_CUSTOMER_APROVAL',
        sectionTitleKey: 'atendimentoTecnico.mobile.waitingApprovalSection',
        sectionTitleFallback: 'Orçamentos aguardando aprovação',
        filteredSectionTitleKey:
            'atendimentoTecnico.mobile.waitingApprovalFilteredSection',
        filteredSectionTitleFallback: 'Resultado do filtro',
      );

  final String titleKey;
  final String titleFallback;
  final String heroTitleKey;
  final String heroTitleFallback;
  final String descriptionKey;
  final String descriptionFallback;
  final String emptyTitleKey;
  final String emptyTitleFallback;
  final String emptyMessageKey;
  final String emptyMessageFallback;
  final String errorTitleKey;
  final String errorTitleFallback;
  final String loadingLabelKey;
  final String loadingLabelFallback;
  final String? statusFilter;
  final String? sectionTitleKey;
  final String? sectionTitleFallback;
  final String? filteredSectionTitleKey;
  final String? filteredSectionTitleFallback;
}

class AtendimentosTecnicosMobileScreen extends StatefulWidget {
  const AtendimentosTecnicosMobileScreen({
    super.key,
    this.service,
    this.pdfShareService,
    this.colaboradorApiClient,
    this.caixaApiClient,
    this.listContext = const AtendimentosTecnicosMobileListContext.standard(),
  });

  final AtendimentoTecnicoService? service;
  final AtendimentoPdfShareService? pdfShareService;
  final ColaboradorUsuarioApiClient? colaboradorApiClient;
  final CaixaApiClient? caixaApiClient;
  final AtendimentosTecnicosMobileListContext listContext;

  @override
  State<AtendimentosTecnicosMobileScreen> createState() =>
      _AtendimentosTecnicosMobileScreenState();
}

class _AtendimentosTecnicosMobileScreenState
    extends State<AtendimentosTecnicosMobileScreen> {
  static const String _semTecnicoKey = '__sem_tecnico__';

  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _highlightedBorderColor =>
      SixMobilePalette.highlightedBorder;
  static Color get _onPrimaryColor => SixMobilePalette.onPrimary;
  static Color get _onAccentColor => SixMobilePalette.onAccent;
  static Color get _heroSupportingTextColor =>
      SixMobilePalette.heroSupportingText;
  static Color get _heroShadowColor => SixMobilePalette.heroShadow;
  static Color get _cardShadowColor => SixMobilePalette.navigationShadow;

  late final AtendimentoTecnicoService _service;
  late final AtendimentoPdfShareService _pdfShareService;
  late final ColaboradorUsuarioApiClient _colaboradorApiClient;
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final TextEditingController _searchController = TextEditingController();

  late Future<_AtendimentosTecnicosMobileState> _future;
  Timer? _salvarBuscaDebounce;
  String? _statusSelecionadoKey;
  DateTime? _dataInicioFiltro;
  DateTime? _dataFimFiltro;
  String? _tecnicoFiltroKey;
  AtendimentosCriadosStatusPagamentoFiltro _statusPagamentoFiltro =
      AtendimentosCriadosStatusPagamentoFiltro.todos;
  bool _processandoAcao = false;
  bool _gerandoLinkStatus = false;
  bool _aplicandoPreferencias = false;
  bool _usuarioAlterouFiltros = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AtendimentoTecnicoService();
    _pdfShareService =
        widget.pdfShareService ??
        AtendimentoPdfShareService(atendimentoService: _service);
    _colaboradorApiClient =
        widget.colaboradorApiClient ?? HttpColaboradorUsuarioApiClient();
    _future = _carregar();
    _searchController.addListener(_onSearchChanged);
    if (_permitePreferenciasAtendimentosCriados) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _restaurarPreferenciasAtendimentosCriadosMobile();
        await _restaurarPreferenciasAtendimentosCriadosMobileBackend();
      });
    }
  }

  @override
  void dispose() {
    _salvarBuscaDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<_AtendimentosTecnicosMobileState> _carregar() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      _service.buscarDominiosBase(),
      _service.listar(status: widget.listContext.statusFilter),
      _colaboradorApiClient.listarTecnicosAssistenciaTecnica(),
    ]);
    return _AtendimentosTecnicosMobileState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      atendimentos: results[1] as List<AtendimentoTecnicoModel>,
      tecnicos: results[2] as List<ColaboradorUsuarioResumo>,
    );
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _carregar();
    });
    await _future;
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    if (!_aplicandoPreferencias && _permitePreferenciasAtendimentosCriados) {
      _usuarioAlterouFiltros = true;
      _agendarSalvarPreferenciasAtendimentosCriadosMobile();
    }
  }

  Future<void> _restaurarPreferenciasAtendimentosCriadosMobile() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
      return;
    }
    _aplicarPreferenciasAtendimentosCriadosMobile(
      preferencias.atendimentosCriadosFiltrosMobile,
    );
  }

  Future<void> _restaurarPreferenciasAtendimentosCriadosMobileBackend() async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
        return;
      }
      _aplicarPreferenciasAtendimentosCriadosMobile(
        preferencias.atendimentosCriadosFiltrosMobile,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar preferencias mobile dos atendimentos criados: '
        '$error\n$stackTrace',
      );
    }
  }

  void _aplicarPreferenciasAtendimentosCriadosMobile(
    AtendimentosCriadosFiltrosMobilePreferencia filtros,
  ) {
    if (!_permitePreferenciasAtendimentosCriados) {
      return;
    }
    _aplicandoPreferencias = true;
    if (_searchController.text != filtros.busca) {
      _searchController.text = filtros.busca;
    }
    setState(() {
      _dataInicioFiltro = filtros.dataInicio;
      _dataFimFiltro = filtros.dataFim;
      _tecnicoFiltroKey = filtros.tecnicoKey;
      _statusSelecionadoKey = filtros.statusKey;
      _statusPagamentoFiltro = filtros.statusPagamento;
    });
    _aplicandoPreferencias = false;
  }

  void _agendarSalvarPreferenciasAtendimentosCriadosMobile() {
    _salvarBuscaDebounce?.cancel();
    _salvarBuscaDebounce = Timer(
      const Duration(milliseconds: 450),
      _salvarPreferenciasAtendimentosCriadosMobile,
    );
  }

  void _salvarPreferenciasAtendimentosCriadosMobile() {
    _salvarBuscaDebounce?.cancel();
    if (!_permitePreferenciasAtendimentosCriados) {
      return;
    }
    final filtros = AtendimentosCriadosFiltrosMobilePreferencia(
      busca: _searchController.text,
      dataInicio: _dataInicioFiltro,
      dataFim: _dataFimFiltro,
      tecnicoKey: _tecnicoFiltroKey,
      statusKey: _statusSelecionadoKey,
      statusPagamento: _statusPagamentoFiltro,
    );

    unawaited(
      _usuarioService
          .atualizarPreferenciasIndividuais(
            atendimentosCriadosFiltrosMobile: filtros.toJson(),
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao salvar preferencias mobile dos atendimentos criados: '
              '$error\n$stackTrace',
            );
          }),
    );
  }

  bool get _permitePreferenciasAtendimentosCriados =>
      widget.listContext.statusFilter == null;

  bool get _statusPagamentoFiltroAtivo =>
      _permitePreferenciasAtendimentosCriados &&
      _statusPagamentoFiltro != AtendimentosCriadosStatusPagamentoFiltro.todos;

  bool get _hasAdvancedFilters =>
      _dataInicioFiltro != null ||
      _dataFimFiltro != null ||
      _tecnicoFiltroKey != null ||
      _statusPagamentoFiltroAtivo;

  bool get _hasAnyFilter =>
      _hasAdvancedFilters ||
      _statusSelecionadoKey != null ||
      _searchController.text.trim().isNotEmpty;

  void _limparFiltros() {
    _aplicandoPreferencias = true;
    setState(() {
      _statusSelecionadoKey = null;
      _dataInicioFiltro = null;
      _dataFimFiltro = null;
      _tecnicoFiltroKey = null;
      _statusPagamentoFiltro = AtendimentosCriadosStatusPagamentoFiltro.todos;
      _searchController.clear();
    });
    _aplicandoPreferencias = false;
    _usuarioAlterouFiltros = true;
    _salvarPreferenciasAtendimentosCriadosMobile();
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}',
    );

    return SixMobilePageShell(
      title: _t(widget.listContext.titleKey, widget.listContext.titleFallback),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _t('common.back', 'Voltar'),
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _t('atendimentoTecnico.mobile.newFab', 'Novo atendimento'),
          icon: Icon(Icons.add_rounded),
          onPressed: _novoAtendimento,
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: _buildBody(scrollController, topInset),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, double topInset) {
    return FutureBuilder<_AtendimentosTecnicosMobileState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loadingState(scrollController, topInset);
        }

        if (snapshot.hasError) {
          return _errorState(
            snapshot.error.toString(),
            scrollController,
            topInset,
          );
        }

        final _AtendimentosTecnicosMobileState state = snapshot.data!;
        final List<AtendimentoTecnicoModel> atendimentos = state.atendimentos;
        final List<DominioOpcaoModel> statusDisponiveis =
            state.dominios.statusAtendimentoTecnico;
        final List<AtendimentoTecnicoModel> filtrados = _filtrar(
          atendimentos,
          statusDisponiveis,
        );

        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView(
            controller: scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
            children: <Widget>[
              SixStaggeredEntry(
                delay: Duration(milliseconds: 60),
                child: _hero(filtrados, totalGeral: atendimentos.length),
              ),
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 120),
                child: _summaryGrid(filtrados),
              ),
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 180),
                child: _statusOverview(atendimentos, statusDisponiveis),
              ),
              SizedBox(height: 14),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 220),
                child: _statusFilter(atendimentos, statusDisponiveis),
              ),
              SizedBox(height: 14),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 260),
                child: _advancedFilters(atendimentos, state.tecnicos),
              ),
              SizedBox(height: 14),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 300),
                child: _searchBox(),
              ),
              SizedBox(height: 16),
              _sectionTitle(
                !_hasAnyFilter
                    ? _t(
                      widget.listContext.sectionTitleKey ??
                          'atendimentoTecnico.mobile.recentSection',
                      widget.listContext.sectionTitleFallback ??
                          'Atendimentos recentes',
                    )
                    : _t(
                      widget.listContext.filteredSectionTitleKey ??
                          'atendimentoTecnico.mobile.filteredSection',
                      widget.listContext.filteredSectionTitleFallback ??
                          'Resultado do filtro',
                    ),
              ),
              SizedBox(height: 12),
              if (filtrados.isEmpty)
                _emptyState()
              else
                ...filtrados
                    .take(20)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SixStaggeredEntry(
                          delay: Duration(milliseconds: 340 + entry.key * 45),
                          child: _atendimentoCard(
                            entry.value,
                            statusDisponiveis,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _loadingState(ScrollController scrollController, double topInset) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _t(
        widget.listContext.loadingLabelKey,
        widget.listContext.loadingLabelFallback,
      ),
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
        children: <Widget>[
          _loadingHeroSkeleton(),
          SizedBox(height: 16),
          _loadingSummaryGrid(),
          SizedBox(height: 16),
          _loadingStatusOverviewSkeleton(),
          SizedBox(height: 14),
          _loadingFilterSkeleton(),
          SizedBox(height: 14),
          _loadingSearchSkeleton(),
          SizedBox(height: 16),
          const _AtendimentoSkeletonBlock(width: 168, height: 18, radius: 8),
          SizedBox(height: 12),
          const _AtendimentoCardSkeleton(),
          SizedBox(height: 12),
          const _AtendimentoCardSkeleton(),
          SizedBox(height: 12),
          const _AtendimentoCardSkeleton(),
        ],
      ),
    );
  }

  Widget _loadingHeroSkeleton() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _iconBox(Icons.fact_check_outlined, size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _AtendimentoSkeletonBlock(height: 18, radius: 8),
                SizedBox(height: 9),
                _AtendimentoSkeletonBlock(height: 12, radius: 7),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: _AtendimentoSkeletonBlock(height: 12, radius: 7),
                ),
                SizedBox(height: 13),
                _AtendimentoSkeletonBlock(width: 126, height: 28, radius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingSummaryGrid() {
    final List<IconData> icons = <IconData>[
      Icons.assignment_turned_in_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.verified_rounded,
      Icons.payments_outlined,
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: icons
              .map(
                (IconData icon) => SizedBox(
                  width: width,
                  child: _loadingSummaryCardSkeleton(icon),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _loadingSummaryCardSkeleton(IconData icon) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _iconBox(icon, size: 38),
          SizedBox(height: 12),
          const _AtendimentoSkeletonBlock(width: 88, height: 12, radius: 7),
          SizedBox(height: 8),
          const _AtendimentoSkeletonBlock(width: 58, height: 22, radius: 8),
          SizedBox(height: 7),
          const _AtendimentoSkeletonBlock(height: 11, radius: 7),
        ],
      ),
    );
  }

  Widget _loadingStatusOverviewSkeleton() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(Icons.flag_outlined, size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _AtendimentoSkeletonBlock(height: 16, radius: 8),
                    SizedBox(height: 7),
                    FractionallySizedBox(
                      widthFactor: 0.76,
                      child: _AtendimentoSkeletonBlock(height: 12, radius: 7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          const _StatusOverviewSkeletonRow(),
          SizedBox(height: 10),
          const _StatusOverviewSkeletonRow(),
          SizedBox(height: 10),
          const _StatusOverviewSkeletonRow(),
        ],
      ),
    );
  }

  Widget _loadingFilterSkeleton() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AtendimentoSkeletonBlock(width: 132, height: 16, radius: 8),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _AtendimentoSkeletonBlock(width: 74, height: 38, radius: 999),
              _AtendimentoSkeletonBlock(width: 92, height: 38, radius: 999),
              _AtendimentoSkeletonBlock(width: 108, height: 38, radius: 999),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingSearchSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, color: _accentColor, size: 22),
          SizedBox(width: 10),
          Expanded(child: _AtendimentoSkeletonBlock(height: 14, radius: 8)),
        ],
      ),
    );
  }

  Widget _errorState(
    String message,
    ScrollController scrollController,
    double topInset,
  ) {
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
        children: <Widget>[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _iconBox(Icons.cloud_off_rounded),
                SizedBox(height: 14),
                Text(
                  _t(
                    widget.listContext.errorTitleKey,
                    widget.listContext.errorTitleFallback,
                  ),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _mutedTextColor, height: 1.3),
                ),
                SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _recarregar,
                  icon: Icon(Icons.refresh_rounded),
                  label: Text(_t('common.tryAgain', 'Tentar novamente')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(
    List<AtendimentoTecnicoModel> atendimentos, {
    required int totalGeral,
  }) {
    final int pendentes = _totalPendentes(atendimentos);
    final bool filtrando =
        _statusSelecionadoKey != null ||
        _searchController.text.trim().isNotEmpty;
    final bool hasContextDescription =
        widget.listContext.descriptionFallback.trim().isNotEmpty;
    final String contextDescription =
        hasContextDescription
            ? _t(
              widget.listContext.descriptionKey,
              widget.listContext.descriptionFallback,
            ).trim()
            : '';
    final String description =
        contextDescription.isNotEmpty
            ? contextDescription
            : filtrando
            ? '${atendimentos.length} de $totalGeral atendimento(s) no filtro.'
            : pendentes == 1
            ? '1 atendimento ainda precisa de atenção.'
            : '$pendentes atendimentos ainda precisam de atenção.';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _heroShadowColor,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _iconBox(
            Icons.fact_check_outlined,
            backgroundColor: Color(0x1AFFFFFF),
            foregroundColor: _onPrimaryColor,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _t(
                    widget.listContext.heroTitleKey,
                    widget.listContext.heroTitleFallback,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _onPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _heroSupportingTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(List<AtendimentoTecnicoModel> atendimentos) {
    final List<_SummaryItem> items = <_SummaryItem>[
      _SummaryItem(
        label: 'Atendimentos',
        value: atendimentos.length.toString(),
        helper: 'Total exibido',
        icon: Icons.assignment_turned_in_outlined,
      ),
      _SummaryItem(
        label: 'Em aberto',
        value: _totalEmAberto(atendimentos).toString(),
        helper: 'Aguardam recebimento',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryItem(
        label: 'Assinados',
        value: _totalAssinados(atendimentos).toString(),
        helper: 'Com aceite do cliente',
        icon: Icons.verified_rounded,
      ),
      _SummaryItem(
        label: 'Valor aberto',
        value: _formatarMoeda(_valorAberto(atendimentos)),
        helper: 'Saldo pendente',
        icon: Icons.payments_outlined,
        highlight: true,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(width: width, child: _summaryCard(item)))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    final Color background = item.highlight ? _primaryColor : _surfaceColor;
    final Color foreground = item.highlight ? _onPrimaryColor : _titleTextColor;
    final Color muted =
        item.highlight ? _heroSupportingTextColor : _mutedTextColor;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.highlight ? _primaryColor : _borderColor,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  item.highlight ? Color(0x1AFFFFFF) : _softAccentSurfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.highlight ? _onPrimaryColor : _accentColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          _animatedValue(item.value, foreground),
          SizedBox(height: 2),
          Text(
            item.helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _animatedValue(String value, Color color) {
    final TextStyle style = TextStyle(
      color: color,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    );
    return int.tryParse(value) == null
        ? Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        )
        : SixAnimatedNumberText(value: value, style: style);
  }

  Widget _statusOverview(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final List<_StatusCount> status =
        _statusCounts(atendimentos, statusDisponiveis).take(4).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(Icons.flag_outlined, size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Visão por status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Acompanhe onde estão os atendimentos.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (status.isEmpty)
            Text(
              'Nenhum status para exibir.',
              style: TextStyle(color: _mutedTextColor),
            )
          else
            ...status.map(_statusRow),
        ],
      ),
    );
  }

  Widget _statusRow(_StatusCount item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _softAccentSurfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _highlightedBorderColor),
            ),
            child: Text(
              item.count.toString(),
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilter(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final List<_StatusCount> statuses = _statusCounts(
      atendimentos,
      statusDisponiveis,
    );
    final int total = atendimentos.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Filtrar por status',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _statusChip(
                  label: 'Todos',
                  count: total,
                  selected: _statusSelecionadoKey == null,
                  onSelected: () {
                    setState(() => _statusSelecionadoKey = null);
                    _usuarioAlterouFiltros = true;
                    _salvarPreferenciasAtendimentosCriadosMobile();
                  },
                ),
                SizedBox(width: 8),
                ...statuses.map(
                  (status) => Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _statusChip(
                      label: status.label,
                      count: status.count,
                      selected: _statusSelecionadoKey == status.key,
                      onSelected: () {
                        setState(() {
                          _statusSelecionadoKey = status.key;
                        });
                        _usuarioAlterouFiltros = true;
                        _salvarPreferenciasAtendimentosCriadosMobile();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text('$label · $count'),
      onSelected: (_) => onSelected(),
      selectedColor: _accentColor,
      backgroundColor: _softSurfaceColor,
      side: BorderSide(color: selected ? _accentColor : _borderColor),
      labelStyle: TextStyle(
        color: selected ? _onAccentColor : _titleTextColor,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _advancedFilters(
    List<AtendimentoTecnicoModel> atendimentos,
    List<ColaboradorUsuarioResumo> tecnicosDisponiveis,
  ) {
    final List<_TecnicoFiltroOption> tecnicos = _tecnicoOptions(
      atendimentos,
      tecnicosDisponiveis,
    );
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Filtros do atendimento',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_hasAnyFilter)
                TextButton.icon(
                  onPressed: _limparFiltros,
                  icon: Icon(Icons.filter_alt_off_rounded, size: 17),
                  label: Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: _accentColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          _filterField(
            label: 'Data',
            value: _periodoFiltroLabel(),
            icon: Icons.event_outlined,
            active: _dataInicioFiltro != null || _dataFimFiltro != null,
            onTap: _abrirFiltroPeriodo,
          ),
          SizedBox(height: 10),
          _filterField(
            label: 'Técnico responsável',
            value: _tecnicoFiltroLabel(tecnicos),
            icon: Icons.engineering_outlined,
            active: _tecnicoFiltroKey != null,
            onTap: () => _abrirFiltroTecnico(tecnicos),
          ),
          if (_permitePreferenciasAtendimentosCriados) ...<Widget>[
            SizedBox(height: 10),
            _filterField(
              label: _t(
                'atendimentoTecnico.filters.paymentStatus.label',
                'Status pagamento',
              ),
              value: _statusPagamentoFiltroLabel(_statusPagamentoFiltro),
              icon: Icons.account_balance_wallet_outlined,
              active:
                  _statusPagamentoFiltro !=
                  AtendimentosCriadosStatusPagamentoFiltro.todos,
              onTap: _abrirFiltroStatusPagamento,
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterField({
    required String label,
    required String value,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: active ? _softAccentSurfaceColor : _softSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? _highlightedBorderColor : _borderColor,
            ),
          ),
          child: Row(
            children: <Widget>[
              _iconBox(
                icon,
                size: 38,
                backgroundColor:
                    active ? _softAccentSurfaceColor : _softSurfaceColor,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded, color: _accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFiltroPeriodo() async {
    final _PeriodoFiltro? result = await showModalBottomSheet<_PeriodoFiltro>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext context) {
        return _PeriodoFiltroMobileSheet(
          dataInicio: _dataInicioFiltro,
          dataFim: _dataFimFiltro,
          formatarData: _formatarData,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _dataInicioFiltro = result.dataInicio;
      _dataFimFiltro = result.dataFim;
    });
    _usuarioAlterouFiltros = true;
    _salvarPreferenciasAtendimentosCriadosMobile();
  }

  Future<void> _abrirFiltroTecnico(List<_TecnicoFiltroOption> tecnicos) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext context) {
        return _TecnicoFiltroMobileSheet(
          tecnicos: tecnicos,
          selectedKey: _tecnicoFiltroKey,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _tecnicoFiltroKey =
          result == _TecnicoFiltroMobileSheet.todosKey ? null : result;
    });
    _usuarioAlterouFiltros = true;
    _salvarPreferenciasAtendimentosCriadosMobile();
  }

  Future<void> _abrirFiltroStatusPagamento() async {
    final AtendimentosCriadosStatusPagamentoFiltro? result =
        await showModalBottomSheet<AtendimentosCriadosStatusPagamentoFiltro>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Color(0x66000000),
          builder: (BuildContext context) {
            return _StatusPagamentoFiltroMobileSheet(
              selected: _statusPagamentoFiltro,
              labelFor: _statusPagamentoFiltroLabel,
            );
          },
        );
    if (result == null || !mounted) return;
    setState(() => _statusPagamentoFiltro = result);
    _usuarioAlterouFiltros = true;
    _salvarPreferenciasAtendimentosCriadosMobile();
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente, status, equipamento ou número',
        prefixIcon: Icon(Icons.search_rounded, color: _accentColor),
        suffixIcon:
            _searchController.text.trim().isEmpty
                ? null
                : IconButton(
                  onPressed: _searchController.clear,
                  icon: Icon(Icons.clear_rounded),
                ),
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _accentColor, width: 1.4),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _atendimentoCard(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final String cliente = _clienteLabel(atendimento);
    final String status = _statusLabel(atendimento, statusDisponiveis);
    final String equipamento = _equipamentoTitulo(atendimento);
    final bool pagamentoAberto = _pagamentoEmAberto(atendimento);
    final bool entregaAtrasada = _entregaAtrasada(atendimento);

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirDetalhesAtendimento(atendimento, statusDisponiveis),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _cardShadowColor,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    equipamento,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${atendimento.numero} • $cliente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: <Widget>[
                      _chip(status, Icons.flag_outlined),
                      _chip(
                        pagamentoAberto
                            ? 'Financeiro aberto'
                            : 'Financeiro liquidado',
                        pagamentoAberto
                            ? Icons.account_balance_wallet_outlined
                            : Icons.price_check_rounded,
                      ),
                      if (entregaAtrasada)
                        _alertChip(
                          'Entrega atrasada',
                          Icons.warning_amber_rounded,
                        ),
                      if (atendimento.assinaturaAprovada)
                        _chip('Assinado', Icons.verified_rounded),
                    ],
                  ),
                ],
              );
              final Widget detailsButton = _cardDetailsButton(
                atendimento,
                statusDisponiveis,
              );

              if (constraints.maxWidth < 290) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _iconBox(Icons.devices_other_outlined, size: 44),
                        Spacer(),
                        detailsButton,
                      ],
                    ),
                    SizedBox(height: 12),
                    content,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _iconBox(Icons.devices_other_outlined, size: 44),
                  SizedBox(width: 12),
                  Expanded(child: content),
                  SizedBox(width: 10),
                  detailsButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cardDetailsButton(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    return Semantics(
      button: true,
      label: _t(
        'atendimentoTecnico.mobile.showDetails',
        'Ver detalhes do atendimento',
      ),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: SixMobilePalette.softAccentSurface,
          foregroundColor: _accentColor,
          fixedSize: Size(40, 40),
          minimumSize: Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: _t(
          'atendimentoTecnico.mobile.showDetails',
          'Ver detalhes do atendimento',
        ),
        onPressed:
            () => _abrirDetalhesAtendimento(atendimento, statusDisponiveis),
        icon: Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  Future<void> _abrirDetalhesAtendimento(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> statusDisponiveis,
  ) async {
    final Future<AtendimentoTecnicoModel> detalhesFuture = _service.buscarPorId(
      atendimento.id,
    );
    bool gerandoPdf = false;
    bool sheetAberto = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.54,
          maxChildSize: 0.96,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return StatefulBuilder(
              builder: (BuildContext detailContext, StateSetter setSheetState) {
                return FutureBuilder<AtendimentoTecnicoModel>(
                  future: detalhesFuture,
                  builder: (BuildContext context, snapshot) {
                    final AtendimentoTecnicoModel detalhes =
                        snapshot.data ?? atendimento;
                    final bool carregando =
                        snapshot.connectionState != ConnectionState.done &&
                        !snapshot.hasData;
                    final bool falhou = snapshot.hasError && !snapshot.hasData;
                    return _atendimentoDetalhesSheet(
                      sheetContext: sheetContext,
                      scrollController: scrollController,
                      atendimento: detalhes,
                      statusDisponiveis: statusDisponiveis,
                      carregandoDetalhes: carregando,
                      erroDetalhes: falhou,
                      gerandoPdf: gerandoPdf,
                      onCompartilharPdf:
                          falhou
                              ? null
                              : (BuildContext originContext) async {
                                if (gerandoPdf) return;
                                setSheetState(() => gerandoPdf = true);
                                try {
                                  await _compartilharPdfAtendimento(
                                    detalhes,
                                    originContext: originContext,
                                  );
                                } finally {
                                  if (mounted && sheetAberto) {
                                    setSheetState(() => gerandoPdf = false);
                                  }
                                }
                              },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
    sheetAberto = false;
  }

  Widget _atendimentoDetalhesSheet({
    required BuildContext sheetContext,
    required ScrollController scrollController,
    required AtendimentoTecnicoModel atendimento,
    required List<DominioOpcaoModel> statusDisponiveis,
    required bool carregandoDetalhes,
    required bool erroDetalhes,
    required bool gerandoPdf,
    required Future<void> Function(BuildContext originContext)?
    onCompartilharPdf,
  }) {
    final String equipamento = _equipamentoTitulo(atendimento);
    final String cliente = _clienteLabel(atendimento);
    final String status = _statusLabel(atendimento, statusDisponiveis);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(sheetContext) ||
        MediaQuery.accessibleNavigationOf(sheetContext);
    final double valorJaRecebido = _valorRecebidoAtendimento(atendimento);
    final bool acaoEmProcessamento = _processandoAcao || gerandoPdf;
    final bool podeReceber =
        !atendimento.operacaoLiquidada &&
        atendimento.valorEmAberto > 0 &&
        !acaoEmProcessamento;
    final bool podeAlterarStatus =
        statusDisponiveis.isNotEmpty && !acaoEmProcessamento;

    final Widget content = ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: <Widget>[
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: _borderColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        SizedBox(height: 14),
        SixStaggeredEntry(
          delay: Duration(milliseconds: 40),
          child: _detailHeaderCard(
            sheetContext: sheetContext,
            atendimento: atendimento,
            equipamento: equipamento,
            cliente: cliente,
            gerandoPdf: gerandoPdf,
            habilitarCompartilhamentoPdf: !carregandoDetalhes && !erroDetalhes,
            onCompartilharPdf: onCompartilharPdf,
          ),
        ),
        if (carregandoDetalhes) ...<Widget>[
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: _softSurfaceColor,
              color: _accentColor,
            ),
          ),
        ],
        if (erroDetalhes) ...<Widget>[
          SizedBox(height: 12),
          _detailInlineWarning(
            _t(
              'atendimentoTecnico.mobile.detailLoadError',
              'Não foi possível carregar os dados atualizados do atendimento.',
            ),
          ),
        ],
        SizedBox(height: 14),
        SixStaggeredEntry(
          delay: Duration(milliseconds: 80),
          child: _publicStatusCard(status: status),
        ),
        SizedBox(height: 16),
        SixStaggeredEntry(
          delay: Duration(milliseconds: 120),
          child: _detailActions(
            sheetContext: sheetContext,
            atendimento: atendimento,
            statusDisponiveis: statusDisponiveis,
            podeReceber: podeReceber,
            podeAlterarStatus: podeAlterarStatus,
            acaoEmProcessamento: acaoEmProcessamento,
          ),
        ),
        SizedBox(height: 18),
        SixStaggeredEntry(
          delay: Duration(milliseconds: 160),
          child: _detailFinancialSummary(
            atendimento,
            valorJaRecebido: valorJaRecebido,
            reduceMotion: reduceMotion,
          ),
        ),
        SizedBox(height: 14),
        _detailSection(
          title: 'Resumo da ordem de serviço',
          icon: Icons.assignment_outlined,
          children: <Widget>[
            _detailLine('Cliente', cliente),
            _detailLine('Técnico', _tecnicoLabelAtendimento(atendimento)),
            _detailLine(
              'Versão do orçamento',
              'v${atendimento.versaoOrcamento}',
            ),
            _detailLine(
              'Atualização',
              _formatarDataHora(atendimento.dataAtualizacao),
            ),
            _detailLine(
              'Entrega prevista',
              _formatarData(atendimento.dataEntregaPrevista),
            ),
            _detailLine(
              'Validade do orçamento',
              _formatarData(atendimento.validadeOrcamentoEm),
            ),
            _detailLine(
              'Vencimento',
              _formatarData(atendimento.dataVencimentoEm),
            ),
            if (atendimento.assinaturaAprovada)
              _detailLine('Assinatura', _assinaturaResumo(atendimento)),
            if (atendimento.requerNovaAssinatura)
              _detailLine(
                'Assinatura',
                'Pendente para a versão atual do orçamento',
              ),
          ],
        ),
        SizedBox(height: 14),
        _detailSection(
          title: 'Equipamento e diagnóstico',
          icon: Icons.devices_other_outlined,
          children: <Widget>[
            _detailLine('Tipo', atendimento.equipamento?.tipo),
            _detailLine('Marca', atendimento.equipamento?.marca),
            _detailLine('Modelo', atendimento.equipamento?.modelo),
            _detailLine(
              'Número de série',
              atendimento.equipamento?.numeroSerie,
            ),
            _detailLine('IMEI', atendimento.equipamento?.imei),
            _detailLine('Acessórios', atendimento.equipamento?.acessorios),
            _detailLine(
              'Observações de entrada',
              atendimento.equipamento?.observacoesEntrada,
            ),
            _detailLine('Defeito relatado', atendimento.defeitoRelatado),
            _detailLine('Diagnóstico técnico', atendimento.diagnosticoTecnico),
          ],
        ),
        SizedBox(height: 14),
        _itemsSection(atendimento),
        SizedBox(height: 14),
        _recebimentosSection(atendimento),
        SizedBox(height: 14),
        _historicoStatusSection(atendimento, statusDisponiveis),
        SizedBox(height: 14),
        _auditoriaSection(atendimento),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Stack(
          children: <Widget>[
            content,
            if (gerandoPdf) Positioned.fill(child: _pdfLoadingOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _detailActions({
    required BuildContext sheetContext,
    required AtendimentoTecnicoModel atendimento,
    required List<DominioOpcaoModel> statusDisponiveis,
    required bool podeReceber,
    required bool podeAlterarStatus,
    required bool acaoEmProcessamento,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double itemWidth =
            compact ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _t('atendimento.mobile.receiveTitle', 'Receber'),
                icon: Icons.payments_outlined,
                filled: true,
                onPressed:
                    podeReceber
                        ? () => _runAfterClosingSheet(
                          sheetContext,
                          () => _abrirRecebimento(atendimento),
                        )
                        : null,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _t('common.edit', 'Editar'),
                icon: Icons.edit_note_rounded,
                onPressed:
                    acaoEmProcessamento
                        ? null
                        : () => _runAfterClosingSheet(
                          sheetContext,
                          () => _editarAtendimento(atendimento),
                        ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label:
                    _gerandoLinkStatus
                        ? _t('common.generating', 'Gerando...')
                        : _t(
                          'atendimentoTecnico.publicStatus.action',
                          'Status público',
                        ),
                icon: Icons.ios_share_rounded,
                onPressed:
                    acaoEmProcessamento || _gerandoLinkStatus
                        ? null
                        : () => _runAfterClosingSheet(
                          sheetContext,
                          () => _compartilharStatusPublico(atendimento),
                        ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _t(
                  'atendimentoTecnico.mobile.changeStatusAction',
                  'Mudar status',
                ),
                icon: Icons.swap_horiz_rounded,
                onPressed:
                    podeAlterarStatus
                        ? () => _runAfterClosingSheet(
                          sheetContext,
                          () => _abrirAlterarStatus(
                            atendimento,
                            statusDisponiveis,
                          ),
                        )
                        : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailHeaderCard({
    required BuildContext sheetContext,
    required AtendimentoTecnicoModel atendimento,
    required String equipamento,
    required String cliente,
    required bool gerandoPdf,
    required bool habilitarCompartilhamentoPdf,
    required Future<void> Function(BuildContext originContext)?
    onCompartilharPdf,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(Icons.devices_other_outlined, size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      equipamento,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '${atendimento.numero} • $cliente',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _sharePdfHeaderButton(
                gerando: gerandoPdf,
                habilitado: habilitarCompartilhamentoPdf,
                onPressed: onCompartilharPdf,
              ),
              IconButton(
                tooltip: _t('common.close', 'Fechar'),
                style: IconButton.styleFrom(
                  fixedSize: Size(46, 46),
                  minimumSize: Size(46, 46),
                  foregroundColor: _titleTextColor,
                  backgroundColor: _softSurfaceColor,
                ),
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: Icon(Icons.close_rounded, size: 21),
              ),
            ],
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pagamentoEmAberto(atendimento)
                  ? _chip(
                    _t(
                      'atendimentoTecnico.mobile.paymentOpen',
                      'Financeiro aberto',
                    ),
                    Icons.account_balance_wallet_outlined,
                  )
                  : _chip(
                    _t(
                      'atendimentoTecnico.mobile.paymentSettled',
                      'Financeiro liquidado',
                    ),
                    Icons.price_check_rounded,
                  ),
              if (atendimento.assinaturaAprovada)
                _chip(
                  _t('atendimentoTecnico.mobile.signed', 'Assinado'),
                  Icons.verified_rounded,
                ),
              if (atendimento.requerNovaAssinatura)
                _alertChip(
                  _t(
                    'atendimentoTecnico.mobile.signaturePending',
                    'Assinatura pendente',
                  ),
                  Icons.draw_outlined,
                ),
              if (_entregaAtrasada(atendimento))
                _alertChip(
                  _t(
                    'atendimentoTecnico.mobile.deliveryLate',
                    'Entrega atrasada',
                  ),
                  Icons.warning_amber_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _publicStatusCard({required String status}) {
    final String title = _t(
      'atendimentoTecnico.publicStatus.action',
      'Status público',
    );
    final String description = _t(
      'atendimentoTecnico.mobile.publicStatusDescription',
      'Visível para o cliente no link de acompanhamento.',
    );

    return Semantics(
      container: true,
      label: '$title: $status',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _softAccentSurfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _highlightedBorderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _iconBox(
              Icons.public_rounded,
              size: 40,
              backgroundColor: _accentColor.withValues(alpha: 0.14),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailFinancialSummary(
    AtendimentoTecnicoModel atendimento, {
    required double valorJaRecebido,
    required bool reduceMotion,
  }) {
    return _detailSection(
      title: _t('gestao.finance.summaryTitle', 'Resumo financeiro'),
      icon: Icons.payments_outlined,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool singleColumn = constraints.maxWidth < 300;
            final double itemWidth =
                singleColumn
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: itemWidth,
                  child: _detailMetricCard(
                    label: _t(
                      'atendimentoTecnico.mobile.valorOriginal',
                      'Valor original',
                    ),
                    value: atendimento.valorTotalAtendimento,
                    icon: Icons.request_quote_outlined,
                    reduceMotion: reduceMotion,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _detailMetricCard(
                    label: _t(
                      'atendimentoTecnico.mobile.valorJaRecebido',
                      'Valor já recebido',
                    ),
                    value: valorJaRecebido,
                    icon: Icons.price_check_rounded,
                    reduceMotion: reduceMotion,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _detailMetricCard(
                    label: _t(
                      'atendimentoTecnico.mobile.valorEmAberto',
                      'Valor em aberto',
                    ),
                    value: atendimento.valorEmAberto,
                    icon: Icons.account_balance_wallet_outlined,
                    reduceMotion: reduceMotion,
                    highlighted: atendimento.valorEmAberto > 0,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _detailStatusMetricCard(
                    label: _t(
                      'atendimentoTecnico.mobile.liquidation',
                      'Liquidação',
                    ),
                    value:
                        atendimento.operacaoLiquidada
                            ? _t(
                              'atendimentoTecnico.mobile.liquidated',
                              'Liquidada',
                            )
                            : _t(
                              'atendimentoTecnico.mobile.notLiquidated',
                              'Não liquidada',
                            ),
                    icon:
                        atendimento.operacaoLiquidada
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 12),
        _detailMoneyLine(
          _t('atendimentoTecnico.mobile.products', 'Produtos'),
          atendimento.valorTotalProdutos,
          reduceMotion: reduceMotion,
        ),
        _detailMoneyLine(
          _t('atendimentoTecnico.mobile.services', 'Serviços'),
          atendimento.valorTotalServicos,
          reduceMotion: reduceMotion,
        ),
      ],
    );
  }

  Widget _detailMetricCard({
    required String label,
    required double value,
    required IconData icon,
    required bool reduceMotion,
    bool highlighted = false,
  }) {
    final Color borderColor =
        highlighted ? _highlightedBorderColor : _borderColor;
    final Color valueColor = highlighted ? _accentColor : _titleTextColor;
    final Widget valueText =
        reduceMotion
            ? _detailMetricMoneyText(value, valueColor)
            : TweenAnimationBuilder<double>(
              key: ValueKey<String>('detail_metric_${label}_$value'),
              tween: Tween<double>(begin: 0, end: value),
              duration: Duration(milliseconds: 620),
              curve: Curves.easeOutCubic,
              builder: (
                BuildContext context,
                double animatedValue,
                Widget? child,
              ) {
                return _detailMetricMoneyText(animatedValue, valueColor);
              },
            );

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? _softAccentSurfaceColor : _softSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: highlighted ? _accentColor : _mutedTextColor,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          valueText,
        ],
      ),
    );
  }

  Widget _detailMetricMoneyText(double value, Color valueColor) {
    return Text(
      _formatarMoeda(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: valueColor,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
    );
  }

  Widget _detailStatusMetricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: _mutedTextColor),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final ButtonStyle style =
        filled
            ? FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: SixMobilePalette.onPrimary,
              minimumSize: Size.fromHeight(46),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
            : OutlinedButton.styleFrom(
              foregroundColor: _titleTextColor,
              side: BorderSide(color: _borderColor),
              minimumSize: Size.fromHeight(46),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17),
        SizedBox(width: 7),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  Widget _sharePdfHeaderButton({
    required bool gerando,
    required bool habilitado,
    required Future<void> Function(BuildContext originContext)? onPressed,
  }) {
    final String tooltip = _t(
      'atendimentoTecnico.mobile.sharePdfTooltip',
      'Compartilhar atendimento',
    );
    return Builder(
      builder: (BuildContext buttonContext) {
        return Semantics(
          button: true,
          label: tooltip,
          enabled: habilitado && !gerando && onPressed != null,
          child: IconButton(
            tooltip: tooltip,
            style: IconButton.styleFrom(
              fixedSize: Size(46, 46),
              minimumSize: Size(46, 46),
              foregroundColor: _accentColor,
              backgroundColor:
                  gerando ? _softSurfaceColor : _softAccentSurfaceColor,
            ),
            onPressed:
                habilitado && !gerando && onPressed != null
                    ? () => onPressed(buttonContext)
                    : null,
            icon:
                gerando
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    )
                    : Icon(Icons.send_rounded, size: 21),
          ),
        );
      },
    );
  }

  Widget _pdfLoadingOverlay() {
    final String title = _t(
      'atendimentoTecnico.mobile.pdfLoadingTitle',
      'Gerando PDF do atendimento',
    );
    final String subtitle = _t(
      'atendimentoTecnico.mobile.pdfLoadingSubtitle',
      'Aguarde enquanto o documento é preparado.',
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: title,
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: _backgroundColor.withValues(alpha: 0.88),
          padding: EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 320),
              padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _highlightedBorderColor),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _cardShadowColor,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailInlineWarning(String message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softAccentSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _highlightedBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: _accentColor, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _runAfterClosingSheet(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(icon, size: 38),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailLine(String label, String? value, {Color? valueColor}) {
    final String display = _blankAsDash(value);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                color: valueColor ?? _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailMoneyLine(
    String label,
    double value, {
    required bool reduceMotion,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child:
                reduceMotion
                    ? _detailMoneyText(value, valueColor)
                    : TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: value),
                      duration: Duration(milliseconds: 620),
                      curve: Curves.easeOutCubic,
                      builder: (
                        BuildContext context,
                        double animatedValue,
                        Widget? child,
                      ) {
                        return _detailMoneyText(animatedValue, valueColor);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _detailMoneyText(double value, Color? valueColor) {
    return Text(
      _formatarMoeda(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: valueColor ?? _titleTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        height: 1.25,
      ),
    );
  }

  Widget _itemsSection(AtendimentoTecnicoModel atendimento) {
    return _detailSection(
      title: 'Itens',
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        if (atendimento.itens.isEmpty)
          Text(
            'Nenhum item vinculado.',
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...atendimento.itens.map((AtendimentoTecnicoItemModel item) {
            final String tipo =
                item.tipoItemCodigo.toUpperCase() == 'SERVICE'
                    ? 'Serviço'
                    : 'Produto';
            return _detailListTile(
              icon:
                  item.tipoItemCodigo.toUpperCase() == 'SERVICE'
                      ? Icons.handyman_outlined
                      : Icons.inventory_2_outlined,
              title: item.descricaoSnapshot,
              subtitle:
                  '$tipo • ${_formatarQuantidade(item.quantidade)} x ${_formatarMoeda(item.valorUnitario)}',
              trailing: _formatarMoeda(item.valorTotal),
            );
          }),
      ],
    );
  }

  Widget _recebimentosSection(AtendimentoTecnicoModel atendimento) {
    return _detailSection(
      title: 'Recebimentos',
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        if (atendimento.recebimentos.isEmpty)
          Text(
            'Nenhum recebimento lançado.',
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...atendimento.recebimentos.reversed.map((
            AtendimentoTecnicoRecebimentoModel item,
          ) {
            final String observacao = item.observacao?.trim() ?? '';
            return _detailListTile(
              icon: Icons.payments_outlined,
              title: _blankAsDash(item.nomeFormaRecebimento),
              subtitle: <String>[
                _formatarDataHora(item.dataHora),
                if (observacao.isNotEmpty) observacao,
              ].join(' • '),
              trailing: _formatarMoeda(item.valor),
            );
          }),
      ],
    );
  }

  Widget _historicoStatusSection(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    return _detailSection(
      title: 'Histórico de status',
      icon: Icons.manage_history_rounded,
      children: <Widget>[
        if (atendimento.historicoStatus.isEmpty)
          Text(
            'Nenhuma mudança registrada.',
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...atendimento.historicoStatus.reversed.map((
            AtendimentoTecnicoHistoricoStatusModel item,
          ) {
            final String anterior =
                item.statusAnteriorNomePtBr ??
                _statusLabelPorCodigo(
                  item.statusAnteriorCodigo,
                  statusDisponiveis,
                );
            final String novo =
                item.statusNomePtBr ??
                _statusLabelPorCodigo(item.statusCodigo, statusDisponiveis);
            final String observacao = item.observacao?.trim() ?? '';
            return _detailListTile(
              icon: Icons.flag_outlined,
              title: '$anterior → $novo',
              subtitle: <String>[
                _formatarDataHora(item.dataHora),
                if (observacao.isNotEmpty) observacao,
              ].join(' • '),
            );
          }),
      ],
    );
  }

  Widget _auditoriaSection(AtendimentoTecnicoModel atendimento) {
    return _detailSection(
      title: 'Histórico de auditoria',
      icon: Icons.fact_check_outlined,
      children: <Widget>[
        if (atendimento.historicoAuditoria.isEmpty)
          Text(
            'Nenhuma auditoria registrada.',
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...atendimento.historicoAuditoria.reversed.map((
            AtendimentoTecnicoAuditoriaModel item,
          ) {
            final String observacao = item.observacao?.trim() ?? '';
            return _detailListTile(
              icon: Icons.fact_check_outlined,
              title: 'v${item.versaoOrcamento} • ${_blankAsDash(item.tipo)}',
              subtitle: <String>[
                _formatarDataHora(item.dataHora),
                if (observacao.isNotEmpty) observacao,
              ].join(' • '),
            );
          }),
      ],
    );
  }

  Widget _detailListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _iconBox(icon, size: 34),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _blankAsDash(title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _blankAsDash(subtitle),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 96),
                child: Text(
                  trailing,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editarAtendimento(AtendimentoTecnicoModel atendimento) async {
    final bool? alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) =>
                AtendimentoTecnicoEditarMobileScreen(atendimento: atendimento),
      ),
    );

    if (alterou == true && mounted) {
      await _recarregar();
    }
  }

  Future<void> _novoAtendimento() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AtendimentoTecnicoMobileScreen()),
    );

    if (mounted) await _recarregar();
  }

  Future<void> _abrirRecebimento(AtendimentoTecnicoModel atendimento) async {
    if (_processandoAcao) return;
    if (atendimento.operacaoLiquidada || atendimento.valorEmAberto <= 0) {
      _mostrarMensagem('Este atendimento já está liquidado.');
      return;
    }

    final SixMobileRecebimentoResultado? resultado =
        await SixMobileRecebimentoBottomSheet.show(
          context,
          titulo: 'Receber atendimento técnico',
          descricao: _equipamentoTitulo(atendimento),
          contato: _clienteLabel(atendimento),
          valorOriginal: atendimento.valorTotalAtendimento,
          valorJaRecebido: atendimento.valorRecebido,
          valorAberto: atendimento.valorEmAberto,
          codigoTipoInicial: _codigoTipoRecebimentoInicial(atendimento),
          permitirParcial: true,
          observacaoInicial:
              'Recebimento realizado no atendimento técnico mobile.',
          caixaApiClient: widget.caixaApiClient,
        );

    if (resultado == null || !mounted) return;
    setState(() => _processandoAcao = true);
    try {
      await _service.receber(
        id: atendimento.id,
        input: AtendimentoTecnicoRecebimentoInput(
          codigoFormaRecebimento: resultado.codigoTipoRecebimento,
          nomeFormaRecebimento: resultado.descricaoTipoRecebimento,
          valor: resultado.valor,
          recebimentos: resultado.recebimentos,
          observacao:
              resultado.observacao ?? _observacaoRecebimentoPadrao(resultado),
        ),
      );
      if (!mounted) return;
      await _recarregar();
      _mostrarMensagem(
        resultado.total
            ? 'Atendimento recebido com sucesso.'
            : 'Parcial recebida com sucesso.',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível lançar o recebimento: $error');
    } finally {
      if (mounted) setState(() => _processandoAcao = false);
    }
  }

  Future<void> _compartilharPdfAtendimento(
    AtendimentoTecnicoModel atendimento, {
    required BuildContext originContext,
  }) async {
    if (_processandoAcao) return;
    setState(() => _processandoAcao = true);
    try {
      final AtendimentoPdfShareResult result = await _pdfShareService
          .compartilharAtendimento(
            atendimentoId: atendimento.id,
            sharePositionOrigin: _shareOrigin(originContext),
          );
      if (!mounted) return;
      if (result.disposition == PdfFileShareDisposition.downloaded) {
        _mostrarMensagem(
          _t(
            'atendimentoTecnico.mobile.pdfDownloaded',
            'PDF baixado com sucesso.',
          ),
        );
      }
    } on AtendimentoPdfShareException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(_mensagemErroCompartilharPdf(error.failure));
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.mobile.pdfShareError',
          'Não foi possível compartilhar o documento.',
        ),
      );
    } finally {
      if (mounted) setState(() => _processandoAcao = false);
    }
  }

  Rect? _shareOrigin(BuildContext originContext) {
    final RenderObject? renderObject = originContext.findRenderObject();
    final RenderObject? overlayObject =
        Overlay.of(context).context.findRenderObject();
    if (renderObject is RenderBox && overlayObject is RenderBox) {
      final Offset origin = renderObject.localToGlobal(
        Offset.zero,
        ancestor: overlayObject,
      );
      return origin & renderObject.size;
    }
    return null;
  }

  String _mensagemErroCompartilharPdf(AtendimentoPdfShareFailure failure) {
    return switch (failure) {
      AtendimentoPdfShareFailure.permissionDenied => _t(
        'atendimentoTecnico.mobile.pdfPermissionDenied',
        'Você não possui permissão para compartilhar este atendimento.',
      ),
      AtendimentoPdfShareFailure.notFound => _t(
        'atendimentoTecnico.mobile.pdfNotFound',
        'Atendimento não encontrado.',
      ),
      AtendimentoPdfShareFailure.invalidFile => _t(
        'atendimentoTecnico.mobile.pdfInvalidFile',
        'O arquivo recebido é inválido.',
      ),
      AtendimentoPdfShareFailure.shareUnavailable => _t(
        'atendimentoTecnico.mobile.pdfShareUnavailable',
        'Não foi possível compartilhar o documento.',
      ),
      AtendimentoPdfShareFailure.connectionFailed ||
      AtendimentoPdfShareFailure.timeout ||
      AtendimentoPdfShareFailure.generationFailed => _t(
        'atendimentoTecnico.mobile.pdfGenerationError',
        'Não foi possível gerar o PDF do atendimento.',
      ),
    };
  }

  Future<void> _compartilharStatusPublico(
    AtendimentoTecnicoModel atendimento,
  ) async {
    if (_processandoAcao || _gerandoLinkStatus) return;
    final String origin = AppConfig.publicFrontendOrigin.trim();
    if (origin.isEmpty) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.publicStatus.publicUrlMissing',
          'URL pública do aplicativo não configurada.',
        ),
      );
      return;
    }

    setState(() {
      _processandoAcao = true;
      _gerandoLinkStatus = true;
    });
    try {
      final response = await _service.gerarLinkStatusPublico(
        id: atendimento.id,
        baseUrl: '$origin/atendimento/status',
      );
      if (!mounted) return;
      final String link = response.link.trim();
      if (link.isEmpty) {
        throw Exception(
          _t(
            'atendimentoTecnico.publicStatus.linkMissing',
            'Link não retornado pelo backend.',
          ),
        );
      }

      await Clipboard.setData(ClipboardData(text: link));
      final String mensagem = <String>[
        _t(
          'atendimentoTecnico.publicStatus.shareMessage',
          'Acompanhe o status do seu serviço pelo link abaixo:',
        ),
        '${atendimento.numero} - ${_equipamentoTitulo(atendimento)}',
        link,
      ].join('\n\n');
      await sharing.Share.share(
        mensagem,
        subject: _t(
          'atendimentoTecnico.publicStatus.shareSubject',
          'Status do serviço',
        ),
      );
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.publicStatus.linkCopiedShort',
          'Link de status copiado.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        '${_t('atendimentoTecnico.publicStatus.linkError', 'Não foi possível gerar o link de status')}: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processandoAcao = false;
          _gerandoLinkStatus = false;
        });
      }
    }
  }

  Future<void> _abrirAlterarStatus(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> statusDisponiveis,
  ) async {
    if (_processandoAcao) return;
    if (statusDisponiveis.isEmpty) {
      _mostrarMensagem('Nenhum status disponível para seleção.');
      return;
    }

    final _StatusAtendimentoMobileResult? result =
        await showModalBottomSheet<_StatusAtendimentoMobileResult>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Color(0x66000000),
          builder: (BuildContext context) {
            return _StatusAtendimentoMobileSheet(
              atendimento: atendimento,
              status: statusDisponiveis,
              statusAtual: _statusAtual(atendimento, statusDisponiveis),
              statusAtualLabel: _statusLabel(atendimento, statusDisponiveis),
            );
          },
        );

    if (result == null || !mounted) return;
    setState(() => _processandoAcao = true);
    try {
      await _service.alterarStatus(
        id: atendimento.id,
        status: result.status,
        observacao: _textoOuNulo(result.observacao),
      );
      if (!mounted) return;
      await _recarregar();
      _mostrarMensagem('Status atualizado no histórico.');
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível alterar o status: $error');
    } finally {
      if (mounted) setState(() => _processandoAcao = false);
    }
  }

  Widget _emptyState() {
    return _card(
      child: Column(
        children: <Widget>[
          _iconBox(Icons.search_off_rounded),
          SizedBox(height: 12),
          Text(
            _t(
              widget.listContext.emptyTitleKey,
              widget.listContext.emptyTitleFallback,
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            _t(
              widget.listContext.emptyMessageKey,
              widget.listContext.emptyMessageFallback,
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(
    IconData icon, {
    Color? backgroundColor,
    Color? foregroundColor,
    double size = 44,
  }) {
    final Color resolvedBackgroundColor =
        backgroundColor ?? _accentColor.withValues(alpha: 0.12);
    final Color resolvedForegroundColor = foregroundColor ?? _accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: resolvedForegroundColor, size: size * 0.52),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      constraints: BoxConstraints(maxWidth: 180),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: _accentColor),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertChip(String label, IconData icon) {
    final Color color = SixMobilePalette.error;
    return Container(
      constraints: BoxConstraints(maxWidth: 180),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _titleTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }

  List<AtendimentoTecnicoModel> _filtrar(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final String termo = _searchController.text.trim().toLowerCase();
    final String? statusSelecionadoKey = _statusSelecionadoKey;
    final DateTime? inicio =
        _dataInicioFiltro == null ? null : _inicioDoDia(_dataInicioFiltro!);
    final DateTime? fim =
        _dataFimFiltro == null ? null : _fimDoDia(_dataFimFiltro!);
    final String? tecnicoKey = _tecnicoFiltroKey;
    final AtendimentosCriadosStatusPagamentoFiltro statusPagamento =
        _permitePreferenciasAtendimentosCriados
            ? _statusPagamentoFiltro
            : AtendimentosCriadosStatusPagamentoFiltro.todos;
    final List<AtendimentoTecnicoModel> sorted =
        List<AtendimentoTecnicoModel>.from(atendimentos)
          ..sort(_compareRecentes);

    return sorted
        .where((AtendimentoTecnicoModel atendimento) {
          final DateTime? dataReferencia = _dataReferenciaFiltro(atendimento);
          if (inicio != null) {
            if (dataReferencia == null || dataReferencia.isBefore(inicio)) {
              return false;
            }
          }
          if (fim != null) {
            if (dataReferencia == null || dataReferencia.isAfter(fim)) {
              return false;
            }
          }
          if (tecnicoKey != null &&
              _tecnicoKeyAtendimento(atendimento) != tecnicoKey) {
            return false;
          }
          if (statusSelecionadoKey != null &&
              _statusFiltroKeyAtendimento(atendimento) !=
                  statusSelecionadoKey) {
            return false;
          }
          if (!_atendimentoPassaStatusPagamento(atendimento, statusPagamento)) {
            return false;
          }

          if (termo.isEmpty) return true;

          final AtendimentoTecnicoEquipamentoModel? equipamento =
              atendimento.equipamento;
          final String source =
              <String>[
                atendimento.numero,
                _clienteLabel(atendimento),
                _tecnicoLabelAtendimento(atendimento),
                _statusLabel(atendimento, statusDisponiveis),
                equipamento?.tipo ?? '',
                equipamento?.marca ?? '',
                equipamento?.modelo ?? '',
                equipamento?.imei ?? '',
                atendimento.defeitoRelatado ?? '',
                atendimento.diagnosticoTecnico ?? '',
                _formatarData(atendimento.dataEntregaPrevista),
              ].join(' ').toLowerCase();
          return source.contains(termo);
        })
        .toList(growable: false);
  }

  bool _atendimentoPassaStatusPagamento(
    AtendimentoTecnicoModel atendimento,
    AtendimentosCriadosStatusPagamentoFiltro filtro,
  ) {
    switch (filtro) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return true;
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return _pagamentoEmAberto(atendimento);
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return _pagamentoLiquidado(atendimento);
    }
  }

  bool _pagamentoEmAberto(AtendimentoTecnicoModel atendimento) {
    return !atendimento.operacaoLiquidada && atendimento.valorEmAberto > 0;
  }

  bool _pagamentoLiquidado(AtendimentoTecnicoModel atendimento) {
    return atendimento.operacaoLiquidada || atendimento.valorEmAberto <= 0;
  }

  int _compareRecentes(
    AtendimentoTecnicoModel first,
    AtendimentoTecnicoModel second,
  ) {
    final DateTime firstDate = first.dataAtualizacao ?? DateTime(1900);
    final DateTime secondDate = second.dataAtualizacao ?? DateTime(1900);
    return secondDate.compareTo(firstDate);
  }

  DateTime _inicioDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _fimDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  bool _entregaAtrasada(AtendimentoTecnicoModel atendimento) {
    final DateTime? entrega = atendimento.dataEntregaPrevista;
    if (entrega == null ||
        atendimento.operacaoLiquidada ||
        _atendimentoFinalizadoOperacionalmente(atendimento)) {
      return false;
    }
    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime dataEntrega = _inicioDoDia(entrega);
    return dataEntrega.isBefore(hoje);
  }

  bool _atendimentoFinalizadoOperacionalmente(
    AtendimentoTecnicoModel atendimento,
  ) {
    final String statusCodigo = atendimento.statusCodigo.trim().toUpperCase();
    if (<String>{
      'DELIVERED',
      'ENTREGUE',
      'CANCELED',
      'CANCELADO',
      'CANCELADA',
      'NO_REPAIR',
      'SEM_REPARO',
      'FINALIZED',
      'FINALIZADO',
      'CONCLUIDO',
      'CONCLUÍDO',
    }.contains(statusCodigo)) {
      return true;
    }

    final String statusTexto =
        <String>[
          atendimento.statusNomePtBr ?? '',
          atendimento.statusNomeEnUs ?? '',
          atendimento.statusNomeEsEs ?? '',
        ].join(' ').toUpperCase();
    return statusTexto.contains('ENTREG') ||
        statusTexto.contains('DELIVER') ||
        statusTexto.contains('CANCEL') ||
        statusTexto.contains('SEM REPARO') ||
        statusTexto.contains('NO REPAIR') ||
        statusTexto.contains('FINALIZ') ||
        statusTexto.contains('CONCLU');
  }

  DateTime? _dataReferenciaFiltro(AtendimentoTecnicoModel atendimento) {
    return atendimento.dataEntregaPrevista ??
        atendimento.dataAtualizacao ??
        atendimento.dataUltimaAlteracaoOrcamento ??
        atendimento.dataVencimentoEm ??
        atendimento.validadeOrcamentoEm;
  }

  String _tecnicoKeyAtendimento(AtendimentoTecnicoModel atendimento) {
    final String id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final String nome =
        atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (nome.isNotEmpty) return nome.toLowerCase();
    return _semTecnicoKey;
  }

  String _tecnicoLabelAtendimento(AtendimentoTecnicoModel atendimento) {
    final String nome =
        atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    return nome.isEmpty ? 'Sem técnico responsável' : nome;
  }

  String _statusFiltroKeyAtendimento(AtendimentoTecnicoModel atendimento) {
    if (atendimento.statusId > 0) return 'id:${atendimento.statusId}';
    final String codigo = atendimento.statusCodigo.trim().toUpperCase();
    if (codigo.isNotEmpty) return 'codigo:$codigo';
    return '__sem_status__';
  }

  List<_TecnicoFiltroOption> _tecnicoOptions(
    List<AtendimentoTecnicoModel> atendimentos,
    List<ColaboradorUsuarioResumo> tecnicos,
  ) {
    final Map<String, _TecnicoFiltroOption> mapa =
        <String, _TecnicoFiltroOption>{};
    for (final ColaboradorUsuarioResumo tecnico in tecnicos) {
      if (!tecnico.ehTecnicoAssistenciaTecnica) continue;
      final String id =
          tecnico.idUnicoPessoal.trim().isNotEmpty
              ? tecnico.idUnicoPessoal.trim()
              : tecnico.email.trim();
      final String nome =
          tecnico.nomeDeGuerra.trim().isNotEmpty
              ? tecnico.nomeDeGuerra.trim()
              : tecnico.nome.trim().isNotEmpty
              ? tecnico.nome.trim()
              : tecnico.email.trim();
      final String key = id.isNotEmpty ? id : nome.toLowerCase();
      if (key.isEmpty || nome.isEmpty) continue;
      mapa[key] = _TecnicoFiltroOption(key: key, label: nome);
    }
    if (atendimentos.any(
      (AtendimentoTecnicoModel atendimento) =>
          _tecnicoKeyAtendimento(atendimento) == _semTecnicoKey,
    )) {
      mapa[_semTecnicoKey] = const _TecnicoFiltroOption(
        key: _semTecnicoKey,
        label: 'Sem técnico responsável',
      );
    }
    final List<_TecnicoFiltroOption> options = mapa.values.toList(
      growable: false,
    )..sort((_TecnicoFiltroOption a, _TecnicoFiltroOption b) {
      if (a.key == _semTecnicoKey) return 1;
      if (b.key == _semTecnicoKey) return -1;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return options;
  }

  String _tecnicoFiltroLabel(List<_TecnicoFiltroOption> options) {
    final String? selected = _tecnicoFiltroKey;
    if (selected == null) return 'Todos os técnicos';
    for (final _TecnicoFiltroOption option in options) {
      if (option.key == selected) return option.label;
    }
    return 'Técnico selecionado';
  }

  String _periodoFiltroLabel() {
    final DateTime? inicio = _dataInicioFiltro;
    final DateTime? fim = _dataFimFiltro;
    if (inicio == null && fim == null) return 'Todas as datas';
    if (inicio != null && fim != null) {
      return '${_formatarData(inicio)} até ${_formatarData(fim)}';
    }
    if (inicio != null) return 'A partir de ${_formatarData(inicio)}';
    return 'Até ${_formatarData(fim!)}';
  }

  List<_StatusCount> _statusCounts(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final Map<String, _StatusCount> counts = <String, _StatusCount>{};
    for (final AtendimentoTecnicoModel atendimento in atendimentos) {
      final String key = _statusFiltroKeyAtendimento(atendimento);
      final String label = _statusLabel(atendimento, statusDisponiveis);
      final _StatusCount? current = counts[key];
      counts[key] = _StatusCount(
        key: key,
        label: current?.label ?? label,
        count: (current?.count ?? 0) + 1,
      );
    }

    final List<_StatusCount> result = counts.values.toList(growable: false)
      ..sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  String _statusPagamentoFiltroLabel(
    AtendimentosCriadosStatusPagamentoFiltro value,
  ) {
    switch (value) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return _t(
          'atendimentoTecnico.filters.paymentStatus.all',
          'Todos os pagamentos',
        );
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return _t('atendimentoTecnico.filters.paymentStatus.open', 'Em aberto');
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return _t('atendimentoTecnico.filters.paymentStatus.paid', 'Liquidado');
    }
  }

  int _totalPendentes(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where(
          (AtendimentoTecnicoModel atendimento) =>
              _pagamentoEmAberto(atendimento) ||
              atendimento.requerNovaAssinatura,
        )
        .length;
  }

  int _totalEmAberto(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos.where(_pagamentoEmAberto).length;
  }

  int _totalAssinados(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where(
          (AtendimentoTecnicoModel atendimento) =>
              atendimento.assinaturaAprovada,
        )
        .length;
  }

  double _valorAberto(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos.fold<double>(
      0,
      (double total, AtendimentoTecnicoModel atendimento) =>
          total + atendimento.valorEmAberto,
    );
  }

  String _clienteLabel(AtendimentoTecnicoModel atendimento) {
    final String cliente = atendimento.nomeClienteSnapshot?.trim() ?? '';
    return cliente.isEmpty ? 'Cliente não informado' : cliente;
  }

  String _statusLabel(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final String statusBackend = atendimento.statusNomePtBr?.trim() ?? '';
    if (statusBackend.isNotEmpty) return statusBackend;
    final String label = _statusLabelPorCodigo(
      atendimento.statusCodigo,
      status,
    );
    return label == '-' ? 'Sem status' : label;
  }

  String _statusLabelPorCodigo(String? codigo, List<DominioOpcaoModel> status) {
    final String normalized = (codigo ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return '-';
    for (final DominioOpcaoModel item in status) {
      if (item.codigo.trim().toUpperCase() == normalized) {
        final String label = item.nomePadraoPtBr.trim();
        return label.isEmpty ? item.codigo : label;
      }
    }
    if (normalized == 'WAITING_CUSTOMER_APROVAL') {
      return _t(
        'technicalService.status.waitingCustomerAproval',
        'Aguardando aprovação do cliente',
      );
    }
    return codigo!.trim();
  }

  DominioOpcaoModel? _statusAtual(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final String codigoAtual = atendimento.statusCodigo.trim().toUpperCase();
    for (final DominioOpcaoModel opcao in status) {
      if (opcao.codigo.trim().toUpperCase() == codigoAtual) return opcao;
    }
    for (final DominioOpcaoModel opcao in status) {
      if (opcao.id == atendimento.statusId) return opcao;
    }
    return null;
  }

  String _equipamentoTitulo(AtendimentoTecnicoModel atendimento) {
    final AtendimentoTecnicoEquipamentoModel? equipamento =
        atendimento.equipamento;
    final List<String> partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? atendimento.numero : partes.join(' ');
  }

  String _formatarMoeda(double value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  double _valorRecebidoAtendimento(AtendimentoTecnicoModel atendimento) {
    final double recebido = atendimento.valorRecebido;
    if (recebido.isFinite && recebido > 0) return recebido;

    final double calculado =
        atendimento.valorTotalAtendimento - atendimento.valorEmAberto;
    return calculado.isFinite && calculado > 0 ? calculado : 0;
  }

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _formatarDataHora(DateTime? value) {
    if (value == null) return '-';
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    return '${localeSettings.formatDate(value)} ${localeSettings.formatTime(value)}';
  }

  String _formatarQuantidade(double value) {
    return context.read<LocaleSettingsProvider>().formatDecimal(value);
  }

  String _blankAsDash(String? value) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  String _assinaturaResumo(AtendimentoTecnicoModel atendimento) {
    final String nome = atendimento.assinaturaNomeAssinante?.trim() ?? '';
    final String data = _formatarDataHora(atendimento.assinaturaDataHora);
    if (nome.isEmpty && data == '-') return 'Aprovada';
    if (nome.isEmpty) return 'Aprovada em $data';
    return '$nome • $data';
  }

  String? _codigoTipoRecebimentoInicial(AtendimentoTecnicoModel atendimento) {
    if (atendimento.recebimentos.isEmpty) return null;
    final String codigo =
        atendimento.recebimentos.last.codigoFormaRecebimento.trim();
    return codigo.isEmpty ? null : codigo;
  }

  String _observacaoRecebimentoPadrao(SixMobileRecebimentoResultado resultado) {
    return resultado.total
        ? 'Recebimento total realizado no atendimento técnico mobile.'
        : 'Recebimento parcial realizado no atendimento técnico mobile.';
  }

  String? _textoOuNulo(String value) {
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);
}

class _AtendimentoCardSkeleton extends StatelessWidget {
  const _AtendimentoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 14, 12, 12),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AtendimentoSkeletonBlock(height: 18, radius: 8),
              SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: 0.74,
                child: _AtendimentoSkeletonBlock(height: 12, radius: 7),
              ),
              SizedBox(height: 13),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  _AtendimentoSkeletonBlock(width: 86, height: 26, radius: 999),
                  _AtendimentoSkeletonBlock(
                    width: 124,
                    height: 26,
                    radius: 999,
                  ),
                  _AtendimentoSkeletonBlock(width: 78, height: 26, radius: 999),
                ],
              ),
            ],
          );
          const Widget detailsButton = _AtendimentoSkeletonActionButton();

          if (constraints.maxWidth < 290) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _AtendimentoSkeletonIconBox(
                      Icons.devices_other_outlined,
                      size: 44,
                    ),
                    Spacer(),
                    detailsButton,
                  ],
                ),
                SizedBox(height: 12),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AtendimentoSkeletonIconBox(
                Icons.devices_other_outlined,
                size: 44,
              ),
              SizedBox(width: 12),
              Expanded(child: content),
              SizedBox(width: 10),
              detailsButton,
            ],
          );
        },
      ),
    );
  }
}

class _StatusOverviewSkeletonRow extends StatelessWidget {
  const _StatusOverviewSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _AtendimentoSkeletonBlock(height: 14, radius: 8)),
        SizedBox(width: 10),
        _AtendimentoSkeletonBlock(width: 42, height: 26, radius: 999),
      ],
    );
  }
}

class _AtendimentoSkeletonActionButton extends StatelessWidget {
  const _AtendimentoSkeletonActionButton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SixMobilePalette.softAccentSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.add_rounded,
          color: SixMobilePalette.accent,
          size: 22,
        ),
      ),
    );
  }
}

class _AtendimentoSkeletonIconBox extends StatelessWidget {
  const _AtendimentoSkeletonIconBox(this.icon, {this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SixMobilePalette.softAccentSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: SixMobilePalette.accent, size: size * 0.52),
      ),
    );
  }
}

class _AtendimentoSkeletonBlock extends StatefulWidget {
  const _AtendimentoSkeletonBlock({
    this.width,
    required this.height,
    this.radius = 18,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<_AtendimentoSkeletonBlock> createState() =>
      _AtendimentoSkeletonBlockState();
}

class _AtendimentoSkeletonBlockState extends State<_AtendimentoSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1120),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncPulse() {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, Widget? child) {
          final bool reduceMotion =
              MediaQuery.disableAnimationsOf(context) ||
              MediaQuery.accessibleNavigationOf(context);
          final double progress = reduceMotion ? 0 : _pulse.value;
          final Color silver = Color.alphaBlend(
            SixMobilePalette.activeBorder.withValues(alpha: 0.48),
            SixMobilePalette.surface,
          );
          final Color fill =
              Color.lerp(
                SixMobilePalette.softNeutralSurface,
                silver,
                progress,
              )!;
          final Color border =
              Color.lerp(
                SixMobilePalette.border,
                SixMobilePalette.activeBorder,
                progress * 0.7,
              )!;

          return Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.activeBorder.withValues(
                    alpha: 0.10 * progress,
                  ),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final bool highlight;
}

class _StatusCount {
  const _StatusCount({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class _PeriodoFiltro {
  const _PeriodoFiltro({required this.dataInicio, required this.dataFim});

  final DateTime? dataInicio;
  final DateTime? dataFim;
}

class _TecnicoFiltroOption {
  const _TecnicoFiltroOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _AtendimentosTecnicosMobileState {
  const _AtendimentosTecnicosMobileState({
    required this.dominios,
    required this.atendimentos,
    required this.tecnicos,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
  final List<ColaboradorUsuarioResumo> tecnicos;
}

class _PeriodoFiltroMobileSheet extends StatefulWidget {
  const _PeriodoFiltroMobileSheet({
    required this.dataInicio,
    required this.dataFim,
    required this.formatarData,
  });

  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String Function(DateTime?) formatarData;

  @override
  State<_PeriodoFiltroMobileSheet> createState() =>
      _PeriodoFiltroMobileSheetState();
}

class _PeriodoFiltroMobileSheetState extends State<_PeriodoFiltroMobileSheet> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  late DateTime? _inicio = widget.dataInicio;
  late DateTime? _fim = widget.dataFim;
  bool _editandoInicio = true;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime initialDate = (_editandoInicio ? _inicio : _fim) ?? now;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(18, 10, 18, 22),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.activeBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    _sheetIcon(Icons.event_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Filtrar por data',
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Use a data de atualização do atendimento.',
                            style: TextStyle(
                              color: _mutedTextColor,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: <Widget>[
                    _dateTargetChip(
                      label: 'Início',
                      value: widget.formatarData(_inicio),
                      selected: _editandoInicio,
                      onTap: () => setState(() => _editandoInicio = true),
                    ),
                    _dateTargetChip(
                      label: 'Fim',
                      value: widget.formatarData(_fim),
                      selected: !_editandoInicio,
                      onTap: () => setState(() => _editandoInicio = false),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _shortcutChip('Hoje', () => _setPeriodo(now, now)),
                    _shortcutChip(
                      'Últimos 7 dias',
                      () => _setPeriodo(now.subtract(Duration(days: 6)), now),
                    ),
                    _shortcutChip(
                      'Próximos 7 dias',
                      () => _setPeriodo(now, now.add(Duration(days: 6))),
                    ),
                    _shortcutChip(
                      'Vencidos',
                      () => _setPeriodoAte(now.subtract(Duration(days: 1))),
                    ),
                    _shortcutChip(
                      'Últimos 30 dias',
                      () => _setPeriodo(now.subtract(Duration(days: 29)), now),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                  ),
                  child: CalendarDatePicker(
                    key: ValueKey<String>(
                      '${_editandoInicio ? 'inicio' : 'fim'}-${initialDate.toIso8601String()}',
                    ),
                    initialDate: initialDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 5, 12, 31),
                    onDateChanged: _selecionarData,
                  ),
                ),
                SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            () => Navigator.of(context).pop(
                              const _PeriodoFiltro(
                                dataInicio: null,
                                dataFim: null,
                              ),
                            ),
                        child: Text('Limpar'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            () => Navigator.of(context).pop(
                              _PeriodoFiltro(
                                dataInicio: _inicio,
                                dataFim: _fim,
                              ),
                            ),
                        icon: Icon(Icons.check_rounded),
                        label: Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: _accentColor),
    );
  }

  Widget _dateTargetChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text('$label: $value'),
      onSelected: (_) => onTap(),
      selectedColor: _accentColor,
      backgroundColor: SixMobilePalette.softNeutralSurface,
      side: BorderSide(color: selected ? _accentColor : _borderColor),
      labelStyle: TextStyle(
        color: selected ? SixMobilePalette.onAccent : _titleTextColor,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }

  Widget _shortcutChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: SixMobilePalette.softNeutralSurface,
      side: BorderSide(color: _borderColor),
      labelStyle: TextStyle(
        color: _titleTextColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  void _selecionarData(DateTime value) {
    final DateTime normalized = DateTime(value.year, value.month, value.day);
    setState(() {
      if (_editandoInicio) {
        _inicio = normalized;
        if (_fim != null && _fim!.isBefore(normalized)) {
          _fim = normalized;
        }
      } else {
        _fim = normalized;
        if (_inicio != null && _inicio!.isAfter(normalized)) {
          _inicio = normalized;
        }
      }
    });
  }

  void _setPeriodo(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
    });
  }

  void _setPeriodoAte(DateTime fim) {
    setState(() {
      _inicio = null;
      _fim = DateTime(fim.year, fim.month, fim.day);
      _editandoInicio = false;
    });
  }
}

class _TecnicoFiltroMobileSheet extends StatefulWidget {
  const _TecnicoFiltroMobileSheet({
    required this.tecnicos,
    required this.selectedKey,
  });

  static const String todosKey = '__todos__';

  final List<_TecnicoFiltroOption> tecnicos;
  final String? selectedKey;

  @override
  State<_TecnicoFiltroMobileSheet> createState() =>
      _TecnicoFiltroMobileSheetState();
}

class _TecnicoFiltroMobileSheetState extends State<_TecnicoFiltroMobileSheet> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_TecnicoFiltroOption> get _filtrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.tecnicos;
    return widget.tecnicos
        .where((_TecnicoFiltroOption item) {
          return _normalize(item.label).contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<_TecnicoFiltroOption> tecnicos = _filtrados;
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.activeBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SixMobilePalette.softAccentSurface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.engineering_outlined,
                          color: _accentColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Técnico responsável',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Filtre pelos responsáveis dos atendimentos.',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged:
                        (String value) => setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar técnico',
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                icon: Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filter = '');
                                },
                              ),
                      filled: true,
                      fillColor: _surfaceColor,
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
                        borderSide: BorderSide(color: _accentColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 22),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return _tecnicoItem(
                          label: 'Todos os técnicos',
                          selected: widget.selectedKey == null,
                          icon: Icons.groups_outlined,
                          onTap:
                              () => Navigator.of(
                                context,
                              ).pop(_TecnicoFiltroMobileSheet.todosKey),
                        );
                      }
                      final _TecnicoFiltroOption tecnico = tecnicos[index - 1];
                      return _tecnicoItem(
                        label: tecnico.label,
                        selected: widget.selectedKey == tecnico.key,
                        icon: Icons.engineering_outlined,
                        onTap: () => Navigator.of(context).pop(tecnico.key),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemCount: tecnicos.length + 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tecnicoItem({
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                selected ? SixMobilePalette.softAccentSurface : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? SixMobilePalette.highlightedBorder : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    selected
                        ? SixMobilePalette.softAccentSurface
                        : SixMobilePalette.iconSurface,
                child: Icon(icon, color: _accentColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _accentColor : _mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _StatusAtendimentoMobileResult {
  const _StatusAtendimentoMobileResult({
    required this.status,
    required this.observacao,
  });

  final DominioOpcaoModel status;
  final String observacao;
}

class _StatusPagamentoFiltroMobileSheet extends StatelessWidget {
  const _StatusPagamentoFiltroMobileSheet({
    required this.selected,
    required this.labelFor,
  });

  final AtendimentosCriadosStatusPagamentoFiltro selected;
  final String Function(AtendimentosCriadosStatusPagamentoFiltro value)
  labelFor;

  static const List<AtendimentosCriadosStatusPagamentoFiltro> _options =
      <AtendimentosCriadosStatusPagamentoFiltro>[
        AtendimentosCriadosStatusPagamentoFiltro.todos,
        AtendimentosCriadosStatusPagamentoFiltro.emAberto,
        AtendimentosCriadosStatusPagamentoFiltro.liquidado,
      ];

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = SixMobilePalette.background;
    final Color surfaceColor = SixMobilePalette.surface;
    final Color accentColor = SixMobilePalette.accent;
    final Color mutedTextColor = SixMobilePalette.mutedText;
    final Color titleTextColor = SixMobilePalette.titleText;
    final Color borderColor = SixMobilePalette.activeBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.36,
      maxChildSize: 0.70,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(18, 10, 18, 22),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.activeBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: SixMobilePalette.softAccentSurface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.t(
                              'atendimentoTecnico.filters.paymentStatus.label',
                              fallback: 'Status pagamento',
                            ),
                            style: TextStyle(
                              color: titleTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            context.t(
                              'atendimentoTecnico.filters.paymentStatus.helper',
                              fallback:
                                  'Filtre atendimentos por saldo em aberto ou liquidado.',
                            ),
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ..._options.map((
                  AtendimentosCriadosStatusPagamentoFiltro option,
                ) {
                  final bool isSelected = selected == option;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).pop(option),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? SixMobilePalette.softAccentSurface
                                    : surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? SixMobilePalette.highlightedBorder
                                      : borderColor,
                              width: isSelected ? 1.2 : 1,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 21,
                                backgroundColor:
                                    isSelected
                                        ? SixMobilePalette.softAccentSurface
                                        : SixMobilePalette.iconSurface,
                                child: Icon(
                                  _iconFor(option),
                                  color: accentColor,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  labelFor(option),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: titleTextColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color:
                                    isSelected ? accentColor : mutedTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(AtendimentosCriadosStatusPagamentoFiltro value) {
    switch (value) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return Icons.receipt_long_outlined;
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return Icons.account_balance_wallet_outlined;
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return Icons.price_check_rounded;
    }
  }
}

class _StatusAtendimentoMobileSheet extends StatefulWidget {
  const _StatusAtendimentoMobileSheet({
    required this.atendimento,
    required this.status,
    required this.statusAtual,
    required this.statusAtualLabel,
  });

  final AtendimentoTecnicoModel atendimento;
  final List<DominioOpcaoModel> status;
  final DominioOpcaoModel? statusAtual;
  final String statusAtualLabel;

  @override
  State<_StatusAtendimentoMobileSheet> createState() =>
      _StatusAtendimentoMobileSheetState();
}

class _StatusAtendimentoMobileSheetState
    extends State<_StatusAtendimentoMobileSheet> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  late DominioOpcaoModel? _statusSelecionado = widget.statusAtual;
  String _filter = '';

  List<DominioOpcaoModel> get _statusFiltrados {
    final String term = _normalize(_filter);
    final List<DominioOpcaoModel> sorted = List<DominioOpcaoModel>.from(
      widget.status,
    )..sort(
      (DominioOpcaoModel a, DominioOpcaoModel b) => a.ordem.compareTo(b.ordem),
    );
    if (term.isEmpty) return sorted;
    return sorted
        .where((DominioOpcaoModel item) {
          return _normalize(
            '${_statusLabel(item)} ${item.codigo} ${item.i18nKey}',
          ).contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<DominioOpcaoModel> status = _statusFiltrados;
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.activeBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      _sheetIcon(Icons.swap_horiz_rounded),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Mudar status',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '${widget.atendimento.numero} • Atual: ${widget.statusAtualLabel}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged:
                        (String value) => setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar status',
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                icon: Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filter = '');
                                },
                              ),
                      filled: true,
                      fillColor: _surfaceColor,
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
                        borderSide: BorderSide(color: _accentColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                    itemBuilder: (BuildContext context, int index) {
                      final DominioOpcaoModel item = status[index];
                      return _statusItem(
                        status: item,
                        selected: _statusSelecionado?.id == item.id,
                        onTap: () => setState(() => _statusSelecionado = item),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemCount: status.length,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: TextField(
                    controller: _observacaoController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Observação opcional',
                      filled: true,
                      fillColor: _surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancelar'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _statusSelecionado == null
                                  ? null
                                  : () => Navigator.of(context).pop(
                                    _StatusAtendimentoMobileResult(
                                      status: _statusSelecionado!,
                                      observacao: _observacaoController.text,
                                    ),
                                  ),
                          icon: Icon(Icons.check_rounded),
                          label: Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: _accentColor),
    );
  }

  Widget _statusItem({
    required DominioOpcaoModel status,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                selected ? SixMobilePalette.softAccentSurface : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? SixMobilePalette.highlightedBorder : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    selected
                        ? SixMobilePalette.softAccentSurface
                        : SixMobilePalette.iconSurface,
                child: Icon(Icons.flag_outlined, color: _accentColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _statusLabel(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      selected
                          ? _t(
                            'atendimentoTecnico.mobile.currentStatusOption',
                            'Status atual',
                          )
                          : _t(
                            'atendimentoTecnico.mobile.selectStatusOption',
                            'Toque para selecionar',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _accentColor : _mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(DominioOpcaoModel status) {
    final String nome = status.nomePadraoPtBr.trim();
    return nome.isEmpty ? status.codigo : nome;
  }

  String _t(String key, String fallback) {
    return context.t(key, fallback: fallback);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
