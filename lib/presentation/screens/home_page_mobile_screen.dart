import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/admin_portal_service.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/empresa_service.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/colaborador_convite_model.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/models/dashboard_inicio_model.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/pagina_principal_web.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/ai_assistant/ai_assistant_host.dart';
import 'package:sixpos/presentation/components/mobile/collaborator_operational_home_dashboard.dart';
import 'package:sixpos/presentation/components/mobile/collaborator_performance_home_dashboard.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_account_panel_action.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_selection_sheet.dart';
import 'package:sixpos/presentation/navigation/mobile_navigation_controller.dart';
import 'package:sixpos/presentation/screens/chat_suporte_mobile_screen.dart';
import 'package:sixpos/presentation/screens/chat_suporte_web_page.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/utils/profile_image_payload.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/colaborador_home_operacional_provider.dart';
import 'package:sixpos/providers/dashboard_inicio_provider.dart';
import 'package:sixpos/providers/desempenho_colaborador_home_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

import '../components/nav_bar_mobile.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({
    super.key,
    required this.title,
    this.desempenhoProvider,
    this.operacionalProvider,
  });

  final String title;
  final DesempenhoColaboradorHomeProvider? desempenhoProvider;
  final ColaboradorHomeOperacionalProvider? operacionalProvider;

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _InfrastructureRequestsFilterSelection {
  const _InfrastructureRequestsFilterSelection({
    required this.value,
    required this.unit,
  });

  final int value;
  final AdminRequestWindowUnit unit;
}

class _HomePageMobileState extends State<HomePageMobile> {
  static const String _allCompaniesFilterValue = '__all_companies__';
  static const String _allCollaboratorsFilterValue = '__all_collaborators__';
  static const double _profileAvatarFadeDistance = 96;
  static const double _profileAvatarFadeStart = 0.10;
  static const int _defaultInfrastructureRequestsWindowValue = 15;
  static const Duration _profileAvatarFadeDuration = Duration(
    milliseconds: 180,
  );

