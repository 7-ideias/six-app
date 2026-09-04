import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/caixa_module.dart';
import '../../data/models/caixa_completo_movimentos_models.dart';
import '../../data/models/caixa_models.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../components/mobile_motion.dart';
import '../components/six_backend_loading.dart';

typedef OperacoesCaixaUsuarioLoader = Future<void> Function();
typedef OperacoesCaixaCollaboratorNameProvider = String Function();
typedef OperacoesCaixaNowProvider = DateTime Function();

enum _OperacoesCaixaFiltroModo { todosOsCaixas, porCaixa }

class OperacoesCaixaMobileScreen extends StatefulWidget {
  const OperacoesCaixaMobileScreen({
    super.key,
    this.caixaService,
    this.usuarioAtualLoader,
    this.collaboratorNameProvider,
    this.nowProvider,
  });

  final CaixaService? caixaService;
  final OperacoesCaixaUsuarioLoader? usuarioAtualLoader;
  final OperacoesCaixaCollaboratorNameProvider? collaboratorNameProvider;
  final OperacoesCaixaNowProvider? nowProvider;

  @override
  State<OperacoesCaixaMobileScreen> createState() =>
      _OperacoesCaixaMobileScreenState();
}

class _OperacoesCaixaMobileScreenState
    extends State<OperacoesCaixaMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static const Color _successColorLight = Color(0xFF047857);
  static const Color _successColorDark = Color(0xFF34D399);
  static const Color _warningColorLight = Color(0xFF92400E);
  static const Color _warningColorDark = Color(0xFFF59E0B);
  static const Color _summaryGradientStart = Color(0xFF173DFF);
  static const Color _summaryGradientMiddle = Color(0xFF3D00D8);
  static const Color _summaryGradientEnd = Color(0xFF2700A8);
  static const Color _summaryTraceColor = Color(0xFF38BDF8);
  static const Duration _transitionDuration = Duration(milliseconds: 240);

  final TextEditingController _trocoInicialController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _fechamentoDinheiroController =
      TextEditingController();
  final TextEditingController _fechamentoPixController =
      TextEditingController();
  final TextEditingController _fechamentoCartaoController =
      TextEditingController();
  final TextEditingController _fechamentoObservacaoController =
      TextEditingController();

  late final CaixaService _caixaService;
  late final OperacoesCaixaUsuarioLoader _usuarioAtualLoader;
  late final OperacoesCaixaNowProvider _nowProvider;

  bool _loading = true;
  bool _loadingMovimentos = false;
  bool _loadingSomatorio = false;
  bool _loadingResumo = false;
  bool _busy = false;
  bool _confirmandoAberturaCaixa = false;
  bool _vincularVenda = false;
  bool _mostrarApenasHoje = false;
  bool _registrarDiferencaComoDespesa = false;
  bool _pedirConfirmacaoDiferencaGestor = false;
  bool _usuarioEhAdministrador = false;
  String? _erro;

  CaixaSessao? _sessaoAtual;
  CaixaOuGuiche? _caixaSelecionado;
  CaixaSessao? _sessaoFiltroSelecionada;
  OperacaoCaixaTipo? _tipoSelecionado;
  TiposRecebimento? _tipoRecebimentoSelecionado;
  InformacoesCaixaComSomatorioResponse? _movimentosComSomatorio;
  ResumoCaixa? _resumo;

  _OperacoesCaixaFiltroModo _filtroModo = _OperacoesCaixaFiltroModo.porCaixa;
  List<CaixaOuGuiche> _caixasDisponiveis = <CaixaOuGuiche>[];
  List<CaixaSessao> _sessoesAbertasVisiveis = <CaixaSessao>[];
  List<TiposRecebimento> _tiposRecebimento = <TiposRecebimento>[];
  List<MovimentoCaixa> _movimentos = <MovimentoCaixa>[];

  @override
  void initState() {
    super.initState();
    _caixaService = widget.caixaService ?? CaixaModule.caixaService;
    _usuarioAtualLoader =
        widget.usuarioAtualLoader ??
        () async {
          await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
        };
    _nowProvider = widget.nowProvider ?? DateTime.now;
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _trocoInicialController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    _referenciaController.dispose();
    _fechamentoDinheiroController.dispose();
    _fechamentoPixController.dispose();
    _fechamentoCartaoController.dispose();
    _fechamentoObservacaoController.dispose();
    super.dispose();
  }

  static Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
  }

  Color get _successColor =>
      Theme.of(context).brightness == Brightness.dark
          ? _successColorDark
          : _successColorLight;

  Color get _warningColor =>
      Theme.of(context).brightness == Brightness.dark
          ? _warningColorDark
          : _warningColorLight;

  Color _foregroundForSemantic(Color background) {
    final Brightness brightness = ThemeData.estimateBrightnessForColor(
      background,
    );
    return brightness == Brightness.dark
        ? SixMobilePalette.onPrimary
        : SixMobilePalette.backgroundDark;
  }

  bool get _temCaixaAberto {
    if (_exibindoTodosOsCaixas) {
      return _sessoesAbertasVisiveis.any(_sessaoCaixaAberta);
    }
    final CaixaSessao? sessao = _sessaoEmFoco;
    return sessao != null && _sessaoCaixaAberta(sessao);
  }

  bool get _podeFiltrarTodosOsCaixas =>
      _usuarioEhAdministrador && _caixasDisponiveis.length > 1;

  bool get _exibindoTodosOsCaixas =>
      _podeFiltrarTodosOsCaixas &&
      _filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas;

  CaixaSessao? get _sessaoEmFoco {
    if (_exibindoTodosOsCaixas) {
      return null;
    }
    final CaixaSessao? selecionada = _sessaoFiltroSelecionada;
    if (selecionada == null) {
      return _sessaoAtual;
    }
    for (final CaixaSessao sessao in _sessoesAbertasVisiveis) {
      if (sessao.idSessaoCaixa == selecionada.idSessaoCaixa) {
        return sessao;
      }
    }
    final String? idCaixaSelecionado = _caixaSelecionado?.id;
    if (idCaixaSelecionado != null) {
      final CaixaSessao? sessaoDaCaixa = _sessaoAbertaPorCaixaId(
        idCaixaSelecionado,
      );
      if (sessaoDaCaixa != null) {
        return sessaoDaCaixa;
      }
    }
    return _sessaoAtual;
  }

  String? get _idSessaoEmFoco {
    final String id = _sessaoEmFoco?.idSessaoCaixa.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  bool get _temPendenciaConferencia {
    return _movimentos.any(
      (MovimentoCaixa item) =>
          item.status.toLowerCase() == 'pendenteconferencia',
    );
  }

  bool _sessaoCaixaAberta(CaixaSessao sessao) {
    final String status = sessao.status.trim().toLowerCase();
    return status == 'aberta' ||
        status == 'open' ||
        status == 'active' ||
        status == 'ativa' ||
        status == 'true';
  }

  CaixaSessao? _sessaoAbertaPorCaixaId(String idCaixaOuGuiche) {
    for (final CaixaSessao sessao in _sessoesAbertasVisiveis) {
      if (sessao.idCaixaOuGuiche == idCaixaOuGuiche) {
        return sessao;
      }
    }
    return null;
  }

  Future<void> _carregarDadosIniciais({String? idCaixaPreferencial}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
        if (_sessaoAtual == null) {
          _loadingMovimentos = false;
          _loadingSomatorio = false;
          _loadingResumo = false;
        }
      });
    }

    try {
      final bool usuarioEhAdministrador =
          context.read<ColaboradorAutorizacoesProvider>().ehAdministrador;
      final InformacoesBasicasCaixaResponse informacoesBasicas =
          await _caixaService.buscarInformacoesBasicasDoCaixa();

      if (mounted && informacoesBasicas.regionalizacao != null) {
        await context
            .read<LocaleSettingsProvider>()
            .atualizarConfiguracaoDaEmpresaPorResponse(
              informacoesBasicas.regionalizacao!,
            );
      }

      await _carregarUsuarioAtualSilencioso();
      final List<Object?> dados = await Future.wait<Object?>(<Future<Object?>>[
        _caixaService.buscarSessaoAtual(),
        _caixaService.listarSessoesAbertas(),
      ]);

      final CaixaSessao? sessao = dados[0] as CaixaSessao?;
      final List<CaixaSessao> sessoesAbertas = (dados[1] as List<CaixaSessao>)
          .toList(growable: false);

      final List<CaixaOuGuiche> caixas =
          informacoesBasicas.caixaOuGuiche.isNotEmpty
              ? informacoesBasicas.caixaOuGuiche
              : informacoesBasicas.caixas
                  .map((String nome) => CaixaOuGuiche(id: nome, nome: nome))
                  .toList(growable: false);

      final List<TiposRecebimento> tiposAtivos = informacoesBasicas
        .tiposRecebimento
        .where((TiposRecebimento item) => item.ativo)
        .toList(growable: false)..sort(
        (TiposRecebimento a, TiposRecebimento b) =>
            a.ordemExibicao.compareTo(b.ordemExibicao),
      );

      final String? idPreferencial =
          idCaixaPreferencial ?? _caixaSelecionado?.id;
      final String? idSessaoAnterior = _sessaoEmFoco?.idSessaoCaixa;
      CaixaOuGuiche? caixaPreferencial;
      if (idPreferencial != null) {
        for (final CaixaOuGuiche caixa in caixas) {
          if (caixa.id == idPreferencial) {
            caixaPreferencial = caixa;
            break;
          }
        }
      }

      CaixaSessao? sessaoPreferencial;
      final String? idSessaoPreferencialAtual =
          _sessaoFiltroSelecionada?.idSessaoCaixa ?? sessao?.idSessaoCaixa;
      if (idSessaoPreferencialAtual != null) {
        for (final CaixaSessao sessaoAberta in sessoesAbertas) {
          if (sessaoAberta.idSessaoCaixa == idSessaoPreferencialAtual) {
            sessaoPreferencial = sessaoAberta;
            break;
          }
        }
      }

      TiposRecebimento? tipoPreferencial;
      final String? codigoAtual = _tipoRecebimentoSelecionado?.codigoTipo;
      if (codigoAtual != null) {
        for (final TiposRecebimento tipo in tiposAtivos) {
          if (tipo.codigoTipo == codigoAtual) {
            tipoPreferencial = tipo;
            break;
          }
        }
      }

      if (!mounted) return;
      final bool podeExibirTodosOsCaixas =
          usuarioEhAdministrador && caixas.length > 1;
      final _OperacoesCaixaFiltroModo filtroModo =
          podeExibirTodosOsCaixas
              ? _filtroModo
              : _OperacoesCaixaFiltroModo.porCaixa;
      final CaixaSessao? sessaoEmFoco =
          filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas
              ? null
              : sessaoPreferencial ??
                  sessao ??
                  (sessoesAbertas.isNotEmpty ? sessoesAbertas.first : null);
      final bool mudouSessao = sessaoEmFoco?.idSessaoCaixa != idSessaoAnterior;
      setState(() {
        _usuarioEhAdministrador = usuarioEhAdministrador;
        _filtroModo = filtroModo;
        _caixasDisponiveis = caixas;
        _sessoesAbertasVisiveis = sessoesAbertas;
        _tiposRecebimento = informacoesBasicas.tiposRecebimento;
        _caixaSelecionado =
            caixaPreferencial ??
            (_caixasDisponiveis.isNotEmpty ? _caixasDisponiveis.first : null);
        _tipoRecebimentoSelecionado =
            tipoPreferencial ??
            (tiposAtivos.isNotEmpty ? tiposAtivos.first : null);
        _sessaoAtual = sessaoEmFoco;
        _sessaoFiltroSelecionada = sessaoEmFoco;
        if (sessaoEmFoco == null &&
            filtroModo != _OperacoesCaixaFiltroModo.todosOsCaixas) {
          _movimentos = <MovimentoCaixa>[];
          _movimentosComSomatorio = null;
          _resumo = null;
          _loadingMovimentos = false;
          _loadingSomatorio = false;
          _loadingResumo = false;
        } else if (mudouSessao ||
            filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas) {
          _movimentos = <MovimentoCaixa>[];
          _movimentosComSomatorio = null;
          _resumo = null;
          _loadingMovimentos = true;
          _loadingSomatorio = true;
          _loadingResumo = true;
        } else if (_resumo == null) {
          _loadingMovimentos = true;
          _loadingSomatorio = true;
          _loadingResumo = true;
        }
      });

      if (filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas) {
        if (sessoesAbertas.isNotEmpty) {
          await _carregarMovimentosEResumoDeTodasAsSessoes(sessoesAbertas);
        }
      } else if (sessaoEmFoco != null) {
        await _carregarMovimentosEResumo(sessaoEmFoco.idSessaoCaixa);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarUsuarioAtualSilencioso() async {
    try {
      await _usuarioAtualLoader();
    } catch (_) {
      // O nome do colaborador é apoio visual; não deve bloquear o caixa.
    }
  }

  Future<void> _carregarMovimentosEResumo(String idSessaoCaixa) async {
    if (mounted) {
      setState(() {
        _loadingMovimentos = true;
        _loadingSomatorio = true;
        _loadingResumo = true;
      });
    }

    await Future.wait<void>(<Future<void>>[
      _carregarMovimentos(idSessaoCaixa),
      _carregarSomatorioMovimentos(idSessaoCaixa),
      _carregarResumoCaixa(idSessaoCaixa),
    ]);
  }

  Future<void> _carregarMovimentosEResumoDeTodasAsSessoes(
    List<CaixaSessao> sessoes,
  ) async {
    if (mounted) {
      setState(() {
        _loadingMovimentos = true;
        _loadingSomatorio = true;
        _loadingResumo = true;
      });
    }

    try {
      final List<_OperacoesCaixaSessaoCarregada> carregadas =
          await Future.wait<_OperacoesCaixaSessaoCarregada>(
            sessoes.map(_carregarDadosDaSessao),
          );
      final List<MovimentoCaixa> movimentos = carregadas
        .expand((item) => item.movimentos)
        .toList(growable: false)..sort(_compararMovimentoPorDataDesc);
      final InformacoesCaixaComSomatorioResponse somatorio =
          _somarMovimentosComSomatorio(
            carregadas.map((item) => item.movimentosComSomatorio).toList(),
            movimentos,
          );
      final ResumoCaixa resumo = _somarResumos(
        carregadas.map((item) => item.resumo).toList(),
      );

      if (!mounted) return;
      setState(() {
        _movimentos = movimentos;
        _movimentosComSomatorio = somatorio;
        _resumo = resumo;
      });
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) {
        setState(() {
          _loadingMovimentos = false;
          _loadingSomatorio = false;
          _loadingResumo = false;
        });
      }
    }
  }

  Future<_OperacoesCaixaSessaoCarregada> _carregarDadosDaSessao(
    CaixaSessao sessao,
  ) async {
    final List<Object> dados = await Future.wait<Object>(<Future<Object>>[
      _caixaService.listarMovimentacoes(sessao.idSessaoCaixa),
      _caixaService.buscarResumoDeMovimentosComSomatorio(sessao.idSessaoCaixa),
      _caixaService.buscarResumo(sessao.idSessaoCaixa),
    ]);
    return _OperacoesCaixaSessaoCarregada(
      sessao: sessao,
      movimentos: dados[0] as List<MovimentoCaixa>,
      movimentosComSomatorio: dados[1] as InformacoesCaixaComSomatorioResponse,
      resumo: dados[2] as ResumoCaixa,
    );
  }

  Future<void> _carregarMovimentos(String idSessaoCaixa) async {
    try {
      final List<MovimentoCaixa> movimentos = await _caixaService
          .listarMovimentacoes(idSessaoCaixa);
      if (!mounted) return;
      setState(() => _movimentos = movimentos);
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _loadingMovimentos = false);
    }
  }

  Future<void> _carregarSomatorioMovimentos(String idSessaoCaixa) async {
    try {
      final InformacoesCaixaComSomatorioResponse movimentosComSomatorio =
          await _caixaService.buscarResumoDeMovimentosComSomatorio(
            idSessaoCaixa,
          );
      if (!mounted) return;
      setState(() {
        _movimentosComSomatorio = movimentosComSomatorio;
        if (_movimentos.isEmpty &&
            movimentosComSomatorio.movimento.isNotEmpty) {
          _movimentos = movimentosComSomatorio.movimento;
        }
      });
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _loadingSomatorio = false);
    }
  }

  Future<void> _carregarResumoCaixa(String idSessaoCaixa) async {
    try {
      final ResumoCaixa resumo = await _caixaService.buscarResumo(
        idSessaoCaixa,
      );
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _loadingResumo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}|${provider.timeFormat}',
    );

    return SixoAppMobileLoadingOverlay(
      isLoading: _busy,
      message: _txt(
        'caixa.operacoes.mobile.processing',
        'Processando operação...',
      ),
      child: SixMobilePageShell(
        title: _txt('caixa.operacoes.mobile.title', 'Operações de caixa'),
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
          tooltip: _txt('common.back', 'Voltar'),
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _txt(
              'caixa.operacoes.mobile.newMovement',
              'Nova movimentação',
            ),
            onPressed: _busy ? null : _abrirFormularioMovimentoSheet,
            icon: Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: _txt(
              'caixa.operacoes.mobile.closingSettings',
              'Configurações de fechamento',
            ),
            onPressed: _abrirConfiguracoesFechamento,
            icon: Icon(Icons.settings_outlined),
          ),
        ],
        bodyBuilder: _buildContent,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => _carregarDadosIniciais(),
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
          children: <Widget>[
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : _transitionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildState(reduceMotion: reduceMotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState({required bool reduceMotion}) {
    if (_erro != null && !_loading && _sessaoAtual == null) {
      return _stateMessage(
        key: ValueKey<String>('operacoes-caixa-error'),
        icon: Icons.error_outline_rounded,
        title: _txt(
          'caixa.operacoes.mobile.errorTitle',
          'Não foi possível carregar',
        ),
        message: _erro!,
        actionLabel: _txt('common.tryAgain', 'Tentar novamente'),
        onAction: () => _carregarDadosIniciais(),
      );
    }

    return _successState(
      key: ValueKey<String>(
        _exibindoTodosOsCaixas
            ? 'operacoes-caixa-todos-os-caixas'
            : _sessaoEmFoco == null
            ? 'operacoes-caixa-sem-sessao'
            : 'operacoes-caixa-${_sessaoEmFoco!.idSessaoCaixa}',
      ),
      reduceMotion: reduceMotion,
    );
  }

  Widget _successState({Key? key, required bool reduceMotion}) {
    final bool aguardandoDadosIniciais =
        _loading && _sessaoAtual == null && _caixasDisponiveis.isEmpty;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _entry(
          _buildHeaderCard(loading: aguardandoDadosIniciais),
          reduceMotion: reduceMotion,
        ),
        if (_podeFiltrarTodosOsCaixas) ...<Widget>[
          SizedBox(height: 12),
          _entry(
            _buildFiltroCaixasCard(),
            delay: Duration(milliseconds: 40),
            reduceMotion: reduceMotion,
          ),
        ],
        SizedBox(height: 12),
        if (aguardandoDadosIniciais)
          _entry(
            _buildInitialLoadingPanel(),
            delay: Duration(milliseconds: 70),
            reduceMotion: reduceMotion,
          )
        else if (!_temCaixaAberto)
          _entry(
            _buildPainelAbertura(),
            delay: Duration(milliseconds: 70),
            reduceMotion: reduceMotion,
          )
        else ...<Widget>[
          _entry(
            _buildResumoOperacional(),
            delay: Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          ),
          SizedBox(height: 12),
          _entry(
            _buildPrepararFechamentoCard(),
            delay: Duration(milliseconds: 150),
            reduceMotion: reduceMotion,
          ),
          SizedBox(height: 12),
          _entry(
            _buildHistorico(),
            delay: Duration(milliseconds: 190),
            reduceMotion: reduceMotion,
          ),
        ],
      ],
    );
  }

  Widget _entry(
    Widget child, {
    Duration delay = Duration.zero,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(
      delay: delay,
      duration: Duration(milliseconds: 340),
      beginOffset: Offset(0, 0.035),
      child: child,
    );
  }

  Widget _buildInitialLoadingPanel() {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _txt(
        'caixa.operacoes.mobile.loadingState',
        'Carregando operações de caixa.',
      ),
      child: SixBackendLoading(
        title: _txt(
          'caixa.operacoes.mobile.loadingTitle',
          'Carregando operações de caixa',
        ),
        subtitle: _txt(
          'caixa.operacoes.mobile.loadingSubtitle',
          'Sincronizando sessão, resumo e movimentações.',
        ),
        animation: SixBackendLoadingAnimation.skeletonPulse,
        leadingIcon: Icons.point_of_sale_rounded,
        backgroundColor: SixMobilePalette.surface,
        borderColor: SixMobilePalette.border,
      ),
    );
  }

  Widget _stateMessage({
    Key? key,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: <Widget>[
          _iconBox(
            icon,
            bg: _withAlpha(SixMobilePalette.error, 0.10),
            fg: SixMobilePalette.error,
          ),
          SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard({bool loading = false}) {
    final ResumoCaixa? resumo = _resumo;
    final CaixaSessao? sessao = _sessaoEmFoco;
    final bool loadingResumo = loading || (_loadingResumo && resumo == null);
    final String status =
        loading
            ? _txt('common.loading', 'Carregando...')
            : _exibindoTodosOsCaixas
            ? _txt('caixa.operacoes.mobile.allCashDesks', 'Todos os caixas')
            : _temCaixaAberto
            ? _txt('caixa.operacoes.mobile.cashOpen', 'Caixa aberto')
            : _txt('caixa.operacoes.mobile.waitingOpen', 'Aguardando abertura');
    final String statusLabel =
        _exibindoTodosOsCaixas
            ? '${_sessoesAbertasVisiveis.length} ${_txt('caixa.operacoes.mobile.openCashDesksCount', 'caixas abertos')}'
            : sessao != null &&
                _temCaixaAberto &&
                sessao.nomeCaixa.trim().isNotEmpty
            ? '$status • ${sessao.nomeCaixa.trim()}'
            : status;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _summaryGradientStart,
            _summaryGradientMiddle,
            _summaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _withAlpha(_summaryGradientMiddle, 0.26),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -22,
            bottom: -36,
            child: IgnorePointer(
              child: Container(
                width: 152,
                height: 96,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      _withAlpha(SixMobilePalette.onPrimary, 0.10),
                      _withAlpha(SixMobilePalette.onPrimary, 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _iconBox(
                    Icons.point_of_sale_rounded,
                    bg: _withAlpha(SixMobilePalette.onPrimary, 0.14),
                    fg: SixMobilePalette.onPrimary,
                    size: 44,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _txt(
                            'caixa.operacoes.mobile.headerTitle',
                            'Operações de caixa',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.onPrimary,
                            fontSize: 20,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 178),
                    child: _statusChip(
                      label: statusLabel,
                      icon:
                          _temCaixaAberto
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                      foreground: SixMobilePalette.onPrimary,
                      background: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                      border: _withAlpha(SixMobilePalette.onPrimary, 0.20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: _summaryTraceColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: 14),
              Semantics(
                container: true,
                label: _txt(
                  'caixa.operacoes.mobile.summaryMetrics',
                  'Resumo financeiro do caixa',
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _heroMetricItem(
                        label: _txt(
                          'caixa.operacoes.mobile.expectedBalance',
                          'Saldo esperado',
                        ),
                        value: resumo?.saldoEsperado ?? 0,
                        icon: Icons.account_balance_wallet_outlined,
                        loading: loadingResumo,
                      ),
                    ),
                    _heroMetricDivider(),
                    Expanded(
                      child: _heroMetricItem(
                        label: _txt(
                          'caixa.operacoes.mobile.inflows',
                          'Entradas',
                        ),
                        value: resumo?.totalEntradas ?? 0,
                        icon: Icons.south_west_rounded,
                        accent: _successColor,
                        loading: loadingResumo,
                      ),
                    ),
                    _heroMetricDivider(),
                    Expanded(
                      child: _heroMetricItem(
                        label: _txt(
                          'caixa.operacoes.mobile.outflows',
                          'Saídas',
                        ),
                        value: resumo?.totalSaidas ?? 0,
                        icon: Icons.north_east_rounded,
                        accent: SixMobilePalette.error,
                        loading: loadingResumo,
                      ),
                    ),
                  ],
                ),
              ),
              if (_exibindoTodosOsCaixas) ...<Widget>[
                SizedBox(height: 10),
                _CaixaHeroCarousel(
                  semanticLabel: _txt(
                    'caixa.operacoes.mobile.sessionContext',
                    'Sessão atual',
                  ),
                  child: Row(
                    children: <Widget>[
                      _heroInfoChip(
                        label: _txt(
                          'caixa.operacoes.mobile.openCashDesks',
                          'Caixas abertos',
                        ),
                        value: '${_sessoesAbertasVisiveis.length}',
                        icon: Icons.storefront_outlined,
                        accent: _summaryTraceColor,
                        wide: true,
                      ),
                      _heroInfoChip(
                        label: _txt(
                          'caixa.operacoes.mobile.movementsCount',
                          'Movimentos',
                        ),
                        value: '${resumo?.quantidadeMovimentos ?? 0}',
                        icon: Icons.receipt_long_outlined,
                        accent: SixMobilePalette.onPrimary,
                      ),
                    ],
                  ),
                ),
              ] else if (sessao != null && _temCaixaAberto) ...<Widget>[
                SizedBox(height: 10),
                _CaixaHeroCarousel(
                  semanticLabel: _txt(
                    'caixa.operacoes.mobile.sessionContext',
                    'Sessão atual',
                  ),
                  child: Row(
                    children: <Widget>[
                      _heroInfoChip(
                        label: _txt(
                          'caixa.operacoes.mobile.openedAt',
                          'Abertura',
                        ),
                        value: _formatarDataHora(sessao.dataHoraAbertura),
                        icon: Icons.schedule_rounded,
                        accent: _summaryTraceColor,
                        wide: true,
                      ),
                      _heroInfoChip(
                        label: _txt(
                          'caixa.operacoes.mobile.initialChange',
                          'Troco inicial',
                        ),
                        value: _formatarValor(sessao.valorAbertura),
                        icon: Icons.account_balance_wallet_outlined,
                        accent: SixMobilePalette.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroCaixasCard() {
    final CaixaOuGuiche? caixaSelecionada = _caixaSelecionado;
    return _sectionCard(
      icon: Icons.filter_alt_outlined,
      title: _txt('caixa.operacoes.mobile.cashFilterTitle', 'Visualização'),
      subtitle: _txt(
        'caixa.operacoes.mobile.cashFilterSubtitle',
        'Administradores podem alternar entre todos os caixas abertos ou um caixa específico.',
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _filterModeButton(
                  label: _txt(
                    'caixa.operacoes.mobile.allCashDesks',
                    'Todos os caixas',
                  ),
                  selected:
                      _filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas,
                  onTap:
                      () => _alterarFiltroModo(
                        _OperacoesCaixaFiltroModo.todosOsCaixas,
                      ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _filterModeButton(
                  label: _txt('caixa.operacoes.mobile.byCashDesk', 'Por caixa'),
                  selected: _filtroModo == _OperacoesCaixaFiltroModo.porCaixa,
                  onTap:
                      () => _alterarFiltroModo(
                        _OperacoesCaixaFiltroModo.porCaixa,
                      ),
                ),
              ),
            ],
          ),
          if (_filtroModo == _OperacoesCaixaFiltroModo.porCaixa) ...<Widget>[
            SizedBox(height: 12),
            _selectorField(
              label: _txt('caixa.operacoes.mobile.cashDesk', 'Caixa / guichê'),
              value:
                  caixaSelecionada?.nome ??
                  _txt('caixa.operacoes.mobile.select', 'Selecione'),
              icon: Icons.store_mall_directory_outlined,
              onTap: _selecionarCaixaFiltro,
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color foreground =
        selected ? SixMobilePalette.onAccent : SixMobilePalette.titleText;
    final Color background =
        selected
            ? SixMobilePalette.accent
            : SixMobilePalette.softNeutralSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: _transitionDuration,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? SixMobilePalette.accent : SixMobilePalette.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _heroMetricItem({
    required String label,
    required double value,
    required IconData icon,
    Color accent = _summaryTraceColor,
    bool loading = false,
  }) {
    return Semantics(
      container: true,
      label:
          loading
              ? '$label: ${_txt('common.loading', 'Carregando...')}'
              : '$label: ${_formatarValor(value)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: accent, size: 16),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _withAlpha(SixMobilePalette.onPrimary, 0.74),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              AnimatedSwitcher(
                duration: _transitionDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child:
                    loading
                        ? _skeletonLine(
                          key: ValueKey<String>('hero-$label-loading'),
                          width: 74,
                          height: 15,
                          colorOnDark: true,
                        )
                        : _animatedCurrencyText(
                          value,
                          style: TextStyle(
                            color: SixMobilePalette.onPrimary,
                            fontSize: 13.5,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMetricDivider() {
    return Container(
      width: 1,
      height: 38,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _withAlpha(SixMobilePalette.onPrimary, 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _heroInfoChip({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    bool wide = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: Semantics(
        container: true,
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Container(
            width: wide ? 172 : 132,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _withAlpha(SixMobilePalette.onPrimary, 0.09),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _withAlpha(SixMobilePalette.onPrimary, 0.16),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: accent, size: 16),
                SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _withAlpha(SixMobilePalette.onPrimary, 0.66),
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.onPrimary,
                          fontSize: 12,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
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

  Widget _buildPainelAbertura() {
    return _sectionCard(
      icon: Icons.lock_open_rounded,
      title: _txt('caixa.operacoes.mobile.openTitle', 'Abertura de caixa'),
      subtitle: _txt(
        'caixa.operacoes.mobile.openSubtitle',
        'Defina o caixa, o troco inicial e inicie a operação do dia.',
      ),
      child: Column(
        children: <Widget>[
          _selectorField(
            label: _txt('caixa.operacoes.mobile.cashDesk', 'Caixa / guichê'),
            value:
                _caixaSelecionado?.nome ??
                _txt('caixa.operacoes.mobile.select', 'Selecione'),
            icon: Icons.store_mall_directory_outlined,
            onTap: _selecionarCaixa,
          ),
          SizedBox(height: 12),
          _textField(
            label: _txt(
              'caixa.operacoes.mobile.initialChange',
              'Troco inicial',
            ),
            controller: _trocoInicialController,
            hint: _formatarDecimalDigitavel(0),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            prefixText:
                '${context.read<LocaleSettingsProvider>().currencySymbol} ',
          ),
          SizedBox(height: 12),
          _readOnlyInfo(
            label: _txt('caixa.operacoes.mobile.responsible', 'Responsável'),
            value: _nomeColaboradorAtual(),
            icon: Icons.person_outline_rounded,
          ),
          SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy || _confirmandoAberturaCaixa ? null : _abrirCaixa,
            icon: Icon(Icons.play_arrow_rounded),
            label: Text(_txt('caixa.operacoes.mobile.openCash', 'Abrir caixa')),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(50),
              backgroundColor: SixMobilePalette.accent,
              foregroundColor: SixMobilePalette.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepararFechamentoCard() {
    final bool loadingSomatorio =
        _loadingSomatorio && _movimentosComSomatorio == null;

    return Semantics(
      button: true,
      label: _txt(
        'caixa.operacoes.mobile.prepareClosing',
        'Preparar fechamento',
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _busy ? null : _abrirPrepararFechamentoSheet,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 92),
            padding: EdgeInsets.fromLTRB(18, 16, 14, 16),
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SixMobilePalette.activeBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                _iconBox(
                  Icons.rule_folder_outlined,
                  bg: SixMobilePalette.softNeutralSurface,
                  fg: SixMobilePalette.accent,
                  size: 52,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _txt(
                          'caixa.operacoes.mobile.prepareClosing',
                          'Preparar fechamento',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 17,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: _transitionDuration,
                        child:
                            loadingSomatorio
                                ? _skeletonLine(
                                  key: ValueKey<String>(
                                    'prepare-closing-loading',
                                  ),
                                  width: 180,
                                  height: 12,
                                )
                                : Text(
                                  _txt(
                                    'caixa.operacoes.mobile.prepareClosingSubtitle',
                                    'Confira os valores por forma e informe a apuração final.',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: SixMobilePalette.mutedText,
                                    fontSize: 13,
                                    height: 1.25,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SixMobilePalette.mutedText,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioMovimentoContent({
    VoidCallback? refreshSheet,
    VoidCallback? onSaved,
  }) {
    return Column(
      children: <Widget>[
        _selectorField(
          label: _txt(
            'caixa.operacoes.mobile.operationType',
            'Tipo da operação',
          ),
          value:
              _tipoSelecionado == null
                  ? _txt('caixa.operacoes.mobile.select', 'Selecione')
                  : _labelTipo(_tipoSelecionado!),
          icon: Icons.category_outlined,
          onTap: () async {
            await _selecionarTipoOperacao();
            refreshSheet?.call();
          },
        ),
        SizedBox(height: 12),
        _textField(
          label: _txt('caixa.operacoes.mobile.amount', 'Valor'),
          controller: _valorController,
          hint: _formatarDecimalDigitavel(0),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          prefixText:
              '${context.read<LocaleSettingsProvider>().currencySymbol} ',
        ),
        SizedBox(height: 12),
        _selectorField(
          label: _txt(
            'caixa.operacoes.mobile.relatedMethod',
            'Forma relacionada',
          ),
          value:
              _tipoRecebimentoSelecionado == null
                  ? _txt('caixa.operacoes.mobile.select', 'Selecione')
                  : _descricaoTipoRecebimentoConfigurado(
                    _tipoRecebimentoSelecionado!,
                  ),
          icon: Icons.payments_outlined,
          onTap: () async {
            await _selecionarFormaRelacionada();
            refreshSheet?.call();
          },
        ),
        SizedBox(height: 12),
        _textField(
          label: _txt(
            'caixa.operacoes.mobile.reference',
            'Referência / comprovante',
          ),
          controller: _referenciaController,
          hint: 'MOV-001',
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 12),
        _textField(
          label: _txt('caixa.operacoes.mobile.note', 'Observação'),
          controller: _observacaoController,
          hint: _txt(
            'caixa.operacoes.mobile.noteHint',
            'Descreva o motivo da movimentação.',
          ),
          keyboardType: TextInputType.multiline,
          maxLines: 3,
        ),
        SizedBox(height: 10),
        CheckboxListTile(
          value: _vincularVenda,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _txt(
              'caixa.operacoes.mobile.hasSaleLink',
              'Possui vínculo com venda',
            ),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _txt(
              'caixa.operacoes.mobile.hasSaleLinkSubtitle',
              'Use em estornos ou situações relacionadas a atendimento anterior.',
            ),
          ),
          onChanged:
              _busy
                  ? null
                  : (bool? value) {
                    setState(() => _vincularVenda = value ?? false);
                    refreshSheet?.call();
                  },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        SizedBox(height: 12),
        FilledButton.icon(
          onPressed:
              _busy
                  ? null
                  : () async {
                    final Future<bool> save = _salvarMovimento();
                    refreshSheet?.call();
                    final bool saved = await save;
                    if (saved) {
                      onSaved?.call();
                    } else {
                      refreshSheet?.call();
                    }
                  },
          icon: Icon(Icons.save_outlined),
          label: Text(
            _txt(
              'caixa.operacoes.mobile.saveMovement',
              'Registrar movimentação',
            ),
          ),
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(50),
            backgroundColor: SixMobilePalette.accent,
            foregroundColor: SixMobilePalette.onAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed:
              _busy
                  ? null
                  : () {
                    _limparFormularioMovimento();
                    refreshSheet?.call();
                  },
          icon: Icon(Icons.refresh_rounded),
          label: Text(
            _txt('caixa.operacoes.mobile.clearForm', 'Limpar formulário'),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumoOperacional() {
    final bool loadingSomatorio =
        _loadingSomatorio && _movimentosComSomatorio == null;

    return Semantics(
      button: true,
      label: _txt(
        'caixa.operacoes.mobile.methodSummary',
        'Conferência por forma',
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _abrirConferenciaPorFormaSheet,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 90),
            padding: EdgeInsets.fromLTRB(18, 16, 14, 16),
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SixMobilePalette.activeBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                _iconBox(
                  Icons.fact_check_outlined,
                  bg: SixMobilePalette.softNeutralSurface,
                  fg: SixMobilePalette.accent,
                  size: 52,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _txt(
                          'caixa.operacoes.mobile.methodSummary',
                          'Conferência por forma',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 17,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: _transitionDuration,
                        child:
                            loadingSomatorio
                                ? _skeletonLine(
                                  key: ValueKey<String>(
                                    'method-summary-loading',
                                  ),
                                  width: 190,
                                  height: 12,
                                )
                                : Text(
                                  _txt(
                                    'caixa.operacoes.mobile.methodSummarySubtitle',
                                    'Resumo pelos tipos configurados no caixa.',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: SixMobilePalette.mutedText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SixMobilePalette.mutedText,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumoOperacionalDetalhado() {
    return Column(
      children: <Widget>[
        ..._linhasResumoPorTipoRecebimento().map(
          (_ResumoTipoRecebimentoData linha) =>
              _summaryLine(linha.label, _formatarValor(linha.valor)),
        ),
        Divider(height: 22),
        _checkItem(
          checked: _temCaixaAberto,
          title: _txt('caixa.operacoes.mobile.cashOpen', 'Caixa aberto'),
        ),
        _checkItem(
          checked: _movimentos.isNotEmpty,
          title: _txt(
            'caixa.operacoes.mobile.hasMovements',
            'Movimentações registradas',
          ),
        ),
        _checkItem(
          checked: _temPendenciaConferencia,
          title: _txt(
            'caixa.operacoes.mobile.hasPending',
            'Há pendências para conferência',
          ),
        ),
      ],
    );
  }

  Widget _buildGuiaFechamentoPorForma() {
    final bool loadingSomatorio =
        _loadingSomatorio && _movimentosComSomatorio == null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(
                Icons.fact_check_outlined,
                bg: SixMobilePalette.softAccentSurface,
                fg: SixMobilePalette.accent,
                size: 40,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'caixa.operacoes.mobile.closingGuideTitle',
                        'Guia por forma',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      _txt(
                        'caixa.operacoes.mobile.closingGuideSubtitle',
                        'Mesmos valores exibidos em Conferência por forma.',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (loadingSomatorio)
            _guiaFechamentoSkeleton()
          else ...<Widget>[
            ..._linhasResumoPorTipoRecebimento().map(
              (_ResumoTipoRecebimentoData linha) =>
                  _summaryLine(linha.label, _formatarValor(linha.valor)),
            ),
            Divider(height: 22),
            _summaryLine(
              _txt('caixa.operacoes.mobile.expectedBalance', 'Saldo esperado'),
              _formatarValor(_resumo?.saldoEsperado ?? 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guiaFechamentoSkeleton() {
    return Column(
      children: <Widget>[
        _skeletonLine(width: double.infinity, height: 13),
        SizedBox(height: 10),
        _skeletonLine(width: 210, height: 13),
        SizedBox(height: 10),
        _skeletonLine(width: 180, height: 13),
      ],
    );
  }

  Widget _buildFechamentoConferenciaContent({
    VoidCallback? refreshSheet,
    VoidCallback? onClosed,
  }) {
    final ResumoCaixa? resumo = _resumo;
    final double dinheiroPrevisto = _valorDinheiroEsperadoFechamento();
    final double pixPrevisto = _valorPixEsperadoFechamento();
    final double cartaoPrevisto = _valorCartaoEsperadoFechamento();
    final bool temDinheiroPrevisto = _temValorPrevisto(dinheiroPrevisto);
    final bool temPixPrevisto = _temValorPrevisto(pixPrevisto);
    final bool temCartaoPrevisto = _temValorPrevisto(cartaoPrevisto);
    final bool temValorPrevisto =
        temDinheiroPrevisto || temPixPrevisto || temCartaoPrevisto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _txt(
            'caixa.operacoes.mobile.closingCheckTitle',
            'Conferência dos valores',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SixMobilePalette.titleText,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _txt(
            'caixa.operacoes.mobile.closingCheckSubtitle',
            'Informe os valores apurados no caixa físico ou nos meios digitais.',
          ),
          style: TextStyle(
            color: SixMobilePalette.mutedText,
            height: 1.32,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        if (!temValorPrevisto)
          _emptyClosingValues()
        else ...<Widget>[
          if (temDinheiroPrevisto) ...<Widget>[
            _closingAmountField(
              label: _labelValorApurado(
                _labelTipoRecebimentoPorCodigo('tipo1', 'Dinheiro'),
              ),
              controller: _fechamentoDinheiroController,
              expectedValue: dinheiroPrevisto,
            ),
            if (temPixPrevisto || temCartaoPrevisto) SizedBox(height: 12),
          ],
          if (temPixPrevisto) ...<Widget>[
            _closingAmountField(
              label: _labelValorApurado(
                _labelTipoRecebimentoPorCodigo('tipo2', 'Pix'),
              ),
              controller: _fechamentoPixController,
              expectedValue: pixPrevisto,
            ),
            if (temCartaoPrevisto) SizedBox(height: 12),
          ],
          if (temCartaoPrevisto) ...<Widget>[
            _closingAmountField(
              label: _txt(
                'caixa.operacoes.mobile.cardsAmount',
                'Cartões apurados',
              ),
              controller: _fechamentoCartaoController,
              expectedValue: cartaoPrevisto,
            ),
          ],
        ],
        SizedBox(height: 12),
        _readOnlyInfo(
          label: _txt(
            'caixa.operacoes.mobile.expectedBalance',
            'Saldo esperado',
          ),
          value: _formatarValor(resumo?.saldoEsperado ?? 0),
          icon: Icons.account_balance_wallet_outlined,
        ),
        SizedBox(height: 12),
        _textField(
          label: _txt(
            'caixa.operacoes.mobile.closingNote',
            'Observação do fechamento',
          ),
          controller: _fechamentoObservacaoController,
          hint: _txt(
            'caixa.operacoes.mobile.closingNoteHint',
            'Detalhe divergências, conferências e observações finais.',
          ),
          keyboardType: TextInputType.multiline,
          maxLines: 3,
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              _busy
                  ? null
                  : () async {
                    final Future<bool> close = _fecharCaixa();
                    refreshSheet?.call();
                    final bool closed = await close;
                    if (closed) {
                      onClosed?.call();
                    } else {
                      refreshSheet?.call();
                    }
                  },
          icon: Icon(Icons.task_alt_rounded),
          label: Text(
            _txt('caixa.operacoes.mobile.finishClosing', 'Concluir fechamento'),
          ),
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(50),
            backgroundColor: SixMobilePalette.accent,
            foregroundColor: SixMobilePalette.onAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed:
              _busy
                  ? null
                  : () {
                    _fechamentoDinheiroController.clear();
                    _fechamentoPixController.clear();
                    _fechamentoCartaoController.clear();
                    _fechamentoObservacaoController.clear();
                    refreshSheet?.call();
                  },
          icon: Icon(Icons.refresh_rounded),
          label: Text(
            _txt('caixa.operacoes.mobile.clearClosing', 'Limpar conferência'),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _closingAmountField({
    required String label,
    required TextEditingController controller,
    required double expectedValue,
  }) {
    return _textField(
      label: label,
      controller: controller,
      hint: _formatarDecimalDigitavel(expectedValue),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      prefixText: '${context.read<LocaleSettingsProvider>().currencySymbol} ',
    );
  }

  Widget _emptyClosingValues() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: SixMobilePalette.mutedText,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _txt(
                'caixa.operacoes.mobile.noExpectedClosingValues',
                'Nenhuma forma possui valor previsto para conferência.',
              ),
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico() {
    final List<MovimentoCaixa> movimentosVisiveis =
        _mostrarApenasHoje
            ? _movimentos
                .where(
                  (MovimentoCaixa movimento) =>
                      _isSameDay(movimento.dataHoraMovimento, _nowProvider()),
                )
                .toList(growable: false)
            : _movimentos;

    return _sectionCard(
      icon: Icons.history_rounded,
      title: _txt('caixa.operacoes.mobile.history', 'Histórico'),
      subtitle:
          _loadingMovimentos && movimentosVisiveis.isEmpty
              ? _txt(
                'caixa.operacoes.mobile.loadingMovements',
                'Carregando movimentações.',
              )
              : '${movimentosVisiveis.length} ${_txt('caixa.operacoes.mobile.visibleRecords', 'registro(s) visível(is).')}',
      trailing: FilterChip(
        label: Text(_txt('caixa.operacoes.mobile.onlyToday', 'Hoje')),
        selected: _mostrarApenasHoje,
        onSelected:
            _busy
                ? null
                : (bool value) => setState(() => _mostrarApenasHoje = value),
      ),
      child:
          _loadingMovimentos && movimentosVisiveis.isEmpty
              ? _historicoSkeleton()
              : movimentosVisiveis.isEmpty
              ? _stateMessage(
                icon: Icons.receipt_long_outlined,
                title: _txt(
                  'caixa.operacoes.mobile.emptyHistoryTitle',
                  'Nenhuma movimentação',
                ),
                message: _txt(
                  'caixa.operacoes.mobile.emptyHistoryMessage',
                  'Os lançamentos aparecerão aqui após a abertura do caixa.',
                ),
              )
              : Column(
                children: movimentosVisiveis
                    .map(
                      (MovimentoCaixa movimento) => Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: _movimentoCard(movimento),
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  Widget _historicoSkeleton() {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _txt(
        'caixa.operacoes.mobile.loadingMovements',
        'Carregando movimentações.',
      ),
      child: Column(
        children: <Widget>[
          _movimentoSkeletonCard(),
          SizedBox(height: 10),
          _movimentoSkeletonCard(),
        ],
      ),
    );
  }

  Widget _movimentoSkeletonCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          _skeletonLine(width: 42, height: 42, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _skeletonLine(width: 160, height: 14),
                SizedBox(height: 8),
                _skeletonLine(width: 110, height: 12),
                SizedBox(height: 10),
                _skeletonLine(width: double.infinity, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _movimentoCard(MovimentoCaixa movimento) {
    final Color color = _corPorNatureza(movimento.natureza);
    final String forma = _descricaoTipoRecebimentoMovimento(movimento);

    return Semantics(
      button: true,
      label:
          '${_labelTipo(movimento.tipoMovimento)}: ${_formatarValor(movimento.valor)}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _abrirDetalhesMovimentoSheet(movimento),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(
              color: SixMobilePalette.softNeutralSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                _iconBox(
                  movimento.natureza.toLowerCase() == 'entrada'
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  bg: _withAlpha(color, 0.10),
                  fg: color,
                  size: 38,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _labelTipo(movimento.tipoMovimento),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SixMobilePalette.titleText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 116),
                            child: Text(
                              _formatarValor(movimento.valor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: color,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          _inlineInfo(
                            Icons.circle,
                            _labelStatusMovimento(movimento.status),
                          ),
                          _inlineInfo(Icons.payments_outlined, forma),
                          _inlineInfo(
                            Icons.schedule_rounded,
                            _formatarDataHora(movimento.dataHoraMovimento),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SixMobilePalette.mutedText,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalhesMovimentoSheet(MovimentoCaixa movimento) async {
    final Color color = _corPorNatureza(movimento.natureza);
    final String forma = _descricaoTipoRecebimentoMovimento(movimento);
    final bool cancelada = movimento.status.toLowerCase() == 'cancelada';
    final String referencia =
        movimento.referencia.isEmpty
            ? _txt('caixa.operacoes.mobile.noReference', 'Sem referência')
            : movimento.referencia;
    final String observacao =
        movimento.observacao.isEmpty
            ? _txt('caixa.operacoes.mobile.noNote', 'Sem observação informada.')
            : movimento.observacao;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.42,
            maxChildSize: 0.88,
            expand: false,
            builder: (
              BuildContext sheetContext,
              ScrollController scrollController,
            ) {
              return Container(
                decoration: BoxDecoration(
                  color: SixMobilePalette.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(18, 12, 18, 22),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: SixMobilePalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _iconBox(
                          movimento.natureza.toLowerCase() == 'entrada'
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          bg: _withAlpha(color, 0.10),
                          fg: color,
                          size: 44,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _txt(
                                  'caixa.operacoes.mobile.movementDetails',
                                  'Detalhes do lançamento',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SixMobilePalette.titleText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _labelTipo(movimento.tipoMovimento),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SixMobilePalette.mutedText,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          tooltip: _txt('common.close', 'Fechar'),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close_rounded),
                          color: SixMobilePalette.mutedText,
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Text(
                      _formatarValor(movimento.valor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _statusChip(
                          label: _labelStatusMovimento(movimento.status),
                          icon: Icons.circle,
                          foreground: _corPorStatus(movimento.status),
                          background: _withAlpha(
                            _corPorStatus(movimento.status),
                            0.10,
                          ),
                          border: _withAlpha(
                            _corPorStatus(movimento.status),
                            0.16,
                          ),
                        ),
                        _statusChip(
                          label: _labelNatureza(movimento.natureza),
                          icon: Icons.swap_vert_rounded,
                          foreground: color,
                          background: _withAlpha(color, 0.10),
                          border: _withAlpha(color, 0.16),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _movementDetailTile(
                      icon: Icons.payments_outlined,
                      label: _txt(
                        'caixa.operacoes.mobile.relatedMethod',
                        'Forma relacionada',
                      ),
                      value: forma,
                    ),
                    SizedBox(height: 10),
                    _movementDetailTile(
                      icon: Icons.person_outline_rounded,
                      label: _txt(
                        'caixa.operacoes.mobile.responsible',
                        'Responsável',
                      ),
                      value: movimento.nomeColaborador,
                    ),
                    SizedBox(height: 10),
                    _movementDetailTile(
                      icon: Icons.schedule_rounded,
                      label: _txt(
                        'caixa.operacoes.mobile.dateTime',
                        'Data e hora',
                      ),
                      value: _formatarDataHora(movimento.dataHoraMovimento),
                    ),
                    SizedBox(height: 10),
                    _movementDetailTile(
                      icon: Icons.receipt_long_outlined,
                      label: _txt(
                        'caixa.operacoes.mobile.reference',
                        'Referência / comprovante',
                      ),
                      value: referencia,
                    ),
                    if (movimento.codigoOperacao.trim().isNotEmpty) ...<Widget>[
                      SizedBox(height: 10),
                      _movementDetailTile(
                        icon: Icons.tag_rounded,
                        label: _txt(
                          'caixa.operacoes.mobile.operationCode',
                          'Código da operação',
                        ),
                        value: movimento.codigoOperacao,
                      ),
                    ],
                    SizedBox(height: 10),
                    _movementDetailTile(
                      icon: Icons.notes_rounded,
                      label: _txt('caixa.operacoes.mobile.note', 'Observação'),
                      value: observacao,
                      multiline: true,
                    ),
                    if (!cancelada) ...<Widget>[
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed:
                            _busy
                                ? null
                                : () async {
                                  Navigator.of(sheetContext).pop();
                                  await _cancelarMovimento(movimento);
                                },
                        icon: Icon(Icons.cancel_outlined),
                        label: Text(_txt('common.cancel', 'Cancelar')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SixMobilePalette.error,
                          minimumSize: Size.fromHeight(48),
                          side: BorderSide(color: SixMobilePalette.errorBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _movementDetailTile({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: SixMobilePalette.accent, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value,
                  maxLines: multiline ? 5 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(
                icon,
                bg: SixMobilePalette.softAccentSurface,
                fg: SixMobilePalette.accent,
                size: 40,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[SizedBox(width: 8), trailing],
            ],
          ),
          SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _selectorField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      value: value,
      child: Material(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _busy ? null : onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 58),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: SixMobilePalette.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: SixMobilePalette.softNeutralSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SixMobilePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SixMobilePalette.highlightedBorder,
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _readOnlyInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return _infoTile(title: label, value: value, icon: icon, fullWidth: true);
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints:
          fullWidth ? null : BoxConstraints(minWidth: 142, maxWidth: 240),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: SixMobilePalette.accent, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem({required bool checked, required String title}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 19,
            color: checked ? _successColor : SixMobilePalette.mutedText,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: SixMobilePalette.mutedText),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _skeletonLine({
    Key? key,
    required double width,
    required double height,
    double radius = 999,
    bool colorOnDark = false,
  }) {
    return Container(
      key: key,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            colorOnDark
                ? _withAlpha(SixMobilePalette.onPrimary, 0.20)
                : _withAlpha(SixMobilePalette.border, 0.62),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color border,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: foreground),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(
    IconData icon, {
    required Color bg,
    required Color fg,
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 44 ? 16 : 14),
      ),
      child: Icon(icon, color: fg, size: size >= 44 ? 23 : 20),
    );
  }

  Widget _animatedCurrencyText(double value, {TextStyle? style}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('caixa-currency-${value.toStringAsFixed(2)}'),
      tween: Tween<double>(begin: 0, end: value),
      duration: Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          _formatarValor(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }

  BoxDecoration _cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: SixMobilePalette.border),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: SixMobilePalette.navigationShadow,
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  Future<void> _selecionarCaixa() async {
    if (_caixasDisponiveis.isEmpty) {
      _snack(
        _txt('caixa.operacoes.mobile.noCashDesk', 'Nenhum caixa disponível.'),
      );
      return;
    }
    final CaixaOuGuiche? selected = await _showSelector<CaixaOuGuiche>(
      title: _txt('caixa.operacoes.mobile.cashDesk', 'Caixa / guichê'),
      subtitle: _txt(
        'caixa.operacoes.mobile.cashDeskSelectorSubtitle',
        'Escolha o caixa que será aberto para a operação.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _caixaSelecionado,
      options: _caixasDisponiveis
          .map(
            (CaixaOuGuiche item) => _SelectorOption<CaixaOuGuiche>(
              value: item,
              title: item.nome,
              subtitle: item.id,
              icon: Icons.store_mall_directory_outlined,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    setState(() => _caixaSelecionado = selected);
  }

  Future<void> _selecionarCaixaFiltro() async {
    if (_caixasDisponiveis.isEmpty) {
      _snack(
        _txt('caixa.operacoes.mobile.noCashDesk', 'Nenhum caixa disponível.'),
      );
      return;
    }
    final CaixaOuGuiche? selected = await _showSelector<CaixaOuGuiche>(
      title: _txt('caixa.operacoes.mobile.cashDesk', 'Caixa / guichê'),
      subtitle: _txt(
        'caixa.operacoes.mobile.cashDeskViewSelectorSubtitle',
        'Escolha o caixa que deseja visualizar.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _caixaSelecionado,
      options: _caixasDisponiveis
          .map(
            (CaixaOuGuiche item) => _SelectorOption<CaixaOuGuiche>(
              value: item,
              title: item.nome,
              subtitle: item.id,
              icon: Icons.store_mall_directory_outlined,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    await _aplicarCaixaFiltro(selected);
  }

  Future<void> _alterarFiltroModo(_OperacoesCaixaFiltroModo modo) async {
    if (_filtroModo == modo) return;
    setState(() => _filtroModo = modo);
    await _carregarDadosIniciais(idCaixaPreferencial: _caixaSelecionado?.id);
  }

  Future<void> _aplicarCaixaFiltro(CaixaOuGuiche caixa) async {
    final CaixaSessao? sessao = _sessaoAbertaPorCaixaId(caixa.id);
    setState(() {
      _filtroModo = _OperacoesCaixaFiltroModo.porCaixa;
      _caixaSelecionado = caixa;
      _sessaoFiltroSelecionada = sessao;
    });
    await _carregarDadosIniciais(idCaixaPreferencial: caixa.id);
  }

  Future<void> _selecionarTipoOperacao() async {
    final List<OperacaoCaixaTipo> tipos = OperacaoCaixaTipo.values
        .where(
          (OperacaoCaixaTipo tipo) =>
              tipo != OperacaoCaixaTipo.aberturaCaixa &&
              tipo != OperacaoCaixaTipo.fechamentoCaixa,
        )
        .toList(growable: false);
    final OperacaoCaixaTipo? selected = await _showSelector<OperacaoCaixaTipo>(
      title: _txt('caixa.operacoes.mobile.operationType', 'Tipo da operação'),
      subtitle: _txt(
        'caixa.operacoes.mobile.operationTypeSelectorSubtitle',
        'Selecione o tipo técnico que será enviado ao caixa.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _tipoSelecionado,
      options: tipos
          .map(
            (OperacaoCaixaTipo tipo) => _SelectorOption<OperacaoCaixaTipo>(
              value: tipo,
              title: _labelTipo(tipo),
              subtitle: tipo.codigoApi,
              icon: _iconeTipo(tipo),
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    setState(() => _tipoSelecionado = selected);
  }

  Future<void> _selecionarFormaRelacionada() async {
    final List<TiposRecebimento> tipos = _tiposRecebimentoAtivosOrdenados();
    if (tipos.isEmpty) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.noPaymentTypes',
          'Nenhuma forma relacionada ativa.',
        ),
      );
      return;
    }

    final TiposRecebimento? selected = await _showSelector<TiposRecebimento>(
      title: _txt('caixa.operacoes.mobile.relatedMethod', 'Forma relacionada'),
      subtitle: _txt(
        'caixa.operacoes.mobile.relatedMethodSelectorSubtitle',
        'Use a configuração compartilhada de formas de recebimento.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _tipoRecebimentoSelecionado,
      options: tipos
          .map(
            (TiposRecebimento tipo) => _SelectorOption<TiposRecebimento>(
              value: tipo,
              title: _descricaoTipoRecebimentoConfigurado(tipo),
              subtitle: tipo.codigoTipo,
              icon: Icons.payments_outlined,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    setState(() => _tipoRecebimentoSelecionado = selected);
  }

  Future<void> _abrirConferenciaPorFormaSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.66,
            minChildSize: 0.42,
            maxChildSize: 0.88,
            expand: false,
            builder: (
              BuildContext bottomSheetContext,
              ScrollController scrollController,
            ) {
              return Container(
                decoration: BoxDecoration(
                  color: SixMobilePalette.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(18, 12, 18, 22),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: SixMobilePalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _iconBox(
                          Icons.fact_check_outlined,
                          bg: SixMobilePalette.softAccentSurface,
                          fg: SixMobilePalette.accent,
                          size: 44,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _txt(
                                  'caixa.operacoes.mobile.methodSummary',
                                  'Conferência por forma',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SixMobilePalette.titleText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _txt(
                                  'caixa.operacoes.mobile.methodSummarySubtitle',
                                  'Resumo pelos tipos configurados no caixa.',
                                ),
                                style: TextStyle(
                                  color: SixMobilePalette.mutedText,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    _buildResumoOperacionalDetalhado(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _abrirConfiguracoesFechamento() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext bottomSheetContext,
            StateSetter setBottomSheetState,
          ) {
            void updateOption(VoidCallback update) {
              setState(update);
              setBottomSheetState(() {});
            }

            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: BoxDecoration(
                  color: SixMobilePalette.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: SixMobilePalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _iconBox(
                          Icons.settings_outlined,
                          bg: SixMobilePalette.softAccentSurface,
                          fg: SixMobilePalette.accent,
                          size: 44,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _txt(
                                  'caixa.operacoes.mobile.closingSettings',
                                  'Configurações de fechamento',
                                ),
                                style: TextStyle(
                                  color: SixMobilePalette.titleText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _txt(
                                  'caixa.operacoes.mobile.closingSettingsSubtitle',
                                  'Preferências locais para orientar a conferência do caixa.',
                                ),
                                style: TextStyle(
                                  color: SixMobilePalette.mutedText,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    _settingsSwitchTile(
                      title: _txt(
                        'caixa.operacoes.mobile.registerDifferenceAsExpense',
                        'Registrar diferença de caixa como despesa',
                      ),
                      subtitle: _txt(
                        'caixa.operacoes.mobile.registerDifferenceAsExpenseSubtitle',
                        'A opção fica salva apenas nesta tela por enquanto.',
                      ),
                      icon: Icons.receipt_long_outlined,
                      value: _registrarDiferencaComoDespesa,
                      onChanged:
                          (bool value) => updateOption(
                            () => _registrarDiferencaComoDespesa = value,
                          ),
                    ),
                    SizedBox(height: 10),
                    _settingsSwitchTile(
                      title: _txt(
                        'caixa.operacoes.mobile.requestManagerDifferenceApproval',
                        'Pedir confirmação de diferença de caixa ao gestor',
                      ),
                      subtitle: _txt(
                        'caixa.operacoes.mobile.requestManagerDifferenceApprovalSubtitle',
                        'Sem integração com backend nesta versão.',
                      ),
                      icon: Icons.admin_panel_settings_outlined,
                      value: _pedirConfirmacaoDiferencaGestor,
                      onChanged:
                          (bool value) => updateOption(
                            () => _pedirConfirmacaoDiferencaGestor = value,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _settingsSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      container: true,
      toggled: value,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Row(
          children: <Widget>[
            _iconBox(
              icon,
              bg: SixMobilePalette.softAccentSurface,
              fg: SixMobilePalette.accent,
              size: 40,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 13,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Future<T?> _showSelector<T>({
    required String title,
    required String subtitle,
    required String searchHint,
    required List<_SelectorOption<T>> options,
    required T? selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder:
          (BuildContext context) => _OperacoesCaixaMobileSelectorSheet<T>(
            title: title,
            subtitle: subtitle,
            searchHint: searchHint,
            options: options,
            selected: selected,
          ),
    );
  }

  Future<void> _abrirFormularioMovimentoSheet() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return;
    }
    if (!_garantirSessaoEspecificaSelecionada()) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            void refreshSheet() {
              if (sheetContext.mounted) {
                setSheetState(() {});
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.82,
                  minChildSize: 0.52,
                  maxChildSize: 0.94,
                  expand: false,
                  builder: (
                    BuildContext sheetContext,
                    ScrollController scrollController,
                  ) {
                    final String subtitle =
                        _tipoSelecionado == null
                            ? _txt(
                              'caixa.operacoes.mobile.entrySubtitleEmpty',
                              'Escolha uma ação rápida ou selecione o tipo da operação.',
                            )
                            : '${_txt('caixa.operacoes.mobile.entrySubtitleFilled', 'Preencha os dados da operação')} ${_labelTipo(_tipoSelecionado!)}.';

                    return Container(
                      decoration: BoxDecoration(
                        color: SixMobilePalette.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(18, 12, 18, 22),
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: SixMobilePalette.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _iconBox(
                                Icons.edit_note_rounded,
                                bg: SixMobilePalette.softAccentSurface,
                                fg: SixMobilePalette.accent,
                                size: 44,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _txt(
                                        'caixa.operacoes.mobile.entryTitle',
                                        'Lançamento operacional',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: SixMobilePalette.titleText,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: SixMobilePalette.mutedText,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                tooltip: _txt('common.close', 'Fechar'),
                                onPressed:
                                    () => Navigator.of(sheetContext).pop(),
                                icon: Icon(Icons.close_rounded),
                                color: SixMobilePalette.mutedText,
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          _buildFormularioMovimentoContent(
                            refreshSheet: refreshSheet,
                            onSaved: () {
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _abrirPrepararFechamentoSheet() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return;
    }
    if (!_garantirSessaoEspecificaSelecionada()) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            void refreshSheet() {
              if (sheetContext.mounted) {
                setSheetState(() {});
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.88,
                  minChildSize: 0.56,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (
                    BuildContext sheetContext,
                    ScrollController scrollController,
                  ) {
                    return Container(
                      decoration: BoxDecoration(
                        color: SixMobilePalette.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(18, 12, 18, 22),
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: SixMobilePalette.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _iconBox(
                                Icons.rule_folder_outlined,
                                bg: SixMobilePalette.softAccentSurface,
                                fg: SixMobilePalette.accent,
                                size: 44,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _txt(
                                        'caixa.operacoes.mobile.prepareClosing',
                                        'Preparar fechamento',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: SixMobilePalette.titleText,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _txt(
                                        'caixa.operacoes.mobile.prepareClosingSheetSubtitle',
                                        'Use o guia por forma para conferir os valores antes de encerrar.',
                                      ),
                                      style: TextStyle(
                                        color: SixMobilePalette.mutedText,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                tooltip: _txt('common.close', 'Fechar'),
                                onPressed:
                                    () => Navigator.of(sheetContext).pop(),
                                icon: Icon(Icons.close_rounded),
                                color: SixMobilePalette.mutedText,
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          _buildGuiaFechamentoPorForma(),
                          SizedBox(height: 14),
                          _buildFechamentoConferenciaContent(
                            refreshSheet: refreshSheet,
                            onClosed: () {
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _abrirCaixa() async {
    final CaixaOuGuiche? caixaSelecionado = _caixaSelecionado;
    if (caixaSelecionado == null) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.selectCashDesk',
          'Selecione um caixa / guichê.',
        ),
      );
      return;
    }

    final double valorAbertura = _parseCurrency(_trocoInicialController.text);
    setState(() => _confirmandoAberturaCaixa = true);
    bool confirmou = false;
    try {
      confirmou = await _confirmarAcao(
        title: _txt(
          'caixa.operacoes.openConfirmTitle',
          'Confirmar abertura de caixa?',
        ),
        message: _mensagemConfirmacaoAbertura(
          caixa: caixaSelecionado,
          valorAbertura: valorAbertura,
        ),
        confirmLabel: _txt('caixa.operacoes.openConfirmAction', 'Abrir caixa'),
        icon: Icons.lock_open_rounded,
      );
    } finally {
      if (mounted) setState(() => _confirmandoAberturaCaixa = false);
    }
    if (!confirmou || !mounted) return;

    setState(() => _busy = true);
    try {
      await _caixaService.abrirCaixa(
        AbrirCaixaRequest(
          idCaixaOuGuiche: caixaSelecionado.id,
          nomeCaixa: caixaSelecionado.nome,
          valorAbertura: valorAbertura,
        ),
      );
      await _carregarDadosIniciais(idCaixaPreferencial: caixaSelecionado.id);
      if (!mounted) return;
      _snack(
        _txt('caixa.operacoes.mobile.openSuccess', 'Caixa aberto com sucesso.'),
      );
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _salvarMovimento() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return false;
    }
    final String? idSessaoCaixa = _idSessaoEmFoco;
    if (!_garantirSessaoEspecificaSelecionada() || idSessaoCaixa == null) {
      return false;
    }
    if (_tipoSelecionado == null) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.selectOperationType',
          'Selecione o tipo da operação.',
        ),
      );
      return false;
    }
    if (_tipoRecebimentoSelecionado == null) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.selectPaymentType',
          'Selecione a forma relacionada.',
        ),
      );
      return false;
    }

    final double valor = _parseCurrency(_valorController.text);
    if (valor <= 0) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.invalidAmount',
          'Informe um valor válido.',
        ),
      );
      return false;
    }

    setState(() => _busy = true);
    try {
      await _caixaService.registrarMovimentacao(
        RegistrarMovimentoRequest(
          idSessaoCaixa: idSessaoCaixa,
          tipoMovimento: _tipoSelecionado!,
          codigoTipoRecebimento: _tipoRecebimentoSelecionado!.codigoTipo,
          valor: valor,
          observacao: _observacaoController.text.trim(),
          referencia: _referenciaController.text.trim(),
          vinculadoVenda: _vincularVenda,
        ),
      );
      await _carregarDadosIniciais(idCaixaPreferencial: _caixaSelecionado?.id);
      _limparFormularioMovimento();
      if (mounted) {
        _snack(
          _txt(
            'caixa.operacoes.mobile.movementSuccess',
            'Movimentação registrada com sucesso.',
          ),
        );
      }
      return true;
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _limparFormularioMovimento() {
    setState(() {
      _tipoSelecionado = null;
      _valorController.clear();
      _observacaoController.clear();
      _referenciaController.clear();
      _vincularVenda = false;
      final List<TiposRecebimento> tipos = _tiposRecebimentoAtivosOrdenados();
      _tipoRecebimentoSelecionado = tipos.isNotEmpty ? tipos.first : null;
    });
  }

  Future<bool> _fecharCaixa() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return false;
    }
    if (!_garantirSessaoEspecificaSelecionada()) {
      return false;
    }

    setState(() => _busy = true);
    try {
      await _caixaService.fecharCaixa(_montarRequestFechamentoCaixa());
      await _carregarDadosIniciais();
      if (!mounted) return true;
      setState(() {
        _fechamentoDinheiroController.clear();
        _fechamentoPixController.clear();
        _fechamentoCartaoController.clear();
        _fechamentoObservacaoController.clear();
      });
      _snack(
        _txt(
          'caixa.operacoes.mobile.closeSuccess',
          'Caixa fechado com sucesso.',
        ),
      );
      return true;
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  FecharCaixaRequest _montarRequestFechamentoCaixa() {
    final String idSessaoCaixa = _idSessaoEmFoco ?? '';
    final double dinheiroPrevisto = _valorDinheiroEsperadoFechamento();
    final double pixPrevisto = _valorPixEsperadoFechamento();
    final double cartaoPrevisto = _valorCartaoEsperadoFechamento();
    final double dinheiro =
        !_temValorPrevisto(dinheiroPrevisto)
            ? 0
            : _fechamentoDinheiroController.text.trim().isEmpty
            ? dinheiroPrevisto
            : _parseCurrency(_fechamentoDinheiroController.text);
    final double pix =
        !_temValorPrevisto(pixPrevisto)
            ? 0
            : _fechamentoPixController.text.trim().isEmpty
            ? pixPrevisto
            : _parseCurrency(_fechamentoPixController.text);
    final double cartao =
        !_temValorPrevisto(cartaoPrevisto)
            ? 0
            : _fechamentoCartaoController.text.trim().isEmpty
            ? cartaoPrevisto
            : _parseCurrency(_fechamentoCartaoController.text);

    return FecharCaixaRequest(
      idSessaoCaixa: idSessaoCaixa,
      valorDinheiroApurado: dinheiro,
      valorPixApurado: pix,
      valorCartaoApurado: cartao,
      observacaoFechamento: _fechamentoObservacaoController.text.trim(),
    );
  }

  Future<void> _cancelarMovimento(MovimentoCaixa movimento) async {
    final String forma = _descricaoTipoRecebimentoMovimento(movimento);
    final bool confirmou = await _confirmarAcao(
      title: _txt(
        'caixa.operacoes.mobile.cancelMovementTitle',
        'Cancelar movimentação?',
      ),
      message:
          '${_txt('caixa.operacoes.mobile.cancelMovementMessage', 'Deseja cancelar a operação')} ${_labelTipo(movimento.tipoMovimento)} em $forma no valor de ${_formatarValor(movimento.valor)}?',
      confirmLabel: _txt(
        'caixa.operacoes.mobile.cancelMovement',
        'Cancelar operação',
      ),
      icon: Icons.cancel_outlined,
      danger: true,
    );
    if (!confirmou) return;

    setState(() => _busy = true);
    try {
      await _caixaService.cancelarMovimentacao(movimento.idMovimento);
      await _carregarDadosIniciais(idCaixaPreferencial: _caixaSelecionado?.id);
      if (mounted) {
        _snack(
          _txt(
            'caixa.operacoes.mobile.movementCanceled',
            'Movimentação cancelada.',
          ),
        );
      }
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _garantirSessaoEspecificaSelecionada() {
    if (!_exibindoTodosOsCaixas && _idSessaoEmFoco != null) {
      return true;
    }
    _snack(
      _txt(
        'caixa.operacoes.mobile.selectSpecificCashDesk',
        'Selecione um caixa específico para continuar.',
      ),
    );
    return false;
  }

  Future<bool> _confirmarAcao({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    bool danger = false,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: SixMobilePalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _iconBox(
                      icon,
                      bg: _withAlpha(
                        danger
                            ? SixMobilePalette.error
                            : SixMobilePalette.accent,
                        0.10,
                      ),
                      fg:
                          danger
                              ? SixMobilePalette.error
                              : SixMobilePalette.accent,
                      size: 44,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              color: SixMobilePalette.titleText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: SixMobilePalette.mutedText,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: Icon(Icons.check_circle_outline_rounded),
                  label: Text(confirmLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        danger
                            ? SixMobilePalette.error
                            : SixMobilePalette.accent,
                    foregroundColor:
                        danger
                            ? _foregroundForSemantic(SixMobilePalette.error)
                            : SixMobilePalette.onAccent,
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: Icon(Icons.arrow_back_rounded),
                  label: Text(_txt('common.back', 'Voltar')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SixMobilePalette.titleText,
                    minimumSize: Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return result == true;
  }

  int _compararMovimentoPorDataDesc(MovimentoCaixa a, MovimentoCaixa b) {
    final DateTime? dataB = DateTime.tryParse(b.dataHoraMovimento);
    final DateTime? dataA = DateTime.tryParse(a.dataHoraMovimento);
    if (dataA == null && dataB == null) return 0;
    if (dataB == null) return -1;
    if (dataA == null) return 1;
    return dataB.compareTo(dataA);
  }

  InformacoesCaixaComSomatorioResponse _somarMovimentosComSomatorio(
    List<InformacoesCaixaComSomatorioResponse> somatorios,
    List<MovimentoCaixa> movimentos,
  ) {
    double tipo1 = 0;
    double tipo2 = 0;
    double tipo3 = 0;
    double tipo4 = 0;
    double tipo5 = 0;
    double tipo6 = 0;
    double tipo7 = 0;
    double tipo8 = 0;
    double tipo9 = 0;
    double tipo10 = 0;

    for (final InformacoesCaixaComSomatorioResponse item in somatorios) {
      tipo1 += item.tipo1;
      tipo2 += item.tipo2;
      tipo3 += item.tipo3;
      tipo4 += item.tipo4;
      tipo5 += item.tipo5;
      tipo6 += item.tipo6;
      tipo7 += item.tipo7;
      tipo8 += item.tipo8;
      tipo9 += item.tipo9;
      tipo10 += item.tipo10;
    }

    return InformacoesCaixaComSomatorioResponse(
      tipo1: tipo1,
      tipo2: tipo2,
      tipo3: tipo3,
      tipo4: tipo4,
      tipo5: tipo5,
      tipo6: tipo6,
      tipo7: tipo7,
      tipo8: tipo8,
      tipo9: tipo9,
      tipo10: tipo10,
      movimento: movimentos,
    );
  }

  ResumoCaixa _somarResumos(List<ResumoCaixa> resumos) {
    double trocoInicial = 0;
    double totalEntradas = 0;
    double totalSaidas = 0;
    double saldoEsperado = 0;
    int quantidadeMovimentos = 0;
    double totalDinheiro = 0;
    double totalPix = 0;
    double totalCartao = 0;
    double totalCartaoCredito = 0;
    double totalCartaoDebito = 0;
    double totalBoleto = 0;
    double totalFiado = 0;
    double totalCrediario = 0;
    double totalConvenio = 0;
    double totalVale = 0;
    double totalOutros = 0;

    for (final ResumoCaixa item in resumos) {
      trocoInicial += item.trocoInicial;
      totalEntradas += item.totalEntradas;
      totalSaidas += item.totalSaidas;
      saldoEsperado += item.saldoEsperado;
      quantidadeMovimentos += item.quantidadeMovimentos;
      totalDinheiro += item.totalDinheiro;
      totalPix += item.totalPix;
      totalCartao += item.totalCartao;
      totalCartaoCredito += item.totalCartaoCredito;
      totalCartaoDebito += item.totalCartaoDebito;
      totalBoleto += item.totalBoleto;
      totalFiado += item.totalFiado;
      totalCrediario += item.totalCrediario;
      totalConvenio += item.totalConvenio;
      totalVale += item.totalVale;
      totalOutros += item.totalOutros;
    }

    return ResumoCaixa(
      trocoInicial: trocoInicial,
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
      saldoEsperado: saldoEsperado,
      quantidadeMovimentos: quantidadeMovimentos,
      totalDinheiro: totalDinheiro,
      totalPix: totalPix,
      totalCartao: totalCartao,
      totalCartaoCredito: totalCartaoCredito,
      totalCartaoDebito: totalCartaoDebito,
      totalBoleto: totalBoleto,
      totalFiado: totalFiado,
      totalCrediario: totalCrediario,
      totalConvenio: totalConvenio,
      totalVale: totalVale,
      totalOutros: totalOutros,
    );
  }

  List<TiposRecebimento> _tiposRecebimentoAtivosOrdenados() {
    return _tiposRecebimento
      .where((TiposRecebimento item) => item.ativo)
      .toList(growable: false)..sort(
      (TiposRecebimento a, TiposRecebimento b) =>
          a.ordemExibicao.compareTo(b.ordemExibicao),
    );
  }

  String _descricaoTipoRecebimentoConfigurado(TiposRecebimento tipo) {
    final String descricao = tipo.descricaoExibicao.trim();
    return descricao.isNotEmpty
        ? descricao
        : _labelTipoRecebimentoPorCodigo(tipo.codigoTipo, tipo.codigoTipo);
  }

  String _descricaoTipoRecebimentoMovimento(MovimentoCaixa movimento) {
    final String descricao = movimento.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    return _labelTipoRecebimentoPorCodigo(
      movimento.codigoTipoRecebimento,
      movimento.descricao.trim().isNotEmpty
          ? movimento.descricao.trim()
          : _txt('caixa.operacoes.mobile.methodMissing', 'Forma não informada'),
    );
  }

  String _labelTipoRecebimentoPorCodigo(String codigoTipo, String fallback) {
    for (final TiposRecebimento tipo in _tiposRecebimento) {
      if (tipo.codigoTipo.toLowerCase() == codigoTipo.toLowerCase()) {
        final String descricao = tipo.descricaoExibicao.trim();
        if (descricao.isNotEmpty) return descricao;
      }
    }
    return fallback;
  }

  List<_ResumoTipoRecebimentoData> _linhasResumoPorTipoRecebimento() {
    final List<TiposRecebimento> tipos = _tiposRecebimentoAtivosOrdenados();
    if (tipos.isEmpty) {
      return <_ResumoTipoRecebimentoData>[
        _ResumoTipoRecebimentoData(
          _txt('caixa.operacoes.mobile.methodMissing', 'Forma não informada'),
          0,
        ),
      ];
    }

    return tipos
        .map(
          (TiposRecebimento tipo) => _ResumoTipoRecebimentoData(
            _descricaoTipoRecebimentoConfigurado(tipo),
            _valorResumoPorCodigoTipo(tipo.codigoTipo),
          ),
        )
        .toList(growable: false);
  }

  double _valorResumoPorCodigoTipo(String codigoTipo) {
    final InformacoesCaixaComSomatorioResponse? resumo =
        _movimentosComSomatorio;
    if (resumo == null) return 0;
    switch (codigoTipo.toLowerCase()) {
      case 'tipo1':
        return resumo.tipo1;
      case 'tipo2':
        return resumo.tipo2;
      case 'tipo3':
        return resumo.tipo3;
      case 'tipo4':
        return resumo.tipo4;
      case 'tipo5':
        return resumo.tipo5;
      case 'tipo6':
        return resumo.tipo6;
      case 'tipo7':
        return resumo.tipo7;
      case 'tipo8':
        return resumo.tipo8;
      case 'tipo9':
        return resumo.tipo9;
      case 'tipo10':
        return resumo.tipo10;
      default:
        return 0;
    }
  }

  double _valorEsperadoFechamentoPorCodigo(String codigoTipo, double fallback) {
    if (_movimentosComSomatorio == null) return fallback;
    return _valorResumoPorCodigoTipo(codigoTipo);
  }

  double _valorDinheiroEsperadoFechamento() {
    return _valorEsperadoFechamentoPorCodigo(
      'tipo1',
      _resumo?.totalDinheiro ?? 0,
    );
  }

  double _valorPixEsperadoFechamento() {
    return _valorEsperadoFechamentoPorCodigo('tipo2', _resumo?.totalPix ?? 0);
  }

  double _valorCartaoEsperadoFechamento() {
    final double fallback =
        (_resumo?.totalCartaoCredito ?? 0) + (_resumo?.totalCartaoDebito ?? 0);
    if (_movimentosComSomatorio == null) return fallback;
    return _valorResumoPorCodigoTipo('tipo3') +
        _valorResumoPorCodigoTipo('tipo4');
  }

  bool _temValorPrevisto(num valor) {
    return valor > 0;
  }

  String _labelValorApurado(String label) {
    return '$label ${_txt('caixa.operacoes.mobile.checkedAmountSuffix', 'apurado')}';
  }

  IconData _iconeTipo(OperacaoCaixaTipo tipo) {
    switch (tipo) {
      case OperacaoCaixaTipo.suprimento:
        return Icons.add_card_rounded;
      case OperacaoCaixaTipo.sangria:
        return Icons.outbox_rounded;
      case OperacaoCaixaTipo.retiradaDespesa:
        return Icons.receipt_long_rounded;
      case OperacaoCaixaTipo.ajuste:
        return Icons.tune_rounded;
      case OperacaoCaixaTipo.estorno:
        return Icons.undo_rounded;
      case OperacaoCaixaTipo.recebimentoAvulso:
        return Icons.arrow_downward_rounded;
      case OperacaoCaixaTipo.pagamentoAvulso:
        return Icons.arrow_upward_rounded;
      case OperacaoCaixaTipo.aberturaCaixa:
        return Icons.lock_open_rounded;
      case OperacaoCaixaTipo.fechamentoCaixa:
        return Icons.lock_outline_rounded;
    }
  }

  Color _corPorNatureza(String? natureza) {
    if (natureza == null) return SixMobilePalette.mutedText;
    return natureza.toLowerCase() == 'entrada'
        ? _successColor
        : SixMobilePalette.error;
  }

  Color _corPorStatus(String? status) {
    if (status == null) return SixMobilePalette.mutedText;
    switch (status.toLowerCase()) {
      case 'aberta':
        return SixMobilePalette.accent;
      case 'concluida':
        return _successColor;
      case 'cancelada':
        return SixMobilePalette.error;
      case 'pendenteconferencia':
        return _warningColor;
      default:
        return SixMobilePalette.mutedText;
    }
  }

  String _labelTipo(dynamic tipo) {
    String? tipoStr;
    if (tipo is OperacaoCaixaTipo) {
      tipoStr = tipo.name;
    } else if (tipo is String) {
      tipoStr = tipo;
    }
    if (tipoStr == null) return '--';
    switch (tipoStr) {
      case 'aberturaCaixa':
      case 'ABERTURA_CAIXA':
        return _txt('caixa.operacoes.mobile.typeOpenCash', 'Abertura de caixa');
      case 'fechamentoCaixa':
      case 'FECHAMENTO_CAIXA':
        return _txt(
          'caixa.operacoes.mobile.typeCloseCash',
          'Fechamento de caixa',
        );
      case 'suprimento':
      case 'SUPRIMENTO':
        return _txt('caixa.operacoes.mobile.supply', 'Suprimento');
      case 'sangria':
      case 'SANGRIA':
        return _txt('caixa.operacoes.mobile.cashOut', 'Sangria');
      case 'retiradaDespesa':
      case 'RETIRADA_DESPESA':
        return _txt(
          'caixa.operacoes.mobile.typeExpenseWithdrawal',
          'Retirada para despesa',
        );
      case 'ajuste':
      case 'AJUSTE':
        return _txt('caixa.operacoes.mobile.adjustment', 'Ajuste');
      case 'estorno':
      case 'ESTORNO':
        return _txt('caixa.operacoes.mobile.reversal', 'Estorno');
      case 'recebimentoAvulso':
      case 'RECEBIMENTO_AVULSO':
        return _txt(
          'caixa.operacoes.mobile.singleReceipt',
          'Recebimento avulso',
        );
      case 'RECEBIMENTO_FINANCEIRO':
        return _txt(
          'caixa.operacoes.mobile.financialReceipt',
          'Recebimento financeiro',
        );
      case 'pagamentoAvulso':
      case 'PAGAMENTO_AVULSO':
        return _txt('caixa.operacoes.mobile.singlePayment', 'Pagamento avulso');
      default:
        return tipoStr;
    }
  }

  String _labelNatureza(String? natureza) {
    if (natureza == null) return '--';
    switch (natureza.toLowerCase()) {
      case 'entrada':
        return _txt('caixa.operacoes.mobile.inflow', 'Entrada');
      case 'saida':
        return _txt('caixa.operacoes.mobile.outflow', 'Saída');
      default:
        return natureza;
    }
  }

  String _labelStatusMovimento(String? status) {
    if (status == null) return '--';
    switch (status.toLowerCase()) {
      case 'aberta':
        return _txt('caixa.operacoes.mobile.statusOpen', 'Aberta');
      case 'concluida':
        return _txt('caixa.operacoes.mobile.statusDone', 'Concluída');
      case 'cancelada':
        return _txt('caixa.operacoes.mobile.statusCanceled', 'Cancelada');
      case 'pendenteconferencia':
        return _txt(
          'caixa.operacoes.mobile.statusPendingCheck',
          'Pendente conferência',
        );
      default:
        return status;
    }
  }

  String _nomeColaboradorAtual() {
    final String? provided = widget.collaboratorNameProvider?.call().trim();
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }

    final usuario = UsuarioProvider().usuario;
    if (usuario == null) {
      return _txt('caixa.operacoes.mobile.collaborator', 'Colaborador');
    }
    if (usuario.nomeDeGuerra.trim().isNotEmpty) {
      return usuario.nomeDeGuerra.trim();
    }
    final String nomeCompleto = '${usuario.nome} ${usuario.sobrenome}'.trim();
    return nomeCompleto.isEmpty
        ? _txt('caixa.operacoes.mobile.collaborator', 'Colaborador')
        : nomeCompleto;
  }

  String _formatarValor(num valor) {
    return context.read<LocaleSettingsProvider>().formatCurrency(valor);
  }

  String _formatarDecimalDigitavel(num valor) {
    return context.read<LocaleSettingsProvider>().formatDecimal(valor);
  }

  String _mensagemConfirmacaoAbertura({
    required CaixaOuGuiche caixa,
    required double valorAbertura,
  }) {
    return _txt(
          'caixa.operacoes.openConfirmMessage',
          'Deseja abrir {cashDesk} com troco inicial de {amount}?',
        )
        .replaceAll('{cashDesk}', caixa.nome)
        .replaceAll('{amount}', _formatarValor(valorAbertura));
  }

  double _parseCurrency(String text) {
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    String cleaned =
        localeSettings
            .stripCurrencyMarkers(text)
            .replaceAll(RegExp(r'\s'), '')
            .replaceAll(localeSettings.thousandSeparator, '')
            .replaceAll(localeSettings.decimalSeparator, '.')
            .replaceAll(RegExp(r'[^0-9.\-]'), '')
            .trim();
    if (cleaned.indexOf('.') != cleaned.lastIndexOf('.')) {
      final int lastSeparator = cleaned.lastIndexOf('.');
      cleaned =
          cleaned.substring(0, lastSeparator).replaceAll('.', '') +
          cleaned.substring(lastSeparator);
    }
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatarDataHora(String? value) {
    if (value == null || value.isEmpty) return '--';
    final DateTime? dateTime = DateTime.tryParse(value);
    if (dateTime == null) return value;
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    return '${localeSettings.formatDate(dateTime)} ${localeSettings.formatTime(dateTime)}';
  }

  bool _isSameDay(String? value, DateTime other) {
    if (value == null || value.isEmpty) return false;
    final DateTime? dateTime = DateTime.tryParse(value);
    if (dateTime == null) return false;
    return dateTime.year == other.year &&
        dateTime.month == other.month &&
        dateTime.day == other.day;
  }

  String _mensagemErro(Object error) {
    final String errorText = error.toString();
    if (errorText.toLowerCase().contains('já está aberto') ||
        errorText.toLowerCase().contains('ja está aberto') ||
        errorText.toLowerCase().contains('ja esta aberto') ||
        errorText.toLowerCase().contains('em uso por outro usuário') ||
        errorText.toLowerCase().contains('em uso por outro usuario')) {
      return _txt(
        'caixa.operacoes.mobile.errorCashDeskAlreadyInUse',
        'Este caixa já está aberto e em uso por outro usuário.',
      );
    }
    if (errorText.contains('statusCode: 401') || errorText.contains(' 401')) {
      return _txt(
        'caixa.operacoes.mobile.errorUnauthorized',
        'Sessão expirada. Faça login novamente.',
      );
    }
    if (errorText.contains('statusCode: 403') || errorText.contains(' 403')) {
      return _txt(
        'caixa.operacoes.mobile.errorForbidden',
        'Você não possui permissão para operar este caixa.',
      );
    }
    if (errorText.contains('statusCode: 404') || errorText.contains(' 404')) {
      return _txt(
        'caixa.operacoes.mobile.errorNotFound',
        'Informação de caixa não encontrada.',
      );
    }
    return _txt(
      'caixa.operacoes.mobile.errorGeneric',
      'Não foi possível concluir a operação de caixa.',
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);
}

class _CaixaHeroCarousel extends StatefulWidget {
  const _CaixaHeroCarousel({required this.semanticLabel, required this.child});

  final String semanticLabel;
  final Widget child;

  @override
  State<_CaixaHeroCarousel> createState() => _CaixaHeroCarouselState();
}

class _CaixaHeroCarouselState extends State<_CaixaHeroCarousel> {
  final ScrollController _controller = ScrollController();
  bool _hintPlayed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleScrollHint(bool reduceMotion) {
    if (_hintPlayed || reduceMotion) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hintPlayed || !_controller.hasClients) return;

      final ScrollPosition position = _controller.position;
      if (position.maxScrollExtent <= 8) return;

      _hintPlayed = true;
      final double hintOffset = position.maxScrollExtent.clamp(0.0, 24.0);
      try {
        await _controller.animateTo(
          hintOffset,
          duration: Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        if (!mounted || !_controller.hasClients) return;
        await _controller.animateTo(
          0,
          duration: Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
        );
      } catch (_) {
        // A tela pode ser desmontada enquanto os dados do backend chegam.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _scheduleScrollHint(reduceMotion);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: widget.child,
      ),
    );
  }
}

class _ResumoTipoRecebimentoData {
  const _ResumoTipoRecebimentoData(this.label, this.valor);

  final String label;
  final double valor;
}

class _OperacoesCaixaSessaoCarregada {
  const _OperacoesCaixaSessaoCarregada({
    required this.sessao,
    required this.movimentos,
    required this.movimentosComSomatorio,
    required this.resumo,
  });

  final CaixaSessao sessao;
  final List<MovimentoCaixa> movimentos;
  final InformacoesCaixaComSomatorioResponse movimentosComSomatorio;
  final ResumoCaixa resumo;
}

class _SelectorOption<T> {
  const _SelectorOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final T value;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _OperacoesCaixaMobileSelectorSheet<T> extends StatefulWidget {
  const _OperacoesCaixaMobileSelectorSheet({
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.options,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final List<_SelectorOption<T>> options;
  final T? selected;

  @override
  State<_OperacoesCaixaMobileSelectorSheet<T>> createState() =>
      _OperacoesCaixaMobileSelectorSheetState<T>();
}

class _OperacoesCaixaMobileSelectorSheetState<T>
    extends State<_OperacoesCaixaMobileSelectorSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_SelectorOption<T>> filtered = widget.options
        .where((_SelectorOption<T> option) {
          final String haystack =
              '${option.title} ${option.subtitle}'.toLowerCase();
          return haystack.contains(_query.trim().toLowerCase());
        })
        .toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: SixMobilePalette.background,
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
                    color: SixMobilePalette.border,
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
                          Icons.tune_rounded,
                          color: SixMobilePalette.accent,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SixMobilePalette.titleText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SixMobilePalette.mutedText,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.t('common.close', fallback: 'Fechar'),
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
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon:
                          _query.isEmpty
                              ? null
                              : IconButton(
                                tooltip: context.t(
                                  'common.clear',
                                  fallback: 'Limpar',
                                ),
                                icon: Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      filled: true,
                      fillColor: SixMobilePalette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: SixMobilePalette.border),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child:
                      filtered.isEmpty
                          ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                context.t(
                                  'common.noResults',
                                  fallback: 'Nenhum resultado encontrado',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: SixMobilePalette.mutedText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                          : ListView.separated(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final _SelectorOption<T> option = filtered[index];
                              final bool selected =
                                  option.value == widget.selected;
                              return Material(
                                color:
                                    selected
                                        ? SixMobilePalette.softAccentSurface
                                        : SixMobilePalette.surface,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap:
                                      () => Navigator.of(
                                        context,
                                      ).pop(option.value),
                                  child: Container(
                                    padding: EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color:
                                            selected
                                                ? SixMobilePalette
                                                    .highlightedBorder
                                                : SixMobilePalette.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color:
                                                selected
                                                    ? SixMobilePalette.surface
                                                    : SixMobilePalette
                                                        .softNeutralSurface,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            option.icon,
                                            color: SixMobilePalette.accent,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                option.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color:
                                                      SixMobilePalette
                                                          .titleText,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              if (option
                                                  .subtitle
                                                  .isNotEmpty) ...<Widget>[
                                                SizedBox(height: 3),
                                                Text(
                                                  option.subtitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        SixMobilePalette
                                                            .mutedText,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (selected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: SixMobilePalette.accent,
                                          ),
                                      ],
                                    ),
                                  ),
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
    );
  }
}
