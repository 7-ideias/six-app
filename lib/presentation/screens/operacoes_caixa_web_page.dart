import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/di/caixa_module.dart';
import '../../data/models/caixa_completo_movimentos_models.dart';
import '../../data/models/caixa_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/empresa_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/web/six_web_cash_movement_cancel_dialog.dart';
import '../components/web/six_web_cash_session_close_dialog.dart';
import '../components/web/six_web_operational_launch_dialog.dart';
import '../components/web/six_web_select_field.dart';
import 'consulta_vendas_web_page.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';

enum _OperacoesCaixaFiltroModo { todosOsCaixas, porCaixa }

class OperacoesCaixaWebPage extends StatefulWidget {
  const OperacoesCaixaWebPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<OperacoesCaixaWebPage> createState() => _OperacoesCaixaWebPageState();
}

class _OperacoesCaixaWebPageState extends State<OperacoesCaixaWebPage> {
  static const String _historicoTodosKey = '__all__';
  static const String _periodoHoje = 'Hoje';
  static const String _periodoUltimos7Dias = 'Últimos 7 dias';
  static const String _periodoUltimos30Dias = 'Últimos 30 dias';
  static const String _periodoEsteMes = 'Este mês';
  static const String _periodoMesPassado = 'Mês passado';
  static const String _periodoIntervaloPersonalizado =
      'Intervalo personalizado';
  static const List<String> _periodosFiltroHistorico = <String>[
    _periodoHoje,
    _periodoUltimos7Dias,
    _periodoUltimos30Dias,
    _periodoEsteMes,
    _periodoMesPassado,
    _periodoIntervaloPersonalizado,
  ];

  final CaixaService _caixaService = CaixaModule.caixaService;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _trocoInicialController = TextEditingController(
    text: '200,00',
  );
  final TextEditingController _fechamentoDinheiroController =
      TextEditingController();
  final TextEditingController _fechamentoPixController =
      TextEditingController();
  final TextEditingController _fechamentoCartaoController =
      TextEditingController();
  final TextEditingController _fechamentoObservacaoController =
      TextEditingController();

  bool _isLoading = false;
  bool _confirmandoAberturaCaixa = false;
  bool _mostrarPainelFechamento = false;
  bool _usuarioEhAdministrador = false;
  late DateTime _dataHistoricoInicial;
  late DateTime _dataHistoricoFinal;
  late DateTime _dataHistoricoInicioPersonalizada;
  late DateTime _dataHistoricoFimPersonalizada;
  String _periodoHistoricoSelecionado = _periodoHoje;
  String? _filtroHistoricoNatureza;
  String? _filtroHistoricoStatus;
  String? _filtroHistoricoTipo;
  String? _filtroHistoricoForma;

