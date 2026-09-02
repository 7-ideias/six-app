import 'dart:async';

import 'package:sixpos/presentation/components/ai_assistant/ai_assistant_button.dart';
import 'package:sixpos/presentation/components/ai_assistant/ai_assistant_panel.dart';
import 'package:sixpos/presentation/components/user_profile_avatar_image.dart';
import 'package:sixpos/presentation/layouts/authenticated_web_shell.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_mapper.dart';
import 'package:sixpos/presentation/navigation/modulo_central_pdv.dart';
import 'package:sixpos/presentation/navigation/pagina_principal_web_navigation_actions.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_navigation_permission_adapter.dart';
import 'package:sixpos/presentation/navigation/web_navigation_registry.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_lista_web_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_web_page.dart';
import 'package:sixpos/presentation/screens/catalogo_reservas_web.dart';
import 'package:sixpos/presentation/screens/catalogo_publico_personalizacao_web.dart';
import 'package:sixpos/presentation/screens/chat_suporte_web_page.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_web_page.dart';
import 'package:sixpos/presentation/screens/compras/compras_web_page.dart';
import 'package:sixpos/presentation/screens/configuracoes_six_web_page.dart';
import 'package:sixpos/presentation/screens/desempenho_colaborador_web_page.dart';
import 'package:sixpos/presentation/screens/estoque_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/etiquetas_web_page.dart';
import 'package:sixpos/presentation/screens/meu_perfil_web_screen.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_web_page.dart';
import 'package:sixpos/presentation/screens/ordem_servico_web.dart';
import 'package:sixpos/presentation/screens/pdv_cliente_identificacao_dialog.dart';
import 'package:sixpos/presentation/screens/pdv_page_web_orcamento.dart';
import 'package:sixpos/presentation/screens/produto_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_web_page.dart';
import 'package:sixpos/presentation/screens/recebimento_pagamento_web.dart';
import 'package:sixpos/presentation/components/web/six_web_logout_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_pdv_clear_sale_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_pdv_quantity_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_recebimento_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_theme_menu_entry.dart';
import 'package:sixpos/presentation/components/web/venda_em_andamento_fab_web.dart';
import 'package:sixpos/presentation/screens/servico_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/workspace_home_web.dart';
import 'package:sixpos/presentation/services/web_authenticated_bootstrap_service.dart';
import 'package:sixpos/presentation/theme/web_pdv_theme.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';
import 'package:sixpos/domain/models/pdv_visual_theme.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';

import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:sixpos/l10n/app_localizations.dart';

import 'data/models/cliente_usuario_model.dart';
import 'data/models/caixa_models.dart';
import 'data/models/produto_model.dart';
import 'data/models/operacao_models.dart';
import 'data/models/streak_models.dart';
import 'data/models/venda_nao_liquidada_models.dart';
import 'data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'core/config/app_config.dart';
import 'core/di/caixa_module.dart';
import 'core/di/operacao_module.dart';
import 'core/services/auth_service.dart';
import 'core/services/websocket_service.dart';
import 'core/utils/browser_location.dart';
import 'design_system/themes/zebra_list_item.dart';
import 'domain/services/caixa/caixa_service.dart';
import 'domain/services/operacao/operacao_service.dart';
import 'providers/locale_settings_provider.dart';
import 'providers/colaborador_autorizacoes_provider.dart';
import 'providers/empresa_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/usuario_provider.dart';

part 'pdv_page_web_cockpit_section.dart';
part 'presentation/screens/pdv_web.dart';

class PaginaPrincipalWeb extends StatefulWidget {
  const PaginaPrincipalWeb({super.key});

  @override
  State<PaginaPrincipalWeb> createState() => _PaginaPrincipalWebState();
}

enum StatusComunicacaoBackend { conectando, conectado, desconectado }

enum _PdvItemVisualFeedback { itemAdded, quantityIncreased, quantityDecreased }

enum _WebHeaderUserAction { profile, support, logout }

class _PdvItemMutationResult {
  const _PdvItemMutationResult({
    required this.itemKey,
    required this.isNewItem,
  });

  final String itemKey;
  final bool isNewItem;
}

