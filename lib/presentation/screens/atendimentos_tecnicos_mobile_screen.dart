import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as sharing;
import 'package:signature/signature.dart';

import '../../core/config/app_config.dart';
import '../../core/services/pdf_file_share_service.dart';
import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/dominio_models.dart';
import '../../data/models/operational_procedure_flow_models.dart';
import '../../data/models/operational_procedure_models.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/atendimento_tecnico/atendimento_status_signature_policy.dart';
import '../../domain/services/atendimento_tecnico/atendimento_pdf_share_service.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import '../components/mobile_motion.dart';
import '../coordinators/operational_procedure_flow_coordinator.dart';
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
    this.persistUserFilters = true,
    this.allowPaymentStatusFilter = true,
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

  const AtendimentosTecnicosMobileListContext.inProgress()
    : this(
        titleKey: 'atendimentoTecnico.mobile.inProgressTitle',
        titleFallback: 'Serviços em andamento',
        heroTitleKey: 'atendimentoTecnico.mobile.inProgressTitle',
        heroTitleFallback: 'Serviços em andamento',
        descriptionKey: 'atendimentoTecnico.mobile.inProgressDescription',
        descriptionFallback:
            'Atendimentos técnicos ativos em execução ou aguardando a próxima etapa.',
        emptyTitleKey: 'atendimentoTecnico.mobile.inProgressEmptyTitle',
        emptyTitleFallback: 'Nenhum serviço em andamento no momento.',
        emptyMessageKey: 'atendimentoTecnico.mobile.inProgressEmptyMessage',
        emptyMessageFallback:
            'Quando um atendimento técnico ativo for criado, ele aparecerá aqui.',
        errorTitleKey: 'atendimentoTecnico.mobile.inProgressErrorTitle',
        errorTitleFallback:
            'Não foi possível consultar os serviços em andamento. Tente novamente.',
        loadingLabelKey: 'atendimentoTecnico.mobile.inProgressLoading',
        loadingLabelFallback: 'Carregando serviços em andamento',
        statusFilter: 'ACTIVE_GROUP',
        sectionTitleKey: 'atendimentoTecnico.mobile.inProgressSection',
        sectionTitleFallback: 'Serviços em andamento',
        filteredSectionTitleKey:
            'atendimentoTecnico.mobile.inProgressFilteredSection',
        filteredSectionTitleFallback: 'Resultado do filtro',
        persistUserFilters: false,
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
        persistUserFilters: false,
        allowPaymentStatusFilter: false,
      );

  const AtendimentosTecnicosMobileListContext.closed()
    : this(
        titleKey: 'atendimentoTecnico.mobile.closedTitle',
        titleFallback: 'Serviços já encerrados',
        heroTitleKey: 'atendimentoTecnico.mobile.closedTitle',
        heroTitleFallback: 'Serviços já encerrados',
        descriptionKey: 'atendimentoTecnico.mobile.closedDescription',
        descriptionFallback:
            'Atendimentos técnicos entregues, cancelados ou encerrados sem reparo.',
        emptyTitleKey: 'atendimentoTecnico.mobile.closedEmptyTitle',
        emptyTitleFallback: 'Nenhum serviço encerrado encontrado.',
        emptyMessageKey: 'atendimentoTecnico.mobile.closedEmptyMessage',
        emptyMessageFallback:
            'Quando um atendimento for entregue, cancelado ou encerrado sem reparo, ele aparecerá aqui.',
        errorTitleKey: 'atendimentoTecnico.mobile.closedErrorTitle',
        errorTitleFallback:
            'Não foi possível consultar os serviços encerrados. Tente novamente.',
        loadingLabelKey: 'atendimentoTecnico.mobile.closedLoading',
        loadingLabelFallback: 'Carregando serviços encerrados',
        statusFilter: 'FINALIZED_GROUP',
        sectionTitleKey: 'atendimentoTecnico.mobile.closedSection',
        sectionTitleFallback: 'Serviços encerrados',
        filteredSectionTitleKey:
            'atendimentoTecnico.mobile.closedFilteredSection',
        filteredSectionTitleFallback: 'Resultado do filtro',
        persistUserFilters: false,
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
  final bool persistUserFilters;
  final bool allowPaymentStatusFilter;
}

class AtendimentosTecnicosMobileScreen extends StatefulWidget {
  const AtendimentosTecnicosMobileScreen({
    super.key,
    this.service,
    this.pdfShareService,
    this.colaboradorApiClient,
    this.caixaApiClient,
    this.procedureCoordinator,
    this.listContext = const AtendimentosTecnicosMobileListContext.standard(),
    this.initialFeedbackMessage,
  });

  final AtendimentoTecnicoService? service;
  final AtendimentoPdfShareService? pdfShareService;
  final ColaboradorUsuarioApiClient? colaboradorApiClient;
  final CaixaApiClient? caixaApiClient;
  final OperationalProcedureFlowCoordinator? procedureCoordinator;
  final AtendimentosTecnicosMobileListContext listContext;
  final String? initialFeedbackMessage;

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
  static Color get _cardShadowColor => SixMobilePalette.navigationShadow;

  late final AtendimentoTecnicoService _service;
  late final AtendimentoPdfShareService _pdfShareService;
  late final ColaboradorUsuarioApiClient _colaboradorApiClient;
  late final OperationalProcedureFlowCoordinator _procedureCoordinator;
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final TextEditingController _searchController = TextEditingController();