  CaixaSessao? _sessaoAtual;
  CaixaSessao? _sessaoFiltroSelecionada;
  CaixaOuGuiche? _caixaSelecionado;
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
    final DateTime hoje = _hojeNormalizado();
    _dataHistoricoInicial = hoje;
    _dataHistoricoFinal = hoje;
    _dataHistoricoInicioPersonalizada = hoje;
    _dataHistoricoFimPersonalizada = hoje;
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _trocoInicialController.dispose();
    _fechamentoDinheiroController.dispose();
    _fechamentoPixController.dispose();
    _fechamentoCartaoController.dispose();
    _fechamentoObservacaoController.dispose();
    super.dispose();
  }

  bool get _podeFiltrarTodosOsCaixas =>
      _usuarioEhAdministrador && _caixasDisponiveis.length > 1;

  bool get _exibindoTodosOsCaixas =>
      _podeFiltrarTodosOsCaixas &&
      _filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas;

  bool get _temCaixaAberto {
    if (_exibindoTodosOsCaixas) {
      return _sessoesAbertasVisiveis.any(_sessaoCaixaAberta);
    }
    final CaixaSessao? sessao = _sessaoEmFoco;
    return sessao != null && _sessaoCaixaAberta(sessao);
  }

  CaixaSessao? get _sessaoEmFoco {
    if (_exibindoTodosOsCaixas) {
      return null;
    }
    final CaixaSessao? selecionada = _sessaoFiltroSelecionada;
    if (selecionada != null) {
      for (final CaixaSessao sessao in _sessoesAbertasVisiveis) {
        if (sessao.idSessaoCaixa == selecionada.idSessaoCaixa) {
          return sessao;
        }
      }
    }
    final CaixaOuGuiche? caixaSelecionado = _caixaSelecionado;
    if (caixaSelecionado != null) {
      final CaixaSessao? sessaoDaCaixa = _sessaoAbertaPorCaixa(
        caixaSelecionado,
      );
      return sessaoDaCaixa;
    }
    return _sessaoAtual;
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
    return _primeiraSessaoDaListaPorCaixaId(
      _sessoesAbertasVisiveis,
      idCaixaOuGuiche,
    );
  }

  CaixaSessao? _sessaoAbertaPorCaixa(CaixaOuGuiche caixa) {
    final CaixaSessao? porId = _sessaoAbertaPorCaixaId(caixa.id);
    if (porId != null) {
      return porId;
    }
    return _primeiraSessaoDaListaPorNome(_sessoesAbertasVisiveis, caixa.nome);
  }

  CaixaSessao? _primeiraSessaoDaListaPorCaixaId(
    List<CaixaSessao> sessoes,
    String idCaixaOuGuiche,
  ) {
    for (final CaixaSessao sessao in sessoes) {
      if (sessao.idCaixaOuGuiche == idCaixaOuGuiche) {
        return sessao;
      }
    }
    return null;
  }

  CaixaSessao? _primeiraSessaoDaListaPorNome(
    List<CaixaSessao> sessoes,
    String nomeCaixa,
  ) {
    final String nomeNormalizado = nomeCaixa.trim().toLowerCase();
    if (nomeNormalizado.isEmpty) {
      return null;
    }
    for (final CaixaSessao sessao in sessoes) {
      if (sessao.nomeCaixa.trim().toLowerCase() == nomeNormalizado) {
        return sessao;
      }
    }
    return null;
  }

  CaixaOuGuiche? _primeiroCaixaPorId(String idCaixaOuGuiche) {
    for (final CaixaOuGuiche caixa in _caixasDisponiveis) {
      if (caixa.id == idCaixaOuGuiche) {
        return caixa;
      }
    }
    return null;
  }

  Future<void> _carregarDadosIniciais({String? idCaixaPreferencial}) async {
    setState(() => _isLoading = true);
    try {
      final bool usuarioEhAdministrador =
          context.read<ColaboradorAutorizacoesProvider>().ehAdministrador;
      final informacoesBasicas =
          await _caixaService.buscarInformacoesBasicasDoCaixa();

      if (mounted && informacoesBasicas.regionalizacao != null) {
        await context
            .read<LocaleSettingsProvider>()
            .atualizarConfiguracaoDaEmpresaPorResponse(
              informacoesBasicas.regionalizacao!,
            );
      }

      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      final List<Object?> dados = await Future.wait<Object?>(<Future<Object?>>[
        _caixaService.buscarSessaoAtual(),
        _caixaService.listarSessoesAbertas(),
      ]);
      final CaixaSessao? sessao = dados[0] as CaixaSessao?;
      final List<CaixaSessao> sessoesAbertas = (dados[1] as List<CaixaSessao>)
          .toList(growable: false);

      final caixas =
          informacoesBasicas.caixaOuGuiche.isNotEmpty
              ? informacoesBasicas.caixaOuGuiche
              : informacoesBasicas.caixas
                  .map((nome) => CaixaOuGuiche(id: nome, nome: nome))
                  .toList(growable: false);

      final idPreferencial = idCaixaPreferencial ?? _caixaSelecionado?.id;
      CaixaOuGuiche? caixaPreferencial;
      if (idPreferencial != null) {
        for (final caixa in caixas) {
          if (caixa.id == idPreferencial) {
            caixaPreferencial = caixa;
            break;
          }
        }
      }

      CaixaSessao? sessaoPreferencial;
      final String? idSessaoPreferencial =
          _sessaoFiltroSelecionada?.idSessaoCaixa ??
          _sessaoAtual?.idSessaoCaixa;
      if (idSessaoPreferencial != null) {
        for (final CaixaSessao sessaoAberta in sessoesAbertas) {
          if (sessaoAberta.idSessaoCaixa == idSessaoPreferencial) {
            sessaoPreferencial = sessaoAberta;
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
      final CaixaSessao? sessaoDoCaixaPreferencial =
          caixaPreferencial != null
              ? _primeiraSessaoDaListaPorCaixaId(
                    sessoesAbertas,
                    caixaPreferencial.id,
                  ) ??
                  _primeiraSessaoDaListaPorNome(
                    sessoesAbertas,
                    caixaPreferencial.nome,
                  )
              : null;
      final CaixaSessao? sessaoEmFoco =
          filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas
              ? null
              : caixaPreferencial != null
              ? sessaoDoCaixaPreferencial
              : sessaoPreferencial ??
                  sessao ??
                  (sessoesAbertas.isNotEmpty ? sessoesAbertas.first : null);
      setState(() {
        _usuarioEhAdministrador = usuarioEhAdministrador;
        _filtroModo = filtroModo;
        _caixasDisponiveis = caixas;
        _sessoesAbertasVisiveis = sessoesAbertas;
        _tiposRecebimento = informacoesBasicas.tiposRecebimento;
        _caixaSelecionado =
            caixaPreferencial ??
            (_caixasDisponiveis.isNotEmpty ? _caixasDisponiveis.first : null);
        _sessaoAtual = sessaoEmFoco;
        _sessaoFiltroSelecionada = sessaoEmFoco;
        _movimentos = <MovimentoCaixa>[];
        _movimentosComSomatorio = null;
        _resumo = null;
      });

      if (filtroModo == _OperacoesCaixaFiltroModo.todosOsCaixas) {
        if (sessoesAbertas.isNotEmpty) {
          await _carregarMovimentosEResumoDeTodasAsSessoes(sessoesAbertas);
        }
      } else if (sessaoEmFoco != null) {
        await _carregarMovimentosEResumo(sessaoEmFoco.idSessaoCaixa);
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados do caixa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarMovimentosEResumo(String idCaixaSessao) async {
    try {
      final movimentos = await _caixaService.listarMovimentacoes(idCaixaSessao);
      if (!mounted) return;
      setState(() => _movimentos = movimentos);
    } catch (e) {
      _mostrarErro('Erro ao carregar movimentações: $e');
    }

    try {
      final movimentosComSomatorio = await _caixaService
          .buscarResumoDeMovimentosComSomatorio(idCaixaSessao);
      if (!mounted) return;
      setState(() {
        _movimentosComSomatorio = movimentosComSomatorio;
        if (_movimentos.isEmpty &&
            movimentosComSomatorio.movimento.isNotEmpty) {
          _movimentos = movimentosComSomatorio.movimento;
        }
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar resumo de movimentações: $e');
    }

    try {
      final resumo = await _caixaService.buscarResumo(idCaixaSessao);
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (e) {
      _mostrarErro('Erro ao carregar resumo do caixa: $e');
    }
  }

  Future<void> _carregarMovimentosEResumoDeTodasAsSessoes(
    List<CaixaSessao> sessoes,
  ) async {
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
    } catch (e) {
      _mostrarErro('Erro ao carregar resumo consolidado dos caixas: $e');
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
      movimentos: dados[0] as List<MovimentoCaixa>,
      movimentosComSomatorio: dados[1] as InformacoesCaixaComSomatorioResponse,
      resumo: dados[2] as ResumoCaixa,
    );
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _mostrarAvisoCaixaNaoAberto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Antes de lançar operações, faça a abertura do caixa.'),
      ),
    );
  }

  void _sairDaTela() {
    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _alternarPainelFechamento() {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    setState(() => _mostrarPainelFechamento = !_mostrarPainelFechamento);
  }

  @override
  Widget build(BuildContext context) {
    final bool podeFecharTela = widget.onBack != null || !widget.embedded;
    final Widget content = Focus(
      autofocus: podeFecharTela,
      child: _buildContent(context),
    );
    final Widget closeAwareContent = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _SairDaTelaIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SairDaTelaIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              _sairDaTela();
              return null;
            },
          ),
        },
        child: content,
      ),
    );

    if (widget.embedded) {
      return podeFecharTela ? closeAwareContent : content;
    }

    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: SafeArea(child: closeAwareContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final initialLoading =
        _isLoading && _sessaoAtual == null && _resumo == null;
    final Widget body =
        initialLoading
            ? KeyedSubtree(
              key: const ValueKey<String>('operacoes-caixa-loading'),
              child: _buildLoading(theme),
            )
            : KeyedSubtree(
              key: const ValueKey<String>('operacoes-caixa-content'),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1120;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SixWebEntry(order: 0, child: _buildKpis(theme)),
                        const SizedBox(height: 18),
                        if (!_temCaixaAberto)
                          SixWebEntry(
                            order: 1,
                            child: _buildPainelAbertura(theme),
                          )
                        else if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    SixWebEntry(
                                      order: 1,
                                      child: _buildContextoOperacao(theme),
                                    ),
                                    if (_mostrarPainelFechamento) ...<Widget>[
                                      const SizedBox(height: 12),
                                      SixWebEntry(
                                        order: 2,
                                        child: _buildPainelFechamento(theme),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    SixWebEntry(
                                      order: 3,
                                      child: _buildHistorico(theme),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 390,
                                child: SixWebEntry(
                                  order: 4,
                                  child: _buildResumoLateral(theme),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: <Widget>[
                              SixWebEntry(
                                order: 1,
                                child: _buildContextoOperacao(theme),
                              ),
                              const SizedBox(height: 12),
                              SixWebEntry(
                                order: 2,
                                child: _buildResumoLateral(theme),
                              ),
                              if (_mostrarPainelFechamento) ...<Widget>[
                                const SizedBox(height: 12),
                                SixWebEntry(
                                  order: 3,
                                  child: _buildPainelFechamento(theme),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SixWebEntry(
                                order: 4,
                                child: _buildHistorico(theme),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            );

    return Material(
      color: tokens.workspaceBackground,
      child: Theme(
        data: theme.copyWith(
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: _outlinedButtonStyle(theme),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: _filledButtonStyle(theme),
          ),
          checkboxTheme: _checkboxTheme(theme),
        ),
        child: Column(
          children: <Widget>[
            _buildHeader(theme),
            Expanded(
              child: AnimatedContainer(
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                color: tokens.workspaceBackground,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: _softBox(theme),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 12),
            Text('Carregando operações de caixa...'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final empresa = EmpresaProvider().empresa?.nomeFantasia ?? 'Empresa';
    final movimentos = _resumo?.quantidadeMovimentos ?? _movimentos.length;
    final String subtituloStatus =
        _exibindoTodosOsCaixas
            ? '${_sessoesAbertasVisiveis.length} caixa(s) abertos'
            : _temCaixaAberto
            ? 'Caixa aberto'
            : 'Aguardando abertura';
    return SixWebDashboardHeader(
      icon: Icons.point_of_sale_rounded,
      title: 'Operações de caixa',
      subtitle: '$empresa • $movimentos movimento(s) • $subtituloStatus',
      onBack: widget.embedded && widget.onBack == null ? null : _sairDaTela,
      actions: <Widget>[
        if (_temCaixaAberto && !_exibindoTodosOsCaixas)
          OutlinedButton.icon(
            onPressed: _confirmarEncerramentoSessao,
            icon: const Icon(Icons.power_settings_new_rounded),
            label: Text(
              _txt('caixa.operacoes.closeSessionAction', 'Encerrar caixa'),
            ),
          ),
        if (_temCaixaAberto && !_exibindoTodosOsCaixas)
          FilledButton.icon(
            onPressed: _isLoading ? null : _abrirDialogoLancamentoOperacional,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _txt('caixa.operacoes.addEntryAction', 'Adicionar lançamento'),
            ),
          ),
        if (_temCaixaAberto && !_exibindoTodosOsCaixas)
          OutlinedButton.icon(
            onPressed: _alternarPainelFechamento,
            icon: const Icon(Icons.rule_folder_outlined),
            label: Text(
              _mostrarPainelFechamento
                  ? 'Ocultar fechamento'
                  : 'Preparar fechamento',
            ),
          ),
        if (_podeFiltrarTodosOsCaixas) _buildFiltroCaixaAction(theme),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _carregarDadosIniciais(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
    );
  }

  Widget _buildKpis(ThemeData theme) {
    final resumo = _resumo;
    final String helperMovimentos =
        _exibindoTodosOsCaixas
            ? '${_sessoesAbertasVisiveis.length} caixa(s) abertos'
            : _usaPeriodoHistoricoPersonalizado
            ? _txt(
              'caixa.operacoes.historyPeriodCustomRange',
              'Intervalo personalizado',
            )
            : _historicoPeriodoItemLabel(_periodoHistoricoSelecionado);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final width =
            compact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 36) / 4).clamp(210.0, 360.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _summaryCard(
              theme,
              width: width,
              label: 'Saldo esperado',
              value: _animatedCurrencyText(
                theme,
                animationKey: 'saldo-esperado',
                value: resumo?.saldoEsperado ?? 0,
                highlight: true,
              ),
              helper:
                  _temCaixaAberto ? 'Caixa em operação' : 'Aguardando abertura',
              icon: Icons.account_balance_wallet_outlined,
              highlight: true,
            ),
            _summaryCard(
              theme,
              width: width,
              label: 'Entradas',
              value: _animatedCurrencyText(
                theme,
                animationKey: 'total-entradas',
                value: resumo?.totalEntradas ?? 0,
              ),
              helper: 'Recebimentos e suprimentos',
              icon: Icons.south_west_rounded,
            ),
            _summaryCard(
              theme,
              width: width,
              label: 'Saídas',
              value: _animatedCurrencyText(
                theme,
                animationKey: 'total-saidas',
                value: resumo?.totalSaidas ?? 0,
              ),
              helper: 'Sangrias e despesas',
              icon: Icons.north_east_rounded,
            ),
            _summaryCard(
              theme,
              width: width,
              label: 'Movimentos',
              value: Text(
                '${resumo?.quantidadeMovimentos ?? _movimentos.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              helper: helperMovimentos,
              icon: Icons.receipt_long_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required double width,
    required String label,
    required Widget value,
    required String helper,
    required IconData icon,
    bool highlight = false,
  }) {
    final colorScheme = theme.colorScheme;
    final tokens = WebThemeTokens.of(context);
    final Color accent = highlight ? tokens.info : colorScheme.primary;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? tokens.surfaceMuted : tokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight ? tokens.selectedBorder : tokens.cardBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    highlight ? tokens.selectedBackground : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  value,
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedCurrencyText(
    ThemeData theme, {
    required String animationKey,
    required double value,
    bool highlight = false,
    double fontSize = 20,
    TextAlign textAlign = TextAlign.end,
  }) {
    final regionalizacao = context.watch<LocaleSettingsProvider>();
    final color = WebThemeTokens.of(context).primaryText;
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(
        '$animationKey:${regionalizacao.currencyCode}:${value.toStringAsFixed(4)}',
      ),
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          regionalizacao.formatCurrency(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }

  Widget _buildPainelAbertura(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            theme,
            title: 'Abertura de caixa',
            subtitle:
                'Defina o caixa, o troco inicial e inicie a operação do dia.',
            icon: Icons.lock_open_rounded,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildFieldBox(
                theme,
                width: 340,
                label: 'Caixa / guichê',
                child: _buildDropdown<CaixaOuGuiche>(
                  theme,
                  value: _caixaSelecionado,
                  items: _caixasDisponiveis,
                  onChanged:
                      (value) => setState(() => _caixaSelecionado = value),
                  itemLabel: (item) => item.nome,
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(
                theme,
                width: 220,
                label: 'Troco inicial',
                child: _buildTextField(
                  theme,
                  controller: _trocoInicialController,
                  hint: '0,00',
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 280,
                label: 'Colaborador responsável',
                child: _buildReadOnlyField(
                  theme,
                  UsuarioProvider().usuario?.nomeDeGuerra ?? '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed:
                _isLoading || _confirmandoAberturaCaixa ? null : _abrirCaixa,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Abrir caixa'),
          ),
        ],
      ),
    );
  }

  Widget _buildContextoOperacao(ThemeData theme) {
    final CaixaSessao? sessao = _sessaoEmFoco;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          _miniMetric(
            theme,
            title: 'Caixa',
            value:
                _exibindoTodosOsCaixas
                    ? 'Todos os caixas'
                    : sessao?.nomeCaixa ?? '--',
            icon: Icons.store_mall_directory_outlined,
          ),
          _miniMetric(
            theme,
            title: _exibindoTodosOsCaixas ? 'Sessões abertas' : 'Abertura',
            value:
                _exibindoTodosOsCaixas
                    ? '${_sessoesAbertasVisiveis.length}'
                    : _formatDateTime(sessao?.dataHoraAbertura),
            icon: Icons.schedule_rounded,
          ),
          _miniMetric(
            theme,
            title:
                _exibindoTodosOsCaixas ? 'Troco consolidado' : 'Troco inicial',
            valueWidget: _animatedCurrencyText(
              theme,
              animationKey: 'contexto-troco-inicial',
              value:
                  _exibindoTodosOsCaixas
                      ? (_resumo?.trocoInicial ?? 0)
                      : (sessao?.valorAbertura ?? 0),
              fontSize: 14.5,
              textAlign: TextAlign.start,
            ),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    ThemeData theme, {
    required String title,
    String? value,
    Widget? valueWidget,
    required IconData icon,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 270),
      padding: const EdgeInsets.all(14),
      decoration: _softBox(theme),
      child: Row(
        children: <Widget>[
          Icon(icon, color: tokens.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                valueWidget ??
                    Text(
                      value ?? '--',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    final regionalizacao = context.watch<LocaleSettingsProvider>();
    final movimentosVisiveis = _movimentosHistoricoFiltrados();
    final opcoesNatureza = _opcoesFiltroHistoricoNatureza();
    final opcoesStatus = _opcoesFiltroHistoricoStatus();
    final opcoesTipo = _opcoesFiltroHistoricoTipo();
    final opcoesForma = _opcoesFiltroHistoricoForma();
    const double campoFiltroLargura = 220;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionHeader(
                  theme,
                  title: 'Histórico de movimentações',
                  subtitle: '${movimentosVisiveis.length} registros visíveis.',
                  icon: Icons.history_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _softBox(theme),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SixWebSelectField(
                  width: campoFiltroLargura,
                  label: _txt('caixa.operacoes.historyPeriod', 'Período'),
                  value: _historicoPeriodoFiltroLabel(regionalizacao),
                  items: <String>[
                    for (final String value in _periodosFiltroHistorico)
                      _historicoPeriodoItemLabel(value),
                  ],
                  icon: Icons.date_range_rounded,
                  onSelected: (String selected) {
                    _selecionarPeriodoHistorico(
                      _historicoPeriodoValueFromLabel(selected),
                    );
                  },
                ),
                if (opcoesNatureza.length > 1)
                  _buildHistoricoPopupFiltro(
                    theme,
                    icon: Icons.compare_arrows_rounded,
                    title: _txt('caixa.operacoes.historyNature', 'Natureza'),
                    value: _filtroHistoricoNatureza,
                    options: opcoesNatureza,
                    onSelected:
                        (value) =>
                            setState(() => _filtroHistoricoNatureza = value),
                  ),
                if (opcoesStatus.length > 1)
                  _buildHistoricoPopupFiltro(
                    theme,
                    icon: Icons.flag_outlined,
                    title: _txt('caixa.operacoes.historyStatus', 'Status'),
                    value: _filtroHistoricoStatus,
                    options: opcoesStatus,
                    onSelected:
                        (value) =>
                            setState(() => _filtroHistoricoStatus = value),
                  ),
                if (opcoesTipo.length > 1)
                  _buildHistoricoPopupFiltro(
                    theme,
                    icon: Icons.receipt_long_outlined,
                    title: _txt('caixa.operacoes.historyOperation', 'Operação'),
                    value: _filtroHistoricoTipo,
                    options: opcoesTipo,
                    onSelected:
                        (value) => setState(() => _filtroHistoricoTipo = value),
                  ),
                if (opcoesForma.length > 1)
                  _buildHistoricoPopupFiltro(
                    theme,
                    icon: Icons.payments_outlined,
                    title: _txt('caixa.operacoes.historyMethod', 'Forma'),
                    value: _filtroHistoricoForma,
                    options: opcoesForma,
                    onSelected:
                        (value) =>
                            setState(() => _filtroHistoricoForma = value),
                  ),
                if (_temFiltrosHistoricoAtivos)
                  OutlinedButton.icon(
                    onPressed: _limparFiltrosHistorico,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: Text(
                      _txt(
                        'caixa.operacoes.historyClearFilters',
                        'Limpar filtros',
                      ),
                    ),
                    style: _outlinedButtonStyle(theme),
                  ),
              ],
            ),
          ),
          if (_usaPeriodoHistoricoPersonalizado) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HistoricoDateFilterButton(
                  tokens: tokens,
                  width: campoFiltroLargura,
                  label: _txt(
                    'caixa.operacoes.historyStartDate',
                    'Data inicial',
                  ),
                  value: regionalizacao.formatDate(
                    _dataHistoricoInicioPersonalizada,
                  ),
                  onPressed:
                      () =>
                          _selecionarDataHistoricoPersonalizada(inicial: true),
                ),
                _HistoricoDateFilterButton(
                  tokens: tokens,
                  width: campoFiltroLargura,
                  label: _txt('caixa.operacoes.historyEndDate', 'Data final'),
                  value: regionalizacao.formatDate(
                    _dataHistoricoFimPersonalizada,
                  ),
                  onPressed:
                      () =>
                          _selecionarDataHistoricoPersonalizada(inicial: false),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (movimentosVisiveis.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _softBox(theme),
              child: Text(
                _temFiltrosHistoricoAtivos
                    ? _txt(
                      'caixa.operacoes.historyNoResultsFiltered',
                      'Nenhuma movimentação encontrada com os filtros aplicados.',
                    )
                    : _txt(
                      'caixa.operacoes.historyNoResultsToday',
                      'Nenhuma movimentação registrada hoje.',
                    ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemCount: movimentosVisiveis.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:
                  (context, index) =>
                      _buildMovimentoCard(theme, movimentosVisiveis[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoricoPopupFiltro(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String? value,
    required List<_HistoricoFiltroOption> options,
    required ValueChanged<String?> onSelected,
  }) {
    final tokens = WebThemeTokens.of(context);
    final selectedLabel = _labelFiltroHistoricoSelecionado(options, value);
    return PopupMenuButton<String>(
      tooltip: title,
      color: tokens.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected:
          (selected) =>
              onSelected(selected == _historicoTodosKey ? null : selected),
      itemBuilder: (context) {
        final List<_HistoricoFiltroOption> menuOptions =
            <_HistoricoFiltroOption>[
              _HistoricoFiltroOption(
                value: _historicoTodosKey,
                label: _txt('common.all', 'Todos'),
              ),
              ...options,
            ];
        return menuOptions
            .map((option) {
              final bool selected =
                  value == null
                      ? option.value == _historicoTodosKey
                      : option.value == value;
              return PopupMenuItem<String>(
                value: option.value,
                child: Row(
                  children: <Widget>[
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: selected ? tokens.info : tokens.secondaryText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 170, maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value == null ? tokens.cardBorder : tokens.selectedBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: tokens.secondaryText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title: $selectedLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.expand_more_rounded, size: 18, color: tokens.mutedText),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimentoCard(ThemeData theme, MovimentoCaixa movimento) {
    final cor = _corPorNatureza(movimento.natureza);
    final forma = _descricaoTipoRecebimentoMovimento(movimento);
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final main = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    cor.withValues(alpha: 0.10),
                    tokens.cardBackground,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  movimento.natureza.toLowerCase() == 'entrada'
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: cor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          _labelTipo(movimento.tipoMovimento),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _statusPill(
                          _labelStatusMovimento(movimento.status),
                          _corPorStatus(movimento.status),
                        ),
                        _statusPill(_labelNatureza(movimento.natureza), cor),
                        _statusPill(forma, tokens.info),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      movimento.observacao.isEmpty
                          ? 'Sem observação informada.'
                          : movimento.observacao,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: <Widget>[
                        _inlineInfo(
                          theme,
                          Icons.person_outline_rounded,
                          movimento.nomeColaborador,
                        ),
                        _inlineInfo(theme, Icons.payments_outlined, forma),
                        _inlineInfo(
                          theme,
                          Icons.receipt_long_outlined,
                          movimento.referencia.isEmpty
                              ? 'Sem referência'
                              : movimento.referencia,
                        ),
                        if (movimento.codigoOperacao.trim().isNotEmpty)
                          _inlineInfo(
                            theme,
                            Icons.tag_rounded,
                            movimento.codigoOperacao,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _formatCurrency(movimento.valor),
                style: TextStyle(
                  color: cor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(movimento.dataHoraMovimento),
                style: TextStyle(
                  color: tokens.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => _abrirDetalhesMovimento(movimento),
                    child: const Text('Detalhes'),
                  ),
                  if (movimento.status.toLowerCase() != 'cancelada')
                    OutlinedButton(
                      onPressed: () => _cancelarMovimento(movimento),
                      child: const Text('Cancelar'),
                    ),
                ],
              ),
            ],
          );

          return compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[main, const SizedBox(height: 12), actions],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: main),
                  const SizedBox(width: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 210),
                    child: actions,
                  ),
                ],
              );
        },
      ),
    );
  }

  Widget _buildResumoLateral(ThemeData theme) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader(
                theme,
                title: 'Conferência por forma',
                subtitle: 'Resumo pelos tipos configurados no caixa.',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 14),
              ..._linhasResumoPorTipoRecebimento().map(
                (linha) => _buildResumoSecundario(
                  theme,
                  label: linha.label,
                  value: linha.valor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader(
                theme,
                title: 'Checklist operacional',
                subtitle: 'Conferência rápida da sessão.',
                icon: Icons.rule_folder_outlined,
              ),
              const SizedBox(height: 14),
              _checkItem(
                theme,
                checked: _temCaixaAberto,
                title: 'Caixa aberto',
              ),
              _checkItem(
                theme,
                checked: _movimentos.isNotEmpty,
                title: 'Movimentações registradas',
              ),
              _checkItem(
                theme,
                checked: _movimentos.any(
                  (m) => m.status.toLowerCase() == 'pendenteconferencia',
                ),
                title: 'Há pendências para conferência',
              ),
              _checkItem(
                theme,
                checked: _mostrarPainelFechamento,
                title: 'Fechamento preparado',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPainelFechamento(ThemeData theme) {
    if (_exibindoTodosOsCaixas) {
      return const SizedBox.shrink();
    }
    final resumo = _resumo;
    if (resumo == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            theme,
            title: 'Fechamento de caixa',
            subtitle:
                'Informe os valores apurados para comparar com o saldo esperado.',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildFieldBox(
                theme,
                width: 230,
                label:
                    '${_labelTipoRecebimentoPorCodigo('tipo1', 'Dinheiro')} apurado',
                child: _buildTextField(
                  theme,
                  controller: _fechamentoDinheiroController,
                  hint: _formatCurrency(resumo.totalDinheiro),
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 230,
                label:
                    '${_labelTipoRecebimentoPorCodigo('tipo2', 'Pix')} apurado',
                child: _buildTextField(
                  theme,
                  controller: _fechamentoPixController,
                  hint: _formatCurrency(resumo.totalPix),
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 250,
                label: 'Cartões apurados',
                child: _buildTextField(
                  theme,
                  controller: _fechamentoCartaoController,
                  hint: _formatCurrency(
                    resumo.totalCartaoCredito + resumo.totalCartaoDebito,
                  ),
                  prefix: _currencyInputPrefix(),
                ),
              ),
              SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _softBox(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Saldo esperado',
                        style: TextStyle(
                          color: WebThemeTokens.of(context).secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _animatedCurrencyText(
                        theme,
                        animationKey: 'fechamento-saldo-esperado',
                        value: resumo.saldoEsperado,
                        fontSize: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldBox(
            theme,
            width: double.infinity,
            label: 'Observação do fechamento',
            child: TextField(
              controller: _fechamentoObservacaoController,
              maxLines: 3,
              decoration: _inputDecoration(
                theme,
                hint:
                    'Detalhe divergências, conferências e observações finais.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isLoading ? null : _confirmarEncerramentoSessao,
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Concluir fechamento'),
              ),
              OutlinedButton.icon(
                onPressed:
                    () => setState(() => _mostrarPainelFechamento = false),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar fechamento'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tokens.selectedBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: tokens.info, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoSecundario(
    ThemeData theme, {
    required String label,
    required double value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _animatedCurrencyText(
                theme,
                animationKey: 'resumo-tipo-$label',
                value: value,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(
    ThemeData theme, {
    required bool checked,
    required String title,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 19,
            color: checked ? tokens.success : tokens.statusNeutral,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.10),
          tokens.cardBackground,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _inlineInfo(ThemeData theme, IconData icon, String text) {
    final tokens = WebThemeTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: tokens.mutedText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldBox(
    ThemeData theme, {
    required double width,
    required String label,
    required Widget child,
    bool showLabel = true,
  }) {
    final tokens = WebThemeTokens.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showLabel) ...<Widget>[
          Text(
            label,
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
        ],
        child,
      ],
    );
    return width == double.infinity
        ? SizedBox(width: double.infinity, child: content)
        : SizedBox(width: width, child: content);
  }

  Widget _buildReadOnlyField(ThemeData theme, String value) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBox(theme, radius: 16),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required String hint,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(theme, hint: hint, prefixText: prefix),
    );
  }

  Widget _buildDropdown<T>(
    ThemeData theme, {
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T item) itemLabel,
    String? hint,
  }) {
    final tokens = WebThemeTokens.of(context);
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      dropdownColor: tokens.menuBackground,
      style: TextStyle(color: tokens.primaryText, fontWeight: FontWeight.w700),
      decoration: _inputDecoration(theme, hint: hint),
      items:
          items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFiltroCaixaAction(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    final String selectedLabel =
        _exibindoTodosOsCaixas
            ? _txt('caixa.operacoes.filter.allCashDesks', 'Todos os caixas')
            : (_caixaSelecionado?.nome ??
                _txt('caixa.operacoes.filter.select', 'Selecionar caixa'));
    return PopupMenuButton<String>(
      enabled: !_isLoading,
      tooltip: _txt('caixa.operacoes.filter.tooltip', 'Filtrar caixa'),
      color: tokens.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (String selected) async {
        if (selected == '__all__') {
          await _alterarFiltroModo(_OperacoesCaixaFiltroModo.todosOsCaixas);
          return;
        }
        final CaixaOuGuiche? caixa = _primeiroCaixaPorId(selected);
        if (caixa != null) {
          await _selecionarCaixaFiltro(caixa);
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];
        items.add(
          PopupMenuItem<String>(
            value: '__all__',
            child: Row(
              children: <Widget>[
                Icon(
                  _exibindoTodosOsCaixas
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color:
                      _exibindoTodosOsCaixas
                          ? tokens.info
                          : tokens.secondaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _txt(
                      'caixa.operacoes.filter.allCashDesks',
                      'Todos os caixas',
                    ),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight:
                          _exibindoTodosOsCaixas
                              ? FontWeight.w800
                              : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        items.add(const PopupMenuDivider(height: 8));
        items.addAll(
          _caixasDisponiveis.map((caixa) {
            final bool selected =
                !_exibindoTodosOsCaixas && _caixaSelecionado?.id == caixa.id;
            return PopupMenuItem<String>(
              value: caixa.id,
              child: Row(
                children: <Widget>[
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.store_mall_directory_outlined,
                    size: 18,
                    color: selected ? tokens.info : tokens.secondaryText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      caixa.nome,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
        return items;
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _softBox(theme, radius: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.filter_alt_outlined,
              size: 18,
              color: tokens.secondaryText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.expand_more_rounded, size: 18, color: tokens.mutedText),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String? hint,
    String? prefixText,
  }) {
    final tokens = WebThemeTokens.of(context);
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: tokens.inputBackground,
      hintStyle: TextStyle(color: tokens.mutedText),
      prefixStyle: TextStyle(
        color: tokens.secondaryText,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
    );
  }

  ButtonStyle _outlinedButtonStyle(ThemeData theme, {Color? accentColor}) {
    final tokens = WebThemeTokens.of(context);
    final Color resolvedAccent = accentColor ?? tokens.info;
    return OutlinedButton.styleFrom(
      backgroundColor: tokens.surfaceMuted,
      foregroundColor: resolvedAccent,
      disabledBackgroundColor: tokens.disabledBackground,
      disabledForegroundColor: tokens.disabledForeground,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      side: BorderSide(
        color: resolvedAccent.withValues(alpha: 0.28),
        width: 1.1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );
  }

  ButtonStyle _filledButtonStyle(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return FilledButton.styleFrom(
      backgroundColor: tokens.info,
      foregroundColor: const Color(0xFF08111F),
      disabledBackgroundColor: tokens.disabledBackground,
      disabledForegroundColor: tokens.disabledForeground,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );
  }

  CheckboxThemeData _checkboxTheme(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.disabledBackground;
        }
        if (states.contains(WidgetState.selected)) {
          return tokens.info;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(const Color(0xFF08111F)),
      side: BorderSide(color: tokens.secondaryText, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return BoxDecoration(
      color: tokens.cardBackground,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: tokens.cardBorder),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.045),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  BoxDecoration _softBox(ThemeData theme, {double radius = 18}) {
    final tokens = WebThemeTokens.of(context);
    return BoxDecoration(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tokens.cardBorder),
    );
  }

  List<TiposRecebimento> _tiposRecebimentoAtivosOrdenados() {
    return _tiposRecebimento.where((item) => item.ativo).toList(growable: false)
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
  }

  bool get _temFiltrosHistoricoAtivos =>
      _periodoHistoricoSelecionado != _periodoHoje ||
      _filtroHistoricoNatureza != null ||
      _filtroHistoricoStatus != null ||
      _filtroHistoricoTipo != null ||
      _filtroHistoricoForma != null;

  bool get _usaPeriodoHistoricoPersonalizado =>
      _periodoHistoricoSelecionado == _periodoIntervaloPersonalizado;

  void _limparFiltrosHistorico() {
    setState(() {
      final DateTime hoje = _hojeNormalizado();
      _periodoHistoricoSelecionado = _periodoHoje;
      _dataHistoricoInicial = hoje;
      _dataHistoricoFinal = hoje;
      _dataHistoricoInicioPersonalizada = hoje;
      _dataHistoricoFimPersonalizada = hoje;
      _filtroHistoricoNatureza = null;
      _filtroHistoricoStatus = null;
      _filtroHistoricoTipo = null;
      _filtroHistoricoForma = null;
    });
  }

  List<MovimentoCaixa> _movimentosHistoricoFiltrados() {
    Iterable<MovimentoCaixa> movimentos = _movimentos;
    final DateTimeRange periodo = _resolverPeriodoHistoricoSelecionado();
    movimentos = movimentos.where(
      (m) => _isWithinDateRange(m.dataHoraMovimento, periodo),
    );

    if (_filtroHistoricoNatureza != null) {
      movimentos = movimentos.where(
        (m) =>
            _normalizeHistoricoFiltro(m.natureza) == _filtroHistoricoNatureza,
      );
    }

    if (_filtroHistoricoStatus != null) {
      movimentos = movimentos.where(
        (m) => _normalizeHistoricoFiltro(m.status) == _filtroHistoricoStatus,
      );
    }

    if (_filtroHistoricoTipo != null) {
      movimentos = movimentos.where(
        (m) =>
            _normalizeHistoricoFiltro(m.tipoMovimento) == _filtroHistoricoTipo,
      );
    }

    if (_filtroHistoricoForma != null) {
      movimentos = movimentos.where(
        (m) => _chaveFiltroHistoricoForma(m) == _filtroHistoricoForma,
      );
    }

    return movimentos.toList(growable: false);
  }

  DateTime _hojeNormalizado() {
    final DateTime agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  DateTime _normalizarData(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTimeRange _resolverPeriodoHistoricoSelecionado() {
    final DateTime hoje = _hojeNormalizado();
    switch (_periodoHistoricoSelecionado) {
      case _periodoHoje:
        return DateTimeRange(start: hoje, end: hoje);
      case _periodoUltimos7Dias:
        return DateTimeRange(
          start: hoje.subtract(const Duration(days: 6)),
          end: hoje,
        );
      case _periodoEsteMes:
        return DateTimeRange(
          start: DateTime(hoje.year, hoje.month, 1),
          end: hoje,
        );
      case _periodoMesPassado:
        final DateTime inicioMesAtual = DateTime(hoje.year, hoje.month, 1);
        final DateTime ultimoDiaMesPassado = inicioMesAtual.subtract(
          const Duration(days: 1),
        );
        return DateTimeRange(
          start: DateTime(
            ultimoDiaMesPassado.year,
            ultimoDiaMesPassado.month,
            1,
          ),
          end: ultimoDiaMesPassado,
        );
      case _periodoIntervaloPersonalizado:
        final DateTime inicio = _normalizarData(
          _dataHistoricoInicioPersonalizada,
        );
        final DateTime fim = _normalizarData(_dataHistoricoFimPersonalizada);
        return DateTimeRange(
          start: inicio.isAfter(fim) ? fim : inicio,
          end: fim.isBefore(inicio) ? inicio : fim,
        );
      case _periodoUltimos30Dias:
      default:
        return DateTimeRange(
          start: hoje.subtract(const Duration(days: 29)),
          end: hoje,
        );
    }
  }

  void _sincronizarPeriodoHistoricoComDatas() {
    final DateTimeRange periodo = _resolverPeriodoHistoricoSelecionado();
    _dataHistoricoInicial = periodo.start;
    _dataHistoricoFinal = periodo.end;
  }

  void _ajustarPeriodoHistoricoPersonalizadoSeguro() {
    final DateTime inicio = _normalizarData(_dataHistoricoInicioPersonalizada);
    final DateTime fim = _normalizarData(_dataHistoricoFimPersonalizada);
    if (fim.isBefore(inicio)) {
      _dataHistoricoFimPersonalizada = inicio;
    }
  }

  void _selecionarPeriodoHistorico(String selected) {
    if (!_periodosFiltroHistorico.contains(selected) ||
        _periodoHistoricoSelecionado == selected) {
      return;
    }
    setState(() {
      _periodoHistoricoSelecionado = selected;
      if (_usaPeriodoHistoricoPersonalizado) {
        _ajustarPeriodoHistoricoPersonalizadoSeguro();
      }
      _sincronizarPeriodoHistoricoComDatas();
    });
  }

  Future<void> _selecionarDataHistoricoPersonalizada({
    required bool inicial,
  }) async {
    final DateTime atual =
        inicial
            ? _dataHistoricoInicioPersonalizada
            : _dataHistoricoFimPersonalizada;
    final DateTime firstDate =
        inicial ? DateTime(2020) : _dataHistoricoInicioPersonalizada;
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _txt(
        inicial
            ? 'caixa.operacoes.historyStartDateHelp'
            : 'caixa.operacoes.historyEndDateHelp',
        inicial ? 'Selecionar data inicial' : 'Selecionar data final',
      ),
    );
    if (selecionada == null || !mounted) return;

    setState(() {
      final DateTime normalizada = _normalizarData(selecionada);
      if (inicial) {
        _dataHistoricoInicioPersonalizada = normalizada;
        _ajustarPeriodoHistoricoPersonalizadoSeguro();
      } else {
        _dataHistoricoFimPersonalizada = normalizada;
      }
      _sincronizarPeriodoHistoricoComDatas();
    });
  }

  String _historicoPeriodoItemLabel(String periodo) {
    switch (periodo) {
      case _periodoHoje:
        return _txt('caixa.operacoes.historyPeriodToday', 'Hoje');
      case _periodoUltimos7Dias:
        return _txt('caixa.operacoes.historyPeriodLast7Days', 'Últimos 7 dias');
      case _periodoEsteMes:
        return _txt('caixa.operacoes.historyPeriodThisMonth', 'Este mês');
      case _periodoMesPassado:
        return _txt('caixa.operacoes.historyPeriodLastMonth', 'Mês passado');
      case _periodoIntervaloPersonalizado:
        return _txt(
          'caixa.operacoes.historyPeriodCustomRange',
          'Intervalo personalizado',
        );
      case _periodoUltimos30Dias:
      default:
        return _txt(
          'caixa.operacoes.historyPeriodLast30Days',
          'Últimos 30 dias',
        );
    }
  }

  String _historicoPeriodoFiltroLabel(LocaleSettingsProvider regionalizacao) {
    if (_usaPeriodoHistoricoPersonalizado) {
      return '${regionalizacao.formatDate(_dataHistoricoInicial)} - ${regionalizacao.formatDate(_dataHistoricoFinal)}';
    }
    return _historicoPeriodoItemLabel(_periodoHistoricoSelecionado);
  }

  String _historicoPeriodoValueFromLabel(String label) {
    for (final String value in _periodosFiltroHistorico) {
      if (_historicoPeriodoItemLabel(value) == label) {
        return value;
      }
    }
    return _periodoHoje;
  }

  List<_HistoricoFiltroOption> _opcoesFiltroHistoricoNatureza() {
    final Set<String> naturezas =
        _movimentos
            .map((m) => _normalizeHistoricoFiltro(m.natureza))
            .where((value) => value.isNotEmpty)
            .toSet();
    final List<_HistoricoFiltroOption> options = <_HistoricoFiltroOption>[];
    for (final value in <String>['entrada', 'saida']) {
      if (naturezas.contains(value)) {
        options.add(
          _HistoricoFiltroOption(value: value, label: _labelNatureza(value)),
        );
      }
    }
    return options;
  }

  List<_HistoricoFiltroOption> _opcoesFiltroHistoricoStatus() {
    final Map<String, String> labels = <String, String>{};
    for (final movimento in _movimentos) {
      final value = _normalizeHistoricoFiltro(movimento.status);
      if (value.isEmpty || labels.containsKey(value)) continue;
      labels[value] = _labelStatusMovimento(movimento.status);
    }

    final List<String> orderedKeys = <String>[
      'concluida',
      'aberta',
      'pendenteconferencia',
      'cancelada',
    ];
    final List<_HistoricoFiltroOption> options = <_HistoricoFiltroOption>[];
    for (final key in orderedKeys) {
      final label = labels.remove(key);
      if (label != null) {
        options.add(_HistoricoFiltroOption(value: key, label: label));
      }
    }

    final remaining =
        labels.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    options.addAll(
      remaining.map(
        (entry) => _HistoricoFiltroOption(value: entry.key, label: entry.value),
      ),
    );
    return options;
  }

  List<_HistoricoFiltroOption> _opcoesFiltroHistoricoTipo() {
    final Map<String, String> labels = <String, String>{};
    for (final movimento in _movimentos) {
      final value = _normalizeHistoricoFiltro(movimento.tipoMovimento);
      if (value.isEmpty || labels.containsKey(value)) continue;
      labels[value] = _labelTipo(movimento.tipoMovimento);
    }

    final entries =
        labels.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return entries
        .map(
          (entry) =>
              _HistoricoFiltroOption(value: entry.key, label: entry.value),
        )
        .toList(growable: false);
  }

  List<_HistoricoFiltroOption> _opcoesFiltroHistoricoForma() {
    final Map<String, String> labels = <String, String>{};
    for (final movimento in _movimentos) {
      final value = _chaveFiltroHistoricoForma(movimento);
      if (value.isEmpty || labels.containsKey(value)) continue;
      labels[value] = _descricaoTipoRecebimentoMovimento(movimento);
    }

    final entries =
        labels.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return entries
        .map(
          (entry) =>
              _HistoricoFiltroOption(value: entry.key, label: entry.value),
        )
        .toList(growable: false);
  }

  String _labelFiltroHistoricoSelecionado(
    List<_HistoricoFiltroOption> options,
    String? value,
  ) {
    if (value == null) {
      return _txt('common.all', 'Todos');
    }
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return _txt('common.all', 'Todos');
  }

  String _chaveFiltroHistoricoForma(MovimentoCaixa movimento) {
    final codigo = _normalizeHistoricoFiltro(movimento.codigoTipoRecebimento);
    if (codigo.isNotEmpty) return 'codigo:$codigo';
    final descricao = _normalizeHistoricoFiltro(
      _descricaoTipoRecebimentoMovimento(movimento),
    );
    return descricao.isNotEmpty ? 'descricao:$descricao' : '';
  }

  String _normalizeHistoricoFiltro(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _descricaoTipoRecebimentoConfigurado(TiposRecebimento tipo) {
    final descricao = tipo.descricaoExibicao.trim();
    return descricao.isNotEmpty
        ? descricao
        : _labelTipoRecebimentoPorCodigo(tipo.codigoTipo, tipo.codigoTipo);
  }

  String _descricaoTipoRecebimentoMovimento(MovimentoCaixa movimento) {
    final descricao = movimento.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    return _labelTipoRecebimentoPorCodigo(
      movimento.codigoTipoRecebimento,
      movimento.descricao.trim().isNotEmpty
          ? movimento.descricao.trim()
          : 'Forma não informada',
    );
  }

  String _labelTipoRecebimentoPorCodigo(String codigoTipo, String fallback) {
    for (final tipo in _tiposRecebimento) {
      if (tipo.codigoTipo.toLowerCase() == codigoTipo.toLowerCase()) {
        final descricao = tipo.descricaoExibicao.trim();
        if (descricao.isNotEmpty) return descricao;
      }
    }
    return fallback;
  }

  List<_ResumoTipoRecebimentoData> _linhasResumoPorTipoRecebimento() {
    final tipos = _tiposRecebimentoAtivosOrdenados();
    if (tipos.isEmpty) {
      return <_ResumoTipoRecebimentoData>[
        _ResumoTipoRecebimentoData('Forma não informada', 0),
      ];
    }

    return tipos
        .map(
          (tipo) => _ResumoTipoRecebimentoData(
            _descricaoTipoRecebimentoConfigurado(tipo),
            _valorResumoPorCodigoTipo(tipo.codigoTipo),
          ),
        )
        .toList(growable: false);
  }

  double _valorResumoPorCodigoTipo(String codigoTipo) {
    final resumo = _movimentosComSomatorio;
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

  Future<void> _abrirCaixa() async {
    final caixaSelecionado = _caixaSelecionado;
    if (caixaSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um caixa / guichê.')),
      );
      return;
    }

    final valorAbertura = _parseCurrency(_trocoInicialController.text);
    setState(() => _confirmandoAberturaCaixa = true);
    bool confirmou = false;
    try {
      confirmou = await _confirmarAberturaCaixa(
        caixa: caixaSelecionado,
        valorAbertura: valorAbertura,
      );
    } finally {
      if (mounted) setState(() => _confirmandoAberturaCaixa = false);
    }
    if (!confirmou || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.abrirCaixa(
        AbrirCaixaRequest(
          idCaixaOuGuiche: caixaSelecionado.id,
          nomeCaixa: caixaSelecionado.nome,
          valorAbertura: valorAbertura,
        ),
      );
      await _carregarDadosIniciais();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caixa aberto com sucesso.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao abrir caixa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _alterarFiltroModo(_OperacoesCaixaFiltroModo modo) async {
    if (_filtroModo == modo) return;
    setState(() => _filtroModo = modo);
    await _carregarDadosIniciais(idCaixaPreferencial: _caixaSelecionado?.id);
  }

  Future<void> _selecionarCaixaFiltro(CaixaOuGuiche caixa) async {
    final CaixaSessao? sessao = _sessaoAbertaPorCaixa(caixa);
    setState(() {
      _filtroModo = _OperacoesCaixaFiltroModo.porCaixa;
      _caixaSelecionado = caixa;
      _sessaoAtual = sessao;
      _sessaoFiltroSelecionada = sessao;
      _mostrarPainelFechamento = false;
    });
    await _carregarDadosIniciais(idCaixaPreferencial: caixa.id);
  }

  Future<bool> _confirmarAberturaCaixa({
    required CaixaOuGuiche caixa,
    required double valorAbertura,
  }) async {
    final tokens = WebThemeTokens.of(context);
    final confirmou =
        await showDialog<bool>(
          context: context,
          barrierColor: tokens.workspaceBackground.withValues(alpha: 0.72),
          builder:
              (context) => _buildConfirmDialog(
                title: _txt(
                  'caixa.operacoes.openConfirmTitle',
                  'Confirmar abertura de caixa?',
                ),
                message: _mensagemConfirmacaoAbertura(
                  caixa: caixa,
                  valorAbertura: valorAbertura,
                ),
                cancelLabel: _txt('common.back', 'Voltar'),
                confirmLabel: _txt(
                  'caixa.operacoes.openConfirmAction',
                  'Abrir caixa',
                ),
              ),
        ) ??
        false;

    return confirmou;
  }

  List<OperacaoCaixaTipo> _tiposOperacaoDisponiveis() {
    return OperacaoCaixaTipo.values
        .where((tipo) => tipo != OperacaoCaixaTipo.fechamentoCaixa)
        .toList(growable: false);
  }

  Future<void> _abrirDialogoLancamentoOperacional() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    if (_mostrarPainelFechamento) {
      setState(() => _mostrarPainelFechamento = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final CaixaSessao? sessaoAtual = _sessaoEmFoco;
    final String cashDeskName =
        sessaoAtual?.nomeCaixa.trim().isNotEmpty == true
            ? sessaoAtual!.nomeCaixa.trim()
            : _txt('caixa.operacoes.closeDialogCashDesk', 'Caixa');

    await showSixWebOperationalLaunchDialog(
      context: context,
      cashDeskName: cashDeskName,
      operationTypes: _tiposOperacaoDisponiveis(),
      relatedTypes: _tiposRecebimentoAtivosOrdenados(),
      operationLabel: _labelTipo,
      operationIcon: _iconeTipo,
      relatedTypeLabel: _descricaoTipoRecebimentoConfigurado,
      currencySymbol: _currencyInputPrefix().trim(),
      formatCurrency: _formatCurrency,
      onConfirm: _registrarMovimentacaoOperacional,
    );
  }

  Future<void> _registrarMovimentacaoOperacional(
    SixWebOperationalLaunchSubmission submission,
  ) async {
    final CaixaSessao? sessaoAtual = _sessaoEmFoco;
    if (sessaoAtual == null) {
      throw StateError('Cash session unavailable');
    }

    setState(() => _isLoading = true);
    try {
      await _caixaService.registrarMovimentacao(
        RegistrarMovimentoRequest(
          idSessaoCaixa: sessaoAtual.idSessaoCaixa,
          tipoMovimento: submission.operationType,
          codigoTipoRecebimento: submission.relatedType.codigoTipo,
          valor: submission.amount,
          observacao: submission.observation,
          referencia: submission.reference,
          vinculadoVenda: submission.linkedSale,
        ),
      );

      final List<MovimentoCaixa> movimentos = await _caixaService
          .listarMovimentacoes(sessaoAtual.idSessaoCaixa);
      final InformacoesCaixaComSomatorioResponse movimentosComSomatorio =
          await _caixaService.buscarResumoDeMovimentosComSomatorio(
            sessaoAtual.idSessaoCaixa,
          );
      final ResumoCaixa resumo = await _caixaService.buscarResumo(
        sessaoAtual.idSessaoCaixa,
      );

      if (!mounted) return;
      setState(() {
        _movimentosComSomatorio = movimentosComSomatorio;
        _movimentos =
            movimentos.isNotEmpty
                ? movimentos
                : movimentosComSomatorio.movimento;
        _resumo = resumo;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  FecharCaixaRequest _montarRequestFechamentoCaixa() {
    final resumo = _resumo;
    final dinheiro =
        _fechamentoDinheiroController.text.trim().isEmpty
            ? (resumo?.totalDinheiro ?? 0)
            : _parseCurrency(_fechamentoDinheiroController.text);
    final pix =
        _fechamentoPixController.text.trim().isEmpty
            ? (resumo?.totalPix ?? 0)
            : _parseCurrency(_fechamentoPixController.text);
    final cartao =
        _fechamentoCartaoController.text.trim().isEmpty
            ? ((resumo?.totalCartaoCredito ?? 0) +
                (resumo?.totalCartaoDebito ?? 0))
            : _parseCurrency(_fechamentoCartaoController.text);

    return FecharCaixaRequest(
      idSessaoCaixa: _sessaoEmFoco!.idSessaoCaixa,
      valorDinheiroApurado: dinheiro,
      valorPixApurado: pix,
      valorCartaoApurado: cartao,
      observacaoFechamento: _fechamentoObservacaoController.text.trim(),
    );
  }

  Future<void> _confirmarEncerramentoSessao() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    final CaixaSessao sessao = _sessaoEmFoco!;
    final ResumoCaixa? resumo = _resumo;
    final int quantidadeMovimentos =
        resumo?.quantidadeMovimentos ?? _movimentos.length;
    final String nomeCaixa =
        sessao.nomeCaixa.trim().isEmpty
            ? _txt('caixa.operacoes.closeDialogCashDesk', 'Caixa')
            : sessao.nomeCaixa.trim();
    final bool confirmou = await showSixWebCashSessionCloseDialog(
      context: context,
      cashDeskName: nomeCaixa,
      movementCount: quantidadeMovimentos,
      expectedBalance: _formatCurrency(resumo?.saldoEsperado ?? 0),
      onConfirm: () async {
        await _caixaService.fecharCaixa(_montarRequestFechamentoCaixa());
        await _carregarDadosIniciais();
      },
    );

    if (!confirmou || !mounted) return;

    setState(() => _mostrarPainelFechamento = false);
  }

  Future<void> _cancelarMovimento(MovimentoCaixa movimento) async {
    final CaixaSessao? sessaoAtual = _sessaoEmFoco;
    if (sessaoAtual == null) return;

    final forma = _descricaoTipoRecebimentoMovimento(movimento);
    final confirmou = await showSixWebCashMovementCancelDialog(
      context: context,
      operationLabel: _labelTipo(movimento.tipoMovimento),
      paymentMethodLabel: forma,
      amountLabel: _formatCurrency(movimento.valor),
      onConfirm: () async {
        await _caixaService.cancelarMovimentacao(movimento.idMovimento);
        await _carregarMovimentosEResumo(sessaoAtual.idSessaoCaixa);
      },
      errorMessageBuilder: _mensagemErroCancelamentoMovimento,
    );

    if (!confirmou) return;
  }

  String _mensagemErroCancelamentoMovimento(Object error) {
    final String genericMessage = _txt(
      'caixa.operacoes.cancelDialogError',
      'Não foi possível cancelar a movimentação agora. Revise os vínculos financeiros e tente novamente.',
    );
    if (error is! CaixaApiException) return genericMessage;

    final String rawBody = error.body.trim();
    final String technicalDetails =
        '${error.toString()} $rawBody'.toLowerCase();
    if (technicalDetails.contains('recebimento_futuro') ||
        technicalDetails.contains('fk_recebimento_futuro_operacao') ||
        technicalDetails.contains('operacao_financeira')) {
      return _txt(
        'caixa.operacoes.cancelDialogLinkedRecordsError',
        'Esta movimentação possui vínculo com recebimentos ou lançamentos futuros e precisa permanecer registrada no histórico financeiro.',
      );
    }

    if (error.statusCode == 403) {
      return _txt(
        'caixa.operacoes.cancelDialogPermissionError',
        'Você não possui permissão para cancelar esta movimentação.',
      );
    }

    if (error.statusCode == 0 ||
        error.statusCode == 408 ||
        error.statusCode == 504) {
      return _txt(
        'caixa.operacoes.cancelDialogConnectivityError',
        'Não foi possível falar com o servidor agora. Verifique sua conexão e tente novamente.',
      );
    }

    final String? backendMessage = _extrairMensagemDoBody(rawBody);
    final String normalizedMessage = backendMessage?.toLowerCase() ?? '';
    final bool backendMessageIsGeneric =
        normalizedMessage.isEmpty ||
        normalizedMessage.contains('erro inesperado') ||
        normalizedMessage.contains('internal server error') ||
        normalizedMessage.contains('tente novamente');

    if (error.statusCode >= 500 &&
        (technicalDetails.contains('agf_999') || backendMessageIsGeneric)) {
      return _txt(
        'caixa.operacoes.cancelDialogLikelyLinkedError',
        'Não foi possível cancelar esta movimentação porque ela pode estar vinculada a outros registros financeiros. Revise os recebimentos relacionados e tente novamente.',
      );
    }

    if (backendMessage != null && backendMessage.trim().isNotEmpty) {
      return backendMessage;
    }

    return genericMessage;
  }

  String? _extrairMensagemDoBody(String body) {
    if (body.isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        for (final String key in <String>['message', 'mensagem', 'title']) {
          final String? value = decoded[key]?.toString();
          if (value != null && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {
      // Alguns endpoints retornam corpo não JSON; nesse caso usamos o fallback.
    }

    return null;
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

  AlertDialog _buildConfirmDialog({
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    bool danger = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    return AlertDialog(
      backgroundColor: tokens.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(message, style: TextStyle(color: tokens.secondaryText)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style:
              danger
                  ? FilledButton.styleFrom(
                    backgroundColor: tokens.danger,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                  : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  Color _corPorNatureza(String? natureza) {
    final tokens = WebThemeTokens.of(context);
    if (natureza == null) return tokens.statusNeutral;
    return natureza.toLowerCase() == 'entrada'
        ? tokens.financialPositive
        : tokens.financialNegative;
  }

  Color _corPorStatus(String? status) {
    final tokens = WebThemeTokens.of(context);
    if (status == null) return tokens.statusNeutral;
    switch (status.toLowerCase()) {
      case 'aberta':
        return tokens.info;
      case 'concluida':
        return tokens.success;
      case 'cancelada':
        return tokens.danger;
      case 'pendenteconferencia':
        return tokens.warning;
      default:
        return tokens.statusNeutral;
    }
  }

  IconData _iconeTipo(OperacaoCaixaTipo tipo) {
    switch (tipo) {
      case OperacaoCaixaTipo.aberturaCaixa:
        return Icons.lock_open_rounded;
      case OperacaoCaixaTipo.fechamentoCaixa:
        return Icons.lock_outline_rounded;
      case OperacaoCaixaTipo.suprimento:
        return Icons.add_circle_outline_rounded;
      case OperacaoCaixaTipo.sangria:
        return Icons.remove_circle_outline_rounded;
      case OperacaoCaixaTipo.retiradaDespesa:
        return Icons.receipt_long_outlined;
      case OperacaoCaixaTipo.ajuste:
        return Icons.tune_rounded;
      case OperacaoCaixaTipo.estorno:
        return Icons.undo_rounded;
      case OperacaoCaixaTipo.recebimentoAvulso:
        return Icons.call_received_rounded;
      case OperacaoCaixaTipo.pagamentoAvulso:
        return Icons.call_made_rounded;
    }
  }

  Future<void> _abrirDetalhesMovimento(MovimentoCaixa movimento) async {
    if (_isMovimentoVenda(movimento)) {
      final String identificadorVenda = _identificadorVendaMovimento(movimento);
      if (identificadorVenda.isEmpty) {
        _mostrarErro(
          'Não foi possível identificar o código da venda desta movimentação.',
        );
        return;
      }

      await showVendaDetalheWebDialog(
        context: context,
        identificador: identificadorVenda,
      );
      return;
    }

    if (!mounted) return;
    final String forma = _descricaoTipoRecebimentoMovimento(movimento);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Forma relacionada: $forma')));
  }

  bool _isMovimentoVenda(MovimentoCaixa movimento) {
    final String tipoMovimento = movimento.tipoMovimento.trim().toLowerCase();
    return tipoMovimento == 'venda' || tipoMovimento.startsWith('venda_');
  }

  String _identificadorVendaMovimento(MovimentoCaixa movimento) {
    final String codigoOperacao = movimento.codigoOperacao.trim();
    if (codigoOperacao.isNotEmpty) {
      return codigoOperacao;
    }

    final String referencia = movimento.referencia.trim();
    if (referencia.toLowerCase() == 'sem referencia') {
      return '';
    }
    return referencia;
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
        return 'Abertura de caixa';
      case 'fechamentoCaixa':
      case 'FECHAMENTO_CAIXA':
        return 'Fechamento de caixa';
      case 'suprimento':
      case 'SUPRIMENTO':
        return 'Suprimento';
      case 'sangria':
      case 'SANGRIA':
        return 'Sangria';
      case 'retiradaDespesa':
      case 'RETIRADA_DESPESA':
        return 'Retirada para despesa';
      case 'ajuste':
      case 'AJUSTE':
        return 'Ajuste';
      case 'estorno':
      case 'ESTORNO':
        return 'Estorno';
      case 'recebimentoAvulso':
      case 'RECEBIMENTO_AVULSO':
        return 'Recebimento avulso';
      case 'RECEBIMENTO_FINANCEIRO':
        return 'Recebimento financeiro';
      case 'pagamentoAvulso':
      case 'PAGAMENTO_AVULSO':
        return 'Pagamento avulso';
      default:
        return tipoStr;
    }
  }

  String _labelNatureza(String? natureza) {
    if (natureza == null) return '--';
    switch (natureza.toLowerCase()) {
      case 'entrada':
        return 'Entrada';
      case 'saida':
        return 'Saída';
      default:
        return natureza;
    }
  }

  String _labelStatusMovimento(String? status) {
    if (status == null) return '--';
    switch (status.toLowerCase()) {
      case 'aberta':
        return 'Aberta';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      case 'pendenteconferencia':
        return 'Pendente conferência';
      default:
        return status;
    }
  }

  String _formatCurrency(double value) {
    try {
      return context.read<LocaleSettingsProvider>().formatCurrency(value);
    } catch (_) {
      final negative = value < 0;
      final absolute = value.abs();
      final fixed = absolute.toStringAsFixed(2);
      final parts = fixed.split('.');
      final integer = parts[0];
      final decimal = parts[1];
      final buffer = StringBuffer();
      for (var i = 0; i < integer.length; i++) {
        final position = integer.length - i;
        buffer.write(integer[i]);
        if (position > 1 && position % 3 == 1) buffer.write('.');
      }
      return '${negative ? '-' : ''}${buffer.toString()},$decimal';
    }
  }

  String _currencyInputPrefix() {
    try {
      return '${context.read<LocaleSettingsProvider>().currencySymbol} ';
    } catch (_) {
      return '';
    }
  }

  double _parseCurrency(String text) {
    final cleaned =
        text
            .replaceAll(RegExp(r'[^0-9,.\-]'), '')
            .replaceAll('.', '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .trim();
    return double.tryParse(cleaned) ?? 0;
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
        .replaceAll('{amount}', _formatCurrency(valorAbertura));
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '--';
    try {
      final dateTime = DateTime.parse(value);
      final dd = dateTime.day.toString().padLeft(2, '0');
      final mm = dateTime.month.toString().padLeft(2, '0');
      final yyyy = dateTime.year.toString();
      final hh = dateTime.hour.toString().padLeft(2, '0');
      final min = dateTime.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yyyy às $hh:$min';
    } catch (_) {
      return value;
    }
  }

  bool _isWithinDateRange(String? value, DateTimeRange range) {
    if (value == null || value.isEmpty) return false;
    try {
      final DateTime dateTime = DateTime.parse(value);
      final DateTime current = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );
      return !current.isBefore(range.start) && !current.isAfter(range.end);
    } catch (_) {
      return false;
    }
  }
}

class _SairDaTelaIntent extends Intent {
  const _SairDaTelaIntent();
}

enum NaturezaMovimento { entrada, saida }

enum NaturezaRecebimento { imediato, futuro }

enum StatusMovimento { aberta, concluida, cancelada, pendenteConferencia }

enum StatusSessaoCaixa { aberta, fechada }

class _ResumoTipoRecebimentoData {
  const _ResumoTipoRecebimentoData(this.label, this.valor);

  final String label;
  final double valor;
}

class _OperacoesCaixaSessaoCarregada {
  const _OperacoesCaixaSessaoCarregada({
    required this.movimentos,
    required this.movimentosComSomatorio,
    required this.resumo,
  });

  final List<MovimentoCaixa> movimentos;
  final InformacoesCaixaComSomatorioResponse movimentosComSomatorio;
  final ResumoCaixa resumo;
}

class _HistoricoFiltroOption {
  const _HistoricoFiltroOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _HistoricoDateFilterButton extends StatelessWidget {
  const _HistoricoDateFilterButton({
    required this.tokens,
    required this.width,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final WebThemeTokens tokens;
  final double width;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          side: BorderSide(color: tokens.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            Icon(Icons.calendar_today_outlined, size: 18, color: tokens.info),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w800,
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
}