class _PaginaPrincipalWebState extends State<PaginaPrincipalWeb>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _notificacoes = <Map<String, dynamic>>[];
  int _quantidadeNotificacoesNaoLidas = 0;
  StatusComunicacaoBackend _statusComunicacaoBackend =
      StatusComunicacaoBackend.conectando;
  DateTime? _ultimaValidacaoBackend;
  Timer? _monitoramentoComunicacaoTimer;
  DateTime? _ultimaTentativaReconexao;

  late final AnimationController _iaPulseController;
  late final Animation<double> _iaPulseAnimation;
  bool _assistenteIAMinimizado = false;

  late final AnimationController _bellAnimationController;
  late final Animation<double> _bellRotationAnimation;

  final SixThemeResolver _themeResolver = SixThemeResolver();
  late PdvVisualTheme _pdvTheme;

  final OperacaoService _operacaoService = OperacaoModule.operacaoService;
  final CaixaService _caixaService = CaixaModule.caixaService;
  final VendaNaoLiquidadaApiClient _vendaNaoLiquidadaApiClient =
      VendaNaoLiquidadaApiClient();
  final OperationalProcedureFlowCoordinator _procedureCoordinator =
      OperationalProcedureFlowCoordinator();

  late final WebNavigationDestinationResolver _webNavigationResolver;

  ModuloCentralPDV _moduloAtual = ModuloCentralPDV.seletor;
  ModuloCentralPDV? _moduloRetornoOperacoesCaixa;

  final List<Map<String, dynamic>> _produtosSelecionados =
      <Map<String, dynamic>>[];
  List<FormaPagamentoSelecionada> _formasPagamentoConfirmadas =
      <FormaPagamentoSelecionada>[];
  Map<String, String> _descricoesFormaPagamentoPorCodigo = <String, String>{};
  bool _pagamentoParcialConfirmado = false;
  bool _registrandoReceberDepois = false;
  bool _recebendoVendaNaoLiquidada = false;
  bool _overlayRecebimentoAberto = false;
  bool _procedimentoVendaWebJaAvaliado = false;
  bool _sincronizandoTotalVendasAReceber = false;
  bool _modoExpandidoFrenteCaixa = false;
  bool _carregandoSessaoCaixaPdv = false;
  bool _atualizandoVisaoPdv = false;
  bool _sessaoCaixaPdvSincronizada = false;
  bool _erroSessaoCaixaPdv = false;
  CaixaSessao? _sessaoCaixaPdv;
  Timer? _sessaoCaixaPdvTempoAtivoTimer;
  Timer? _vendasAReceberPollingTimer;
  DateTime _referenciaTempoSessaoCaixaPdv = DateTime.now();
  ClienteUsuario? _clienteIdentificado;
  VendaNaoLiquidadaModel? _vendaNaoLiquidadaEmConsulta;
  int _totalVendasAReceberPendentes = 0;

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _itensTotalController = TextEditingController(
    text: '0',
  );
  final TextEditingController _clienteIdentificadoController =
      TextEditingController();

  final FocusNode _atalhosFocusNode = FocusNode(debugLabel: 'pdv-shortcuts');
  final FocusNode _codigoBarrasFocusNode = FocusNode(
    debugLabel: 'barcode-field',
  );
  final FocusScopeNode _barcodeInteractionFocusScopeNode = FocusScopeNode(
    debugLabel: 'barcode-interaction-scope',
  );
  bool _barcodeInteractionActive = false;

  final Map<String, _PdvItemVisualFeedback> _itemVisualFeedbackByItemKey =
      <String, _PdvItemVisualFeedback>{};
  final Map<String, Timer> _itemVisualFeedbackTimersByItemKey =
      <String, Timer>{};
  final Map<String, GlobalKey> _itemRowKeysByItemKey = <String, GlobalKey>{};

  final ScrollController _notificacoesScrollController = ScrollController();
  final ScrollController _gradeItensScrollController = ScrollController();
  final ScrollController _resumoVendaScrollController = ScrollController();
  final ScrollController _areaVendaScrollController = ScrollController();

  void _onThemeChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // void _limparFiltrosCockpit() {
  //   setState(() {
  //     _opcaoCockpitSelecionada = 0;
  //   });
  // }
  //
  // void _selecionarOpcaoCockpit(int index) {
  //   setState(() {
  //     _opcaoCockpitSelecionada = index;
  //   });
  // }
  //
  // void _voltarParaSeletor() {
  //   if (_cockpitAbertoEmDialog) {
  //     Navigator.of(context).pop();
  //     return;
  //   }
  //
  //   setState(() {
  //     _moduloAtual = ModuloCentralPDV.seletor;
  //   });
  // }
  //
  // Future<void> _abrirCockpitEstrategico() async {
  //   setState(() {
  //     _opcaoCockpitSelecionada = 0;
  //     _cockpitAbertoEmDialog = true;
  //   });
  //
  //   await showDialog<void>(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext dialogContext) {
  //       final Size size = MediaQuery.of(dialogContext).size;
  //
  //       return Dialog(
  //         insetPadding: const EdgeInsets.symmetric(
  //           horizontal: 24,
  //           vertical: 24,
  //         ),
  //         backgroundColor: Colors.transparent,
  //         child: ClipRRect(
  //           borderRadius: BorderRadius.circular(22),
  //           child: SizedBox(
  //             width: size.width * 0.94,
  //             height: size.height * 0.90,
  //             child: Column(children: <Widget>[_buildCockpitEstrategico()]),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  //
  //   if (!mounted) {
  //     return;
  //   }
  //
  //   setState(() {
  //     _cockpitAbertoEmDialog = false;
  //   });
  // }

  @override
  void initState() {
    super.initState();

    _webNavigationResolver = WebNavigationDestinationResolver(
      actions: PaginaPrincipalWebNavigationActions(
        abrirModuloCentral: _abrirModuloCentralPelaNavegacaoWeb,
        abrirFrenteCaixa: _iniciarVenda,
        abrirCaixa: () => _abrirOperacoesCaixa(),
      ),
    );

    _iaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iaPulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _iaPulseController, curve: Curves.easeInOut),
    );

    _iaPulseController.repeat(reverse: true);

    _pdvTheme = PdvVisualTheme.defaultTheme();
    _themeResolver.addListener(_onThemeChanged);
    _atualizarCamposDerivados();

    _bellAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bellRotationAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -0.10),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.10, end: 0.10),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.10, end: -0.08),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.08, end: 0.08),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.08, end: 0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _bellAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _barcodeInteractionFocusScopeNode.addListener(
      _onBarcodeInteractionFocusChanged,
    );

    _configurarWebSocket();
    _iniciarPollingTotalVendasAReceber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registrarOfensivaWeb();
    });
  }

  @override
  void dispose() {
    _iaPulseController.dispose();
    _themeResolver.removeListener(_onThemeChanged);
    onMensagemRecebida = null;
    onStompConectado = null;
    onStompDesconectado = null;
    onStompErro = null;
    _monitoramentoComunicacaoTimer?.cancel();
    _sessaoCaixaPdvTempoAtivoTimer?.cancel();
    _vendasAReceberPollingTimer?.cancel();
    disconnectStomp();
    _bellAnimationController.dispose();
    _atalhosFocusNode.dispose();
    _codigoBarrasFocusNode.dispose();
    _barcodeInteractionFocusScopeNode
      ..removeListener(_onBarcodeInteractionFocusChanged)
      ..dispose();
    _clearAllItemVisualState();
    _codigoBarrasController.dispose();
    _itensTotalController.dispose();
    _clienteIdentificadoController.dispose();
    _notificacoesScrollController.dispose();
    _gradeItensScrollController.dispose();
    _resumoVendaScrollController.dispose();
    _areaVendaScrollController.dispose();
    super.dispose();
  }

  void _iniciarPollingTotalVendasAReceber() {
    _vendasAReceberPollingTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarTotalVendasAReceber();
    });
    _vendasAReceberPollingTimer = Timer.periodic(const Duration(seconds: 20), (
      _,
    ) {
      _sincronizarTotalVendasAReceber();
    });
  }

  Future<void> _sincronizarTotalVendasAReceber() async {
    if (!mounted || _sincronizandoTotalVendasAReceber) {
      return;
    }

    _sincronizandoTotalVendasAReceber = true;
    try {
      final List<VendaNaoLiquidadaModel> vendas =
          await _vendaNaoLiquidadaApiClient.listar();
      if (!mounted) {
        return;
      }

      final int total = vendas.length;
      if (_totalVendasAReceberPendentes != total) {
        setState(() {
          _totalVendasAReceberPendentes = total;
        });
      }
    } catch (_) {
      // Polling silencioso: manter o último total conhecido é preferível
      // a poluir o fluxo do PDV com mensagens transitórias.
    } finally {
      _sincronizandoTotalVendasAReceber = false;
    }
  }

  void _configurarWebSocket() {
    onStompConectado = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.conectado;
        _ultimaValidacaoBackend = DateTime.now();
      });
    };

    onStompDesconectado = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.desconectado;
      });
    };

    onStompErro = (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.desconectado;
      });
    };

    onMensagemRecebida = (json) {
      if (!mounted) {
        return;
      }

      final Map<String, dynamic> notificacao = <String, dynamic>{
        ...json,
        'recebidoEm': DateTime.now().toIso8601String(),
      };

      setState(() {
        _notificacoes.insert(0, notificacao);
        _quantidadeNotificacoesNaoLidas = (_quantidadeNotificacoesNaoLidas + 1)
            .clamp(0, 9);
        _statusComunicacaoBackend = StatusComunicacaoBackend.conectado;
        _ultimaValidacaoBackend = DateTime.now();
      });

      _bellAnimationController.forward(from: 0);

      final String mensagem =
          json['mensagem']?.toString() ?? 'Evento recebido do backend';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    };

    connectStomp();
    _iniciarMonitoramentoComunicacaoBackend();
  }

  Future<void> _registrarOfensivaWeb() async {
    if (!mounted) {
      return;
    }
    final String timezone = context.read<LocaleSettingsProvider>().timeZone;
    await context.read<StreakProvider>().registerActivity(
      platform: StreakPlatform.web,
      timezone: timezone,
    );
  }

  void _iniciarMonitoramentoComunicacaoBackend() {
    _monitoramentoComunicacaoTimer?.cancel();
    _monitoramentoComunicacaoTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _validarComunicacaoBackend(),
    );
  }

  void _validarComunicacaoBackend() {
    if (!mounted) {
      return;
    }

    final bool conectado = isStompConnected();

    if (conectado) {
      if (_statusComunicacaoBackend != StatusComunicacaoBackend.conectado) {
        setState(() {
          _statusComunicacaoBackend = StatusComunicacaoBackend.conectado;
        });
      }
      _ultimaValidacaoBackend = DateTime.now();
      return;
    }

    final DateTime agora = DateTime.now();
    final bool podeReconectar =
        _ultimaTentativaReconexao == null ||
        agora.difference(_ultimaTentativaReconexao!) >=
            const Duration(seconds: 20);

    if (podeReconectar) {
      _ultimaTentativaReconexao = agora;
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.conectando;
      });
      connectStomp();
      return;
    }

    if (_statusComunicacaoBackend != StatusComunicacaoBackend.desconectado) {
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.desconectado;
      });
    }
  }

  Color _corStatusBackend(WebThemeTokens tokens) {
    switch (_statusComunicacaoBackend) {
      case StatusComunicacaoBackend.conectado:
        return tokens.success;
      case StatusComunicacaoBackend.conectando:
        return tokens.warning;
      case StatusComunicacaoBackend.desconectado:
        return tokens.danger;
    }
  }

  String _textoStatusBackend() {
    switch (_statusComunicacaoBackend) {
      case StatusComunicacaoBackend.conectado:
        return 'Backend online';
      case StatusComunicacaoBackend.conectando:
        return 'Validando conexão...';
      case StatusComunicacaoBackend.desconectado:
        return 'Backend offline';
    }
  }

  Color _webHeaderAccentColor(ColorScheme colorScheme, WebThemeTokens tokens) {
    return colorScheme.brightness == Brightness.dark
        ? tokens.info
        : colorScheme.primary;
  }

  Color _foregroundForBackground(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
  }

  WidgetStateProperty<Color?> _webHeaderActionOverlay(WebThemeTokens tokens) {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return tokens.selectedBackground;
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return tokens.hoverBackground;
      }
      return null;
    });
  }

  Widget _buildIndicadorComunicacaoBackend() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color corStatus = _corStatusBackend(tokens);
    final String tooltip =
        _ultimaValidacaoBackend == null
            ? _textoStatusBackend()
            : '${_textoStatusBackend()} • última validação: ${_ultimaValidacaoBackend!.toIso8601String()}';

    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        key: const Key('web-header-backend-status'),
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: corStatus,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: corStatus.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'online',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWebShellHeaderActions() {
    return <Widget>[
      _buildIAAssistente(),
      _buildIndicadorComunicacaoBackend(),
      _buildNotificationBellButton(),
      _buildUserMenuButton(),
    ];
  }

  Widget _buildIAAssistente() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = _webHeaderAccentColor(colorScheme, tokens);
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String tooltip = l10n?.aiAssistantAsk ?? 'Perguntar à IA';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          overlayColor: _webHeaderActionOverlay(tokens),
          onTap: _abrirAssistenteIA,
          child: AnimatedContainer(
            key: const Key('web-header-ai-action'),
            duration: WebThemeTokens.transitionDuration,
            curve: WebThemeTokens.transitionCurve,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ScaleTransition(
                  scale: _iaPulseAnimation,
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'IA',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirAssistenteIA() async {
    final String barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;
    bool expanded = false;
    bool minimizarSolicitado = false;
    bool abrirSuporteSolicitado = false;
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.read<ColaboradorAutorizacoesProvider>();
    final bool ehSuper = autorizacoes.ehSuperUsuario;
    final bool podeAcessarSuporte =
        ehSuper ||
        autorizacoes.ehAdministrador ||
        autorizacoes.ehColaborador;

    if (_assistenteIAMinimizado) {
      setState(() => _assistenteIAMinimizado = false);
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext dialogContext,
        Animation<double> _,
        Animation<double> __,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(VoidCallback fn) setDialogState,
          ) {
            return SafeArea(
              minimum: const EdgeInsets.all(14),
              child: Center(
                child: AiAssistantPanel(
                  modulo: _moduloAtualParaIA(),
                  telaAtual: _telaAtualParaIA(),
                  expanded: expanded,
                  onClose: () {
                    minimizarSolicitado = false;
                    Navigator.of(dialogContext).pop();
                  },
                  onMinimize: () {
                    minimizarSolicitado = true;
                    Navigator.of(dialogContext).pop();
                  },
                  onOpenSupport:
                      podeAcessarSuporte && ehSuper
                          ? () {
                            abrirSuporteSolicitado = true;
                            minimizarSolicitado = false;
                            Navigator.of(dialogContext).pop();
                          }
                          : null,
                  supportContentBuilder:
                      podeAcessarSuporte && !ehSuper
                          ? (_) => const ChatSuporteWebPage(embedded: true)
                          : null,
                  onToggleExpanded:
                      () => setDialogState(() => expanded = !expanded),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (
        BuildContext _,
        Animation<double> animation,
        Animation<double> __,
        Widget child,
      ) {
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );

    if (!mounted) return;
    setState(() => _assistenteIAMinimizado = minimizarSolicitado);
    if (abrirSuporteSolicitado) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ChatSuporteWebPage(),
        ),
      );
    }
  }

  Widget _buildAssistenteIAMinimizado() {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Positioned(
      right: 24,
      bottom: 24,
      child: SafeArea(
        minimum: const EdgeInsets.only(right: 4, bottom: 4),
        child: AiAssistantButton(
          onTap: _abrirAssistenteIA,
          label: l10n?.aiAssistantMinimizedLabel ?? 'Lis minimizada',
          tooltip:
              l10n?.aiAssistantMinimizedTooltip ??
              'Abrir assistente minimizado',
          extended: true,
          highlighted: true,
        ),
      ),
    );
  }

  bool get _possuiVendaEmAndamentoParaRetomar {
    return _vendaNaoLiquidadaEmConsulta != null ||
        _produtosSelecionados.isNotEmpty ||
        _formasPagamentoConfirmadas.isNotEmpty ||
        _clienteIdentificado != null ||
        _clienteIdentificadoController.text.trim().isNotEmpty;
  }

  bool get _deveExibirVendaEmAndamentoFlutuante {
    return _moduloAtual != ModuloCentralPDV.vendas &&
        _possuiVendaEmAndamentoParaRetomar;
  }

  bool get _deveExecutarProcedimentoNaPrimeiraInclusaoNoCarrinho {
    return _vendaNaoLiquidadaEmConsulta == null &&
        !_procedimentoVendaWebJaAvaliado &&
        _produtosSelecionados.isEmpty;
  }

  double _totalVendaEmAndamentoFlutuante(double totalAtual) {
    final VendaNaoLiquidadaModel? venda = _vendaNaoLiquidadaEmConsulta;
    if (venda == null) {
      return totalAtual;
    }

    final bool possuiRecebimentoAnterior =
        venda.recebimentos.isNotEmpty ||
        (venda.valorOriginal - venda.valorAberto).abs() > 0.009;
    return possuiRecebimentoAnterior ? venda.valorAberto : totalAtual;
  }

  String _resumoVendaEmAndamentoFlutuante(
    LocaleSettingsProvider regionalizacao,
    double totalAtual,
  ) {
    final int quantidadeItens = _calcularQuantidadeItens();
    if (quantidadeItens > 0) {
      final AppLocalizations? l10n = AppLocalizations.of(context);
      final String itens = l10n?.pdvWebItemsCounterLabel ?? 'itens';
      final String totalFormatado = regionalizacao.formatCurrency(
        _totalVendaEmAndamentoFlutuante(totalAtual),
      );
      return '$quantidadeItens $itens  •  $totalFormatado';
    }

    if (_clienteIdentificado != null ||
        _clienteIdentificadoController.text.trim().isNotEmpty) {
      final AppLocalizations? l10n = AppLocalizations.of(context);
      return l10n?.pdvWebCustomerIdentifiedStatus ?? 'Cliente identificado';
    }

    final AppLocalizations? l10n = AppLocalizations.of(context);
    return l10n?.pdvWebPaymentDefinedLabel ?? 'Pagamento definido';
  }

  Widget _buildVendaEmAndamentoFlutuante(
    LocaleSettingsProvider regionalizacao,
    double totalAtual,
  ) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Positioned(
      right: 24,
      bottom: _assistenteIAMinimizado ? 96 : 24,
      child: SafeArea(
        minimum: const EdgeInsets.only(right: 4, bottom: 4),
        child: VendaEmAndamentoFabWeb(
          titulo: context.t('pdv.openSale.status', fallback: 'Venda em aberto'),
          resumo: _resumoVendaEmAndamentoFlutuante(regionalizacao, totalAtual),
          tooltip: l10n?.pdvWebContinueSaleAction ?? 'Continuar venda',
          onPressed: _iniciarVenda,
        ),
      ),
    );
  }

  String _moduloAtualParaIA() {
    switch (_moduloAtual) {
      case ModuloCentralPDV.seletor:
      case ModuloCentralPDV.cockpit:
        return 'geral';
      case ModuloCentralPDV.vendas:
      case ModuloCentralPDV.orcamento:
        return 'pdv';
      case ModuloCentralPDV.recebimento:
      case ModuloCentralPDV.agendaFinanceira:
        return 'financeiro';
      case ModuloCentralPDV.clientesList:
        return 'clientes';
      case ModuloCentralPDV.colaboradoresList:
        return 'colaboradores';
      case ModuloCentralPDV.desempenho:
        return 'colaboradores';
      case ModuloCentralPDV.operacoesCaixa:
        return 'caixa';
      case ModuloCentralPDV.ordemServico:
      case ModuloCentralPDV.atendimentoTecnico:
        return 'assistencia_tecnica';
      case ModuloCentralPDV.compras:
        return 'compras';
      case ModuloCentralPDV.reservas:
        return 'reservas';
      case ModuloCentralPDV.catalogoPublico:
      case ModuloCentralPDV.categorias:
      case ModuloCentralPDV.produtos:
      case ModuloCentralPDV.servicos:
      case ModuloCentralPDV.estoque:
        return 'produtos';
      case ModuloCentralPDV.configuracoes:
        return 'configuracoes';
    }
  }

  String _telaAtualParaIA() {
    switch (_moduloAtual) {
      case ModuloCentralPDV.seletor:
        return 'inicio_web';
      case ModuloCentralPDV.cockpit:
        return 'cockpit_web';
      case ModuloCentralPDV.vendas:
        return 'vendas_web';
      case ModuloCentralPDV.recebimento:
        return 'recebimento_web';
      case ModuloCentralPDV.clientesList:
        return 'clientes_lista_web';
      case ModuloCentralPDV.colaboradoresList:
        return 'colaboradores_lista_web';
      case ModuloCentralPDV.desempenho:
        return 'desempenho_colaborador_web';
      case ModuloCentralPDV.orcamento:
        return 'orcamento_web';
      case ModuloCentralPDV.operacoesCaixa:
        return 'operacoes_caixa_web';
      case ModuloCentralPDV.ordemServico:
        return 'ordem_servico_web';
      case ModuloCentralPDV.agendaFinanceira:
        return 'agenda_financeira_web';
      case ModuloCentralPDV.atendimentoTecnico:
        return 'atendimentos_tecnicos_web';
      case ModuloCentralPDV.compras:
        return 'compras_web';
      case ModuloCentralPDV.reservas:
        return 'reservas_catalogo_web';
      case ModuloCentralPDV.catalogoPublico:
        return 'catalogo_publico_personalizacao_web';
      case ModuloCentralPDV.produtos:
        return 'produtos_dashboard_web';
      case ModuloCentralPDV.servicos:
        return 'servicos_dashboard_web';
      case ModuloCentralPDV.estoque:
        return 'estoque_dashboard_web';
      case ModuloCentralPDV.categorias:
        return 'categorias_web';
      case ModuloCentralPDV.configuracoes:
        return 'configuracoes_web';
    }
  }

  Widget _buildUserMenuButton() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = _webHeaderAccentColor(colorScheme, tokens);
    final ColaboradorAutorizacoesProvider autorizacoes =
        context.watch<ColaboradorAutorizacoesProvider>();
    final bool podeAcessarSuporte =
        autorizacoes.ehSuperUsuario ||
        autorizacoes.ehAdministrador ||
        autorizacoes.ehColaborador;

    return AnimatedBuilder(
      animation: UsuarioProvider(),
      builder: (BuildContext context, Widget? child) {
        final String fotoUsuario = UsuarioProvider().usuario?.foto.trim() ?? '';

        return Tooltip(
          message: context.t('web.header.userMenu', fallback: 'Usuário'),
          child: PopupMenuButton<_WebHeaderUserAction>(
            tooltip: '',
            position: PopupMenuPosition.under,
            color: tokens.menuBackground,
            constraints: const BoxConstraints(minWidth: 228, maxWidth: 248),
            onSelected: (_WebHeaderUserAction action) {
              switch (action) {
                case _WebHeaderUserAction.profile:
                  showMeuPerfilWebDialog(context);
                  return;
                case _WebHeaderUserAction.support:
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChatSuporteWebPage(),
                    ),
                  );
                  return;
                case _WebHeaderUserAction.logout:
                  _confirmarLogout();
                  return;
              }
            },
            itemBuilder:
                (BuildContext context) =>
                    <PopupMenuEntry<_WebHeaderUserAction>>[
                      PopupMenuItem<_WebHeaderUserAction>(
                        value: _WebHeaderUserAction.profile,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: accent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.t(
                                'web.header.myProfile',
                                fallback: 'Meu perfil',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (podeAcessarSuporte)
                        PopupMenuItem<_WebHeaderUserAction>(
                          value: _WebHeaderUserAction.support,
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.support_agent_rounded,
                                size: 18,
                                color: accent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.t(
                                  'chatSupport.title',
                                  fallback: 'Suporte',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SixWebThemeMenuEntry<_WebHeaderUserAction>(),
                      PopupMenuItem<_WebHeaderUserAction>(
                        value: _WebHeaderUserAction.logout,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.logout_rounded, size: 18, color: accent),
                            const SizedBox(width: 10),
                            Text(
                              context.t('web.header.logout', fallback: 'Sair'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
            child: AnimatedContainer(
              key: const Key('web-header-user-action'),
              duration: WebThemeTokens.transitionDuration,
              curve: WebThemeTokens.transitionCurve,
              height: 46,
              padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: UserProfileAvatarImage(
                      imageValue: fotoUsuario,
                      fallbackIcon: Icons.account_circle_outlined,
                      fallbackColor: accent,
                      fallbackIconSize: 20,
                      size: 30,
                      circle: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: tokens.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmarLogout() async {
    final bool confirmar = await showSixWebLogoutDialog(
      context: context,
      onConfirm: _executarLogout,
    );

    if (!confirmar) return;
    _redirecionarParaLoginPublico();
  }

  Future<void> _executarLogout() async {
    await AuthService().logout();
    WebAuthenticatedBootstrapService().clearInMemorySession(
      mounted ? context : null,
    );
  }

  void _redirecionarParaLoginPublico() {
    if (replaceBrowserLocation('/login')) {
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  String _badgeNotificacaoTexto() {
    if (_quantidadeNotificacoesNaoLidas <= 0) {
      return '';
    }

    if (_quantidadeNotificacoesNaoLidas > 9) {
      return '+9';
    }

    return '+$_quantidadeNotificacoesNaoLidas';
  }

  void _abrirPainelNotificacoes() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 640),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.notifications_active_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notificações',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _notificacoes.clear();
                          _quantidadeNotificacoesNaoLidas = 0;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Limpar'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _notificacoes.isEmpty
                          ? Center(
                            child: Text(
                              'Nenhuma notificação recebida.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          : ListView.separated(
                            controller: _notificacoesScrollController,
                            primary: false,
                            itemCount: _notificacoes.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (BuildContext context, int index) {
                              final Map<String, dynamic> item =
                                  _notificacoes[index];
                              final String ordemId =
                                  item['ordemId']?.toString() ?? '-';
                              final String status =
                                  item['status']?.toString() ?? '-';
                              final String mensagem =
                                  item['mensagem']?.toString() ??
                                  'Sem mensagem';
                              final String recebidoEm =
                                  item['recebidoEm']?.toString() ?? '';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.campaign_rounded,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            mensagem,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text('Ordem: $ordemId'),
                                    const SizedBox(height: 4),
                                    Text('Status: $status'),
                                    if (recebidoEm.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Recebido em: $recebidoEm',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _quantidadeNotificacoesNaoLidas = 0;
      });
    });
  }

  Widget _buildNotificationBellButton() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = _webHeaderAccentColor(colorScheme, tokens);
    final bool temNaoLidas = _quantidadeNotificacoesNaoLidas > 0;
    final String badgeTexto = _badgeNotificacaoTexto();
    final Color badgeForeground = _foregroundForBackground(tokens.warning);

    return AnimatedBuilder(
      animation: _bellRotationAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.rotate(
          angle: _bellRotationAnimation.value,
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              overlayColor: _webHeaderActionOverlay(tokens),
              onTap: _abrirPainelNotificacoes,
              child: AnimatedContainer(
                key: const Key('web-header-notification-action'),
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Icon(
                  temNaoLidas
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: temNaoLidas ? tokens.warning : accent,
                ),
              ),
            ),
          ),
          if (temNaoLidas)
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.warning,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: tokens.warning.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  badgeTexto,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeForeground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrirSelecaoProdutoWeb({String tipoInicial = 'PRODUTO'}) async {
    if (_vendaNaoLiquidadaEmConsulta != null &&
        !_vendaNaoLiquidadaPermiteEdicaoItens) {
      return;
    }
    if (!await _garantirSessaoCaixaAbertaParaVenda()) {
      return;
    }
    if (!mounted) {
      return;
    }

    final dynamic result = await showProdutoListaSelecaoWebDialog<dynamic>(
      context: context,
      permitirSelecaoMultipla: true,
      tipoInicial: tipoInicial,
      apenasAtivosNoBackend: true,
      widthFactor: 0.80,
      heightFactor: 0.80,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
    );

    if (!mounted) {
      return;
    }

    if (result is ProdutoModel) {
      await _adicionarProdutoSelecionado(result);
    } else if (result is List) {
      final List<ProdutoModel> produtos = result
          .whereType<ProdutoModel>()
          .toList(growable: false);

      if (produtos.isNotEmpty) {
        await _adicionarProdutosSelecionados(produtos);
      }
    }

    _restaurarFocoLeituraRapidaSeCabivel();
  }

  Future<void> _abrirListaProdutosParaEdicao({
    String tipoInicial = 'PRODUTO',
    bool exibirInformacoesEstoque = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.9,
            child: SubPainelWebProdutoLista(
              isSelecao: false,
              modoEdicao: true,
              tipoInicial: tipoInicial,
              exibirInformacoesEstoque: exibirInformacoesEstoque,
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirCategoriasDoCatalogo() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width * 0.92,
            height: MediaQuery.sizeOf(dialogContext).height * 0.9,
            child: CategoriasProdutosServicosWebPage(
              embedded: true,
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirEtiquetasDoCatalogo() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width * 0.92,
            height: MediaQuery.sizeOf(dialogContext).height * 0.9,
            child: EtiquetasWebPage(
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _iniciarVenda() async {
    setState(() {
      _moduloAtual = ModuloCentralPDV.vendas;
    });
    _carregarSessaoCaixaPdv();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focarCodigoBarras();
      }
    });
  }

  Future<void> _abrirNovoAtendimentoTecnico() async {
    if (!mounted) {
      return;
    }

    final ProcedureFlowResult procedureResult = await _procedureCoordinator
        .execute(
          context: context,
          operationPoint: ProcedureOperationPoint.technicalServiceStartBefore,
        );
    if (!mounted || !procedureResult.shouldContinue) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: SizedBox(
            width: size.width * 0.96,
            height: size.height * 0.92,
            child: AtendimentosTecnicosWebPage(
              embedded: true,
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  void _abrirModuloCentralPelaNavegacaoWeb(ModuloCentralPDV modulo) {
    if (!mounted) {
      return;
    }

    if (modulo == ModuloCentralPDV.configuracoes) {
      showConfiguracoesSixWebDialog(context);
      return;
    }

    setState(() {
      _moduloRetornoOperacoesCaixa = null;
      _moduloAtual = modulo;
    });
  }

  Future<void> _abrirOperacoesCaixa({
    ModuloCentralPDV retorno = ModuloCentralPDV.seletor,
  }) async {
    final ProcedureFlowResult result = await _procedureCoordinator.execute(
      context: context,
      operationPoint: ProcedureOperationPoint.cashRegisterStartBefore,
    );
    if (!mounted || !result.shouldContinue) return;
    setState(() {
      _moduloRetornoOperacoesCaixa = retorno;
      _moduloAtual = ModuloCentralPDV.operacoesCaixa;
    });
  }

  void _voltarDeOperacoesCaixa() {
    final ModuloCentralPDV retorno =
        _moduloRetornoOperacoesCaixa ?? ModuloCentralPDV.seletor;

    setState(() {
      _moduloRetornoOperacoesCaixa = null;
      _moduloAtual = retorno;
    });

    if (retorno == ModuloCentralPDV.vendas) {
      _carregarSessaoCaixaPdv();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focarCodigoBarras();
        }
      });
    }
  }

  Future<void> _carregarSessaoCaixaPdv() async {
    if (_carregandoSessaoCaixaPdv) {
      return;
    }

    setState(() {
      _carregandoSessaoCaixaPdv = true;
      _erroSessaoCaixaPdv = false;
    });

    try {
      final CaixaSessao? sessao = await _caixaService.buscarSessaoAtual();
      if (!mounted) {
        return;
      }

      setState(() {
        _sessaoCaixaPdv = sessao;
        _erroSessaoCaixaPdv = false;
        _sessaoCaixaPdvSincronizada = true;
        _referenciaTempoSessaoCaixaPdv = DateTime.now();
      });
      _sincronizarTimerTempoAtivoSessaoCaixaPdv();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sessaoCaixaPdv = null;
        _erroSessaoCaixaPdv = true;
        _sessaoCaixaPdvSincronizada = true;
      });
      _sincronizarTimerTempoAtivoSessaoCaixaPdv();
    } finally {
      if (mounted) {
        setState(() {
          _carregandoSessaoCaixaPdv = false;
        });
      }
    }
  }

  Future<void> _atualizarVisaoPdv() async {
    if (_atualizandoVisaoPdv) {
      return;
    }

    setState(() {
      _atualizandoVisaoPdv = true;
    });

    try {
      await Future.wait<void>(<Future<void>>[
        _carregarSessaoCaixaPdv(),
        _sincronizarTotalVendasAReceber(),
      ]);
      if (!mounted) {
        return;
      }

      final VendaNaoLiquidadaModel? vendaEmConsulta =
          _vendaNaoLiquidadaEmConsulta;
      final bool podeRecarregarVendaEmConsulta =
          vendaEmConsulta != null &&
          !_recebendoVendaNaoLiquidada &&
          !_vendaNaoLiquidadaPossuiAlteracoesNosItens;

      if (podeRecarregarVendaEmConsulta) {
        await _carregarVendaNaoLiquidadaNoPdv(vendaEmConsulta);
        if (!mounted) {
          return;
        }
      } else {
        setState(() {
          _atualizarCamposDerivados();
        });
      }

      _restaurarFocoLeituraRapidaSeCabivel();
    } finally {
      if (mounted) {
        setState(() {
          _atualizandoVisaoPdv = false;
        });
      }
    }
  }

  bool _sessaoCaixaPdvAberta(CaixaSessao sessao) {
    final String status = sessao.status.trim().toLowerCase();
    return status == 'aberta' ||
        status == 'open' ||
        status == 'active' ||
        status == 'ativa' ||
        status == 'true';
  }

  void _sincronizarTimerTempoAtivoSessaoCaixaPdv() {
    final CaixaSessao? sessao = _sessaoCaixaPdv;
    final bool deveAtualizarTempo =
        sessao != null && _sessaoCaixaPdvAberta(sessao);

    if (!deveAtualizarTempo) {
      _sessaoCaixaPdvTempoAtivoTimer?.cancel();
      _sessaoCaixaPdvTempoAtivoTimer = null;
      return;
    }

    if (_sessaoCaixaPdvTempoAtivoTimer != null) {
      return;
    }

    _sessaoCaixaPdvTempoAtivoTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _referenciaTempoSessaoCaixaPdv = DateTime.now();
        });
      },
    );
  }

  bool get _pdvTemSessaoCaixaAberta {
    final CaixaSessao? sessao = _sessaoCaixaPdv;
    return sessao != null && _sessaoCaixaPdvAberta(sessao);
  }

  bool get _pdvPodeLancarVenda {
    return !_carregandoSessaoCaixaPdv &&
        !_erroSessaoCaixaPdv &&
        _pdvTemSessaoCaixaAberta;
  }

  Future<bool> _garantirSessaoCaixaAbertaParaVenda() async {
    if (_pdvPodeLancarVenda) {
      return true;
    }

    if (!_carregandoSessaoCaixaPdv) {
      await _carregarSessaoCaixaPdv();
      if (_pdvPodeLancarVenda) {
        return true;
      }
    }

    if (!mounted) {
      return false;
    }

    _mostrarAvisoSessaoCaixaObrigatoriaPdv();
    return false;
  }

  void _mostrarAvisoSessaoCaixaObrigatoriaPdv() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            'pdv.cashSessionRequiredMessage',
            fallback: 'Abra uma sessão de caixa antes de lançar vendas no PDV.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: context.t(
            'pdv.openCashOperations',
            fallback: 'Operações de caixa',
          ),
          onPressed: () {
            _abrirOperacoesCaixa(retorno: ModuloCentralPDV.vendas);
          },
        ),
      ),
    );
  }

  bool get _atalhosContextuaisDisponiveis {
    return _moduloAtual == ModuloCentralPDV.vendas &&
        (_vendaNaoLiquidadaEmConsulta == null ||
            _vendaNaoLiquidadaPermiteEdicaoItens) &&
        !_overlayRecebimentoAberto &&
        _barcodeInteractionActive;
  }

  bool get _prefereReducaoDeMovimento {
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return false;
    }
    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }

  void _onBarcodeInteractionFocusChanged() {
    if (!mounted) {
      return;
    }

    final bool isActive = _barcodeInteractionFocusScopeNode.hasFocus;
    if (_barcodeInteractionActive == isActive) {
      return;
    }

    setState(() {
      _barcodeInteractionActive = isActive;
    });
  }

  void _restaurarFocoLeituraRapidaSeCabivel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _moduloAtual != ModuloCentralPDV.vendas ||
          _overlayRecebimentoAberto) {
        return;
      }
      _focarCodigoBarras();
    });
  }

  void _alternarModoExpandidoFrenteCaixa() {
    if (_moduloAtual != ModuloCentralPDV.vendas) {
      return;
    }

    setState(() {
      _modoExpandidoFrenteCaixa = !_modoExpandidoFrenteCaixa;
    });
  }

  Future<void> _confirmarFecharFrenteCaixa() async {
    if (_moduloAtual != ModuloCentralPDV.vendas) {
      return;
    }

    if (!_vendaTemDadosTemporariosPreenchidos()) {
      _fecharFrenteCaixa();
      return;
    }

    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool confirmar =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                l10n?.pdvWebCloseFrontDeskConfirmTitle ??
                    'Fechar frente de caixa?',
              ),
              content: Text(
                l10n?.pdvWebCloseFrontDeskConfirmMessage ??
                    'Existe uma venda em andamento. Ao fechar esta tela, você poderá continuar esta venda depois.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    l10n?.pdvWebContinueSaleAction ?? 'Continuar venda',
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    l10n?.pdvWebCloseFrontDeskAction ??
                        'Fechar frente de caixa',
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmar) {
      _fecharFrenteCaixa();
    }
  }

  void _fecharFrenteCaixa() {
    setState(() {
      _modoExpandidoFrenteCaixa = false;
      _moduloAtual = ModuloCentralPDV.seletor;
      _barcodeInteractionActive = false;
    });
  }

  bool _vendaTemDadosTemporariosPreenchidos() {
    return _vendaNaoLiquidadaEmConsulta != null ||
        _produtosSelecionados.isNotEmpty ||
        _formasPagamentoConfirmadas.isNotEmpty ||
        _clienteIdentificado != null ||
        _clienteIdentificadoController.text.trim().isNotEmpty ||
        _codigoBarrasController.text.trim().isNotEmpty;
  }

  String _itemVisualKey(Map<String, dynamic> item) {
    final String key = item['chaveItem']?.toString().trim() ?? '';
    if (key.isNotEmpty) {
      return key;
    }

    final String tipo = _normalizarTipoProdutoWeb(
      item['tipoProduto']?.toString() ??
          ((item['ehServico'] ?? false) == true ? 'SERVICO' : 'PRODUTO'),
    );
    final String id = item['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) {
      return '$tipo:id:$id';
    }

    final String codigo = item['codigo']?.toString().trim() ?? '';
    if (codigo.isNotEmpty) {
      return '$tipo:codigo:$codigo';
    }

    final String nome = item['nome']?.toString().trim().toLowerCase() ?? '';
    final double preco = ((item['preco'] ?? 0) as num).toDouble();
    return '$tipo:nome:$nome|preco:${preco.toStringAsFixed(4)}';
  }

  GlobalKey _itemRowKey(String itemKey) {
    return _itemRowKeysByItemKey.putIfAbsent(
      itemKey,
      () => GlobalKey(debugLabel: 'pdv-item-row-$itemKey'),
    );
  }

  _PdvItemVisualFeedback? _itemVisualFeedbackForKey(String itemKey) {
    return _itemVisualFeedbackByItemKey[itemKey];
  }

  Color _itemFeedbackHighlightColor(_PdvItemVisualFeedback feedback) {
    switch (feedback) {
      case _PdvItemVisualFeedback.itemAdded:
      case _PdvItemVisualFeedback.quantityIncreased:
        return _pdvTheme.successColor.withValues(alpha: 0.16);
      case _PdvItemVisualFeedback.quantityDecreased:
        return _pdvTheme.warningColor.withValues(alpha: 0.18);
    }
  }

  Duration _itemFeedbackDuration(_PdvItemVisualFeedback feedback) {
    if (_prefereReducaoDeMovimento) {
      return const Duration(milliseconds: 120);
    }

    switch (feedback) {
      case _PdvItemVisualFeedback.itemAdded:
      case _PdvItemVisualFeedback.quantityIncreased:
        return const Duration(milliseconds: 820);
      case _PdvItemVisualFeedback.quantityDecreased:
        return const Duration(milliseconds: 700);
    }
  }

  void _clearAllItemVisualState() {
    for (final Timer timer in _itemVisualFeedbackTimersByItemKey.values) {
      timer.cancel();
    }
    _itemVisualFeedbackTimersByItemKey.clear();
    _itemVisualFeedbackByItemKey.clear();
    _itemRowKeysByItemKey.clear();
  }

  void _clearItemVisualStateForKey(String itemKey) {
    _itemVisualFeedbackTimersByItemKey.remove(itemKey)?.cancel();
    _itemVisualFeedbackByItemKey.remove(itemKey);
    _itemRowKeysByItemKey.remove(itemKey);
  }

  void _scheduleItemFeedbackClear(
    String itemKey,
    _PdvItemVisualFeedback value,
  ) {
    _itemVisualFeedbackTimersByItemKey[itemKey]?.cancel();
    _itemVisualFeedbackTimersByItemKey[itemKey] = Timer(
      _itemFeedbackDuration(value),
      () {
        if (!mounted) {
          return;
        }
        final _PdvItemVisualFeedback? current =
            _itemVisualFeedbackByItemKey[itemKey];
        if (current != value) {
          return;
        }
        setState(() {
          _itemVisualFeedbackByItemKey.remove(itemKey);
        });
        _itemVisualFeedbackTimersByItemKey.remove(itemKey)?.cancel();
      },
    );
  }

  void _registerItemFeedbackWithoutSetState(
    String itemKey,
    _PdvItemVisualFeedback value,
  ) {
    _itemVisualFeedbackByItemKey[itemKey] = value;
    _scheduleItemFeedbackClear(itemKey, value);
  }

  void _scrollToItemIfNeeded(String itemKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _moduloAtual != ModuloCentralPDV.vendas ||
          !_gradeItensScrollController.hasClients) {
        return;
      }

      final GlobalKey? rowKey = _itemRowKeysByItemKey[itemKey];
      final BuildContext? rowContext = rowKey?.currentContext;
      if (rowContext == null) {
        return;
      }

      final RenderObject? renderObject = rowContext.findRenderObject();
      if (renderObject is! RenderBox) {
        return;
      }

      final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
        renderObject,
      );
      if (viewport == null) {
        return;
      }

      final ScrollPosition position = _gradeItensScrollController.position;
      final RevealedOffset revealStart = viewport.getOffsetToReveal(
        renderObject,
        0.0,
      );
      final RevealedOffset revealEnd = viewport.getOffsetToReveal(
        renderObject,
        1.0,
      );
      final double currentOffset = position.pixels;
      final double viewportEnd = currentOffset + position.viewportDimension;
      final bool fullyVisible =
          revealStart.offset >= currentOffset &&
          revealEnd.offset <= viewportEnd;

      if (fullyVisible) {
        return;
      }

      final double targetOffset =
          revealStart.offset
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble();
      _gradeItensScrollController.animateTo(
        targetOffset,
        duration:
            _prefereReducaoDeMovimento
                ? const Duration(milliseconds: 120)
                : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _limparDadosTemporariosVenda({required ModuloCentralPDV moduloDestino}) {
    setState(() {
      _produtosSelecionados.clear();
      _formasPagamentoConfirmadas = <FormaPagamentoSelecionada>[];
      _descricoesFormaPagamentoPorCodigo = <String, String>{};
      _pagamentoParcialConfirmado = false;
      _codigoBarrasController.clear();
      _itensTotalController.text = '0';
      _clienteIdentificado = null;
      _clienteIdentificadoController.clear();
      _vendaNaoLiquidadaEmConsulta = null;
      _procedimentoVendaWebJaAvaliado = false;
      _recebendoVendaNaoLiquidada = false;
      _clearAllItemVisualState();
      _moduloAtual = moduloDestino;
    });

    if (moduloDestino == ModuloCentralPDV.vendas) {
      _carregarSessaoCaixaPdv();
    }
  }

  Future<void> _confirmarLimparVendaAtual() async {
    if (!_vendaTemDadosTemporariosPreenchidos()) {
      return;
    }

    if (_vendaNaoLiquidadaEmConsulta != null) {
      await _confirmarSairDaConsultaVendaNaoLiquidada();
      return;
    }

    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool confirmar = await showSixWebPdvClearSaleDialog(
      context: context,
      itemCount: _produtosSelecionados.length,
      totalLabel: _formatCurrency(_calcularTotal()),
      customerLabel:
          _clienteSelecionadoNaVenda
              ? _clienteAtualLabel()
              : (l10n?.pdvWebCustomerNotInformedStatus ??
                  'Cliente não identificado'),
      onConfirm: () async {
        _limparDadosTemporariosVenda(moduloDestino: ModuloCentralPDV.vendas);
      },
    );

    if (confirmar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focarCodigoBarras();
        }
      });
    }
  }

  Future<void> _confirmarSairDaConsultaVendaNaoLiquidada() async {
    final bool possuiAlteracoes = _vendaNaoLiquidadaPossuiAlteracoesNosItens;
    final bool sair =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                context.t(
                  possuiAlteracoes
                      ? 'pdv.openSale.discardTitle'
                      : 'pdv.openSale.exitTitle',
                  fallback:
                      possuiAlteracoes
                          ? 'Descartar alterações?'
                          : 'Sair da consulta?',
                ),
              ),
              content: Text(
                context.t(
                  possuiAlteracoes
                      ? 'pdv.openSale.discardMessage'
                      : 'pdv.openSale.exitMessage',
                  fallback:
                      possuiAlteracoes
                          ? 'As alterações feitas no PDV não serão salvas. A venda continuará em aberto com os dados anteriores.'
                          : 'A venda continuará em aberto. Nenhum item, preço ou recebimento será alterado.',
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.t('common.back', fallback: 'Voltar')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    context.t(
                      possuiAlteracoes
                          ? 'pdv.openSale.discardAction'
                          : 'pdv.openSale.exitAction',
                      fallback:
                          possuiAlteracoes
                              ? 'Descartar e sair'
                              : 'Sair da consulta',
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!sair || !mounted) {
      return;
    }

    _limparDadosTemporariosVenda(moduloDestino: ModuloCentralPDV.vendas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focarCodigoBarras();
      }
    });
  }

  Future<void> _adicionarProdutoSelecionado(ProdutoModel produto) async {
    if (_vendaNaoLiquidadaEmConsulta != null &&
        !_vendaNaoLiquidadaPermiteEdicaoItens) {
      return;
    }
    final bool deveExecutarProcedimento =
        _deveExecutarProcedimentoNaPrimeiraInclusaoNoCarrinho;
    late final _PdvItemMutationResult mutation;
    setState(() {
      mutation = _adicionarProdutoNaListaSemSetState(produto);
      _atualizarCamposDerivados();
      _registerItemFeedbackWithoutSetState(
        mutation.itemKey,
        mutation.isNewItem
            ? _PdvItemVisualFeedback.itemAdded
            : _PdvItemVisualFeedback.quantityIncreased,
      );
    });

    if (mutation.isNewItem) {
      _scrollToItemIfNeeded(mutation.itemKey);
    }

    await _executarProcedimentoAposPrimeiroItemSeNecessario(
      deveExecutarProcedimento,
    );
  }

  Future<void> _adicionarProdutosSelecionados(
    List<ProdutoModel> produtos,
  ) async {
    if ((_vendaNaoLiquidadaEmConsulta != null &&
            !_vendaNaoLiquidadaPermiteEdicaoItens) ||
        produtos.isEmpty) {
      return;
    }

    final bool deveExecutarProcedimento =
        _deveExecutarProcedimentoNaPrimeiraInclusaoNoCarrinho;
    final List<_PdvItemMutationResult> mutations = <_PdvItemMutationResult>[];
    setState(() {
      for (final ProdutoModel produto in produtos) {
        final _PdvItemMutationResult mutation =
            _adicionarProdutoNaListaSemSetState(produto);
        mutations.add(mutation);
        _registerItemFeedbackWithoutSetState(
          mutation.itemKey,
          mutation.isNewItem
              ? _PdvItemVisualFeedback.itemAdded
              : _PdvItemVisualFeedback.quantityIncreased,
        );
      }

      _atualizarCamposDerivados();
    });

    for (final _PdvItemMutationResult mutation in mutations) {
      if (mutation.isNewItem) {
        _scrollToItemIfNeeded(mutation.itemKey);
      }
    }

    await _executarProcedimentoAposPrimeiroItemSeNecessario(
      deveExecutarProcedimento,
    );
  }

  Future<void> _executarProcedimentoAposPrimeiroItemSeNecessario(
    bool deveExecutarProcedimento,
  ) async {
    if (!deveExecutarProcedimento || !mounted) {
      return;
    }

    final ProcedureFlowResult result = await _procedureCoordinator.execute(
      context: context,
      operationPoint: ProcedureOperationPoint.saleStartBefore,
    );
    if (!mounted) {
      return;
    }

    if (result.shouldContinue) {
      setState(() {
        _procedimentoVendaWebJaAvaliado = true;
      });
      _restaurarFocoLeituraRapidaSeCabivel();
      return;
    }

    setState(() {
      _produtosSelecionados.clear();
      _formasPagamentoConfirmadas = <FormaPagamentoSelecionada>[];
      _descricoesFormaPagamentoPorCodigo = <String, String>{};
      _pagamentoParcialConfirmado = false;
      _clearAllItemVisualState();
      _atualizarCamposDerivados();
    });
    _restaurarFocoLeituraRapidaSeCabivel();
  }

  _PdvItemMutationResult _adicionarProdutoNaListaSemSetState(
    ProdutoModel produto,
  ) {
    final String tipoNormalizado = _normalizarTipoProdutoWeb(
      produto.tipoProduto,
    );
    final String chaveProduto = _chaveProdutoVenda(produto);

    final int indexExistente = _produtosSelecionados.indexWhere(
      (Map<String, dynamic> item) => _mesmoProduto(item, produto),
    );

    if (indexExistente >= 0) {
      final int quantidadeAtual =
          (_produtosSelecionados[indexExistente]['quantidade'] ?? 1) as int;
      _produtosSelecionados[indexExistente]['quantidade'] = quantidadeAtual + 1;
      return _PdvItemMutationResult(
        itemKey: _itemVisualKey(_produtosSelecionados[indexExistente]),
        isNewItem: false,
      );
    }

    _produtosSelecionados.add(<String, dynamic>{
      'id': _extrairIdProduto(produto),
      'codigo': produto.codigoDeBarras,
      'nome': produto.nomeProduto,
      'preco': produto.precoVenda,
      'quantidade': 1,
      'tipoProduto': tipoNormalizado,
      'ehServico': _ehServicoTipoWeb(tipoNormalizado),
      'chaveItem': chaveProduto,
      'produtoOriginal': produto,
    });

    return _PdvItemMutationResult(itemKey: chaveProduto, isNewItem: true);
  }

  bool _mesmoProduto(Map<String, dynamic> item, ProdutoModel produto) {
    final String chaveItem = item['chaveItem']?.toString() ?? '';
    final String chaveProduto = _chaveProdutoVenda(produto);
    if (chaveItem.isNotEmpty && chaveItem == chaveProduto) {
      return true;
    }

    final String tipoItem = _normalizarTipoProdutoWeb(
      item['tipoProduto']?.toString() ??
          ((item['ehServico'] ?? false) == true ? 'SERVICO' : 'PRODUTO'),
    );
    final String tipoProduto = _normalizarTipoProdutoWeb(produto.tipoProduto);
    if (tipoItem != tipoProduto) return false;

    final dynamic idItem = item['id'];
    final dynamic idProduto = _extrairIdProduto(produto);

    if (idItem != null && idProduto != null) {
      return idItem.toString() == idProduto.toString();
    }

    final String codigoItem = item['codigo']?.toString().trim() ?? '';
    final String codigoProduto = produto.codigoDeBarras.trim();

    if (codigoItem.isNotEmpty && codigoProduto.isNotEmpty) {
      return codigoItem == codigoProduto;
    }

    return item['nome'] == produto.nomeProduto;
  }

  dynamic _extrairIdProduto(ProdutoModel produto) {
    final String? id = produto.id;
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    return null;
  }

  String _normalizarTipoProdutoWeb(String tipo) {
    final String normalizado = tipo.trim().toUpperCase();
    if (normalizado == 'SERVICO' || normalizado == 'SERVIÇO') {
      return 'SERVICO';
    }
    return 'PRODUTO';
  }

  bool _ehServicoTipoWeb(String tipo) {
    return _normalizarTipoProdutoWeb(tipo) == 'SERVICO';
  }

  bool _ehServicoItem(Map<String, dynamic> item) {
    final Object? valor = item['ehServico'];
    if (valor == true) return true;
    return _ehServicoTipoWeb(item['tipoProduto']?.toString() ?? '');
  }

  String _chaveProdutoVenda(ProdutoModel produto) {
    final String tipo = _normalizarTipoProdutoWeb(produto.tipoProduto);
    final dynamic id = _extrairIdProduto(produto);
    if (id != null && id.toString().trim().isNotEmpty) {
      return '$tipo:id:${id.toString().trim()}';
    }

    final String codigo = produto.codigoDeBarras.trim();
    if (codigo.isNotEmpty) {
      return '$tipo:codigo:$codigo';
    }

    final String nome = produto.nomeProduto.trim().toLowerCase();
    return '$tipo:nome:$nome|preco:${produto.precoVenda.toStringAsFixed(4)}';
  }

  void _alterarQuantidade(Map<String, dynamic> produto, int delta) {
    final int quantidadeAtual = (produto['quantidade'] ?? 1) as int;
    _definirQuantidadeProduto(produto, quantidadeAtual + delta);
  }

  void _definirQuantidadeProduto(
    Map<String, dynamic> produto,
    int novaQuantidade,
  ) {
    if (_vendaNaoLiquidadaEmConsulta != null &&
        !_vendaNaoLiquidadaPermiteEdicaoItens) {
      return;
    }

    final int quantidadeAtual = (produto['quantidade'] ?? 1) as int;
    if (quantidadeAtual == novaQuantidade) {
      _restaurarFocoLeituraRapidaSeCabivel();
      return;
    }

    final String itemKey = _itemVisualKey(produto);
    setState(() {
      if (novaQuantidade <= 0) {
        _produtosSelecionados.remove(produto);
        _clearItemVisualStateForKey(itemKey);
      } else {
        produto['quantidade'] = novaQuantidade;
        _registerItemFeedbackWithoutSetState(
          itemKey,
          novaQuantidade > quantidadeAtual
              ? _PdvItemVisualFeedback.quantityIncreased
              : _PdvItemVisualFeedback.quantityDecreased,
        );
      }

      _atualizarCamposDerivados();
    });

    _restaurarFocoLeituraRapidaSeCabivel();
  }

  void _removerProduto(Map<String, dynamic> produto) {
    if (_vendaNaoLiquidadaEmConsulta != null &&
        !_vendaNaoLiquidadaPermiteEdicaoItens) {
      return;
    }
    final String itemKey = _itemVisualKey(produto);
    setState(() {
      _produtosSelecionados.remove(produto);
      _clearItemVisualStateForKey(itemKey);
      _atualizarCamposDerivados();
    });

    _restaurarFocoLeituraRapidaSeCabivel();
  }

  void _atualizarCamposDerivados() {
    _itensTotalController.text = _calcularQuantidadeItens().toString();
  }

  double _calcularTotal() {
    return _produtosSelecionados.fold<double>(0, (
      double soma,
      Map<String, dynamic> item,
    ) {
      return soma +
          (((item['preco'] ?? 0) as num).toDouble() *
              ((item['quantidade'] ?? 1) as int));
    });
  }

  int _calcularQuantidadeItens() {
    return _produtosSelecionados.fold<int>(
      0,
      (int soma, Map<String, dynamic> item) =>
          soma + ((item['quantidade'] ?? 1) as int),
    );
  }

  double _calcularSubtotal(Map<String, dynamic> produto) {
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final int quantidade = (produto['quantidade'] ?? 1) as int;
    return preco * quantidade;
  }

  void _mostrarDialogMensagem(String titulo, String mensagem) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _focarCodigoBarras() {
    if (_vendaNaoLiquidadaEmConsulta != null &&
        !_vendaNaoLiquidadaPermiteEdicaoItens) {
      return;
    }
    _codigoBarrasFocusNode.requestFocus();
  }

  Future<void> _abrirDialogClienteRapido() async {
    if (_vendaNaoLiquidadaEmConsulta != null) {
      return;
    }
    final ClienteIdentificacaoVendaResult? result =
        await showDialog<ClienteIdentificacaoVendaResult>(
          context: context,
          builder: (BuildContext context) {
            return PdvClienteIdentificacaoDialog(
              clienteAtual: _clienteIdentificado,
            );
          },
        );

    if (result == null) {
      _restaurarFocoLeituraRapidaSeCabivel();
      return;
    }

    setState(() {
      if (result.limpar) {
        _clienteIdentificado = null;
        _clienteIdentificadoController.clear();
        return;
      }

      final ClienteUsuario? cliente = result.cliente;
      _clienteIdentificado = cliente;
      _clienteIdentificadoController.text =
          cliente?.nome.trim().isNotEmpty == true
              ? cliente!.nome.trim()
              : cliente?.documento.trim() ?? '';
    });

    _restaurarFocoLeituraRapidaSeCabivel();
  }

  KeyEventResult _handleAtalhoPdv(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_overlayRecebimentoAberto) {
      return KeyEventResult.handled;
    }

    if (_moduloAtual != ModuloCentralPDV.vendas) {
      return KeyEventResult.ignored;
    }

    if (_vendaNaoLiquidadaEmConsulta != null) {
      if (event.logicalKey == LogicalKeyboardKey.f8) {
        _acionarRecebimentoPrincipal();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _confirmarSairDaConsultaVendaNaoLiquidada();
        return KeyEventResult.handled;
      }
      if (!_vendaNaoLiquidadaPermiteEdicaoItens) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _abrirSelecaoProdutoWeb();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (!_atalhosContextuaisDisponiveis) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _abrirSelecaoProdutoWeb();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.f4) {
      _abrirDialogClienteRapido();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.f8 &&
        _produtosSelecionados.isNotEmpty) {
      _acionarRecebimentoPrincipal();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _confirmarLimparVendaAtual();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _pausarVenda() => _registrarVendaParaReceberDepoisWeb();

  List<ItemVendaAtual> _montarItensDaVendaParaOperacao() {
    return _produtosSelecionados
        .map((Map<String, dynamic> produto) {
          final String idProduto =
              (produto['id'] ?? produto['codigo'] ?? '').toString();

          return ItemVendaAtual(
            idProduto: idProduto,
            nome: (produto['nome'] ?? '').toString(),
            quantidade: (produto['quantidade'] ?? 1) as int,
            valorUnitario: ((produto['preco'] ?? 0) as num).toDouble(),
            ehServico: _ehServicoItem(produto),
          );
        })
        .toList(growable: false);
  }

  Future<void> _registrarVendaParaReceberDepoisWeb() async {
    if (_registrandoReceberDepois) {
      return;
    }

    if (!await _garantirSessaoCaixaAbertaParaVenda()) {
      return;
    }
    if (!mounted) {
      return;
    }

    if (_produtosSelecionados.isEmpty) {
      _mostrarDialogMensagem(
        'Venda vazia',
        'Adicione pelo menos um item antes de registrar para receber depois.',
      );
      return;
    }

    final double total = _calcularTotal();
    final int quantidadeItens = _calcularQuantidadeItens();

    final bool confirmou =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              icon: Icon(
                Icons.schedule_send_outlined,
                color: _pdvTheme.actionButtonBackground,
                size: 34,
              ),
              title: const Text('Receber depois'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'A venda ficará em aberto para liquidação posterior no caixa.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _pdvTheme.iconColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _pdvTheme.cardBorder),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '$quantidadeItens item(ns)',
                              style: TextStyle(
                                color: _pdvTheme.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            _formatCurrency(total),
                            style: TextStyle(
                              color: _pdvTheme.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Voltar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Registrar para receber depois'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmou || !mounted) {
      return;
    }

    if (!await _executarProcedimentoAntesDeFinalizarVendaWeb()) {
      return;
    }

    setState(() => _registrandoReceberDepois = true);

    try {
      final DateTime dataOperacao = DateTime.now();
      final String idColaborador = await AuthService().getUserId() ?? '';

      final OperacaoVendaInput input = OperacaoVendaInput(
        descricao:
            'Venda web para receber depois ${dataOperacao.toIso8601String()}',
        idColaborador: idColaborador,
        nomeColaborador: 'Colaborador',
        itens: _montarItensDaVendaParaOperacao(),
        formasPagamento: const <FormaPagamentoSelecionada>[],
        dataOperacao: dataOperacao,
        receberDepois: true,
      );

      await _operacaoService.finalizarVenda(input);

      if (!mounted) {
        return;
      }

      await _sincronizarTotalVendasAReceber();
      if (!mounted) {
        return;
      }

      _limparVendaAposSucessoRecebimento();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venda registrada para receber depois.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mostrarDialogMensagem(
        'Erro ao registrar venda',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _registrandoReceberDepois = false);
      }
    }
  }

  bool _temPagamentoConfirmado() {
    return _formasPagamentoConfirmadas.any(
      (FormaPagamentoSelecionada forma) => forma.valor > 0,
    );
  }

  double _totalPagamentoConfirmado() {
    return _formasPagamentoConfirmadas.fold<double>(
      0,
      (double soma, FormaPagamentoSelecionada forma) => soma + forma.valor,
    );
  }

  double _restantePagamentoConfirmado() {
    final double total =
        _vendaNaoLiquidadaEmConsulta?.valorAberto ?? _calcularTotal();
    return total - _totalPagamentoConfirmado();
  }

  bool _pagamentoConfirmadoCompleto() {
    if (!_temPagamentoConfirmado()) {
      return false;
    }

    return _restantePagamentoConfirmado().abs() <= 0.009;
  }

  bool _pagamentoConfirmadoParcial() {
    if (!_pagamentoParcialConfirmado || !_temPagamentoConfirmado()) {
      return false;
    }

    return _totalPagamentoConfirmado() > 0.009 &&
        _restantePagamentoConfirmado() > 0.009;
  }

  bool _pagamentoConfirmadoPrecisaRevisao() {
    return _temPagamentoConfirmado() &&
        !_pagamentoConfirmadoCompleto() &&
        !_pagamentoConfirmadoParcial();
  }

  Future<void> _abrirOverlayRecebimento({required bool somenteSelecao}) async {
    if (_produtosSelecionados.isEmpty) {
      _mostrarDialogMensagem(
        'Venda vazia',
        'Adicione pelo menos um item antes de finalizar.',
      );
      return;
    }

    if (!await _garantirSessaoCaixaAbertaParaVenda()) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _overlayRecebimentoAberto = true;
    });

    try {
      await showRecebimentoPagamentoWebDialog(
        context: context,
        somenteSelecao: somenteSelecao,
        formasPagamentoIniciais: _formasPagamentoConfirmadas,
        descricoesFormasIniciais: _descricoesFormaPagamentoPorCodigo,
        recebimentoParcialInicial: _pagamentoConfirmadoParcial(),
        onSelecaoConfirmada: (RecebimentoPagamentoSelecaoResultado resultado) {
          setState(() {
            _formasPagamentoConfirmadas = resultado.formasPagamento
                .where((FormaPagamentoSelecionada forma) => forma.valor > 0)
                .toList(growable: false);
            _descricoesFormaPagamentoPorCodigo = Map<String, String>.from(
              resultado.descricaoPorCodigo,
            );
            _pagamentoParcialConfirmado = resultado.parcial;
          });
        },
        onSuccess: _limparVendaAposSucessoRecebimento,
        valorTotalVenda: _calcularTotal(),
        itensResumo: _montarItensResumoPagamento(),
        clienteNome:
            _clienteIdentificado?.nome.trim().isNotEmpty == true
                ? _clienteIdentificado!.nome.trim()
                : _clienteIdentificadoController.text.trim(),
        numeroVenda: '',
        idColaborador: 'idUnicoDoColaborador',
        nomeColaborador: 'Nome do colaborador',
        operacaoService: _operacaoService,
        procedureCoordinator: _procedureCoordinator,
      );
    } finally {
      if (mounted) {
        setState(() {
          _overlayRecebimentoAberto = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _moduloAtual == ModuloCentralPDV.vendas) {
            _focarCodigoBarras();
          }
        });
      }
    }
  }

  void _abrirTelaRecebimento() {
    if (_vendaNaoLiquidadaEmConsulta != null) {
      _receberVendaNaoLiquidadaEmConsulta();
      return;
    }
    _abrirOverlayRecebimento(somenteSelecao: true);
  }

  void _editarPagamentoConfirmado() {
    if (_vendaNaoLiquidadaEmConsulta != null) {
      _receberVendaNaoLiquidadaEmConsulta();
      return;
    }
    _abrirOverlayRecebimento(somenteSelecao: true);
  }

  void _acionarRecebimentoPrincipal() {
    if (_vendaNaoLiquidadaEmConsulta != null) {
      _receberVendaNaoLiquidadaEmConsulta();
      return;
    }
    if (_pagamentoConfirmadoCompleto() || _pagamentoConfirmadoParcial()) {
      _abrirOverlayRecebimento(somenteSelecao: false);
      return;
    }

    _abrirOverlayRecebimento(somenteSelecao: true);
  }

  List<Map<String, dynamic>> _montarItensResumoPagamento() {
    return _produtosSelecionados.map((Map<String, dynamic> produto) {
      final int quantidade = (produto['quantidade'] ?? 1) as int;
      final double precoUnitario = ((produto['preco'] ?? 0) as num).toDouble();

      return <String, dynamic>{
        'id': produto['id'],
        'codigo': produto['codigo'],
        'nome': produto['nome'] ?? '',
        'quantidade': quantidade,
        'valor': precoUnitario,
        'subtotal': precoUnitario * quantidade,
        'ehServico': _ehServicoItem(produto),
      };
    }).toList();
  }

  String _formatCurrency(double value) {
    try {
      return context.read<LocaleSettingsProvider>().formatCurrency(value);
    } catch (_) {
      return value.toStringAsFixed(2);
    }
  }

  String? _nomeEmpresaAtualParaHeader() {
    try {
      final EmpresaProvider empresaProvider = context.watch<EmpresaProvider>();
      final empresa = empresaProvider.empresa;
      final String nomeFantasia = empresa?.nomeFantasia.trim() ?? '';
      if (nomeFantasia.isNotEmpty) {
        return nomeFantasia;
      }

      final String nomeEmpresa = empresa?.nomeEmpresa.trim() ?? '';
      if (nomeEmpresa.isNotEmpty) {
        return nomeEmpresa;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _clienteAtualLabel() {
    final ClienteUsuario? cliente = _clienteIdentificado;
    if (cliente != null) {
      final String nome = cliente.nome.trim();
      if (nome.isNotEmpty) {
        return nome;
      }

      final String documento = cliente.documento.trim();
      if (documento.isNotEmpty) {
        return documento;
      }
    }

    final String nome = _clienteIdentificadoController.text.trim();
    return nome.isEmpty ? 'Não identificado' : nome;
  }

  Widget _buildConteudoCentral(double total) {
    const VoidCallback? voltarParaInicio = null;
    switch (_moduloAtual) {
      case ModuloCentralPDV.cockpit:
        return _buildCockpitEstrategico();

      case ModuloCentralPDV.vendas:
        return _buildAreaVenda(total);

      case ModuloCentralPDV.recebimento:
        return Expanded(
          child: RecebimentoPagamentoWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.vendas;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _focarCodigoBarras();
                }
              });
            },
            onSuccess: _limparVendaAposSucessoRecebimento,
            valorTotalVenda: _calcularTotal(),
            itensResumo: _montarItensResumoPagamento(),
            clienteNome:
                _clienteIdentificado?.nome.trim().isNotEmpty == true
                    ? _clienteIdentificado!.nome.trim()
                    : _clienteIdentificadoController.text.trim(),
            numeroVenda: '',
            idColaborador: 'idUnicoDoColaborador',
            nomeColaborador: 'Nome do colaborador',
            operacaoService: _operacaoService,
            procedureCoordinator: _procedureCoordinator,
          ),
        );

      case ModuloCentralPDV.clientesList:
        return Expanded(
          child: ClientesUsuarioListPage(
            embedded: true,
            onBack: voltarParaInicio,
          ),
        );

      case ModuloCentralPDV.colaboradoresList:
        return Expanded(
          child: ColaboradoresUsuarioListPage(
            embedded: true,
            onBack: voltarParaInicio,
          ),
        );

      case ModuloCentralPDV.operacoesCaixa:
        return Expanded(
          child: OperacoesCaixaWebPage(
            embedded: true,
            onBack: _voltarDeOperacoesCaixaSeNecessario(),
          ),
        );

      case ModuloCentralPDV.orcamento:
        return Expanded(
          child: OrcamentoWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.ordemServico:
        return Expanded(
          child: OrdemServicoWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.agendaFinanceira:
        return Expanded(
          child: AgendaFinanceiraWeb(embedded: true, onBack: voltarParaInicio),
        );

      case ModuloCentralPDV.atendimentoTecnico:
        return Expanded(
          child: AtendimentosTecnicosListaWebPage(
            embedded: true,
            onBack: voltarParaInicio,
            procedureCoordinator: _procedureCoordinator,
          ),
        );

      case ModuloCentralPDV.compras:
        return Expanded(child: ComprasWebPage(onBack: voltarParaInicio));

      case ModuloCentralPDV.reservas:
        return const Expanded(child: CatalogoReservasWebPage());

      case ModuloCentralPDV.catalogoPublico:
        return const Expanded(child: CatalogoPublicoPersonalizacaoWebPage());

      case ModuloCentralPDV.produtos:
        return Expanded(
          child: ProdutoDashboardWebPage(
            onBack: voltarParaInicio,
            onNovoProduto: () {
              showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
            },
            onNovoServico: () {
              showSubPainelCadastroProduto(context, 'Cadastro de Serviços');
            },
            onOpenListaCompleta: () => _abrirListaProdutosParaEdicao(),
            onOpenListaServicos:
                () => _abrirListaProdutosParaEdicao(tipoInicial: 'SERVICO'),
            onOpenCategorias: _abrirCategoriasDoCatalogo,
            onOpenEtiquetas: _abrirEtiquetasDoCatalogo,
            onOpenCatalogoVirtual: () => showCatalogoVirtualWebDialog(context),
            onOpenEstoque: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.estoque;
              });
            },
          ),
        );

      case ModuloCentralPDV.servicos:
        return Expanded(
          child: ServicoDashboardWebPage(
            onBack: voltarParaInicio,
            onNovoServico: () {
              showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
            },
            onOpenListaCompleta: () => _abrirListaProdutosParaEdicao(),
          ),
        );

      case ModuloCentralPDV.estoque:
        return Expanded(
          child: EstoqueDashboardWebPage(
            onBack: voltarParaInicio,
            onOpenListaCompleta:
                () => _abrirListaProdutosParaEdicao(
                  exibirInformacoesEstoque: true,
                ),
          ),
        );

      case ModuloCentralPDV.desempenho:
        return Expanded(
          child: DesempenhoColaboradorWebPage(onBack: voltarParaInicio),
        );

      case ModuloCentralPDV.configuracoes:
        return Expanded(
          child: ConfiguracoesSixWebPage(
            embedded: true,
            onBack: voltarParaInicio,
          ),
        );

      case ModuloCentralPDV.categorias:
        return Expanded(
          child: CategoriasProdutosServicosWebPage(
            embedded: true,
            onBack: voltarParaInicio,
          ),
        );

      case ModuloCentralPDV.seletor:
        return _buildSeletorModoOperacao();
    }
  }

  VoidCallback? _voltarDeOperacoesCaixaSeNecessario() {
    final ModuloCentralPDV? retorno = _moduloRetornoOperacoesCaixa;
    if (retorno == null || retorno == ModuloCentralPDV.seletor) {
      return null;
    }

    return _voltarDeOperacoesCaixa;
  }

  List<WebNavigationItem> _webNavigationItemsPermitidos(
    ColaboradorAutorizacoesProvider autorizacoesProvider,
  ) {
    final Set<WebNavigationPermission> permissions =
        WebNavigationPermissionAdapter.permissionsFor(autorizacoesProvider);

    return WebNavigationRegistry.activeItemsForPermissions(
      permissions,
      includeUnresolved: WebNavigationPermissionAdapter.includeUnresolvedFor(
        autorizacoesProvider,
      ),
    );
  }

  void _garantirModuloAtualPermitido(List<WebNavigationItem> navigationItems) {
    final WebNavigationDestination? destinoAtual =
        webNavigationDestinationForModuloCentralPdv(_moduloAtual);

    if (destinoAtual == null ||
        destinoAtual == WebNavigationDestination.home ||
        _navigationItemsContainDestination(navigationItems, destinoAtual)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final ColaboradorAutorizacoesProvider autorizacoesProvider =
          context.read<ColaboradorAutorizacoesProvider>();
      final List<WebNavigationItem> currentNavigationItems =
          _webNavigationItemsPermitidos(autorizacoesProvider);
      final WebNavigationDestination? destinoAindaAtual =
          webNavigationDestinationForModuloCentralPdv(_moduloAtual);
      if (destinoAindaAtual == WebNavigationDestination.home ||
          _navigationItemsContainDestination(
            currentNavigationItems,
            destinoAindaAtual,
          )) {
        return;
      }

      setState(() {
        _moduloRetornoOperacoesCaixa = null;
        _moduloAtual = ModuloCentralPDV.seletor;
      });
    });
  }

  Future<bool> _executarProcedimentoAntesDeFinalizarVendaWeb() async {
    final ProcedureFlowResult result = await _procedureCoordinator.execute(
      context: context,
      operationPoint: ProcedureOperationPoint.saleFinishBefore,
    );
    if (!mounted) {
      return false;
    }
    if (!result.shouldContinue) {
      _restaurarFocoLeituraRapidaSeCabivel();
      return false;
    }
    return true;
  }

  bool _navigationItemsContainDestination(
    List<WebNavigationItem> navigationItems,
    WebNavigationDestination? destination,
  ) {
    if (destination == null) return false;

    for (final WebNavigationItem item in navigationItems) {
      for (final WebNavigationItem flattenedItem in item.flatten()) {
        if (flattenedItem.destination == destination) {
          return true;
        }
      }
    }

    return false;
  }

  // Widget _buildModoOperacaoButton({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onPressed,
  // }) {
  //   String badge;
  //   String descricao;
  //   final l10n = AppLocalizations.of(context);
  //
  //   switch (label) {
  //     case 'Cockpit':
  //       badge = 'Gestão visionária';
  //       descricao =
  //           'Antecipe riscos de margem, vendas e atendimento com foco em resultado sustentável.';
  //       break;
  //     case 'Vendas':
  //       badge = 'Fluxo principal';
  //       descricao =
  //           l10n?.pdvQuickServiceDescription ??
  //           'Atendimento rápido no caixa, inclusão de itens e fechamento da venda.';
  //       break;
  //     case 'Atendimento Técnico':
  //       badge = 'Assistência técnica';
  //       descricao =
  //           'Acompanhe atendimentos criados, status, assinaturas e recebimentos da assistência.';
  //       break;
  //     case 'Orçamento':
  //       badge = 'Assistência comercial';
  //       descricao =
  //           'Monte propostas com organização, clareza e continuidade do atendimento.';
  //       break;
  //     default:
  //       badge = 'Operação interna';
  //       descricao = 'Controle operacional e financeiro da rotina do balcão.';
  //   }
  //
  //   return SizedBox(
  //     width: 300,
  //     height: 304,
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(28),
  //         onTap: onPressed,
  //         child: Ink(
  //           decoration: BoxDecoration(
  //             color: _pdvTheme.cardBackground,
  //             borderRadius: BorderRadius.circular(28),
  //             border: Border.all(color: _pdvTheme.cardBorder),
  //             boxShadow: <BoxShadow>[
  //               BoxShadow(
  //                 color: _pdvTheme.cardShadow,
  //                 blurRadius: 16,
  //                 offset: const Offset(0, 8),
  //               ),
  //             ],
  //           ),
  //           child: Padding(
  //             padding: const EdgeInsets.all(22),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: <Widget>[
  //                 Row(
  //                   children: <Widget>[
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 14,
  //                         vertical: 8,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: _pdvTheme.badgeBackground.withValues(
  //                           alpha: 0.10,
  //                         ),
  //                         borderRadius: BorderRadius.circular(999),
  //                         border: Border.all(
  //                           color: _pdvTheme.badgeBackground.withValues(
  //                             alpha: 0.20,
  //                           ),
  //                         ),
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: <Widget>[
  //                           Icon(
  //                             label == 'Vendas'
  //                                 ? Icons.flash_on_rounded
  //                                 : label == 'Cockpit'
  //                                 ? Icons.visibility_rounded
  //                                 : label == 'Orçamento'
  //                                 ? Icons.auto_awesome
  //                                 : label == 'Atendimento Técnico'
  //                                 ? Icons.handyman_rounded
  //                                 : Icons.settings_outlined,
  //                             size: 16,
  //                             color: _pdvTheme.iconColor,
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Text(
  //                             badge,
  //                             style: TextStyle(
  //                               fontSize: 13,
  //                               fontWeight: FontWeight.w700,
  //                               color: _pdvTheme.iconColor,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     const Spacer(),
  //                     Icon(
  //                       Icons.north_east_rounded,
  //                       size: 22,
  //                       color: _pdvTheme.iconColor,
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 18),
  //                 Container(
  //                   width: 72,
  //                   height: 72,
  //                   decoration: BoxDecoration(
  //                     color: _pdvTheme.iconColor.withValues(alpha: 0.10),
  //                     borderRadius: BorderRadius.circular(22),
  //                     border: Border.all(
  //                       color: _pdvTheme.iconColor.withValues(alpha: 0.20),
  //                     ),
  //                   ),
  //                   child: Icon(icon, size: 34, color: _pdvTheme.iconColor),
  //                 ),
  //                 const SizedBox(height: 22),
  //                 Text(
  //                   label,
  //                   style: TextStyle(
  //                     fontSize: 22,
  //                     fontWeight: FontWeight.w800,
  //                     color: _pdvTheme.iconColor,
  //                     height: 1.10,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 12),
  //                 Expanded(
  //                   child: Text(
  //                     descricao,
  //                     maxLines: 4,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       height: 1.45,
  //                       color: _pdvTheme.secondaryText,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSeletorModoOperacao() {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 1040;
          final EdgeInsets padding = EdgeInsets.fromLTRB(
            compact ? 12 : 24,
            compact ? 12 : 18,
            compact ? 12 : 24,
            compact ? 12 : 24,
          );

          return Padding(
            padding: padding,
            child: WorkspaceHomeWeb(
              compact: compact,
              resolver: _webNavigationResolver,
              onNovoAtendimentoTecnico: _abrirNovoAtendimentoTecnico,
            ),
          );
        },
      ),
    );
  }

  Widget _buildConteudoPrincipalWeb(double total) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool inicio = _moduloAtual == ModuloCentralPDV.seletor;
        final bool compact = constraints.maxWidth < 760;
        final EdgeInsets padding =
            inicio ? EdgeInsets.zero : EdgeInsets.all(compact ? 12 : 16);

        return Padding(
          padding: padding,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 16 : 22),
            child: Column(children: <Widget>[_buildConteudoCentral(total)]),
          ),
        );
      },
    );
  }

  Widget _buildModoExpandidoFrenteCaixaWeb(double total) {
    return ColoredBox(
      key: const Key('pdv-expanded-front-desk-overlay'),
      color: _pdvTheme.backgroundPage,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 760;
            final EdgeInsets padding = EdgeInsets.all(compact ? 10 : 16);

            return Padding(
              padding: padding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(compact ? 16 : 22),
                child: Material(
                  color: _pdvTheme.backgroundPage,
                  child: SizedBox.expand(
                    child: Column(children: <Widget>[_buildAreaVenda(total)]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String labelAgendaFinanceira() => 'Agenda Financeira';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    _pdvTheme = WebPdvTheme.resolve(theme);
    final double total = _calcularTotal();
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    final bool modoExpandidoAtivo =
        _moduloAtual == ModuloCentralPDV.vendas && _modoExpandidoFrenteCaixa;
    final WebThemeTokens webTokens = WebThemeTokens.of(context);

    if (modoExpandidoAtivo) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: _pdvTheme.backgroundPage,
          body: _buildModoExpandidoFrenteCaixaWeb(total),
        ),
      );
    }

    final ColaboradorAutorizacoesProvider autorizacoesProvider =
        context.watch<ColaboradorAutorizacoesProvider>();
    final List<WebNavigationItem> webNavigationItems =
        _webNavigationItemsPermitidos(autorizacoesProvider);

    if (WebNavigationPermissionAdapter.canApplySidebarFiltering(
      autorizacoesProvider,
    )) {
      _garantirModuloAtualPermitido(webNavigationItems);
    }

    final Widget webShell = AuthenticatedWebShell(
      navigationItems: webNavigationItems,
      resolver: _webNavigationResolver,
      activeDestination: webNavigationDestinationForModuloCentralPdv(
        _moduloAtual,
      ),
      appVersion: AppConfig.appVersion,
      currentCommerceName: _nomeEmpresaAtualParaHeader(),
      headerActions: _buildWebShellHeaderActions(),
      child: _buildConteudoPrincipalWeb(total),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: webTokens.workspaceBackground,
        body: Stack(
          children: <Widget>[
            Positioned.fill(child: webShell),
            if (_deveExibirVendaEmAndamentoFlutuante)
              _buildVendaEmAndamentoFlutuante(regionalizacao, total),
            if (_assistenteIAMinimizado) _buildAssistenteIAMinimizado(),
          ],
        ),
      ),
    );
  }

  void _limparVendaAposSucessoRecebimento() {
    _limparDadosTemporariosVenda(moduloDestino: ModuloCentralPDV.vendas);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focarCodigoBarras();
      }
    });
  }
}