  late Future<_AtendimentosTecnicosMobileState> _future;
  _AtendimentosTecnicosMobileState? _lastLoadedState;
  Timer? _salvarBuscaDebounce;
  Timer? _aplicarBuscaDebounce;
  _AtendimentosTecnicosConsulta _consulta =
      const _AtendimentosTecnicosConsulta();
  bool _processandoAcao = false;
  bool _gerandoLinkStatus = false;
  bool _gerandoLinkAssinatura = false;
  bool _aplicandoPreferencias = false;
  bool _usuarioAlterouFiltros = false;
  bool _abrindoNovoAtendimento = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AtendimentoTecnicoService();
    _pdfShareService =
        widget.pdfShareService ??
        AtendimentoPdfShareService(atendimentoService: _service);
    _colaboradorApiClient =
        widget.colaboradorApiClient ?? HttpColaboradorUsuarioApiClient();
    _procedureCoordinator =
        widget.procedureCoordinator ?? OperationalProcedureFlowCoordinator();
    _future = _carregarECachear();
    _searchController.addListener(_onSearchChanged);
    final String? initialFeedbackMessage =
        widget.initialFeedbackMessage?.trim();
    if (initialFeedbackMessage != null && initialFeedbackMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mostrarMensagem(initialFeedbackMessage);
      });
    }
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
    _aplicarBuscaDebounce?.cancel();
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

  Future<_AtendimentosTecnicosMobileState> _carregarECachear() async {
    final _AtendimentosTecnicosMobileState state = await _carregar();
    _lastLoadedState = state;
    return state;
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _carregarECachear();
    });
    await _future;
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    if (!_aplicandoPreferencias) {
      _aplicarBuscaDebounce?.cancel();
      _aplicarBuscaDebounce = Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        final String busca = _searchController.text.trim();
        if (_consulta.busca == busca) return;
        _aplicarConsulta(_consulta.copyWith(busca: busca));
      });
    }
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
      _consulta = _AtendimentosTecnicosConsulta(
        busca: filtros.busca.trim(),
        dataInicio: filtros.dataInicio,
        dataFim: filtros.dataFim,
        tecnicoKey: filtros.tecnicoKey,
        statusKey: filtros.statusKey,
        statusPagamento: filtros.statusPagamento,
      );
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
      dataInicio: _consulta.dataInicio,
      dataFim: _consulta.dataFim,
      tecnicoKey: _consulta.tecnicoKey,
      statusKey: _consulta.statusKey,
      statusPagamento: _consulta.statusPagamento,
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
      widget.listContext.persistUserFilters;

  bool get _permiteFiltroStatusPagamento =>
      widget.listContext.allowPaymentStatusFilter;

  bool get _statusPagamentoFiltroAtivo =>
      _permiteFiltroStatusPagamento &&
      _consulta.statusPagamento !=
          AtendimentosCriadosStatusPagamentoFiltro.todos;

  int get _advancedFiltersCount => _consulta.advancedFilterCount(
    includePayment: _permiteFiltroStatusPagamento,
  );

  bool get _hasAdvancedFilters => _advancedFiltersCount > 0;

  bool get _hasAnyFilter =>
      _hasAdvancedFilters || _consulta.busca.trim().isNotEmpty;

  void _aplicarConsulta(
    _AtendimentosTecnicosConsulta consulta, {
    bool salvarPreferencias = true,
  }) {
    _aplicarBuscaDebounce?.cancel();
    setState(() => _consulta = consulta.copyWith(page: 0));
    if (salvarPreferencias && _permitePreferenciasAtendimentosCriados) {
      _usuarioAlterouFiltros = true;
      _salvarPreferenciasAtendimentosCriadosMobile();
    }
  }

  void _limparBusca() {
    _aplicarBuscaDebounce?.cancel();
    _aplicandoPreferencias = true;
    _searchController.clear();
    _aplicandoPreferencias = false;
    _aplicarConsulta(_consulta.copyWith(busca: ''));
  }

  void _limparFiltrosAvancados() {
    _aplicarConsulta(
      _consulta.copyWith(
        dataInicio: null,
        dataFim: null,
        tecnicoKey: null,
        statusKey: null,
        statusPagamento: AtendimentosCriadosStatusPagamentoFiltro.todos,
      ),
    );
  }

  void _limparConsultaCompleta() {
    _aplicarBuscaDebounce?.cancel();
    _aplicandoPreferencias = true;
    _searchController.clear();
    _aplicandoPreferencias = false;
    setState(() {
      _consulta = const _AtendimentosTecnicosConsulta();
    });
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
        _advancedFilterButton(),
        IconButton(
          tooltip: _t('atendimentoTecnico.mobile.newFab', 'Novo atendimento'),
          icon: Icon(Icons.add_rounded),
          onPressed: _abrindoNovoAtendimento ? null : _novoAtendimento,
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
        final List<_TecnicoFiltroOption> tecnicos = _tecnicoOptions(
          atendimentos,
          state.tecnicos,
        );
        final List<_StatusFiltroOption> status = _statusFiltroOptions(
          atendimentos,
          statusDisponiveis,
        );
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
                child: _querySearchBar(),
              ),
              _activeAdvancedFilterChips(tecnicos, status),
              if (filtrados.isNotEmpty) ...<Widget>[
                SizedBox(height: 12),
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 150),
                  child: _summaryCompactCard(filtrados),
                ),
              ],
              SizedBox(height: 12),
              _resultSummary(filtrados.length),
              SizedBox(height: 10),
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
                          delay: Duration(milliseconds: 160 + entry.key * 45),
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
          _loadingSearchSkeleton(),
          SizedBox(height: 14),
          _loadingSummaryGrid(),
          SizedBox(height: 14),
          const _AtendimentoSkeletonBlock(width: 142, height: 18, radius: 8),
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

  Widget _loadingSummaryGrid() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(Icons.query_stats_rounded, size: 34),
              SizedBox(width: 10),
              const _AtendimentoSkeletonBlock(
                width: 132,
                height: 14,
                radius: 7,
              ),
            ],
          ),
          SizedBox(height: 10),
          const _AtendimentoSkeletonBlock(width: 120, height: 24, radius: 8),
          SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: const <Widget>[
              _AtendimentoSkeletonBlock(width: 96, height: 14, radius: 7),
              _AtendimentoSkeletonBlock(width: 78, height: 14, radius: 7),
              _AtendimentoSkeletonBlock(width: 76, height: 14, radius: 7),
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

  Widget _summaryCompactCard(List<AtendimentoTecnicoModel> atendimentos) {
    final int total = atendimentos.length;
    final int totalEmAberto = _totalEmAberto(atendimentos);
    final int totalAssinados = _totalAssinados(atendimentos);
    final String valorEmAberto = _formatarMoeda(_valorAberto(atendimentos));
    final String title = _t(
      'atendimentoTecnico.mobile.periodSummaryTitle',
      'Resumo do período',
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked =
            constraints.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.15;
        final Widget moneyMetric = _summaryMoneyMetric(valorEmAberto);
        final Widget countMetrics = _summaryCountMetrics(
          total: total,
          totalEmAberto: totalEmAberto,
          totalAssinados: totalAssinados,
        );

        return Semantics(
          container: true,
          label: <String>[
            title,
            _summaryServicesLabel(total),
            _summaryOpenCountLabel(totalEmAberto),
            _summarySignedCountLabel(totalAssinados),
            _summaryOpenValueLabel(valorEmAberto),
          ].join('. '),
          child: Container(
            key: const ValueKey<String>(
              'atendimentos-tecnicos-resumo-compacto',
            ),
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _cardShadowColor,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _iconBox(Icons.query_stats_rounded, size: 34),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (stacked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      moneyMetric,
                      SizedBox(height: 10),
                      countMetrics,
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(flex: 5, child: moneyMetric),
                      SizedBox(width: 14),
                      Container(width: 1, height: 38, color: _borderColor),
                      SizedBox(width: 14),
                      Expanded(flex: 7, child: countMetrics),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryMoneyMetric(String value) {
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 2),
          Text(
            _t(
              'atendimentoTecnico.mobile.summaryOpenValueCaption',
              'em aberto',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCountMetrics({
    required int total,
    required int totalEmAberto,
    required int totalAssinados,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 7,
      children: <Widget>[
        _summaryCountMetric(
          count: total,
          label: _summaryServiceUnitLabel(total),
          icon: Icons.assignment_turned_in_outlined,
        ),
        _summaryCountMetric(
          count: totalEmAberto,
          label: _summaryOpenUnitLabel(totalEmAberto),
          icon: Icons.account_balance_wallet_outlined,
        ),
        _summaryCountMetric(
          count: totalAssinados,
          label: _summarySignedUnitLabel(totalAssinados),
          icon: Icons.verified_rounded,
        ),
      ],
    );
  }

  Widget _summaryCountMetric({
    required int count,
    required String label,
    required IconData icon,
  }) {
    final TextStyle countStyle = TextStyle(
      color: _titleTextColor,
      fontSize: 13,
      fontWeight: FontWeight.w900,
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 15),
          SizedBox(width: 5),
          SixAnimatedNumberText(value: count.toString(), style: countStyle),
          SizedBox(width: 3),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _summaryServicesLabel(int count) {
    return '$count ${_summaryServiceUnitLabel(count)}';
  }

  String _summaryOpenCountLabel(int count) {
    return '$count ${_summaryOpenUnitLabel(count)}';
  }

  String _summarySignedCountLabel(int count) {
    return '$count ${_summarySignedUnitLabel(count)}';
  }

  String _summaryOpenValueLabel(String value) {
    return _t(
      'atendimentoTecnico.mobile.summaryOpenValue',
      '{value} em aberto',
    ).replaceAll('{value}', value);
  }

  String _summaryServiceUnitLabel(int count) {
    return count == 1
        ? _t('atendimentoTecnico.mobile.summaryServiceOne', 'atendimento')
        : _t('atendimentoTecnico.mobile.summaryServiceMany', 'atendimentos');
  }

  String _summaryOpenUnitLabel(int count) {
    return count == 1
        ? _t('atendimentoTecnico.mobile.summaryOpenOne', 'em aberto')
        : _t('atendimentoTecnico.mobile.summaryOpenMany', 'em aberto');
  }

  String _summarySignedUnitLabel(int count) {
    return count == 1
        ? _t('atendimentoTecnico.mobile.summarySignedOne', 'assinado')
        : _t('atendimentoTecnico.mobile.summarySignedMany', 'assinados');
  }

  Widget _querySearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: _t(
          'atendimentoTecnico.mobile.searchHint',
          'Buscar por cliente, status, equipamento ou número',
        ),
        prefixIcon: Icon(Icons.search_rounded, color: _accentColor),
        suffixIcon:
            _searchController.text.trim().isNotEmpty
                ? IconButton(
                  tooltip: _t('common.clear', 'Limpar'),
                  onPressed: _limparBusca,
                  icon: Icon(Icons.clear_rounded),
                )
                : null,
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

  Widget _advancedFilterButton() {
    final _AtendimentosTecnicosMobileState? state = _lastLoadedState;
    final int count = _advancedFiltersCount;
    return Semantics(
      button: true,
      enabled: state != null,
      label:
          count == 0
              ? _t(
                'atendimentoTecnico.mobile.advancedFilters',
                'Filtros avançados',
              )
              : _t(
                'atendimentoTecnico.mobile.advancedFiltersActive',
                'Filtros avançados ativos',
              ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          IconButton(
            tooltip: _t(
              'atendimentoTecnico.mobile.advancedFilters',
              'Filtros avançados',
            ),
            onPressed:
                state == null
                    ? null
                    : () => _abrirFiltrosAvancados(
                      atendimentos: state.atendimentos,
                      statusDisponiveis:
                          state.dominios.statusAtendimentoTecnico,
                      tecnicos: _tecnicoOptions(
                        state.atendimentos,
                        state.tecnicos,
                      ),
                    ),
            icon: Icon(Icons.tune_rounded),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                constraints: BoxConstraints(minWidth: 17, minHeight: 17),
                padding: EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SixMobilePalette.notificationBadge,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _primaryColor, width: 1.4),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _activeAdvancedFilterChips(
    List<_TecnicoFiltroOption> tecnicos,
    List<_StatusFiltroOption> status,
  ) {
    if (!_hasAdvancedFilters) return SizedBox.shrink();

    final List<Widget> chips = <Widget>[];
    if (_consulta.dataInicio != null || _consulta.dataFim != null) {
      chips.add(
        _activeFilterChip(
          label: _periodoFiltroLabel(_consulta),
          icon: Icons.event_outlined,
          onDeleted:
              () => _aplicarConsulta(
                _consulta.copyWith(dataInicio: null, dataFim: null),
              ),
        ),
      );
    }
    if (_consulta.tecnicoKey != null) {
      chips.add(
        _activeFilterChip(
          label: _tecnicoFiltroLabel(tecnicos, _consulta.tecnicoKey),
          icon: Icons.engineering_outlined,
          onDeleted:
              () => _aplicarConsulta(_consulta.copyWith(tecnicoKey: null)),
        ),
      );
    }
    if (_consulta.statusKey != null) {
      chips.add(
        _activeFilterChip(
          label: _statusFiltroLabel(status, _consulta.statusKey),
          icon: Icons.flag_outlined,
          onDeleted:
              () => _aplicarConsulta(_consulta.copyWith(statusKey: null)),
        ),
      );
    }
    if (_statusPagamentoFiltroAtivo) {
      chips.add(
        _activeFilterChip(
          label: _statusPagamentoFiltroLabel(_consulta.statusPagamento),
          icon: Icons.account_balance_wallet_outlined,
          onDeleted:
              () => _aplicarConsulta(
                _consulta.copyWith(
                  statusPagamento:
                      AtendimentosCriadosStatusPagamentoFiltro.todos,
                ),
              ),
        ),
      );
    }
    chips.add(
      ActionChip(
        avatar: Icon(Icons.filter_alt_off_rounded, size: 16),
        label: Text(
          _t('atendimentoTecnico.mobile.clearFilters', 'Limpar filtros'),
        ),
        onPressed: _limparFiltrosAvancados,
        backgroundColor: _surfaceColor,
        side: BorderSide(color: _borderColor),
        labelStyle: TextStyle(
          color: _accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map(
                (Widget chip) =>
                    Padding(padding: EdgeInsets.only(right: 8), child: chip),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _activeFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDeleted,
  }) {
    return InputChip(
      avatar: Icon(icon, size: 16, color: _accentColor),
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: Icon(Icons.close_rounded, size: 16),
      backgroundColor: _softAccentSurfaceColor,
      side: BorderSide(color: _highlightedBorderColor),
      labelStyle: TextStyle(
        color: _titleTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _resultSummary(int count) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            _resultadoConsultaLabel(count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: _softSurfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.sort_rounded, size: 14, color: _accentColor),
              SizedBox(width: 5),
              Text(
                _t('atendimentoTecnico.mobile.sortRecent', 'Mais recentes'),
                style: TextStyle(
                  color: _titleTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFiltrosAvancados({
    required List<AtendimentoTecnicoModel> atendimentos,
    required List<DominioOpcaoModel> statusDisponiveis,
    required List<_TecnicoFiltroOption> tecnicos,
  }) async {
    final _AtendimentosTecnicosConsulta? result =
        await showModalBottomSheet<_AtendimentosTecnicosConsulta>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Color(0x66000000),
          builder: (BuildContext context) {
            return _FiltrosAvancadosAtendimentosTecnicosMobileSheet(
              consulta: _consulta,
              tecnicos: tecnicos,
              status: _statusFiltroOptions(
                atendimentos,
                statusDisponiveis,
              ),
              permitePagamento: _permiteFiltroStatusPagamento,
              formatarData: _formatarData,
              statusPagamentoLabel: _statusPagamentoFiltroLabel,
              previewCountFor:
                  (consulta) => _previewCountForAdvancedQuery(
                    atendimentos: atendimentos,
                    statusDisponiveis: statusDisponiveis,
                    consulta: consulta,
                  ),
            );
          },
        );
    if (result == null || !mounted) return;
    _aplicarConsulta(result);
  }

  int _previewCountForAdvancedQuery({
    required List<AtendimentoTecnicoModel> atendimentos,
    required List<DominioOpcaoModel> statusDisponiveis,
    required _AtendimentosTecnicosConsulta consulta,
  }) {
    return _filtrar(
      atendimentos,
      statusDisponiveis,
      consultaOverride: consulta,
    ).length;
  }

  Widget _atendimentoCard(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final String cliente = _clienteLabel(atendimento);
    final String status = _statusLabel(atendimento, statusDisponiveis);
    final String equipamento = _equipamentoTitulo(atendimento);
    final String subtitulo = _cardSubtitle(atendimento, equipamento);
    final bool pagamentoAberto = _pagamentoEmAberto(atendimento);
    final bool entregaAtrasada = _entregaAtrasada(atendimento);
    final bool clienteNaoAssinou = _clienteNaoAssinouAtendimentoAberto(
      atendimento,
    );

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
                    cliente,
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
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  _cardMetaRow(
                    status: status,
                    pagamentoAberto: pagamentoAberto,
                    clienteNaoAssinou: clienteNaoAssinou,
                    entregaAtrasada: entregaAtrasada,
                    assinaturaAprovada: atendimento.assinaturaAprovada,
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
                        _atendimentoLeadVisual(atendimento, size: 44),
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
                  _atendimentoLeadVisual(atendimento, size: 44),
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
        icon: Icon(Icons.chevron_right_rounded, size: 22),
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

    final Widget content = Column(
      children: <Widget>[
        _detailStickyQuickActions(
          sheetContext: sheetContext,
          atendimento: atendimento,
          statusDisponiveis: statusDisponiveis,
          podeAlterarStatus: podeAlterarStatus,
          acaoEmProcessamento: acaoEmProcessamento,
          gerandoPdf: gerandoPdf,
          onCompartilharPdf: onCompartilharPdf,
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: <Widget>[
              SixStaggeredEntry(
                delay: Duration(milliseconds: 40),
                child: _detailHeaderCard(
                  sheetContext: sheetContext,
                  atendimento: atendimento,
                  equipamento: equipamento,
                  cliente: cliente,
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
              SizedBox(height: 12),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 80),
                child: _financialActionButton(
                  sheetContext: sheetContext,
                  atendimento: atendimento,
                  podeReceber: podeReceber,
                  acaoEmProcessamento: acaoEmProcessamento,
                ),
              ),
              SizedBox(height: 18),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 120),
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
                  _detailLine('Status', status),
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
                  _detailLine(
                    'Acessórios',
                    atendimento.equipamento?.acessorios,
                  ),
                  _detailLine(
                    'Observações de entrada',
                    atendimento.equipamento?.observacoesEntrada,
                  ),
                  _detailLine('Defeito relatado', atendimento.defeitoRelatado),
                  _detailLine(
                    'Diagnóstico técnico',
                    atendimento.diagnosticoTecnico,
                  ),
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
          ),
        ),
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

  Widget _detailStickyQuickActions({
    required BuildContext sheetContext,
    required AtendimentoTecnicoModel atendimento,
    required List<DominioOpcaoModel> statusDisponiveis,
    required bool podeAlterarStatus,
    required bool acaoEmProcessamento,
    required bool gerandoPdf,
    required Future<void> Function(BuildContext originContext)?
    onCompartilharPdf,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor.withValues(alpha: 0.55),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
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
          SizedBox(height: 12),
          _card(
            child: Row(
              key: const ValueKey<String>(
                'atendimento-detail-operational-actions',
              ),
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: _detailQuickActionTile(
                      key: const ValueKey<String>(
                        'atendimento-detail-public-status-share-action',
                      ),
                      label: _t(
                        'atendimentoTecnico.publicStatus.shareLinkAction',
                        'Compartilhar link',
                      ),
                      icon: Icons.link_rounded,
                      busy: _gerandoLinkStatus,
                      onPressed:
                          acaoEmProcessamento
                              ? null
                              : () => _runAfterClosingSheet(
                                sheetContext,
                                () => _compartilharStatusPublico(atendimento),
                              ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Builder(
                      builder: (BuildContext actionContext) {
                        return _detailQuickActionTile(
                          key: const ValueKey<String>(
                            'atendimento-detail-share-pdf-action',
                          ),
                          label: _t(
                            'atendimentoTecnico.mobile.sharePdfAction',
                            'Compartilhar PDF',
                          ),
                          icon: Icons.picture_as_pdf_outlined,
                          busy: gerandoPdf,
                          highlighted: true,
                          onPressed:
                              acaoEmProcessamento
                                  ? null
                                  : onCompartilharPdf == null
                                  ? null
                                  : () => onCompartilharPdf(actionContext),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _detailQuickActionTile(
                      key: const ValueKey<String>(
                        'atendimento-detail-edit-action',
                      ),
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
                ),
                Expanded(
                  child: Center(
                    child: _detailQuickActionTile(
                      key: const ValueKey<String>(
                        'atendimento-detail-change-status-action',
                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailHeaderCard({
    required BuildContext sheetContext,
    required AtendimentoTecnicoModel atendimento,
    required String equipamento,
    required String cliente,
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
              _atendimentoLeadVisual(atendimento, size: 42),
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

  Widget _financialActionButton({
    required BuildContext sheetContext,
    required AtendimentoTecnicoModel atendimento,
    required bool podeReceber,
    required bool acaoEmProcessamento,
  }) {
    final bool financeiroLiquidado =
        atendimento.operacaoLiquidada || atendimento.valorEmAberto <= 0;
    final String label =
        financeiroLiquidado
            ? _t(
              'atendimentoTecnico.mobile.paymentSettled',
              'Financeiro liquidado',
            )
            : _t('atendimento.mobile.receiveTitle', 'Receber');
    final IconData icon =
        financeiroLiquidado
            ? Icons.price_check_rounded
            : Icons.payments_outlined;

    return SizedBox(
      key: const ValueKey<String>('atendimento-detail-financial-action'),
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: podeReceber,
        label: label,
        child: _sheetActionButton(
          label: label,
          icon: icon,
          filled: podeReceber,
          onPressed:
              podeReceber && !acaoEmProcessamento
                  ? () => _runAfterClosingSheet(
                    sheetContext,
                    () => _abrirRecebimento(atendimento),
                  )
                  : null,
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
              foregroundColor: SixMobilePalette.onAccent,
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
    if (_abrindoNovoAtendimento) return;
    setState(() => _abrindoNovoAtendimento = true);
    try {
      final ProcedureFlowResult procedureResult = await _procedureCoordinator
          .execute(
            context: context,
            operationPoint: ProcedureOperationPoint.technicalServiceStartBefore,
          );
      if (!mounted || !procedureResult.shouldContinue) return;

      final AtendimentoTecnicoCreateFlowResult? result = await Navigator.of(
        context,
      ).push<AtendimentoTecnicoCreateFlowResult>(
        MaterialPageRoute<AtendimentoTecnicoCreateFlowResult>(
          builder: (_) => AtendimentoTecnicoMobileScreen(),
        ),
      );

      if (result != null && mounted) {
        await _recarregar();
        if (!mounted) return;
        _mostrarMensagem(result.feedbackMessage);
      }
    } finally {
      if (mounted) setState(() => _abrindoNovoAtendimento = false);
    }
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

  Future<_StatusSignatureGateAction?> _abrirAssinaturaStatusSheet(
    AtendimentoTecnicoModel atendimento,
    DominioOpcaoModel status,
  ) {
    final String statusLabel = _statusOptionLabel(status);
    return showModalBottomSheet<_StatusSignatureGateAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _iconBox(
                        Icons.draw_rounded,
                        size: 44,
                        backgroundColor: SixMobilePalette.error.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: SixMobilePalette.error,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _t(
                                'atendimentoTecnico.signatureGate.title',
                                'Assinatura necessária',
                              ),
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              _t(
                                'atendimentoTecnico.signatureGate.message',
                                'Para avançar para {status}, envie o link de assinatura ao cliente, assine neste dispositivo ou registre o bypass.',
                              ).replaceAll('{status}', statusLabel),
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        () => Navigator.of(
                          sheetContext,
                        ).pop(_StatusSignatureGateAction.enviarLink),
                    icon: Icon(Icons.ios_share_rounded),
                    label: Text(
                      _t(
                        'atendimentoTecnico.signatureGate.sendLink',
                        'Enviar link ao cliente',
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        () => Navigator.of(sheetContext).pop(
                          _StatusSignatureGateAction.assinarNesteDispositivo,
                        ),
                    icon: Icon(Icons.edit_note_rounded),
                    label: Text(
                      _t(
                        'atendimentoTecnico.signatureGate.signHere',
                        'Assinar neste dispositivo',
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton.icon(
                    onPressed:
                        () => Navigator.of(
                          sheetContext,
                        ).pop(_StatusSignatureGateAction.avancarSemAssinatura),
                    icon: Icon(Icons.warning_amber_rounded),
                    label: Text(
                      _t(
                        'atendimentoTecnico.signatureGate.bypass',
                        'Avançar sem assinatura',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _gerarLinkAssinaturaAtendimento(
    AtendimentoTecnicoModel atendimento,
  ) async {
    final String origin = AppConfig.publicFrontendOrigin.trim();
    if (origin.isEmpty) {
      throw Exception(
        _t(
          'atendimentoTecnico.signatureGate.publicUrlMissing',
          'URL pública do aplicativo não configurada.',
        ),
      );
    }
    final Map<String, dynamic> response = await _service.gerarLinkAssinatura(
      id: atendimento.id,
      baseUrl: '$origin/atendimento/assinatura',
    );
    final String link = response['link']?.toString().trim() ?? '';
    if (link.isEmpty) {
      throw Exception(
        _t(
          'atendimentoTecnico.signatureGate.linkMissing',
          'Link de assinatura não retornado pelo backend.',
        ),
      );
    }
    return link;
  }

  Future<void> _compartilharLinkAssinatura(
    AtendimentoTecnicoModel atendimento,
  ) async {
    if (_processandoAcao || _gerandoLinkAssinatura) return;
    setState(() {
      _processandoAcao = true;
      _gerandoLinkAssinatura = true;
    });
    try {
      final String link = await _gerarLinkAssinaturaAtendimento(atendimento);
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: link));
      await sharing.Share.share(
        <String>[
          _t(
            'atendimentoTecnico.signatureGate.shareMessage',
            'Para aprovar o atendimento, assine pelo link abaixo:',
          ),
          '${atendimento.numero} - ${_equipamentoTitulo(atendimento)}',
          link,
        ].join('\n\n'),
        subject: _t(
          'atendimentoTecnico.signatureGate.shareSubject',
          'Assinatura do atendimento',
        ),
      );
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.signatureGate.linkCopied',
          'Link de assinatura copiado.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        '${_t('atendimentoTecnico.signatureGate.linkError', 'Não foi possível gerar o link de assinatura')}: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processandoAcao = false;
          _gerandoLinkAssinatura = false;
        });
      }
    }
  }

  Future<void> _abrirAssinaturaNoDispositivo(
    AtendimentoTecnicoModel atendimento,
    DominioOpcaoModel status,
    String? observacaoStatus,
  ) async {
    if (_processandoAcao) return;
    final _AssinaturaDispositivoMobileResult? result =
        await showModalBottomSheet<_AssinaturaDispositivoMobileResult>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Color(0x66000000),
          builder: (BuildContext sheetContext) {
            return _AssinaturaDispositivoMobileSheet(
              atendimento: atendimento,
              statusLabel: _statusOptionLabel(status),
            );
          },
        );

    if (result == null || !mounted) return;
    setState(() {
      _processandoAcao = true;
    });
    try {
      await _service.assinarNoDispositivo(
        id: atendimento.id,
        status: status,
        observacaoStatus: _textoOuNulo(observacaoStatus),
        nomeAssinante: result.nomeAssinante,
        documentoAssinante: _textoOuNulo(result.documentoAssinante),
        assinaturaDataUrl: result.assinaturaDataUrl,
        observacaoAssinatura: _textoOuNulo(result.observacao),
      );
      if (!mounted) return;
      await _recarregar();
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.signatureGate.deviceSignatureSaved',
          'Assinatura registrada e status atualizado.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        '${_t('atendimentoTecnico.signatureGate.deviceSignatureError', 'Não foi possível registrar a assinatura')}: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _processandoAcao = false);
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
    bool bypassAssinatura = false;
    if (AtendimentoStatusSignaturePolicy.atendimentoPrecisaAssinaturaPara(
      atendimento: atendimento,
      status: result.status,
    )) {
      final _StatusSignatureGateAction? action =
          await _abrirAssinaturaStatusSheet(atendimento, result.status);
      if (action == null || !mounted) return;
      switch (action) {
        case _StatusSignatureGateAction.enviarLink:
          await _compartilharLinkAssinatura(atendimento);
          return;
        case _StatusSignatureGateAction.assinarNesteDispositivo:
          await _abrirAssinaturaNoDispositivo(
            atendimento,
            result.status,
            result.observacao,
          );
          return;
        case _StatusSignatureGateAction.avancarSemAssinatura:
          bypassAssinatura = true;
      }
    }

    setState(() => _processandoAcao = true);
    try {
      await _service.alterarStatus(
        id: atendimento.id,
        status: result.status,
        observacao: _textoOuNulo(result.observacao),
        bypassAssinatura: bypassAssinatura,
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
    final bool filtering = _hasAnyFilter;
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
            filtering
                ? _t(
                  'atendimentoTecnico.mobile.emptyFilteredMessage',
                  'Nenhum atendimento encontrado com os filtros selecionados.',
                )
                : _t(
                  widget.listContext.emptyMessageKey,
                  widget.listContext.emptyMessageFallback,
                ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.3),
          ),
          if (filtering) ...<Widget>[
            SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _limparConsultaCompleta,
              icon: Icon(Icons.filter_alt_off_rounded),
              label: Text(
                _t('atendimentoTecnico.mobile.clearFilters', 'Limpar filtros'),
              ),
            ),
          ],
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

  Widget _atendimentoLeadVisual(
    AtendimentoTecnicoModel atendimento, {
    double size = 44,
  }) {
    final Uint8List? imageBytes = _atendimentoPhotoBytes(atendimento);
    if (imageBytes == null) {
      return _iconBox(Icons.devices_other_outlined, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder:
            (_, _, _) => _iconBox(Icons.devices_other_outlined, size: size),
      ),
    );
  }

  Uint8List? _atendimentoPhotoBytes(AtendimentoTecnicoModel atendimento) {
    for (final AtendimentoTecnicoFotoModel foto in atendimento.fotos) {
      final Uint8List? bytes = _decodeDataUrl(foto.conteudoDataUrl);
      if (bytes != null) return bytes;
    }
    return null;
  }

  Uint8List? _decodeDataUrl(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (!trimmed.startsWith('data:image')) return null;
    final int commaIndex = trimmed.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= trimmed.length - 1) return null;
    try {
      return base64Decode(trimmed.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _cardMetaRow({
    required String status,
    required bool pagamentoAberto,
    required bool clienteNaoAssinou,
    required bool entregaAtrasada,
    required bool assinaturaAprovada,
  }) {
    final List<Widget> chips = <Widget>[
      Expanded(
        child: _chip(status, Icons.flag_outlined, compact: true, expand: true),
      ),
      SizedBox(width: 6),
      Expanded(
        child: _chip(
          pagamentoAberto ? 'Financeiro aberto' : 'Financeiro liquidado',
          pagamentoAberto
              ? Icons.account_balance_wallet_outlined
              : Icons.price_check_rounded,
          compact: true,
          expand: true,
        ),
      ),
    ];

    Widget? secondaryStateChip;
    if (clienteNaoAssinou) {
      secondaryStateChip = _alertChip(
        _t(
          'atendimentoTecnico.mobile.customerNotSigned',
          'Cliente não assinou',
        ),
        Icons.assignment_late_outlined,
        compact: true,
        expand: true,
      );
    } else if (entregaAtrasada) {
      secondaryStateChip = _alertChip(
        'Entrega atrasada',
        Icons.warning_amber_rounded,
        compact: true,
        expand: true,
      );
    } else if (assinaturaAprovada) {
      secondaryStateChip = _chip(
        'Assinado',
        Icons.verified_rounded,
        compact: true,
        expand: true,
      );
    }

    if (secondaryStateChip != null) {
      chips.addAll(<Widget>[
        SizedBox(width: 6),
        Expanded(child: secondaryStateChip),
      ]);
    }

    return Row(children: chips);
  }

  String _cardSubtitle(
    AtendimentoTecnicoModel atendimento,
    String equipamento,
  ) {
    final String numero = atendimento.numero.trim();
    final String equipamentoNormalizado = equipamento.trim();
    if (numero.isEmpty) return equipamentoNormalizado;
    if (equipamentoNormalizado.isEmpty || equipamentoNormalizado == numero) {
      return numero;
    }
    return '$numero • $equipamentoNormalizado';
  }

  Widget _detailQuickActionTile({
    Key? key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool highlighted = false,
    bool busy = false,
  }) {
    final ButtonStyle style =
        highlighted
            ? FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: SixMobilePalette.onAccent,
              padding: EdgeInsets.zero,
              minimumSize: Size(52, 52),
              fixedSize: Size(52, 52),
              shape: CircleBorder(),
            )
            : OutlinedButton.styleFrom(
              foregroundColor: _titleTextColor,
              side: BorderSide(color: _borderColor),
              backgroundColor: _softSurfaceColor,
              padding: EdgeInsets.zero,
              minimumSize: Size(52, 52),
              fixedSize: Size(52, 52),
              shape: CircleBorder(),
            );

    final Widget child =
        busy
            ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  highlighted ? SixMobilePalette.onAccent : _accentColor,
                ),
              ),
            )
            : Icon(icon, size: 20);

    final Widget button =
        highlighted
            ? FilledButton(
              key: key,
              onPressed: onPressed,
              style: style,
              child: child,
            )
            : OutlinedButton(
              key: key,
              onPressed: onPressed,
              style: style,
              child: child,
            );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Tooltip(message: label, child: button),
    );
  }

  Widget _chip(
    String label,
    IconData icon, {
    bool compact = false,
    bool expand = false,
  }) {
    return Container(
      width: expand ? double.infinity : null,
      constraints:
          expand ? null : BoxConstraints(maxWidth: compact ? 164 : 180),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 12 : 13, color: _accentColor),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertChip(
    String label,
    IconData icon, {
    bool compact = false,
    bool expand = false,
  }) {
    final Color color = SixMobilePalette.error;
    return Container(
      width: expand ? double.infinity : null,
      constraints:
          expand ? null : BoxConstraints(maxWidth: compact ? 164 : 180),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 12 : 13, color: color),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AtendimentoTecnicoModel> _filtrar(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusDisponiveis, {
    _AtendimentosTecnicosConsulta? consultaOverride,
  }) {
    final _AtendimentosTecnicosConsulta consulta =
        consultaOverride ?? _consulta;
    final String termo = consulta.busca.trim().toLowerCase();
    final DateTime? inicio =
        consulta.dataInicio == null ? null : _inicioDoDia(consulta.dataInicio!);
    final DateTime? fim =
        consulta.dataFim == null ? null : _fimDoDia(consulta.dataFim!);
    final String? tecnicoKey = consulta.tecnicoKey;
    final String? statusKey = consulta.statusKey;
    final AtendimentosCriadosStatusPagamentoFiltro statusPagamento =
        _permiteFiltroStatusPagamento
            ? consulta.statusPagamento
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
          if (statusKey != null &&
              _statusFiltroKeyAtendimento(atendimento) != statusKey) {
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

  bool _clienteNaoAssinouAtendimentoAberto(
    AtendimentoTecnicoModel atendimento,
  ) {
    if (_atendimentoFinalizadoOperacionalmente(atendimento)) {
      return false;
    }
    return !atendimento.assinaturaAprovada || atendimento.requerNovaAssinatura;
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

  String _statusOptionLabel(DominioOpcaoModel status) {
    final String fallback =
        status.nomePadraoPtBr.trim().isEmpty
            ? status.codigo.trim()
            : status.nomePadraoPtBr.trim();
    final String key = status.i18nKey.trim();
    return key.isEmpty ? fallback : _t(key, fallback);
  }

  String _resultadoConsultaLabel(int count) {
    if (count == 1) {
      return _t('atendimentoTecnico.mobile.resultCountOne', '1 atendimento');
    }
    return _t(
      'atendimentoTecnico.mobile.resultCountMany',
      '{count} atendimentos',
    ).replaceAll('{count}', count.toString());
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

  List<_StatusFiltroOption> _statusFiltroOptions(
    List<AtendimentoTecnicoModel> atendimentos,
    List<DominioOpcaoModel> statusDisponiveis,
  ) {
    final Map<String, _StatusFiltroOption> options =
        <String, _StatusFiltroOption>{};
    for (final AtendimentoTecnicoModel atendimento in atendimentos) {
      final String key = _statusFiltroKeyAtendimento(atendimento);
      final String label = _statusLabel(atendimento, statusDisponiveis);
      final _StatusFiltroOption? current = options[key];
      options[key] = _StatusFiltroOption(
        key: key,
        label: current?.label ?? label,
        count: (current?.count ?? 0) + 1,
      );
    }
    return options.values.toList(growable: false)..sort(
      (_StatusFiltroOption a, _StatusFiltroOption b) {
        final int countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      },
    );
  }

  String _tecnicoFiltroLabel(
    List<_TecnicoFiltroOption> options,
    String? selected,
  ) {
    if (selected == null) {
      return _t(
        'atendimentoTecnico.mobile.allTechnicians',
        'Todos os técnicos',
      );
    }
    for (final _TecnicoFiltroOption option in options) {
      if (option.key == selected) return option.label;
    }
    return _t(
      'atendimentoTecnico.mobile.selectedTechnician',
      'Técnico selecionado',
    );
  }

  String _statusFiltroLabel(
    List<_StatusFiltroOption> options,
    String? selected,
  ) {
    if (selected == null) {
      return _t(
        'atendimentoTecnico.filters.status.all',
        'Todos os status',
      );
    }
    for (final _StatusFiltroOption option in options) {
      if (option.key == selected) return option.label;
    }
    return _t(
      'atendimentoTecnico.filters.status.selectedFallback',
      'Status selecionado',
    );
  }

  String _periodoFiltroLabel(_AtendimentosTecnicosConsulta consulta) {
    final DateTime? inicio = consulta.dataInicio;
    final DateTime? fim = consulta.dataFim;
    if (inicio == null && fim == null) {
      return _t('atendimentoTecnico.mobile.dateAll', 'Todas as datas');
    }
    final DateTime hoje = _inicioDoDia(DateTime.now());
    if (inicio != null &&
        fim != null &&
        _inicioDoDia(inicio) == hoje &&
        _inicioDoDia(fim) == hoje) {
      return _t('atendimentoTecnico.mobile.dateToday', 'Hoje');
    }
    if (inicio != null && fim != null) {
      return _t('atendimentoTecnico.mobile.dateRange', '{start} até {end}')
          .replaceAll('{start}', _formatarData(inicio))
          .replaceAll('{end}', _formatarData(fim));
    }
    if (inicio != null) {
      return _t(
        'atendimentoTecnico.mobile.dateFrom',
        'A partir de {date}',
      ).replaceAll('{date}', _formatarData(inicio));
    }
    return _t(
      'atendimentoTecnico.mobile.dateUntil',
      'Até {date}',
    ).replaceAll('{date}', _formatarData(fim!));
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

  String? _textoOuNulo(String? value) {
    final String text = value?.trim() ?? '';
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

class _TecnicoFiltroOption {
  const _TecnicoFiltroOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _StatusFiltroOption {
  const _StatusFiltroOption({
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

class _AtendimentosTecnicosConsulta {
  const _AtendimentosTecnicosConsulta({
    this.busca = '',
    this.statusKey,
    this.dataInicio,
    this.dataFim,
    this.tecnicoKey,
    this.statusPagamento = AtendimentosCriadosStatusPagamentoFiltro.todos,
    this.page = 0,
    this.pageSize = 20,
    this.sortKey = 'dataAtualizacaoDesc',
  });

  static const Object _unset = Object();

  final String busca;
  final String? statusKey;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? tecnicoKey;
  final AtendimentosCriadosStatusPagamentoFiltro statusPagamento;
  final int page;
  final int pageSize;
  final String sortKey;

  int advancedFilterCount({required bool includePayment}) {
    int count = 0;
    if (dataInicio != null || dataFim != null) count++;
    if (tecnicoKey != null) count++;
    if (statusKey != null) count++;
    if (includePayment &&
        statusPagamento != AtendimentosCriadosStatusPagamentoFiltro.todos) {
      count++;
    }
    return count;
  }

  _AtendimentosTecnicosConsulta copyWith({
    String? busca,
    Object? statusKey = _unset,
    Object? dataInicio = _unset,
    Object? dataFim = _unset,
    Object? tecnicoKey = _unset,
    AtendimentosCriadosStatusPagamentoFiltro? statusPagamento,
    int? page,
    int? pageSize,
    String? sortKey,
  }) {
    return _AtendimentosTecnicosConsulta(
      busca: busca ?? this.busca,
      statusKey:
          identical(statusKey, _unset) ? this.statusKey : statusKey as String?,
      dataInicio:
          identical(dataInicio, _unset)
              ? this.dataInicio
              : dataInicio as DateTime?,
      dataFim: identical(dataFim, _unset) ? this.dataFim : dataFim as DateTime?,
      tecnicoKey:
          identical(tecnicoKey, _unset)
              ? this.tecnicoKey
              : tecnicoKey as String?,
      statusPagamento: statusPagamento ?? this.statusPagamento,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortKey: sortKey ?? this.sortKey,
    );
  }
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

class _FiltrosAvancadosAtendimentosTecnicosMobileSheet extends StatefulWidget {
  const _FiltrosAvancadosAtendimentosTecnicosMobileSheet({
    required this.consulta,
    required this.tecnicos,
    required this.status,
    required this.permitePagamento,
    required this.formatarData,
    required this.statusPagamentoLabel,
    required this.previewCountFor,
  });

  final _AtendimentosTecnicosConsulta consulta;
  final List<_TecnicoFiltroOption> tecnicos;
  final List<_StatusFiltroOption> status;
  final bool permitePagamento;
  final String Function(DateTime?) formatarData;
  final String Function(AtendimentosCriadosStatusPagamentoFiltro value)
  statusPagamentoLabel;
  final int Function(_AtendimentosTecnicosConsulta consulta) previewCountFor;

  @override
  State<_FiltrosAvancadosAtendimentosTecnicosMobileSheet> createState() =>
      _FiltrosAvancadosAtendimentosTecnicosMobileSheetState();
}

enum _FiltrosAvancadosAtendimentosTecnicosMobileView {
  principal,
  periodo,
  tecnico,
  status,
  pagamento,
}

class _FiltrosAvancadosAtendimentosTecnicosMobileSheetState
    extends State<_FiltrosAvancadosAtendimentosTecnicosMobileSheet> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _highlightedBorderColor =>
      SixMobilePalette.highlightedBorder;

  final TextEditingController _tecnicoSearchController =
      TextEditingController();
  late DateTime? _dataInicio = widget.consulta.dataInicio;
  late DateTime? _dataFim = widget.consulta.dataFim;
  late String? _tecnicoKey = widget.consulta.tecnicoKey;
  late String? _statusKey = widget.consulta.statusKey;
  late AtendimentosCriadosStatusPagamentoFiltro _statusPagamento =
      widget.consulta.statusPagamento;
  bool _editandoInicio = true;
  String _tecnicoSearch = '';
  _FiltrosAvancadosAtendimentosTecnicosMobileView _view =
      _FiltrosAvancadosAtendimentosTecnicosMobileView.principal;

  static const List<AtendimentosCriadosStatusPagamentoFiltro>
  _statusPagamentoOptions = <AtendimentosCriadosStatusPagamentoFiltro>[
    AtendimentosCriadosStatusPagamentoFiltro.todos,
    AtendimentosCriadosStatusPagamentoFiltro.emAberto,
    AtendimentosCriadosStatusPagamentoFiltro.liquidado,
  ];

  List<_TecnicoFiltroOption> get _tecnicosFiltrados {
    final String term = _normalize(_tecnicoSearch);
    if (term.isEmpty) return widget.tecnicos;
    return widget.tecnicos
        .where((_TecnicoFiltroOption item) {
          return _normalize(item.label).contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _tecnicoSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.56,
      maxChildSize: 0.96,
      expand: false,
      builder: (BuildContext context, ScrollController _) {
        final _AtendimentosTecnicosConsulta consulta = _temporaryConsulta();
        final int previewCount = widget.previewCountFor(consulta);
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: PopScope(
              canPop:
                  _view ==
                  _FiltrosAvancadosAtendimentosTecnicosMobileView.principal,
              onPopInvokedWithResult: (bool didPop, Object? result) {
                if (didPop) return;
                if (_view !=
                    _FiltrosAvancadosAtendimentosTecnicosMobileView.principal) {
                  _voltarPainelPrincipal();
                }
              },
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
                  SizedBox(height: 14),
                  _sheetHeader(),
                  SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 180),
                      reverseDuration: Duration(milliseconds: 140),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        final Animation<Offset> offset = Tween<Offset>(
                          begin: Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<
                          _FiltrosAvancadosAtendimentosTecnicosMobileView
                        >(_view),
                        child: _buildCurrentView(),
                      ),
                    ),
                  ),
                  if (_view ==
                      _FiltrosAvancadosAtendimentosTecnicosMobileView.principal)
                    _sheetActions(
                      consulta: consulta,
                      previewCount: previewCount,
                    )
                  else
                    SizedBox(
                      height: 14 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHeader() {
    if (_view != _FiltrosAvancadosAtendimentosTecnicosMobileView.principal) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: _t('common.back', 'Voltar'),
              onPressed: _voltarPainelPrincipal,
              icon: Icon(Icons.arrow_back_rounded),
            ),
            _sheetIcon(_currentViewIcon(), size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentViewTitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _titleTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          _sheetIcon(Icons.tune_rounded),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _t(
                'atendimentoTecnico.mobile.filterSheetTitle',
                'Filtrar atendimentos',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: _t('common.close', 'Fechar'),
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_view) {
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.principal:
        return _mainFiltersView();
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.periodo:
        return _periodSelectorView();
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.tecnico:
        return _technicianSelectorView();
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.status:
        return _statusSelectorView();
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.pagamento:
        return _paymentSelectorView();
    }
  }

  Widget _mainFiltersView() {
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
      children: <Widget>[
        _compactFilterRow(
          title: _t('atendimentoTecnico.mobile.filterPeriod', 'Período'),
          value: _periodoResumoLabel(),
          icon: Icons.event_outlined,
          onTap:
              () => _openView(
                _FiltrosAvancadosAtendimentosTecnicosMobileView.periodo,
              ),
        ),
        SizedBox(height: 10),
        _compactFilterRow(
          title: _t(
            'atendimentoTecnico.mobile.filterTechnician',
            'Técnico responsável',
          ),
          value: _tecnicoResumoLabel(),
          icon: Icons.engineering_outlined,
          onTap:
              () => _openView(
                _FiltrosAvancadosAtendimentosTecnicosMobileView.tecnico,
              ),
        ),
        SizedBox(height: 10),
        _compactFilterRow(
          title: _t('atendimentoTecnico.status', 'Status'),
          value: _statusResumoLabel(),
          icon: Icons.flag_outlined,
          onTap:
              () => _openView(
                _FiltrosAvancadosAtendimentosTecnicosMobileView.status,
              ),
        ),
        if (widget.permitePagamento) ...<Widget>[
          SizedBox(height: 10),
          _compactFilterRow(
            title: _t(
              'atendimentoTecnico.mobile.filterPaymentStatus',
              'Status do pagamento',
            ),
            value: widget.statusPagamentoLabel(_statusPagamento),
            icon: Icons.account_balance_wallet_outlined,
            onTap:
                () => _openView(
                  _FiltrosAvancadosAtendimentosTecnicosMobileView.pagamento,
                ),
          ),
        ],
      ],
    );
  }

  Widget _periodSelectorView() {
    final DateTime now = DateTime.now();
    final DateTime selected = (_editandoInicio ? _dataInicio : _dataFim) ?? now;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _dateTargetChip(
              label: _t('atendimentoTecnico.mobile.filterStartDate', 'Início'),
              value: widget.formatarData(_dataInicio),
              selected: _editandoInicio,
              onTap: () => setState(() => _editandoInicio = true),
            ),
            _dateTargetChip(
              label: _t('atendimentoTecnico.mobile.filterEndDate', 'Fim'),
              value: widget.formatarData(_dataFim),
              selected: !_editandoInicio,
              onTap: () => setState(() => _editandoInicio = false),
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _shortcutChip(
              _t('atendimentoTecnico.mobile.dateToday', 'Hoje'),
              () => _setPeriodo(now, now),
            ),
            _shortcutChip(
              _t('atendimentoTecnico.mobile.dateLast7Days', 'Últimos 7 dias'),
              () => _setPeriodo(now.subtract(Duration(days: 6)), now),
            ),
            _shortcutChip(
              _t('atendimentoTecnico.mobile.dateNext7Days', 'Próximos 7 dias'),
              () => _setPeriodo(now, now.add(Duration(days: 7))),
            ),
            _shortcutChip(
              _t('atendimentoTecnico.mobile.dateOverdue', 'Vencidos'),
              () => _setPeriodoAte(now.subtract(Duration(days: 1))),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          child: CalendarDatePicker(
            key: ValueKey<String>(
              '${_editandoInicio ? 'inicio' : 'fim'}-${selected.toIso8601String()}',
            ),
            initialDate: selected,
            firstDate: DateTime(2000),
            lastDate: DateTime(now.year + 5, 12, 31),
            onDateChanged: _selecionarData,
          ),
        ),
      ],
    );
  }

  Widget _technicianSelectorView() {
    final List<_TecnicoFiltroOption> tecnicos = _tecnicosFiltrados;
    final bool noResults = _tecnicoSearch.trim().isNotEmpty && tecnicos.isEmpty;
    final int itemCount = 1 + (noResults ? 1 : tecnicos.length);

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: _tecnicoSearchController,
            onChanged: (String value) => setState(() => _tecnicoSearch = value),
            decoration: InputDecoration(
              hintText: _t(
                'atendimentoTecnico.mobile.searchTechnician',
                'Buscar técnico',
              ),
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon:
                  _tecnicoSearchController.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: _t('common.clear', 'Limpar'),
                        icon: Icon(Icons.close_rounded),
                        onPressed: () {
                          _tecnicoSearchController.clear();
                          setState(() => _tecnicoSearch = '');
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
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: _optionTile(
                    label: _t(
                      'atendimentoTecnico.mobile.allTechnicians',
                      'Todos os técnicos',
                    ),
                    icon: Icons.groups_outlined,
                    selected: _tecnicoKey == null,
                    onTap: _selecionarTodosTecnicos,
                  ),
                );
              }

              if (noResults) {
                return _selectorEmptyState(
                  icon: Icons.search_off_rounded,
                  message: _t(
                    'atendimentoTecnico.mobile.noTechnicianFound',
                    'Nenhum técnico encontrado.',
                  ),
                );
              }

              final _TecnicoFiltroOption tecnico = tecnicos[index - 1];
              return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _optionTile(
                  label: tecnico.label,
                  icon: Icons.engineering_outlined,
                  selected: _tecnicoKey == tecnico.key,
                  onTap: () => _selecionarTecnico(tecnico.key),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _paymentSelectorView() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      itemCount: _statusPagamentoOptions.length,
      itemBuilder: (BuildContext context, int index) {
        final AtendimentosCriadosStatusPagamentoFiltro option =
            _statusPagamentoOptions[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _optionTile(
            label: widget.statusPagamentoLabel(option),
            icon: _paymentIcon(option),
            selected: _statusPagamento == option,
            onTap: () => _selecionarStatusPagamento(option),
          ),
        );
      },
    );
  }

  Widget _statusSelectorView() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      itemCount: widget.status.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _optionTile(
              label: _t(
                'atendimentoTecnico.filters.status.all',
                'Todos os status',
              ),
              icon: Icons.flag_outlined,
              selected: _statusKey == null,
              onTap: () => _selecionarStatus(null),
            ),
          );
        }

        final _StatusFiltroOption status = widget.status[index - 1];
        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _optionTile(
            label: status.label,
            count: status.count,
            icon: Icons.flag_outlined,
            selected: _statusKey == status.key,
            onTap: () => _selecionarStatus(status.key),
          ),
        );
      },
    );
  }

  Widget _sheetActions({
    required _AtendimentosTecnicosConsulta consulta,
    required int previewCount,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        8,
        18,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: _limparTemporarios,
              child: Text(_t('common.clear', 'Limpar')),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(consulta),
              icon: Icon(Icons.check_rounded),
              label: Text(_verAtendimentosLabel(previewCount)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactFilterRow({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title, $value',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: <Widget>[
                _sheetIcon(icon, size: 40),
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
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.22,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _mutedTextColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          _sheetIcon(icon, size: 36),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currentViewTitle() {
    switch (_view) {
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.principal:
        return _t(
          'atendimentoTecnico.mobile.filterSheetTitle',
          'Filtrar atendimentos',
        );
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.periodo:
        return _t('atendimentoTecnico.mobile.filterPeriod', 'Período');
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.tecnico:
        return _t(
          'atendimentoTecnico.mobile.filterTechnician',
          'Técnico responsável',
        );
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.status:
        return _t('atendimentoTecnico.status', 'Status');
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.pagamento:
        return _t(
          'atendimentoTecnico.mobile.filterPaymentStatus',
          'Status do pagamento',
        );
    }
  }

  IconData _currentViewIcon() {
    switch (_view) {
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.principal:
        return Icons.tune_rounded;
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.periodo:
        return Icons.event_outlined;
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.tecnico:
        return Icons.engineering_outlined;
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.status:
        return Icons.flag_outlined;
      case _FiltrosAvancadosAtendimentosTecnicosMobileView.pagamento:
        return Icons.account_balance_wallet_outlined;
    }
  }

  void _openView(_FiltrosAvancadosAtendimentosTecnicosMobileView view) {
    setState(() => _view = view);
  }

  void _voltarPainelPrincipal() {
    setState(
      () => _view = _FiltrosAvancadosAtendimentosTecnicosMobileView.principal,
    );
  }

  void _selecionarTodosTecnicos() {
    setState(() {
      _tecnicoKey = null;
      _tecnicoSearch = '';
      _tecnicoSearchController.clear();
      _view = _FiltrosAvancadosAtendimentosTecnicosMobileView.principal;
    });
  }

  void _selecionarTecnico(String key) {
    setState(() {
      _tecnicoKey = key;
      _tecnicoSearch = '';
      _tecnicoSearchController.clear();
      _view = _FiltrosAvancadosAtendimentosTecnicosMobileView.principal;
    });
  }

  void _selecionarStatus(String? key) {
    setState(() {
      _statusKey = key;
      _view = _FiltrosAvancadosAtendimentosTecnicosMobileView.principal;
    });
  }

  void _selecionarStatusPagamento(
    AtendimentosCriadosStatusPagamentoFiltro value,
  ) {
    setState(() {
      _statusPagamento = value;
      _view = _FiltrosAvancadosAtendimentosTecnicosMobileView.principal;
    });
  }

  String _periodoResumoLabel() {
    final DateTime? inicio = _dataInicio;
    final DateTime? fim = _dataFim;
    if (inicio == null && fim == null) {
      return _t('atendimentoTecnico.mobile.dateAll', 'Todas as datas');
    }

    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime ultimos7Inicio = hoje.subtract(Duration(days: 6));
    final DateTime proximos7Fim = hoje.add(Duration(days: 7));
    final DateTime vencidosFim = hoje.subtract(Duration(days: 1));

    if (inicio != null && fim != null) {
      final DateTime inicioDia = _inicioDoDia(inicio);
      final DateTime fimDia = _inicioDoDia(fim);
      if (inicioDia == hoje && fimDia == hoje) {
        return _t('atendimentoTecnico.mobile.dateToday', 'Hoje');
      }
      if (inicioDia == ultimos7Inicio && fimDia == hoje) {
        return _t('atendimentoTecnico.mobile.dateLast7Days', 'Últimos 7 dias');
      }
      if (inicioDia == hoje && fimDia == proximos7Fim) {
        return _t('atendimentoTecnico.mobile.dateNext7Days', 'Próximos 7 dias');
      }
      return _t('atendimentoTecnico.mobile.dateRange', '{start} até {end}')
          .replaceAll('{start}', widget.formatarData(inicio))
          .replaceAll('{end}', widget.formatarData(fim));
    }

    if (inicio == null && fim != null && _inicioDoDia(fim) == vencidosFim) {
      return _t('atendimentoTecnico.mobile.dateOverdue', 'Vencidos');
    }

    if (inicio != null) {
      return _t(
        'atendimentoTecnico.mobile.dateFrom',
        'A partir de {date}',
      ).replaceAll('{date}', widget.formatarData(inicio));
    }
    return _t(
      'atendimentoTecnico.mobile.dateUntil',
      'Até {date}',
    ).replaceAll('{date}', widget.formatarData(fim));
  }

  String _tecnicoResumoLabel() {
    if (_tecnicoKey == null) {
      return _t(
        'atendimentoTecnico.mobile.allTechnicians',
        'Todos os técnicos',
      );
    }
    for (final _TecnicoFiltroOption tecnico in widget.tecnicos) {
      if (tecnico.key == _tecnicoKey) return tecnico.label;
    }
    return _t(
      'atendimentoTecnico.mobile.selectedTechnician',
      'Técnico selecionado',
    );
  }

  String _statusResumoLabel() {
    if (_statusKey == null) {
      return _t(
        'atendimentoTecnico.filters.status.all',
        'Todos os status',
      );
    }
    for (final _StatusFiltroOption status in widget.status) {
      if (status.key == _statusKey) return status.label;
    }
    return _t(
      'atendimentoTecnico.filters.status.selectedFallback',
      'Status selecionado',
    );
  }

  DateTime _inicioDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _optionTile({
    required String label,
    int? count,
    required IconData icon,
    required bool selected,
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
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected
                    ? SixMobilePalette.softAccentSurface
                    : SixMobilePalette.softNeutralSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _highlightedBorderColor : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              _sheetIcon(icon, size: 36),
              SizedBox(width: 10),
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
              if (count != null) ...<Widget>[
                SizedBox(width: 8),
                Container(
                  constraints: BoxConstraints(minWidth: 28),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
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

  Widget _sheetIcon(IconData icon, {double size = 42}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, color: _accentColor, size: size * 0.52),
    );
  }

  void _selecionarData(DateTime value) {
    final DateTime normalized = DateTime(value.year, value.month, value.day);
    setState(() {
      if (_editandoInicio) {
        _dataInicio = normalized;
        if (_dataFim != null && _dataFim!.isBefore(normalized)) {
          _dataFim = normalized;
        }
      } else {
        _dataFim = normalized;
        if (_dataInicio != null && _dataInicio!.isAfter(normalized)) {
          _dataInicio = normalized;
        }
      }
    });
  }

  void _setPeriodo(DateTime inicio, DateTime fim) {
    setState(() {
      _dataInicio = DateTime(inicio.year, inicio.month, inicio.day);
      _dataFim = DateTime(fim.year, fim.month, fim.day);
    });
  }

  void _setPeriodoAte(DateTime fim) {
    setState(() {
      _dataInicio = null;
      _dataFim = DateTime(fim.year, fim.month, fim.day);
      _editandoInicio = false;
    });
  }

  void _limparTemporarios() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _tecnicoKey = null;
      _statusKey = null;
      _statusPagamento = AtendimentosCriadosStatusPagamentoFiltro.todos;
      _tecnicoSearch = '';
      _tecnicoSearchController.clear();
      _view = _FiltrosAvancadosAtendimentosTecnicosMobileView.principal;
    });
  }

  _AtendimentosTecnicosConsulta _temporaryConsulta() {
    return widget.consulta.copyWith(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      tecnicoKey: _tecnicoKey,
      statusKey: _statusKey,
      statusPagamento:
          widget.permitePagamento
              ? _statusPagamento
              : AtendimentosCriadosStatusPagamentoFiltro.todos,
    );
  }

  String _verAtendimentosLabel(int count) {
    if (count == 1) {
      return _t(
        'atendimentoTecnico.mobile.viewOneService',
        'Ver 1 atendimento',
      );
    }
    return _t(
      'atendimentoTecnico.mobile.viewManyServices',
      'Ver {count} atendimentos',
    ).replaceAll('{count}', count.toString());
  }

  IconData _paymentIcon(AtendimentosCriadosStatusPagamentoFiltro value) {
    switch (value) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return Icons.receipt_long_outlined;
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return Icons.account_balance_wallet_outlined;
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return Icons.price_check_rounded;
    }
  }

  String _t(String key, String fallback) {
    return context.t(key, fallback: fallback);
  }

  String _normalize(String value) {
    String normalized = value.toLowerCase();
    const Map<String, String> replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    for (final MapEntry<String, String> entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
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

enum _StatusSignatureGateAction {
  enviarLink,
  assinarNesteDispositivo,
  avancarSemAssinatura,
}

class _AssinaturaDispositivoMobileResult {
  const _AssinaturaDispositivoMobileResult({
    required this.nomeAssinante,
    required this.documentoAssinante,
    required this.assinaturaDataUrl,
    required this.observacao,
  });

  final String nomeAssinante;
  final String documentoAssinante;
  final String assinaturaDataUrl;
  final String observacao;
}

class _AssinaturaDispositivoMobileSheet extends StatefulWidget {
  const _AssinaturaDispositivoMobileSheet({
    required this.atendimento,
    required this.statusLabel,
  });

  final AtendimentoTecnicoModel atendimento;
  final String statusLabel;

  @override
  State<_AssinaturaDispositivoMobileSheet> createState() =>
      _AssinaturaDispositivoMobileSheetState();
}

class _AssinaturaDispositivoMobileSheetState
    extends State<_AssinaturaDispositivoMobileSheet> {
  late final TextEditingController _nomeController;
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  late final SignatureController _signatureController;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final String cliente = widget.atendimento.nomeClienteSnapshot?.trim() ?? '';
    _nomeController = TextEditingController(text: cliente);
    _signatureController = SignatureController(
      penStrokeWidth: 2.6,
      penColor: SixMobilePalette.titleText,
      exportBackgroundColor: SixMobilePalette.surface,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _observacaoController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final String nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() {
        _erro = context.t(
          'atendimentoTecnico.signatureGate.deviceSignerRequired',
          fallback: 'Informe o nome de quem está assinando.',
        );
      });
      return;
    }
    if (_signatureController.isEmpty) {
      setState(() {
        _erro = context.t(
          'atendimentoTecnico.signatureGate.deviceSignatureRequired',
          fallback: 'Faça a assinatura no quadro indicado.',
        );
      });
      return;
    }

    final String assinaturaDataUrl = _assinaturaSvgDataUrl(
      _signatureController,
      SixMobilePalette.surface,
      SixMobilePalette.titleText,
    );
    if (assinaturaDataUrl.isEmpty) {
      setState(() {
        _erro = context.t(
          'atendimentoTecnico.signatureGate.deviceSignatureRequired',
          fallback: 'Faça a assinatura no quadro indicado.',
        );
      });
      return;
    }
    Navigator.of(context).pop(
      _AssinaturaDispositivoMobileResult(
        nomeAssinante: nome,
        documentoAssinante: _documentoController.text.trim(),
        assinaturaDataUrl: assinaturaDataUrl,
        observacao: _observacaoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: SixMobilePalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: SixMobilePalette.softAccentSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.draw_rounded,
                        color: SixMobilePalette.accent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.t(
                              'atendimentoTecnico.signatureGate.deviceTitle',
                              fallback: 'Coletar assinatura',
                            ),
                            style: TextStyle(
                              color: SixMobilePalette.titleText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            context
                                .t(
                                  'atendimentoTecnico.signatureGate.deviceMessage',
                                  fallback:
                                      'Registre a assinatura para avançar para {status}.',
                                )
                                .replaceAll('{status}', widget.statusLabel),
                            style: TextStyle(
                              color: SixMobilePalette.mutedText,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
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
                TextField(
                  controller: _nomeController,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    context.t(
                      'atendimentoTecnico.signatureGate.deviceSigner',
                      fallback: 'Nome de quem assina',
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _documentoController,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    context.t(
                      'atendimentoTecnico.signatureGate.deviceDocument',
                      fallback: 'Documento opcional',
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  context.t(
                    'atendimentoTecnico.signatureGate.deviceSignatureField',
                    fallback: 'Assinatura',
                  ),
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SixMobilePalette.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: SixMobilePalette.surface,
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _signatureController.clear();
                      setState(() => _erro = null);
                    },
                    icon: Icon(Icons.cleaning_services_rounded),
                    label: Text(context.t('common.clear', fallback: 'Limpar')),
                  ),
                ),
                TextField(
                  controller: _observacaoController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _decoration(
                    context.t(
                      'atendimentoTecnico.signatureGate.deviceObservation',
                      fallback: 'Observação opcional',
                    ),
                  ),
                ),
                if (_erro != null) ...<Widget>[
                  SizedBox(height: 10),
                  Text(
                    _erro!,
                    style: TextStyle(
                      color: SixMobilePalette.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                SizedBox(height: 16),
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
                      child: FilledButton.icon(
                        onPressed: _confirmar,
                        icon: Icon(Icons.check_rounded),
                        label: Text(
                          context.t(
                            'atendimentoTecnico.signatureGate.deviceSave',
                            fallback: 'Registrar assinatura',
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

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: SixMobilePalette.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: SixMobilePalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: SixMobilePalette.accent, width: 1.4),
      ),
    );
  }
}

String _assinaturaSvgDataUrl(
  SignatureController controller,
  Color backgroundColor,
  Color penColor,
) {
  if (controller.isEmpty) return '';

  final double minX = controller.minXValue ?? 0;
  final double minY = controller.minYValue ?? 0;
  final double stroke = controller.penStrokeWidth;
  final int width =
      ((controller.maxXValue ?? minX) - minX + stroke * 2)
          .ceil()
          .clamp(1, 4096)
          .toInt();
  final int height =
      ((controller.maxYValue ?? minY) - minY + stroke * 2)
          .ceil()
          .clamp(1, 4096)
          .toInt();
  final String points = controller.points
      .map((Point point) {
        final double dx = point.offset.dx - minX + stroke;
        final double dy = point.offset.dy - minY + stroke;
        return '${dx.toStringAsFixed(2)},${dy.toStringAsFixed(2)}';
      })
      .join(' ');

  if (points.trim().isEmpty) return '';

  final String svg =
      '<svg viewBox="0 0 $width $height" width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">'
      '<rect width="100%" height="100%" fill="${_svgColor(backgroundColor)}"/>'
      '<polyline fill="none" stroke="${_svgColor(penColor)}" stroke-linecap="round" stroke-linejoin="round" stroke-width="${stroke.toStringAsFixed(2)}" points="$points"/>'
      '</svg>';
  return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
}

String _svgColor(Color color) {
  return '#${_svgColorChannel(color.r).toRadixString(16).padLeft(2, '0')}'
      '${_svgColorChannel(color.g).toRadixString(16).padLeft(2, '0')}'
      '${_svgColorChannel(color.b).toRadixString(16).padLeft(2, '0')}';
}

int _svgColorChannel(double value) {
  return (value * 255).round().clamp(0, 255).toInt();
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