  // Formatters
  final NumberFormat _compactFmt = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 1,
  );
  final DateFormat _dateFmt = DateFormat('dd/MM', 'pt_BR');

  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final EmpresaService _empresaService = EmpresaService();
  final ColaboradorUsuarioApiClient _colaboradorApiClient =
      HttpColaboradorUsuarioApiClient();
  final NotificacaoService _notificacaoService = NotificacaoService();
  final UsuarioService _usuarioService = UsuarioService();
  final DashboardInicioProvider _dashboardProvider = DashboardInicioProvider(
    initialPeriod: DashboardPeriod.last30Days,
  );
  late final DesempenhoColaboradorHomeProvider _desempenhoProvider;
  late final bool _ownsDesempenhoProvider;
  late final ColaboradorHomeOperacionalProvider _operacionalProvider;
  late final bool _ownsOperacionalProvider;
  final AdminPortalService _adminPortalService = AdminPortalService();
  final EmpresaProvider _empresaProvider = EmpresaProvider();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final ScrollController _homeScrollController = ScrollController();
  final ValueNotifier<double> _profileAvatarScrollProgress =
      ValueNotifier<double>(0);

  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _backgroundColor => _colors.background;
  Color get _primaryColor => _colors.primary;
  Color get _secondaryColor => _colors.secondary;
  Color get _accentColor => _colors.accent;
  Color get _surfaceColor => _colors.surface;
  Color get _mutedTextColor => _colors.mutedText;
  Color get _titleTextColor => _colors.titleText;
  Color get _borderColor => _colors.border;
  Color get _softSurface => _colors.softSurface;
  bool _salvandoFotoPerfil = false;
  bool _sincronizandoPerfilInicial = false;
  bool _carregandoTrocaDeComercio = false;
  bool _carregandoFiltroDeComercio = false;
  bool _carregandoFiltroDeColaborador = false;
  bool _podeFiltrarComercios = false;
  String? _fotoPerfilSincronizada;
  AdminPortalResumo? _resumoInfraestrutura;
  String? _erroInfraestrutura;
  bool _carregandoInfraestrutura = false;
  bool _tentouCarregarInfraestrutura = false;
  int _infrastructureRequestsWindowValue =
      _defaultInfrastructureRequestsWindowValue;
  AdminRequestWindowUnit _infrastructureRequestsWindowUnit =
      AdminRequestWindowUnit.minutes;
  bool _tentouCarregarDesempenho = false;
  String _comercioSelecionadoNoFiltro = _allCompaniesFilterValue;
  String? _colaboradorSelecionadoNoFiltro;
  List<EmpresaVinculoWebModel> _comerciosDisponiveis =
      const <EmpresaVinculoWebModel>[];
  List<ColaboradorUsuarioResumo> _colaboradoresDisponiveis =
      const <ColaboradorUsuarioResumo>[];

  @override
  void initState() {
    super.initState();
    _ownsDesempenhoProvider = widget.desempenhoProvider == null;
    _desempenhoProvider =
        widget.desempenhoProvider ?? DesempenhoColaboradorHomeProvider();
    _ownsOperacionalProvider = widget.operacionalProvider == null;
    _operacionalProvider =
        widget.operacionalProvider ?? ColaboradorHomeOperacionalProvider();
    _notificacaoService.addListener(_onNotificacoesChanged);
    _dashboardProvider.addListener(_onDashboardChanged);
    _desempenhoProvider.addListener(_onDesempenhoChanged);
    _operacionalProvider.addListener(_onOperacionalChanged);
    _empresaProvider.addListener(_onEmpresaChanged);
    _usuarioProvider.addListener(_onUsuarioChanged);
    _homeScrollController.addListener(_onHomeScrollChanged);
    _carregarContextoDoFiltroDeComercio();
    if (!kIsWeb) {
      _configurarWebSocketMobile();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sincronizarPerfilInicial();
      });
    }
  }

  @override
  void dispose() {
    _notificacaoService.removeListener(_onNotificacoesChanged);
    _dashboardProvider.removeListener(_onDashboardChanged);
    _desempenhoProvider.removeListener(_onDesempenhoChanged);
    _operacionalProvider.removeListener(_onOperacionalChanged);
    _empresaProvider.removeListener(_onEmpresaChanged);
    _usuarioProvider.removeListener(_onUsuarioChanged);
    _homeScrollController.removeListener(_onHomeScrollChanged);
    _homeScrollController.dispose();
    _profileAvatarScrollProgress.dispose();
    _dashboardProvider.dispose();
    if (_ownsDesempenhoProvider) {
      _desempenhoProvider.dispose();
    }
    if (_ownsOperacionalProvider) {
      _operacionalProvider.dispose();
    }
    if (!kIsWeb) {
      onMensagemRecebida = null;
      onStompConectado = null;
      onStompDesconectado = null;
      onStompErro = null;
      disconnectStomp();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.read<ColaboradorAutorizacoesProvider>();
    final bool ehSuper = autorizacoes.ehSuperUsuario;
    if (ehSuper && !_tentouCarregarInfraestrutura) {
      _tentouCarregarInfraestrutura = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _carregarInfraestrutura();
        }
      });
    }
    if (autorizacoes.ehColaborador && !_tentouCarregarDesempenho) {
      _tentouCarregarDesempenho = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_desempenhoProvider.load());
        }
      });
    }
    if (!kIsWeb) {
      _scheduleOperationalLoad(autorizacoes);
    }
  }

  void _onHomeScrollChanged() {
    final double scrollOffset =
        _homeScrollController.hasClients ? _homeScrollController.offset : 0;
    final double rawProgress =
        (scrollOffset / _profileAvatarFadeDistance).clamp(0.0, 1.0).toDouble();
    final double progress =
        ((rawProgress - _profileAvatarFadeStart) /
                (1 - _profileAvatarFadeStart))
            .clamp(0.0, 1.0)
            .toDouble();

    if ((_profileAvatarScrollProgress.value - progress).abs() < 0.02 &&
        progress != 0 &&
        progress != 1) {
      return;
    }

    _profileAvatarScrollProgress.value = progress;
  }

  void _onNotificacoesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onDashboardChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onDesempenhoChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onOperacionalChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _scheduleOperationalLoad(ColaboradorAutorizacoesProvider autorizacoes) {
    final bool canAccessSales =
        autorizacoes.ehColaborador && autorizacoes.podeVerQuantoVendeu;
    final bool canAccessServices =
        autorizacoes.ehColaborador &&
        autorizacoes.podeAcompanharAssistenciaTecnica;
    final bool canAccessReservations =
        autorizacoes.ehColaborador && autorizacoes.podeFazerVenda;
    if ((!canAccessSales && !canAccessServices && !canAccessReservations) ||
        _operacionalProvider.loading ||
        !_operacionalProvider.needsLoad(
          canAccessSales: canAccessSales,
          canAccessServices: canAccessServices,
          canAccessReservations: canAccessReservations,
        )) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _operacionalProvider.loading) return;
      unawaited(
        _operacionalProvider.load(
          canAccessSales: canAccessSales,
          canAccessServices: canAccessServices,
          canAccessReservations: canAccessReservations,
        ),
      );
    });
  }

  Future<void> _reloadOperational(
    ColaboradorAutorizacoesProvider autorizacoes,
  ) {
    final bool canAccessSales =
        autorizacoes.ehColaborador && autorizacoes.podeVerQuantoVendeu;
    final bool canAccessServices =
        autorizacoes.ehColaborador &&
        autorizacoes.podeAcompanharAssistenciaTecnica;
    return _operacionalProvider.reload(
      canAccessSales: canAccessSales,
      canAccessServices: canAccessServices,
      canAccessReservations:
          autorizacoes.ehColaborador && autorizacoes.podeFazerVenda,
    );
  }

  void _onEmpresaChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onUsuarioChanged() {
    if (!mounted) return;
    final String foto = _usuarioProvider.usuario?.foto.trim() ?? '';
    if (foto.isEmpty) {
      return;
    }

    setState(() => _fotoPerfilSincronizada = foto);
  }

  void _configurarWebSocketMobile() {
    onMensagemRecebida = null;

    onStompErro = (Object error) {
      debugPrint('[HomePageMobile] Erro no WebSocket: $error');
    };

    connectStomp();
  }

  Future<void> _carregarContextoDoFiltroDeComercio() async {
    try {
      final bool podeFiltrarComercios =
          context.read<ColaboradorAutorizacoesProvider>().ehAdministrador;
      final String empresaAtual =
          (await _authService.getEmpresaId())?.trim() ?? '';
      if (!mounted) {
        return;
      }

      setState(() {
        _podeFiltrarComercios = podeFiltrarComercios;
        _comercioSelecionadoNoFiltro =
            empresaAtual.isEmpty ? _allCompaniesFilterValue : empresaAtual;
      });
    } catch (error) {
      debugPrint(
        '[HomePageMobile] Falha ao carregar contexto do filtro de comércio: $error',
      );
    }
  }

  Future<void> _garantirComerciosDoUsuarioCarregados() async {
    if (_carregandoFiltroDeComercio || _comerciosDisponiveis.isNotEmpty) {
      return;
    }

    setState(() => _carregandoFiltroDeComercio = true);
    try {
      final List<EmpresaVinculoWebModel> vinculos =
          await _usuarioService.listarEmpresasVinculadas();
      final Map<String, EmpresaVinculoWebModel> ativosPorId =
          <String, EmpresaVinculoWebModel>{};

      for (final EmpresaVinculoWebModel vinculo in vinculos) {
        final String id = vinculo.idUnicoDaEmpresa.trim();
        if (id.isEmpty || !vinculo.ativo) {
          continue;
        }
        ativosPorId[id] = vinculo;
      }

      final List<EmpresaVinculoWebModel> comercios = ativosPorId.values.toList(
        growable: false,
      )..sort((EmpresaVinculoWebModel a, EmpresaVinculoWebModel b) {
        return _rotuloDoComercio(
          a,
        ).toLowerCase().compareTo(_rotuloDoComercio(b).toLowerCase());
      });

      if (!mounted) {
        return;
      }

      setState(() => _comerciosDisponiveis = comercios);
    } finally {
      if (mounted) {
        setState(() => _carregandoFiltroDeComercio = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.read<ColaboradorAutorizacoesProvider>();

    await Future.wait<void>(<Future<void>>[
      _atualizarDadosPessoaisNoRefresh(),
      autorizacoes.carregarAutorizacoesDoUsuarioLogado(force: true),
    ]);

    if (!mounted) {
      return;
    }

    await _carregarContextoDoFiltroDeComercio();

    final bool canAccessSales =
        autorizacoes.ehColaborador && autorizacoes.podeVerQuantoVendeu;
    final bool canAccessServices =
        autorizacoes.ehColaborador &&
        autorizacoes.podeAcompanharAssistenciaTecnica;
    final bool canAccessReservations =
        autorizacoes.ehColaborador && autorizacoes.podeFazerVenda;
    final bool podeCarregarPainelOperacional =
        canAccessSales || canAccessServices || canAccessReservations;

    final List<Future<void>> tasks = <Future<void>>[];
    if (autorizacoes.ehAdministrador) {
      tasks.add(_dashboardProvider.reload());
    }
    if (autorizacoes.ehColaborador) {
      tasks.add(_desempenhoProvider.reload());
      if (podeCarregarPainelOperacional) {
        tasks.add(_reloadOperational(autorizacoes));
      }
    }
    if (autorizacoes.ehSuperUsuario) {
      tasks.add(_carregarInfraestrutura());
    }
    await Future.wait(tasks);
  }

  Future<void> _carregarInfraestrutura() async {
    if (_carregandoInfraestrutura) {
      return;
    }

    if (mounted) {
      setState(() {
        _carregandoInfraestrutura = true;
        _erroInfraestrutura = null;
      });
    } else {
      _carregandoInfraestrutura = true;
      _erroInfraestrutura = null;
    }

    try {
      final AdminPortalResumo resumo = await _adminPortalService.buscarResumo(
        janelaValor: _infrastructureRequestsWindowValue,
        janelaUnidade: _infrastructureRequestsWindowUnit,
      );
      void applyResumo() {
        _resumoInfraestrutura = resumo;
        final AdminRequestStatusResumo? requestsHttp = resumo.requestsHttp;
        if (requestsHttp != null) {
          _infrastructureRequestsWindowValue =
              requestsHttp.janelaValor > 0
                  ? requestsHttp.janelaValor
                  : _infrastructureRequestsWindowValue;
          _infrastructureRequestsWindowUnit = requestsHttp.janelaUnidade;
        }
      }

      if (!mounted) {
        applyResumo();
        return;
      }
      setState(applyResumo);
    } catch (error) {
      final String mensagem = error.toString().replaceAll('Exception: ', '');
      if (!mounted) {
        _erroInfraestrutura = mensagem;
        return;
      }
      setState(() => _erroInfraestrutura = mensagem);
    } finally {
      if (mounted) {
        setState(() => _carregandoInfraestrutura = false);
      } else {
        _carregandoInfraestrutura = false;
      }
    }
  }

  Future<void> _atualizarDadosPessoaisNoRefresh() async {
    try {
      await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      final String foto = _usuarioProvider.usuario?.foto.trim() ?? '';
      if (mounted) {
        setState(() {
          if (foto.isNotEmpty) {
            _fotoPerfilSincronizada = foto;
          }
        });
      }
    } catch (error) {
      debugPrint(
        '[HomePageMobile] Falha ao atualizar dados pessoais no refresh: $error',
      );
    }
  }

  Future<void> _sincronizarPerfilInicial() async {
    if (_sincronizandoPerfilInicial) {
      return;
    }

    if (mounted) {
      setState(() => _sincronizandoPerfilInicial = true);
    } else {
      _sincronizandoPerfilInicial = true;
    }
    try {
      await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      final String foto = _usuarioProvider.usuario?.foto.trim() ?? '';
      if (mounted) {
        setState(() {
          if (foto.isNotEmpty) {
            _fotoPerfilSincronizada = foto;
          }
        });
      } else {
        if (foto.isNotEmpty) {
          _fotoPerfilSincronizada = foto;
        }
      }
    } catch (error) {
      debugPrint(
        '[HomePageMobile] Falha ao sincronizar perfil inicial: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _sincronizandoPerfilInicial = false);
      } else {
        _sincronizandoPerfilInicial = false;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_salvandoFotoPerfil) {
      return;
    }

    final XFile? selected = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (selected == null) {
      return;
    }

    setState(() => _salvandoFotoPerfil = true);
    try {
      final String imageDataUrl = await buildProfileImageDataUrl(selected);
      await _usuarioService.atualizarFotoDoUsuario(imageDataUrl);
      if (mounted) {
        setState(() => _fotoPerfilSincronizada = imageDataUrl);
      } else {
        _fotoPerfilSincronizada = imageDataUrl;
      }
    } catch (error) {
      debugPrint('[HomePageMobile] Falha ao atualizar foto do perfil: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'perfil.mobile.photoSaveError',
              fallback:
                  'Não foi possível atualizar a foto do perfil. Tente novamente.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoFotoPerfil = false);
      }
    }
  }

  void _abrirChatSuporte() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) =>
                kIsWeb
                    ? const ChatSuporteWebPage()
                    : const ChatSuporteMobileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.watch<ColaboradorAutorizacoesProvider>();
    final bool podeAcessarSuporte =
        autorizacoes.ehSuperUsuario ||
        autorizacoes.ehAdministrador ||
        autorizacoes.ehColaborador;
    if (kIsWeb) {
      return AiAssistantHost(
        modulo: 'geral',
        telaAtual: 'inicio_web',
        onOpenSupport:
            podeAcessarSuporte && autorizacoes.ehSuperUsuario
                ? _abrirChatSuporte
                : null,
        supportContentBuilder:
            podeAcessarSuporte && !autorizacoes.ehSuperUsuario
                ? (_) => const ChatSuporteWebPage(embedded: true)
                : null,
        child: PaginaPrincipalWeb(),
      );
    }

    return AiAssistantHost(
      modulo: 'geral',
      telaAtual: 'inicio_mobile',
      onOpenSupport: podeAcessarSuporte ? _abrirChatSuporte : null,
      child: SixMobilePageShell(
        title: context.t('mobile.nav.home'),
        backgroundColor: _backgroundColor,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        accentColor: _accentColor,
        automaticallyImplyLeading: false,
        scrollController: _homeScrollController,
        leading: _buildAppBarProfileAction(context),
        actions: [
          if (_podeFiltrarComercios)
            IconButton(
              tooltip: _tooltipFiltroDeComercio(context),
              onPressed:
                  _carregandoTrocaDeComercio || _carregandoFiltroDeComercio
                      ? null
                      : _abrirFiltroDeComercios,
              icon: _buildCompanyFilterIcon(),
            ),
          IconButton(
            tooltip: context.t(
              'gestao.settings.item.notifications.title',
              fallback: 'Notificações',
            ),
            icon: _buildNotificationIcon(),
            onPressed: () => _openNotifications(context),
          ),
          SizedBox(width: 6),
        ],
        bodyBuilder: _buildHomeContent,
        bottomNavigationBar:
            kIsWeb
                ? null
                : NavBarMobile(
                  initialIndex: MobileNavigationController.dashIndex,
                ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final DashboardInicioModel data = _dashboardProvider.data;
    final bool loading = _dashboardProvider.isLoading;
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.watch<ColaboradorAutorizacoesProvider>();
    final bool ehSuper = autorizacoes.ehSuperUsuario;
    final bool ehAdmin = autorizacoes.ehAdministrador;
    final bool ehColaborador = autorizacoes.ehColaborador;
    final bool canAccessSales =
        ehColaborador && autorizacoes.podeVerQuantoVendeu;
    final bool canAccessServices =
        ehColaborador && autorizacoes.podeAcompanharAssistenciaTecnica;
    final bool canAccessReservations =
        ehColaborador && autorizacoes.podeFazerVenda;
    final bool hasOperationalAccess =
        canAccessSales || canAccessServices || canAccessReservations;

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
          children: [
            SixStaggeredEntry(
              delay: Duration(milliseconds: 40),
              child: _buildGreetingHeader(context),
            ),
            if (ehSuper) ...[
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 80),
                child: _buildRoleBlockHeader(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: context.t(
                    'dashboardInicio.mobileSuperBlockTitle',
                    fallback: 'Bloco SUPER',
                  ),
                  subtitle: context.t(
                    'dashboardInicio.mobileSuperBlockSubtitle',
                    fallback:
                        'Infraestrutura monitorada e saúde atual do backend.',
                  ),
                ),
              ),
              SizedBox(height: 12),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 110),
                child: _buildSuperInfrastructureBlock(context),
              ),
            ],
            if (ehAdmin) ...[
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: ehSuper ? 150 : 80),
                child: _buildPeriodFilter(),
              ),
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: ehSuper ? 200 : 130),
                child: _buildKpiGrid(data, loading),
              ),
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: ehSuper ? 250 : 180),
                child: _buildDashboardChart(data),
              ),
              if (data.alerts.isNotEmpty) ...[
                SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: Duration(milliseconds: ehSuper ? 300 : 230),
                  child: _buildAlertasSection(data, context),
                ),
              ],
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: ehSuper ? 350 : 280),
                child: _buildUpcomingSection(data),
              ),
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: ehSuper ? 400 : 330),
                child: _buildOperationsSection(data),
              ),
            ],
            if (ehColaborador) ...[
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 80),
                child: _buildRoleBlockHeader(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  title: context.t(
                    'collaboratorHome.title',
                    fallback: 'Meu painel',
                  ),
                  subtitle: context.t(
                    'collaboratorHome.subtitle',
                    fallback:
                        'Acompanhe metas, vendas, serviços e prioridades do seu trabalho.',
                  ),
                ),
              ),
              if (hasOperationalAccess) ...<Widget>[
                SizedBox(height: 12),
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 130),
                  child: CollaboratorOperationalHomeMobileDashboard(
                    provider: _operacionalProvider,
                    showSales: canAccessSales,
                    showServices: canAccessServices,
                    showReservations: canAccessReservations,
                    onRetry: () => _reloadOperational(autorizacoes),
                  ),
                ),
              ],
              SizedBox(height: 12),
              SixStaggeredEntry(
                delay: Duration(milliseconds: hasOperationalAccess ? 210 : 130),
                child: CollaboratorPerformanceHomeMobileDashboard(
                  provider: _desempenhoProvider,
                ),
              ),
            ],
            if (!ehSuper && !ehAdmin && !ehColaborador) ...[
              SizedBox(height: 16),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 80),
                child: _buildEmptyRoleBlock(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBlockHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _surfaceColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SixMobilePalette.onPrimary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(icon, color: SixMobilePalette.onPrimary, size: 18),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: SixMobilePalette.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.heroSupportingText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuperInfrastructureBlock(BuildContext context) {
    final AdminPortalResumo? resumo = _resumoInfraestrutura;

    if (_carregandoInfraestrutura && resumo == null) {
      return _buildInfrastructureLoadingCard(context);
    }

    if (_erroInfraestrutura != null && resumo == null) {
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
                  value: resumo.actuator!.threadsAtivas.toString(),
                ),
                _buildInfrastructurePill(
                  context,
                  label: 'CPU',
                  value: resumo.actuator!.processadoresDisponiveis.toString(),
                ),
                _buildInfrastructurePill(
                  context,
                  label: 'Carga',
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _softSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: _accentColor),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 14),
          child,
        ],
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
            count.toString(),
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
              label: 'Total',
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
              label: 'Dados',
              value: _formatInfrastructureBytes(banco.tamanhoDadosBytes),
            ),
            _buildInfrastructureCompactMetric(
              label: 'Storage',
              value: _formatInfrastructureBytes(banco.tamanhoArmazenadoBytes),
            ),
            _buildInfrastructureCompactMetric(
              label: 'Índices',
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
    final Color color = ok ? Color(0xFF16A34A) : SixMobilePalette.error;
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
    final TextEditingController controller = TextEditingController(
      text: _infrastructureRequestsWindowValue.toString(),
    );
    AdminRequestWindowUnit stagedUnit = _infrastructureRequestsWindowUnit;

    try {
      final _InfrastructureRequestsFilterSelection?
      selection = await showModalBottomSheet<
        _InfrastructureRequestsFilterSelection
      >(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.44),
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final double keyboardInset =
                  MediaQuery.of(context).viewInsets.bottom;
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                                tooltip: context.t(
                                  'common.close',
                                  fallback: 'Fechar',
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: _titleTextColor,
                                ),
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
                                  _defaultInfrastructureRequestsWindowValue
                                      .toString(),
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
                                  selected:
                                      stagedUnit ==
                                      AdminRequestWindowUnit.minutes,
                                  onTap: () {
                                    setModalState(() {
                                      stagedUnit =
                                          AdminRequestWindowUnit.minutes;
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
                                  selected:
                                      stagedUnit ==
                                      AdminRequestWindowUnit.hours,
                                  onTap: () {
                                    setModalState(() {
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
                                    context.t(
                                      'common.cancel',
                                      fallback: 'Cancelar',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    final int value =
                                        _sanitizeInfrastructureWindowValue(
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
            },
          );
        },
      );

      if (selection == null || !mounted) {
        return;
      }

      setState(() {
        _infrastructureRequestsWindowValue = selection.value;
        _infrastructureRequestsWindowUnit = selection.unit;
      });
      await _carregarInfraestrutura();
    } finally {
      controller.dispose();
    }
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
                color: selected ? SixMobilePalette.onAccent : _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfrastructureLoadingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t(
                'dashboardInicio.mobileInfrastructureLoading',
                fallback: 'Carregando infraestrutura monitorada.',
              ),
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SixMobilePalette.errorBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                color: SixMobilePalette.error,
                size: 18,
              ),
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

  Widget _buildEmptyRoleBlock(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, color: _mutedTextColor, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'dashboardInicio.mobileNoRoleBlock',
                fallback:
                    'Os blocos desta tela não estão disponíveis para o seu perfil.',
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

  // ─── NOTIFICATION ICON ─────────────────────────────────────────────────────

  Widget _buildGreetingHeader(BuildContext context) {
    final String nome = _resolveGreetingName();
    final String? profileImage =
        _fotoPerfilSincronizada ?? _usuarioProvider.usuario?.foto;

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: _buildProfileAvatarScrollFade(
              showInAppBar: false,
              child: SixMobileAccountPanelAction(
                profileImage: profileImage,
                onPickImage: _pickImage,
                isUpdatingImage:
                    _salvandoFotoPerfil || _sincronizandoPerfilInicial,
                size: 44,
                borderColor: SixMobilePalette.onPrimary.withValues(alpha: 0.36),
                backgroundColor: SixMobilePalette.onPrimary.withValues(
                  alpha: 0.10,
                ),
                iconColor: SixMobilePalette.onPrimary,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .t(
                        'dashboardInicio.mobileGreeting',
                        fallback: 'Olá, {nome}!',
                      )
                      .replaceAll('{nome}', nome),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 28,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  context
                      .t(
                        'dashboardInicio.mobileGreetingSubtitle',
                        fallback:
                            'Veja os principais movimentos de {empresa} hoje.',
                      )
                      .replaceAll(
                        '{empresa}',
                        _rotuloDoFiltroSelecionado(context),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarProfileAction(BuildContext context) {
    final String? profileImage =
        _fotoPerfilSincronizada ?? _usuarioProvider.usuario?.foto;

    return ValueListenableBuilder<double>(
      valueListenable: _profileAvatarScrollProgress,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SixMobileAccountPanelAction(
            profileImage: profileImage,
            onPickImage: _pickImage,
            isUpdatingImage: _salvandoFotoPerfil || _sincronizandoPerfilInicial,
            size: 34,
            borderColor: _borderColor.withValues(alpha: 0.85),
            backgroundColor: _surfaceColor.withValues(alpha: 0.96),
            iconColor: _titleTextColor,
          ),
        ),
      ),
      builder: (BuildContext context, double progress, Widget? child) {
        final double clampedProgress = progress.clamp(0.0, 1.0).toDouble();

        return _applyProfileAvatarScrollFade(
          context: context,
          progress: clampedProgress,
          showInAppBar: true,
          child: child ?? SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildProfileAvatarScrollFade({
    required bool showInAppBar,
    required Widget child,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: _profileAvatarScrollProgress,
      child: child,
      builder: (BuildContext context, double progress, Widget? child) {
        return _applyProfileAvatarScrollFade(
          context: context,
          progress: progress,
          showInAppBar: showInAppBar,
          child: child ?? SizedBox.shrink(),
        );
      },
    );
  }

  Widget _applyProfileAvatarScrollFade({
    required BuildContext context,
    required double progress,
    required bool showInAppBar,
    required Widget child,
  }) {
    final double clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final double easedProgress = Curves.easeInOutCubic.transform(
      clampedProgress,
    );
    final double opacity = showInAppBar ? easedProgress : 1 - easedProgress;
    final bool enabled =
        showInAppBar ? clampedProgress >= 0.5 : clampedProgress < 0.5;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    Widget buildFadedAvatar(double animatedOpacity) {
      return ExcludeSemantics(
        excluding: !enabled,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Opacity(opacity: animatedOpacity, child: child),
        ),
      );
    }

    if (reduceMotion) {
      return buildFadedAvatar(opacity);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: opacity),
      duration: _profileAvatarFadeDuration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedOpacity, Widget? _) {
        return buildFadedAvatar(animatedOpacity);
      },
    );
  }

  String _resolveGreetingName() {
    final usuario = _usuarioProvider.usuario;
    final String nomeDeGuerra = usuario?.nomeDeGuerra.trim() ?? '';
    if (nomeDeGuerra.isNotEmpty) return nomeDeGuerra;

    final String nome = usuario?.nome.trim() ?? '';
    if (nome.isNotEmpty) return nome.split(RegExp(r'\s+')).first;

    return 'bem-vindo';
  }

  Widget _buildCompanyFilterIcon() {
    if (_carregandoTrocaDeComercio || _carregandoFiltroDeComercio) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.1,
          valueColor: AlwaysStoppedAnimation<Color>(SixMobilePalette.onPrimary),
        ),
      );
    }

    final bool selecionouTodos =
        _comercioSelecionadoNoFiltro == _allCompaniesFilterValue;
    return Icon(
      selecionouTodos ? Icons.filter_alt_outlined : Icons.filter_alt_rounded,
    );
  }

  String _tooltipFiltroDeComercio(BuildContext context) {
    final String comercioSelecionado = _rotuloDoFiltroSelecionado(context);
    return context
        .t(
          'dashboardInicio.mobileCompanyFilterTooltip',
          fallback: 'Filtrar comércios: {comercio}',
        )
        .replaceAll('{comercio}', comercioSelecionado);
  }

  Future<void> _abrirFiltroDeComercios() async {
    try {
      await _garantirComerciosDoUsuarioCarregados();
      await _garantirColaboradoresDoComercioCarregados();
    } catch (error) {
      debugPrint(
        '[HomePageMobile] Falha ao carregar filtros da dashboard: $error',
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.t(
              'dashboardInicio.mobileCompanyFilterLoadError',
              fallback:
                  'Não foi possível carregar os comércios disponíveis agora.',
            ),
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    String stagedCompany = _comercioSelecionadoNoFiltro;
    String? stagedCollaborator = _colaboradorSelecionadoNoFiltro;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool companyFilterIsAll =
                stagedCompany == _allCompaniesFilterValue;
            final bool loading =
                _carregandoTrocaDeComercio || _carregandoFiltroDeColaborador;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Material(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.t(
                                      'dashboardInicio.mobileDashboardFilterTitle',
                                      fallback: 'Filtrar dashboard',
                                    ),
                                    style: TextStyle(
                                      color: _titleTextColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.t(
                                      'dashboardInicio.mobileDashboardFilterSubtitle',
                                      fallback:
                                          'Escolha o comércio e, se precisar, refine por colaborador.',
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
                              tooltip: context.t(
                                'common.close',
                                fallback: 'Fechar',
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: _titleTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SixMobileSelectionField(
                          label: context.t(
                            'dashboardInicio.mobileDashboardFilterCompanyLabel',
                            fallback: 'Comércio',
                          ),
                          value: _rotuloDoComercioSelecionado(stagedCompany),
                          helperText: context.t(
                            'dashboardInicio.mobileDashboardFilterCompanyHelper',
                            fallback:
                                'Define qual comércio alimenta os indicadores exibidos.',
                          ),
                          icon: Icons.storefront_rounded,
                          enabled: !loading,
                          onTap: () async {
                            final String? selecionado =
                                await _abrirSelecaoDeEmpresaNoSheet(
                                  context,
                                  selectedValue: stagedCompany,
                                );
                            if (selecionado == null || !mounted) {
                              return;
                            }

                            await _aplicarFiltroDeComercio(selecionado);
                            if (!mounted || !context.mounted) {
                              return;
                            }

                            stagedCompany = _comercioSelecionadoNoFiltro;
                            stagedCollaborator =
                                _colaboradorSelecionadoNoFiltro;
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: context.t(
                            'dashboardInicio.mobileCollaboratorFilterLabel',
                            fallback: 'Colaborador',
                          ),
                          value: _rotuloDoColaboradorSelecionadoComFallback(
                            context,
                            stagedCollaborator,
                          ),
                          hint: context.t(
                            'dashboardInicio.mobileCollaboratorFilterAll',
                            fallback: 'Todos os colaboradores',
                          ),
                          helperText:
                              companyFilterIsAll
                                  ? context.t(
                                    'dashboardInicio.mobileCollaboratorFilterDisabledHelper',
                                    fallback:
                                        'Escolha um comércio específico para filtrar colaboradores.',
                                  )
                                  : _carregandoFiltroDeColaborador
                                  ? context.t(
                                    'dashboardInicio.mobileCollaboratorFilterLoadingHelper',
                                    fallback:
                                        'Carregando colaboradores do comércio atual.',
                                  )
                                  : context.t(
                                    'dashboardInicio.mobileCollaboratorFilterHelper',
                                    fallback:
                                        'Mostra os indicadores do colaborador selecionado na dashboard.',
                                  ),
                          icon: Icons.manage_accounts_outlined,
                          enabled: !companyFilterIsAll && !loading,
                          onTap: () async {
                            final String? selecionado =
                                await _abrirSelecaoDeColaboradorNoSheet(
                                  context,
                                  selectedValue: stagedCollaborator,
                                );
                            if (selecionado == null || !mounted) {
                              return;
                            }

                            _aplicarFiltroDeColaborador(selecionado);
                            if (!mounted || !context.mounted) {
                              return;
                            }

                            stagedCollaborator =
                                _colaboradorSelecionadoNoFiltro;
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _aplicarFiltroDeComercio(String filtroSelecionado) async {
    if (filtroSelecionado == _comercioSelecionadoNoFiltro) {
      return;
    }

    if (filtroSelecionado == _allCompaniesFilterValue) {
      setState(() {
        _comercioSelecionadoNoFiltro = filtroSelecionado;
        _resetCollaboratorFilterState();
      });
      _dashboardProvider.setCollaboratorFilter(null, reload: false);
      await _dashboardProvider.reload();
      return;
    }

    final String filtroAnterior = _comercioSelecionadoNoFiltro;
    final String empresaAnterior =
        (await _authService.getEmpresaId())?.trim() ?? '';

    setState(() {
      _carregandoTrocaDeComercio = true;
      _comercioSelecionadoNoFiltro = filtroSelecionado;
      _resetCollaboratorFilterState();
    });

    try {
      if (empresaAnterior != filtroSelecionado) {
        await _authService.setEmpresaId(filtroSelecionado);
      }

      _notificacaoService.limpar();
      if (!kIsWeb) {
        disconnectStomp();
        await connectStomp(idUnicoDaEmpresa: filtroSelecionado);
      }

      await Future.wait<dynamic>(<Future<dynamic>>[
        _empresaService.buscarDadosDaEmpresa(),
        Future<void>.sync(
          () => _dashboardProvider.setCollaboratorFilter(null, reload: false),
        ),
        _dashboardProvider.reload(),
      ]);
    } catch (error) {
      debugPrint('[HomePageMobile] Falha ao trocar comércio no filtro: $error');
      await _authService.setEmpresaId(empresaAnterior);

      if (!mounted) {
        return;
      }

      setState(() => _comercioSelecionadoNoFiltro = filtroAnterior);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.t(
              'dashboardInicio.mobileCompanyFilterSwitchError',
              fallback:
                  'Não foi possível trocar o comércio agora. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregandoTrocaDeComercio = false);
      }
    }
  }

  String _rotuloDoFiltroSelecionado(BuildContext context) {
    if (_comercioSelecionadoNoFiltro == _allCompaniesFilterValue) {
      return context.t(
        'dashboardInicio.mobileCompanyFilterAll',
        fallback: 'Todos',
      );
    }

    final EmpresaVinculoWebModel? vinculoSelecionado = _comerciosDisponiveis
        .cast<EmpresaVinculoWebModel?>()
        .firstWhere(
          (EmpresaVinculoWebModel? vinculo) =>
              vinculo?.idUnicoDaEmpresa == _comercioSelecionadoNoFiltro,
          orElse: () => null,
        );
    if (vinculoSelecionado != null) {
      return _rotuloDoComercio(vinculoSelecionado);
    }

    final String nomeFantasiaAtual =
        _empresaProvider.empresa?.nomeFantasia.trim() ?? '';
    if (nomeFantasiaAtual.isNotEmpty) {
      return nomeFantasiaAtual;
    }

    return _comercioSelecionadoNoFiltro;
  }

  String _rotuloDoComercio(EmpresaVinculoWebModel vinculo) {
    final String nomeFantasia = vinculo.nomeFantasia.trim();
    if (nomeFantasia.isNotEmpty) {
      return nomeFantasia;
    }

    return vinculo.idUnicoDaEmpresa.trim();
  }

  String _rotuloDoComercioSelecionado(String companyId) {
    if (companyId == _allCompaniesFilterValue) {
      return context.t(
        'dashboardInicio.mobileCompanyFilterAll',
        fallback: 'Todos',
      );
    }

    final EmpresaVinculoWebModel? vinculoSelecionado = _comerciosDisponiveis
        .cast<EmpresaVinculoWebModel?>()
        .firstWhere(
          (EmpresaVinculoWebModel? vinculo) =>
              vinculo?.idUnicoDaEmpresa == companyId,
          orElse: () => null,
        );
    if (vinculoSelecionado != null) {
      return _rotuloDoComercio(vinculoSelecionado);
    }

    return companyId;
  }

  Future<String?> _abrirSelecaoDeEmpresaNoSheet(
    BuildContext context, {
    required String selectedValue,
  }) {
    final List<SixMobileSelectionOption<String>> options =
        <SixMobileSelectionOption<String>>[
          SixMobileSelectionOption<String>(
            value: _allCompaniesFilterValue,
            title: context.t(
              'dashboardInicio.mobileCompanyFilterAll',
              fallback: 'Todos',
            ),
            icon: Icons.layers_rounded,
          ),
          ..._comerciosDisponiveis.map(
            (EmpresaVinculoWebModel vinculo) =>
                SixMobileSelectionOption<String>(
                  value: vinculo.idUnicoDaEmpresa,
                  title: _rotuloDoComercio(vinculo),
                  icon: Icons.storefront_rounded,
                ),
          ),
        ];

    return showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t(
        'dashboardInicio.mobileCompanyFilterTitle',
        fallback: 'Filtrar comércios',
      ),
      subtitle: context.t(
        'dashboardInicio.mobileCompanyFilterSubtitle',
        fallback: 'Escolha um comércio para visualizar a dashboard.',
      ),
      options: options,
      selectedValue: selectedValue,
      emptyTitle: context.t(
        'dashboardInicio.mobileCompanyFilterEmptyTitle',
        fallback: 'Nenhum comércio disponível',
      ),
      searchHint: context.t(
        'dashboardInicio.mobileCompanyFilterSearchHint',
        fallback: 'Buscar comércio',
      ),
      emptyMessage: context.t(
        'dashboardInicio.mobileCompanyFilterEmptyMessage',
        fallback: 'Não encontramos vínculos ativos para este usuário.',
      ),
    );
  }

  Future<void> _garantirColaboradoresDoComercioCarregados({
    bool force = false,
  }) async {
    final bool companyFilterIsAll =
        _comercioSelecionadoNoFiltro == _allCompaniesFilterValue;
    if (companyFilterIsAll) {
      if (mounted) {
        setState(_resetCollaboratorFilterState);
      } else {
        _resetCollaboratorFilterState();
      }
      return;
    }

    if (_carregandoFiltroDeColaborador) {
      return;
    }

    if (!force && _colaboradoresDisponiveis.isNotEmpty) {
      return;
    }

    setState(() => _carregandoFiltroDeColaborador = true);
    try {
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _colaboradorApiClient.listarColaboradores();
      final List<ColaboradorUsuarioResumo> ativos = colaboradores
        .where(
          (ColaboradorUsuarioResumo colaborador) =>
              colaborador.ativo && _rotuloDoColaborador(colaborador).isNotEmpty,
        )
        .toList(growable: false)..sort(
        (ColaboradorUsuarioResumo a, ColaboradorUsuarioResumo b) =>
            _rotuloDoColaborador(
              a,
            ).toLowerCase().compareTo(_rotuloDoColaborador(b).toLowerCase()),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _colaboradoresDisponiveis = ativos;
        if (_colaboradorSelecionadoNoFiltro != null) {
          final ColaboradorUsuarioResumo? selecionado = _colaboradorById(
            _colaboradorSelecionadoNoFiltro!,
          );
          if (selecionado == null) {
            _colaboradorSelecionadoNoFiltro = null;
            _dashboardProvider.setCollaboratorFilter(null, reload: false);
          }
        }
      });
    } finally {
      if (mounted) {
        setState(() => _carregandoFiltroDeColaborador = false);
      }
    }
  }

  Future<String?> _abrirSelecaoDeColaboradorNoSheet(
    BuildContext context, {
    required String? selectedValue,
  }) {
    final List<SixMobileSelectionOption<String>> options =
        <SixMobileSelectionOption<String>>[
          SixMobileSelectionOption<String>(
            value: _allCollaboratorsFilterValue,
            title: context.t(
              'dashboardInicio.mobileCollaboratorFilterAll',
              fallback: 'Todos os colaboradores',
            ),
            icon: Icons.groups_rounded,
          ),
          ..._colaboradoresDisponiveis.map(
            (ColaboradorUsuarioResumo colaborador) =>
                SixMobileSelectionOption<String>(
                  value: colaborador.idUnicoPessoal,
                  title: _rotuloDoColaborador(colaborador),
                  subtitle: _subtituloDoColaborador(colaborador),
                  icon: Icons.person_outline_rounded,
                ),
          ),
        ];

    return showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t(
        'dashboardInicio.mobileCollaboratorFilterTitle',
        fallback: 'Filtrar colaborador',
      ),
      subtitle: context.t(
        'dashboardInicio.mobileCollaboratorFilterSubtitle',
        fallback: 'Escolha um colaborador para refinar os indicadores.',
      ),
      options: options,
      selectedValue: selectedValue ?? _allCollaboratorsFilterValue,
      emptyTitle: context.t(
        'dashboardInicio.mobileCollaboratorFilterEmptyTitle',
        fallback: 'Nenhum colaborador disponível',
      ),
      searchHint: context.t(
        'dashboardInicio.mobileCollaboratorFilterSearchHint',
        fallback: 'Buscar colaborador',
      ),
      emptyMessage: context.t(
        'dashboardInicio.mobileCollaboratorFilterEmptyMessage',
        fallback: 'Não encontramos colaboradores ativos neste comércio.',
      ),
    );
  }

  void _aplicarFiltroDeColaborador(String filtroSelecionado) {
    final String? collaboratorId =
        filtroSelecionado == _allCollaboratorsFilterValue
            ? null
            : filtroSelecionado;
    if (_colaboradorSelecionadoNoFiltro == collaboratorId) {
      return;
    }

    setState(() {
      _colaboradorSelecionadoNoFiltro = collaboratorId;
    });
    _dashboardProvider.setCollaboratorFilter(collaboratorId);
  }

  void _resetCollaboratorFilterState() {
    _colaboradorSelecionadoNoFiltro = null;
    _colaboradoresDisponiveis = const <ColaboradorUsuarioResumo>[];
  }

  ColaboradorUsuarioResumo? _colaboradorById(String collaboratorId) {
    for (final ColaboradorUsuarioResumo colaborador
        in _colaboradoresDisponiveis) {
      if (colaborador.idUnicoPessoal == collaboratorId) {
        return colaborador;
      }
    }
    return null;
  }

  String _rotuloDoColaboradorSelecionadoComFallback(
    BuildContext context,
    String? collaboratorId,
  ) {
    if (collaboratorId == null) {
      return context.t(
        'dashboardInicio.mobileCollaboratorFilterAll',
        fallback: 'Todos os colaboradores',
      );
    }

    final ColaboradorUsuarioResumo? selecionado = _colaboradorById(
      collaboratorId,
    );
    if (selecionado != null) {
      return _rotuloDoColaborador(selecionado);
    }

    return context.t(
      'dashboardInicio.mobileCollaboratorFilterSelectedFallback',
      fallback: 'Colaborador selecionado',
    );
  }

  String _rotuloDoColaborador(ColaboradorUsuarioResumo colaborador) {
    final String nomeDeGuerra = colaborador.nomeDeGuerra.trim();
    if (nomeDeGuerra.isNotEmpty) {
      return nomeDeGuerra;
    }

    final String nome = colaborador.nome.trim();
    if (nome.isNotEmpty) {
      return nome;
    }

    final String email = colaborador.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return colaborador.idUnicoPessoal.trim();
  }

  String? _subtituloDoColaborador(ColaboradorUsuarioResumo colaborador) {
    final String email = colaborador.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    final String celular = colaborador.celularDeAcesso.trim();
    if (celular.isNotEmpty) {
      return celular;
    }

    return null;
  }

  Widget _buildNotificationIcon() {
    final int naoLidas = _notificacaoService.naoLidas;
    final bool temNaoLidas = naoLidas > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          temNaoLidas
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
        ),
        if (temNaoLidas)
          Positioned(
            right: -6,
            top: -6,
            child: SixPulsingBadge(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: SixMobilePalette.notificationBadge,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SixMobilePalette.onPrimary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _badgeText(naoLidas),
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── PERIOD FILTER ─────────────────────────────────────────────────────────

  Widget _buildPeriodFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            DashboardPeriod.values.map((DashboardPeriod period) {
              final bool selected = _dashboardProvider.period == period;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _dashboardProvider.setPeriod(period),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _accentColor : _surfaceColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? _accentColor : _borderColor,
                      ),
                    ),
                    child: Text(
                      _periodLabel(period),
                      style: TextStyle(
                        color:
                            selected
                                ? SixMobilePalette.onAccent
                                : _titleTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ─── KPI GRID ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(DashboardInicioModel data, bool loading) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                kpi: data.vendasRealizadas,
                label: 'Vendas',
                loading: loading,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                kpi: data.valorRecebido,
                label: 'Recebido',
                loading: loading,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                kpi: data.valorAReceber,
                label: 'A receber',
                loading: loading,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                kpi: data.resultado,
                label: 'Resultado',
                loading: loading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required DashboardKpi kpi,
    required String label,
    required bool loading,
  }) {
    final Color borderColor =
        kpi.highlight ? SixMobilePalette.highlightedBorder : _borderColor;
    final Color iconBg =
        kpi.highlight ? _accentColor.withValues(alpha: 0.12) : _softSurface;

    return AnimatedOpacity(
      opacity: loading ? 0.55 : 1.0,
      duration: Duration(milliseconds: 250),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: kpi.highlight ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(kpi.icon, size: 17, color: _accentColor),
                ),
                Spacer(),
                _buildDeltaBadge(kpi),
              ],
            ),
            SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              key: ValueKey<String>('kpi-$label-${kpi.value}'),
              tween: Tween<double>(begin: 0, end: kpi.value),
              duration: Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (BuildContext ctx, double v, Widget? _) {
                return Text(
                  _compactFmt.format(v),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                );
              },
            ),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaBadge(DashboardKpi kpi) {
    final double? delta = kpi.deltaPercent;
    final bool? positive = kpi.isPositive;
    if (delta == null || positive == null) return SizedBox.shrink();

    final Color color = positive ? Color(0xFF16A34A) : SixMobilePalette.error;
    final IconData arrow =
        positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(arrow, size: 11, color: color),
        SizedBox(width: 2),
        Text(
          '${delta.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── CHART ─────────────────────────────────────────────────────────────────

  Widget _buildDashboardChart(DashboardInicioModel data) {
    if (data.chartData.isEmpty) return SizedBox.shrink();

    final List<FlSpot> vendaSpots =
        data.chartData
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.vendas))
            .toList();
    final List<FlSpot> recebSpots =
        data.chartData
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.recebimentos))
            .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(14, 14, 10, 10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Evolução no período',
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              _chartLegend(_accentColor, 'Vendas', dashed: false),
              SizedBox(width: 10),
              _chartLegend(Color(0xFF16A34A), 'Recebido', dashed: true),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: _surfaceColor,
                    getTooltipItems: (List<LineBarSpot> spots) {
                      return spots.map((LineBarSpot spot) {
                        return LineTooltipItem(
                          _compactFmt.format(spot.y),
                          TextStyle(
                            color: spot.bar.color ?? _accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (double v) => FlLine(
                        color: _borderColor.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (double v, TitleMeta meta) {
                        final int idx = v.round();
                        if (idx < 0 || idx >= data.chartData.length) {
                          return SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            data.chartData[idx].label,
                            style: TextStyle(
                              fontSize: 10,
                              color: _mutedTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: vendaSpots,
                    color: _accentColor,
                    barWidth: 2.5,
                    isCurved: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _accentColor.withValues(alpha: 0.07),
                    ),
                  ),
                  LineChartBarData(
                    spots: recebSpots,
                    color: Color(0xFF16A34A),
                    barWidth: 2,
                    isCurved: true,
                    dashArray: <int>[5, 3],
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label, {required bool dashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 2, color: color),
              SizedBox(width: 3, height: 2),
              Container(width: 5, height: 2, color: color),
            ],
          )
        else
          Container(width: 16, height: 2.5, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _mutedTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── ALERTS ────────────────────────────────────────────────────────────────

  Widget _buildAlertasSection(DashboardInicioModel data, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SixMobilePalette.errorBorder.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: SixMobilePalette.error,
                ),
                SizedBox(width: 8),
                Text(
                  'Atenção necessária',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SixMobilePalette.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${data.alerts.length}',
                    style: TextStyle(
                      color: SixMobilePalette.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: _borderColor.withValues(alpha: 0.75),
          ),
          ...data.alerts.asMap().entries.map((entry) {
            final int idx = entry.key;
            final DashboardAlertItem alert = entry.value;
            return Column(
              children: [
                _buildAlertRow(alert, context),
                if (idx < data.alerts.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: _borderColor.withValues(alpha: 0.75),
                  ),
              ],
            );
          }),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAlertRow(DashboardAlertItem alert, BuildContext context) {
    final Color color;
    switch (alert.severity) {
      case DashboardAlertSeverity.critical:
        color = SixMobilePalette.error;
      case DashboardAlertSeverity.warning:
        color = Color(0xFFF59E0B);
      case DashboardAlertSeverity.info:
        color = _accentColor;
    }

    return InkWell(
      onTap: alert.routeHint != null ? _showFeatureInProgress : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.titulo,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    alert.descricao,
                    style: TextStyle(color: _mutedTextColor, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (alert.valor != null && alert.valor! > 0) ...[
              SizedBox(width: 8),
              Text(
                _compactFmt.format(alert.valor),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── UPCOMING ──────────────────────────────────────────────────────────────

  Widget _buildUpcomingSection(DashboardInicioModel data) {
    if (data.upcoming.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.upcoming_outlined, size: 18, color: _accentColor),
                SizedBox(width: 8),
                Text(
                  'Próximos 7 dias',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: _borderColor.withValues(alpha: 0.75),
          ),
          ...data.upcoming.asMap().entries.map((entry) {
            final int idx = entry.key;
            final DashboardUpcomingItem item = entry.value;
            return Column(
              children: [
                _buildUpcomingRow(item),
                if (idx < data.upcoming.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: _borderColor.withValues(alpha: 0.75),
                  ),
              ],
            );
          }),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(DashboardUpcomingItem item) {
    final Color color;
    final IconData icon;
    switch (item.tipo) {
      case 'receber':
        color = Color(0xFF16A34A);
        icon = Icons.arrow_downward_rounded;
      case 'pagar':
        color = SixMobilePalette.error;
        icon = Icons.arrow_upward_rounded;
      default:
        color = _accentColor;
        icon = Icons.build_circle_outlined;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descricao,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  _dateFmt.format(item.dataPrevista),
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.valor > 0) ...[
            SizedBox(width: 8),
            Text(
              _compactFmt.format(item.valor),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── OPERATIONS ────────────────────────────────────────────────────────────

  Widget _buildOperationsSection(DashboardInicioModel data) {
    final DashboardOperationSummary ops = data.operations;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_center_outlined,
                size: 18,
                color: _accentColor,
              ),
              SizedBox(width: 8),
              Text(
                'Operação atual',
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildOpChip(
                  icon: Icons.build_circle_outlined,
                  label: 'Em andamento',
                  count: ops.atendimentosEmAndamento,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildOpChip(
                  icon: Icons.description_outlined,
                  label: 'Orçamentos',
                  count: ops.orcamentosAguardando,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOpChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'Para retirada',
                  count: ops.equipamentosParaRetirada,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildOpChip(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Caixas abertos',
                  count: ops.caixasAbertos,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpChip({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _accentColor),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _periodLabel(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.today:
        return 'Hoje';
      case DashboardPeriod.last7Days:
        return '7 dias';
      case DashboardPeriod.last30Days:
        return '30 dias';
      case DashboardPeriod.currentMonth:
        return 'Mês atual';
    }
  }

  String _badgeText(int count) {
    if (count > 9) return '+9';
    return count.toString();
  }

  String _formatInfrastructureBytes(int bytes) {
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final bool roundToInt = value >= 100 || unitIndex == 0;
    final String text =
        roundToInt ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$text ${units[unitIndex]}';
  }

  String _formatInfrastructureDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    final int seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  String _formatInfrastructureLoad(double load) {
    return load.toStringAsFixed(load >= 10 ? 1 : 2);
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
        return Color(0xFF16A34A);
      case 400:
        return Color(0xFFD97706);
      case 500:
      default:
        return SixMobilePalette.error;
    }
  }

  void _openNotifications(BuildContext context) {
    _navigateTo(context, NotificacoesMobileScreen());
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => page),
    );
  }

  void _showFeatureInProgress() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fluxo mobile em evolução.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
