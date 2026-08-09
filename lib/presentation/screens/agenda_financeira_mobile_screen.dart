import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import 'agenda_financeira_lancamento_mobile_create_screen.dart';
import 'agenda_financeira_lancamento_mobile_edit_screen.dart';

class AgendaFinanceiraMobileScreen extends StatefulWidget {
  const AgendaFinanceiraMobileScreen({
    super.key,
    this.lancamentoService,
    this.acoesFinanceiras,
    this.caixaApiClient,
    this.enablePeriodHint = true,
  });

  final AgendaFinanceiraLancamentoService? lancamentoService;
  final AgendaFinanceiraAcoesFinanceiras? acoesFinanceiras;
  final CaixaApiClient? caixaApiClient;
  final bool enablePeriodHint;

  @override
  State<AgendaFinanceiraMobileScreen> createState() =>
      _AgendaFinanceiraMobileScreenState();
}

class _AgendaFinanceiraMobileScreenState
    extends State<AgendaFinanceiraMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;
  static Color get _softBlueColor => SixMobilePalette.softAccentSurface;

  late final AgendaFinanceiraLancamentoService _service =
      widget.lancamentoService ?? AgendaFinanceiraLancamentoService();
  late final AgendaFinanceiraAcoesFinanceiras _acoesService =
      widget.acoesFinanceiras ?? AgendaFinanceiraAcoesFinanceiras();
  late final CaixaApiClient _caixaApiClient =
      widget.caixaApiClient ?? HttpCaixaApiClient();
  final ScrollController _periodosScrollController = ScrollController();

  final List<String> _abas = <String>[
    'Agenda',
    'Calendário',
    'Fluxo previsto',
    'Valores confirmados',
  ];
  final List<String> _periodos = <String>[
    'Hoje',
    'Próximos 7 dias',
    'Este mês',
    'Próximo mês',
  ];
  final List<String> _tipos = <String>['Todos', 'Receber', 'Pagar'];
  final List<String> _status = <String>[
    'Todos',
    'Previsto',
    'Pendente',
    'Vence hoje',
    'Vencido',
    'Pago',
    'Recebido',
    'Parcial',
    'Cancelado',
  ];
  final Map<String, String> _codigoTipoPorDescricaoFormaPagamento =
      <String, String>{
        'Dinheiro': 'tipo1',
        'Pix': 'tipo2',
        'Cartão de crédito': 'tipo3',
        'Cartão de débito': 'tipo4',
        'Boleto': 'tipo5',
        'Fiado': 'tipo6',
        'Débito automático': 'tipo7',
        'Transferência': 'tipo8',
        'Vale': 'tipo9',
        'Outros': 'tipo10',
      };
  final Map<String, String> _descricaoPorCodigoTipoFormaPagamento =
      <String, String>{
        'tipo1': 'Dinheiro',
        'tipo2': 'Pix',
        'tipo3': 'Cartão de crédito',
        'tipo4': 'Cartão de débito',
        'tipo5': 'Boleto',
        'tipo6': 'Fiado',
        'tipo7': 'Débito automático',
        'tipo8': 'Transferência',
        'tipo9': 'Vale',
        'tipo10': 'Outros',
      };
  List<String> _formasPagamentoFiltro = <String>['Todos'];

  int _abaSelecionada = 0;
  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  final Set<String> _formasPagamentoSelecionadas = <String>{};

  bool _carregando = false;
  bool _executandoAcao = false;
  bool _dicaPeriodosExecutada = false;
  String? _erroConsulta;
  DateTime? _ultimaConsultaEm;

  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _itensConfirmados = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _carregarTiposPagamentoConfigurados();
      if (!mounted) return;
      await _consultar();
      if (widget.enablePeriodHint) {
        _executarDicaScrollPeriodos();
      }
    });
  }

  @override
  void dispose() {
    _periodosScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _itensAgenda {
    return _gruposAgenda
        .expand(
          (grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>(),
        )
        .where(_passaFiltrosLocais)
        .toList();
  }

  List<Map<String, dynamic>> get _itensConfirmadosFiltrados =>
      _itensConfirmados.where(_passaFiltrosLocais).toList();

  List<Map<String, dynamic>> get _itensSomaveis =>
      _itensAgenda
          .where((item) => item['status']?.toString() != 'Cancelado')
          .toList();

  double get _totalReceberPrevisto =>
      _somar(_itensSomaveis, 'receber', 'valorRestante');
  double get _totalPagarPrevisto =>
      _somar(_itensSomaveis, 'pagar', 'valorRestante');
  double get _totalRecebidoConfirmado =>
      _somar(_itensConfirmadosFiltrados, 'receber', 'valorConfirmado');
  double get _totalPagoConfirmado =>
      _somar(_itensConfirmadosFiltrados, 'pagar', 'valorConfirmado');
  double get _saldoPrevisto =>
      (_totalRecebidoConfirmado + _totalReceberPrevisto) -
      (_totalPagoConfirmado + _totalPagarPrevisto);
  double get _saldoConfirmado =>
      _totalRecebidoConfirmado - _totalPagoConfirmado;

  bool _passaFiltrosLocais(Map<String, dynamic> item) {
    final tipoOk =
        _tipoSelecionado == 'Todos' ||
        (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') ||
        (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
    final statusOk =
        _statusSelecionado == 'Todos' || item['status'] == _statusSelecionado;
    final formaOk =
        _formasPagamentoSelecionadas.isEmpty ||
        _codigosTipoRecebimentoFiltro().contains(
          item['codigoTipoRecebimento']?.toString().trim().toLowerCase(),
        );
    return tipoOk && statusOk && formaOk;
  }

  Future<void> _executarDicaScrollPeriodos() async {
    if (_dicaPeriodosExecutada) return;
    _dicaPeriodosExecutada = true;
    await Future<void>.delayed(Duration(milliseconds: 650));
    if (!mounted || !_periodosScrollController.hasClients) return;
    final double maxOffset = _periodosScrollController.position.maxScrollExtent;
    if (maxOffset <= 0) return;
    final double hintOffset = maxOffset < 46 ? maxOffset : 46;
    try {
      await _periodosScrollController.animateTo(
        hintOffset,
        duration: Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(Duration(milliseconds: 160));
      if (!mounted || !_periodosScrollController.hasClients) return;
      await _periodosScrollController.animateTo(
        0,
        duration: Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  Future<void> _consultar({bool mostrarFeedback = false}) async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      final request = _buildRequest();
      final agenda = await _service.consultarLancamentos(request);
      final confirmados = await _service.consultarValoresConfirmados(request);
      if (!mounted) return;
      _aplicarAgenda(agenda);
      _aplicarConfirmados(confirmados);
      _sincronizarValoresConfirmadosNosLancamentos();
      _ultimaConsultaEm = DateTime.now();
      _erroConsulta = null;
      if (mostrarFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Agenda atualizada: ${_itensAgenda.length} lançamento(s).',
            ),
          ),
        );
      }
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _erroConsulta = 'Falha ao consultar agenda (${e.statusCode}).',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao consultar agenda (${e.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erroConsulta = 'Não foi possível consultar a agenda financeira.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível consultar a agenda financeira.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  AgendaFinanceiraConsultaRequest _buildRequest() {
    return AgendaFinanceiraConsultaRequest(
      periodo: _periodoRequest(),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo:
            _tipoSelecionado == 'Todos'
                ? 'TODOS'
                : _tipoSelecionado.toUpperCase(),
        status: _statusFiltro(),
        origens: <String>[],
        categorias: <String>[],
        formasPagamento: <String>[],
        codigosTipoRecebimento: _codigosTipoRecebimentoFiltro(),
        clienteFornecedor: null,
        somenteCriticos: false,
      ),
      visaoSelecionada: _abas[_abaSelecionada].toUpperCase().replaceAll(
        ' ',
        '_',
      ),
    );
  }

  Future<void> _carregarTiposPagamentoConfigurados() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<String> formas = _montarFormasPagamentoFiltro(
        informacoes.tiposRecebimento,
      );
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasPagamentoFiltro = <String>['Todos', ...formas];
        _formasPagamentoSelecionadas.removeWhere(
          (String forma) => !_formasPagamentoFiltro.contains(forma),
        );
      });
    } catch (_) {
      // Mantém as formas padrão quando a configuração do caixa não carregar.
    }
  }

  List<String> _montarFormasPagamentoFiltro(List<TiposRecebimento> tipos) {
    final List<String> descricoes = <String>[];
    final Map<String, String> codigosAtualizados = Map<String, String>.from(
      _codigoTipoPorDescricaoFormaPagamento,
    );
    final Map<String, String> descricoesAtualizadas = Map<String, String>.from(
      _descricaoPorCodigoTipoFormaPagamento,
    );
    final List<TiposRecebimento> ativos =
        tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()..sort(
          (TiposRecebimento a, TiposRecebimento b) =>
              a.ordemExibicao.compareTo(b.ordemExibicao),
        );
    for (final TiposRecebimento tipo in ativos) {
      final String codigo = tipo.codigoTipo.trim().toLowerCase();
      if (codigo.isEmpty) continue;
      final String descricao =
          tipo.descricaoExibicao.trim().isNotEmpty
              ? tipo.descricaoExibicao.trim()
              : (_descricaoPorCodigoTipoFormaPagamento[codigo] ?? codigo);
      if (descricao.isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      codigosAtualizados[descricao] = codigo;
      descricoesAtualizadas[codigo] = descricao;
    }
    if (descricoes.isNotEmpty) {
      _codigoTipoPorDescricaoFormaPagamento
        ..clear()
        ..addAll(codigosAtualizados);
      _descricaoPorCodigoTipoFormaPagamento
        ..clear()
        ..addAll(descricoesAtualizadas);
    }
    return descricoes;
  }

  List<String> _codigosTipoRecebimentoFiltro() {
    if (_formasPagamentoSelecionadas.isEmpty) return <String>[];
    return _formasPagamentoSelecionadas
        .map((String forma) => _codigoTipoPorDescricaoFormaPagamento[forma])
        .whereType<String>()
        .where((String codigo) => codigo.trim().isNotEmpty)
        .toList();
  }

  AgendaFinanceiraPeriodoRequest _periodoRequest() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    switch (_periodoSelecionado) {
      case 'Hoje':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'HOJE',
          dataInicio: hoje,
          dataFim: hoje,
        );
      case 'Este mês':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'ESTE_MES',
          dataInicio: DateTime(hoje.year, hoje.month, 1),
          dataFim: DateTime(hoje.year, hoje.month + 1, 0),
        );
      case 'Próximo mês':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PROXIMO_MES',
          dataInicio: DateTime(hoje.year, hoje.month + 1, 1),
          dataFim: DateTime(hoje.year, hoje.month + 2, 0),
        );
      default:
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PROXIMOS_7_DIAS',
          dataInicio: hoje,
          dataFim: hoje.add(Duration(days: 7)),
        );
    }
  }

  List<String> _statusFiltro() {
    switch (_statusSelecionado) {
      case 'Previsto':
        return <String>['PREVISTO'];
      case 'Pendente':
        return <String>['PENDENTE'];
      case 'Vence hoje':
        return <String>['VENCE_HOJE'];
      case 'Vencido':
        return <String>['VENCIDO'];
      case 'Pago':
        return <String>['PAGO'];
      case 'Recebido':
        return <String>['RECEBIDO'];
      case 'Parcial':
        return <String>['PARCIAL'];
      case 'Cancelado':
        return <String>['CANCELADO'];
      default:
        return <String>[];
    }
  }

  void _aplicarAgenda(Map<String, dynamic> payload) {
    final gruposRaw = payload['gruposAgenda'];
    final grupos = <Map<String, dynamic>>[];
    if (gruposRaw is List) {
      for (final grupo in gruposRaw.whereType<Map<String, dynamic>>()) {
        final itensRaw = grupo['itens'];
        grupos.add(<String, dynamic>{
          'grupo': grupo['titulo']?.toString() ?? 'Lançamentos',
          'descricao': grupo['descricao']?.toString() ?? '',
          'itens':
              itensRaw is List
                  ? itensRaw
                      .whereType<Map<String, dynamic>>()
                      .map(_mapearItemAgenda)
                      .toList()
                  : <Map<String, dynamic>>[],
        });
      }
    }
    _gruposAgenda
      ..clear()
      ..addAll(grupos);
  }

  void _aplicarConfirmados(Map<String, dynamic> payload) {
    final itens = payload['itens'];
    _itensConfirmados
      ..clear()
      ..addAll(
        itens is List
            ? itens
                .whereType<Map<String, dynamic>>()
                .map(_mapearItemConfirmado)
                .toList()
            : <Map<String, dynamic>>[],
      );
  }

  Map<String, dynamic> _mapearItemAgenda(Map<String, dynamic> item) {
    final tipo =
        item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    final valorOriginal = _toDouble(item['valorOriginal'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final valorRestante = _toDouble(
      item['valorRestante'] ?? (valorOriginal - valorConfirmado),
    );
    final acoesRaw = item['acoesDisponiveis'];
    final acoes =
        acoesRaw is List
            ? acoesRaw
                .map((acao) => _acaoLabel(acao?.toString()))
                .where((acao) => acao.isNotEmpty)
                .toList()
            : <String>[];

    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'uuidOperacaoApp': item['uuidOperacaoApp']?.toString(),
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': valorOriginal,
      'valorConfirmado': valorConfirmado,
      'valorRestante': valorRestante,
      'valor': valorRestante > 0 ? valorRestante : valorOriginal,
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'origem': item['origem']?.toString() ?? '',
      'codigoTipoRecebimento': _codigoTipoRecebimentoItem(item),
      'formaPagamento': _formaPagamentoLabel(
        _codigoTipoRecebimentoItem(item) ?? item['formaPagamento']?.toString(),
      ),
      'empresa': _empresaNome(item['empresa']),
      'categoria': item['categoria']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'acoes':
          acoes.isNotEmpty
              ? acoes
              : <String>['Liquidar', 'Registrar parcial', 'Detalhes'],
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
      'dataOperacao': item['dataOperacao']?.toString(),
      'dataCompetencia': item['dataCompetencia']?.toString(),
    };
  }

  Map<String, dynamic> _mapearItemConfirmado(Map<String, dynamic> item) {
    final tipo =
        item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'uuidOperacaoApp': item['uuidOperacaoApp']?.toString(),
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': _toDouble(item['valorOriginal']),
      'valorConfirmado': _toDouble(item['valorConfirmado']),
      'valorRestante': _toDouble(item['valorRestante']),
      'data': _formatarDataIsoParaBr(
        (item['dataUltimaConfirmacao'] ?? item['dataVencimento'])?.toString(),
      ),
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'codigoTipoRecebimento': _codigoTipoRecebimentoItem(item),
      'formaPagamento': _formaPagamentoLabel(
        _codigoTipoRecebimentoItem(item) ?? item['formaPagamento']?.toString(),
      ),
      'empresa': item['empresa']?.toString() ?? '',
      'quantidadeConfirmacoes':
          item['quantidadeConfirmacoes'] ?? item['quantidadeLiquidacoes'] ?? 1,
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
      'acoes': <String>['Detalhes'],
    };
  }

  List<Map<String, dynamic>> _mapearLiquidacoes(dynamic raw) {
    return raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];
  }

  void _sincronizarValoresConfirmadosNosLancamentos() {
    final confirmadosPorId = <String, Map<String, dynamic>>{
      for (final item in _itensConfirmados) item['id'].toString(): item,
    };
    for (final grupo in _gruposAgenda) {
      final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
      for (final item in itens) {
        final confirmado = confirmadosPorId[item['id']?.toString()];
        if (confirmado == null) continue;
        item['valorConfirmado'] = confirmado['valorConfirmado'];
        item['valorRestante'] = confirmado['valorRestante'];
        item['valor'] = confirmado['valorRestante'];
        item['liquidacoes'] =
            confirmado['liquidacoes'] ?? <Map<String, dynamic>>[];
        item['quantidadeConfirmacoes'] =
            confirmado['quantidadeConfirmacoes'] ?? 0;
        if (_toDouble(confirmado['valorConfirmado']) > 0 &&
            _toDouble(confirmado['valorRestante']) > 0) {
          item['status'] = 'Parcial';
        }
      }
    }
  }

  Future<void> _novoLancamento() async {
    final item = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder:
            (_) => AgendaFinanceiraLancamentoMobileCreateScreen(
              service: _service,
              caixaApiClient: _caixaApiClient,
            ),
      ),
    );
    if (!mounted || item == null) return;
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _editarLancamento(Map<String, dynamic> item) async {
    final itemAtualizado = await Navigator.of(
      context,
    ).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder:
            (_) => AgendaFinanceiraLancamentoMobileEditScreen(
              lancamento: item,
              service: _service,
              caixaApiClient: _caixaApiClient,
            ),
      ),
    );
    if (!mounted || itemAtualizado == null) return;
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _executarAcao(String acao, Map<String, dynamic> item) async {
    final comando = acao.trim().toLowerCase();
    if (comando == 'detalhes') {
      _mostrarDetalhes(item);
      return;
    }
    if (comando == 'editar') {
      await _editarLancamento(item);
      return;
    }
    if (comando == 'registrar parcial') {
      await _registrarParcial(item);
      return;
    }
    if (comando == 'liquidar' || comando == 'receber' || comando == 'pagar') {
      await _confirmarTotal(
        item,
        item['tipo'] == 'pagar' ? 'Pagar' : 'Receber',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ação "$acao" ainda não implementada.')),
    );
  }

  Future<void> _registrarParcial(Map<String, dynamic> item) async {
    final List<String> formasDisponiveis =
        _formasPagamentoFiltro
            .where(
              (String forma) => forma != 'Todos' && forma.trim().isNotEmpty,
            )
            .toList();
    if (formasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Carregue os tipos de recebimento antes de registrar parcial.',
          ),
        ),
      );
      return;
    }
    final String codigoAtual =
        item['codigoTipoRecebimento']?.toString().trim().toLowerCase() ?? '';
    String formaSelecionada = formasDisponiveis.firstWhere(
      (String forma) =>
          _codigoTipoPorDescricaoFormaPagamento[forma] == codigoAtual,
      orElse: () => formasDisponiveis.first,
    );
    final double valorAberto = _toDouble(
      item['valorRestante'] ?? item['valor'],
    );
    final _AgendaParcialResultado? resultado =
        await showModalBottomSheet<_AgendaParcialResultado>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext sheetContext) {
            return _AgendaParcialBottomSheet(
              valorAberto: valorAberto,
              valorAbertoFormatado: _formatarMoeda(valorAberto),
              formasDisponiveis: formasDisponiveis,
              codigoTipoPorDescricaoFormaPagamento:
                  _codigoTipoPorDescricaoFormaPagamento,
              formaInicial: formaSelecionada,
            );
          },
        );
    if (resultado == null) return;
    await Future<void>.delayed(Duration(milliseconds: 80));
    if (!mounted) return;
    await _executarComLoading(() async {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      await _acoesService.executarAbatimento(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraParcialRequest(
          tipoLiquidacao: 'PARCIAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: resultado.valor,
          formaPagamentoRealizada: resultado.codigoTipoRecebimento,
          observacoes:
              resultado.observacao.trim().isEmpty
                  ? 'Lançamento parcial registrado pela agenda financeira.'
                  : resultado.observacao.trim(),
          idSessaoCaixa: idSessaoCaixa,
        ),
      );
      await _consultar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parcial registrada com sucesso.')),
      );
    });
  }

  Future<void> _confirmarTotal(Map<String, dynamic> item, String label) async {
    final valor = _toDouble(item['valorRestante'] ?? item['valor']);
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Liquidar lançamento'),
            content: Text('Confirmar liquidação de ${_formatarMoeda(valor)}?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(label),
              ),
            ],
          ),
    );
    if (confirmado != true) return;
    await _executarComLoading(() async {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      await _acoesService.executarTotal(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraLiquidacaoRequest(
          tipoLiquidacao: 'TOTAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada:
              item['codigoTipoRecebimento']?.toString() ??
              _codigoTipoRecebimentoItem(item) ??
              'tipo2',
          observacoes: 'Liquidação realizada pela agenda financeira.',
          referenciaExterna: item['id']?.toString(),
          idSessaoCaixa: idSessaoCaixa,
        ),
      );
      await _consultar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lançamento liquidado com sucesso.')),
      );
    });
  }

  Future<String?> _buscarIdSessaoCaixaAberta() async {
    final CaixaSessao? sessao = await _caixaApiClient.getSessaoAtual();
    final String? idSessaoCaixa = sessao?.idSessaoCaixa.trim();
    return idSessaoCaixa == null || idSessaoCaixa.isEmpty
        ? null
        : idSessaoCaixa;
  }

  Future<void> _executarComLoading(Future<void> Function() action) async {
    if (_executandoAcao) return;
    setState(() => _executandoAcao = true);
    try {
      await action();
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na ação (${e.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível executar a ação.')),
      );
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: 'Agenda financeira',
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      scrollEffectOffset: 24,
      scrolledSurfaceOpacity: 0.66,
      leading: IconButton(
        tooltip: 'Voltar',
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Atualizar',
          onPressed:
              _carregando ? null : () => _consultar(mostrarFeedback: true),
          icon: Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Novo lançamento',
          onPressed: _executandoAcao ? null : _novoLancamento,
          icon: Icon(Icons.add_rounded),
        ),
      ],
      bodyBuilder: _buildContent,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => _consultar(mostrarFeedback: true),
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
          children: <Widget>[
            SixStaggeredEntry(child: _buildHeaderCard()),
            SizedBox(height: 12),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 60),
              child: _buildFilterCard(),
            ),
            if (_carregando || _executandoAcao) ...<Widget>[
              SizedBox(height: 10),
              LinearProgressIndicator(minHeight: 3),
            ],
            SizedBox(height: 14),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 110),
              child: _buildResumo(),
            ),
            SizedBox(height: 16),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 160),
              child: _buildTabs(),
            ),
            SizedBox(height: 12),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 210),
              child: _buildConteudoAba(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0x33FFFFFF)),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: SixMobilePalette.onPrimary,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Agenda financeira',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _ultimaConsultaEm == null
                      ? 'Previsões e confirmações do período.'
                      : 'Atualizado às ${_ultimaConsultaEm!.hour.toString().padLeft(2, '0')}:${_ultimaConsultaEm!.minute.toString().padLeft(2, '0')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow.withValues(alpha: 0.70),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPeriodosSelector(),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _smallInfoChip(Icons.swap_vert_rounded, _tipoSelecionado),
              _smallInfoChip(Icons.flag_outlined, _statusSelecionado),
              _smallInfoChip(
                Icons.payments_outlined,
                _formasPagamentoFiltroLabel(),
              ),
              OutlinedButton.icon(
                onPressed: _carregando ? null : _abrirFiltros,
                icon: Icon(Icons.tune_rounded, size: 18),
                label: Text('Filtros'),
              ),
              FilledButton.icon(
                onPressed:
                    _carregando
                        ? null
                        : () => _consultar(mostrarFeedback: true),
                icon: Icon(Icons.search_rounded, size: 18),
                label: Text('Buscar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodosSelector() {
    return SizedBox(
      height: 40,
      child: Stack(
        children: <Widget>[
          ListView.separated(
            controller: _periodosScrollController,
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(right: 34),
            itemCount: _periodos.length,
            separatorBuilder: (_, __) => SizedBox(width: 8),
            itemBuilder: (context, index) {
              final periodo = _periodos[index];
              final selected = periodo == _periodoSelecionado;
              return ChoiceChip(
                selected: selected,
                visualDensity: VisualDensity.compact,
                label: Text(periodo),
                onSelected:
                    _carregando
                        ? null
                        : (_) {
                          setState(() => _periodoSelecionado = periodo);
                        },
                selectedColor: _primaryColor,
                backgroundColor: SixMobilePalette.softNeutralSurface,
                side: BorderSide(
                  color: selected ? _primaryColor : _borderColor,
                ),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color:
                      selected ? SixMobilePalette.onPrimary : _titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
                avatar:
                    selected
                        ? Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: SixMobilePalette.onPrimary,
                        )
                        : null,
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 42,
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      _surfaceColor.withValues(alpha: 0),
                      _surfaceColor,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: SixPulsingBadge(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _accentColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _softBlueColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 16),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFiltros() async {
    String tipoTemp = _tipoSelecionado;
    String statusTemp = _statusSelecionado;
    final Set<String> formasPagamentoTemp = Set<String>.from(
      _formasPagamentoSelecionadas,
    );
    final result = await showModalBottomSheet<_AgendaMobileFiltro>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: SixMobilePalette.activeBorder,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Filtrar agenda',
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildFilterOptions(
                        title: 'Tipo',
                        values: _tipos,
                        selected: tipoTemp,
                        onSelected:
                            (value) => setModalState(() => tipoTemp = value),
                      ),
                      SizedBox(height: 16),
                      _buildFilterOptions(
                        title: 'Status',
                        values: _status,
                        selected: statusTemp,
                        onSelected:
                            (value) => setModalState(() => statusTemp = value),
                      ),
                      SizedBox(height: 16),
                      _buildFilterOptions(
                        title: 'Tipo de pagamento',
                        values: _formasPagamentoFiltro,
                        selectedValues: formasPagamentoTemp,
                        onSelected: (value) {
                          setModalState(() {
                            if (value == 'Todos') {
                              formasPagamentoTemp.clear();
                              return;
                            }
                            if (formasPagamentoTemp.contains(value)) {
                              formasPagamentoTemp.remove(value);
                            } else {
                              formasPagamentoTemp.add(value);
                            }
                          });
                        },
                      ),
                      SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              () => Navigator.of(context).pop(
                                _AgendaMobileFiltro(
                                  tipo: tipoTemp,
                                  status: statusTemp,
                                  formasPagamento: formasPagamentoTemp,
                                ),
                              ),
                          icon: Icon(Icons.check_rounded),
                          label: Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _tipoSelecionado = result.tipo;
      _statusSelecionado = result.status;
      _formasPagamentoSelecionadas
        ..clear()
        ..addAll(result.formasPagamento);
    });
  }

  Widget _buildFilterOptions({
    required String title,
    required List<String> values,
    String? selected,
    Set<String>? selectedValues,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: _mutedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              values.map((value) {
                final bool isMultiSelection = selectedValues != null;
                final isSelected =
                    isMultiSelection
                        ? (value == 'Todos'
                            ? selectedValues.isEmpty
                            : selectedValues.contains(value))
                        : value == selected;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(value),
                  onSelected: (_) => onSelected(value),
                  selectedColor: _primaryColor,
                  backgroundColor: SixMobilePalette.softNeutralSurface,
                  side: BorderSide(
                    color: isSelected ? _primaryColor : _borderColor,
                  ),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? SixMobilePalette.onPrimary
                            : _titleTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  String _formasPagamentoFiltroLabel() {
    if (_formasPagamentoSelecionadas.isEmpty) return 'Todos';
    if (_formasPagamentoSelecionadas.length == 1) {
      return _formasPagamentoSelecionadas.first;
    }
    return '${_formasPagamentoSelecionadas.length} tipos';
  }

  Widget _buildResumo() {
    final items = <_ResumoAgendaCardData>[
      _ResumoAgendaCardData(
        'A receber aberto',
        _totalReceberPrevisto,
        Icons.south_west_rounded,
        _accentColor,
      ),
      _ResumoAgendaCardData(
        'A pagar aberto',
        _totalPagarPrevisto,
        Icons.north_east_rounded,
        Color(0xFF16A34A),
      ),
      _ResumoAgendaCardData(
        'Saldo previsto',
        _saldoPrevisto,
        Icons.query_stats_rounded,
        Color(0xFF7C3AED),
      ),
      _ResumoAgendaCardData(
        'Recebido confirmado',
        _totalRecebidoConfirmado,
        Icons.verified_rounded,
        Color(0xFF0891B2),
      ),
      _ResumoAgendaCardData(
        'Pago confirmado',
        _totalPagoConfirmado,
        Icons.task_alt_rounded,
        Color(0xFFF59E0B),
      ),
      _ResumoAgendaCardData(
        'Saldo confirmado',
        _saldoConfirmado,
        Icons.account_balance_wallet_rounded,
        _accentColor,
      ),
    ];

    final maiorValor = items.fold<double>(0, (maior, item) {
      final valorAbsoluto = item.value.abs();
      return valorAbsoluto > maior ? valorAbsoluto : maior;
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow.withValues(alpha: 0.70),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _softBlueColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _accentColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Resumo financeiro',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Distribuição dos valores do período selecionado.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          ...items.map(
            (item) => _buildResumoItem(
              item,
              percent: maiorValor <= 0 ? 0 : item.value.abs() / maiorValor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(
    _ResumoAgendaCardData item, {
    required double percent,
  }) {
    final safePercent = percent.clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: 13),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Icon(item.icon, color: item.color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey<String>(
                  '${item.title}-${item.value.toStringAsFixed(2)}',
                ),
                tween: Tween<double>(begin: 0, end: item.value),
                duration: Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder:
                    (context, value, child) => Text(
                      _formatarMoeda(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safePercent,
              minHeight: 8,
              color: item.color,
              backgroundColor: _borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final aba = _abas[index];
          final selected = index == _abaSelecionada;
          return ChoiceChip(
            selected: selected,
            label: Text(aba),
            onSelected: (_) => setState(() => _abaSelecionada = index),
            selectedColor: _primaryColor,
            backgroundColor: SixMobilePalette.softNeutralSurface,
            side: BorderSide(color: selected ? _primaryColor : _borderColor),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? SixMobilePalette.onPrimary : _titleTextColor,
              fontWeight: FontWeight.w800,
            ),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemCount: _abas.length,
      ),
    );
  }

  Widget _buildConteudoAba() {
    if (_erroConsulta != null &&
        _itensAgenda.isEmpty &&
        _itensConfirmadosFiltrados.isEmpty) {
      return _buildErrorState(_erroConsulta!);
    }

    switch (_abaSelecionada) {
      case 1:
        return _buildCalendario();
      case 2:
        return _buildFluxo();
      case 3:
        return _buildValoresConfirmados();
      default:
        return _buildAgenda();
    }
  }

  Widget _buildAgenda() {
    if (_itensAgenda.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Nenhum lançamento encontrado',
        subtitle:
            'Ajuste os filtros ou cadastre um novo lançamento financeiro.',
      );
    }
    return Column(children: _itensAgenda.map(_buildLancamentoCard).toList());
  }

  Widget _buildLancamentoCard(Map<String, dynamic> item) {
    final tipoEntrada = item['tipo'] == 'receber';
    final valorAberto = _toDouble(item['valorRestante'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final acoes =
        item['acoes'] is List
            ? (item['acoes'] as List)
                .cast<dynamic>()
                .map((acao) => acao.toString())
                .toList()
            : <String>[];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow.withValues(alpha: 0.70),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(
                tipoEntrada ? 'Receber' : 'Pagar',
                tipoEntrada
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
              ),
              _pill(item['status']?.toString() ?? '-', Icons.flag_outlined),
              if (valorConfirmado > 0)
                _pill(
                  'Confirmado: ${_formatarMoeda(valorConfirmado)}',
                  Icons.verified_outlined,
                ),
              if (valorAberto > 0)
                _pill(
                  'Aberto: ${_formatarMoeda(valorAberto)}',
                  Icons.pending_actions_outlined,
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            item['descricao']?.toString() ?? '',
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            '${item['contato']} • Vence em ${item['vencimento']} • ${item['formaPagamento']}',
            style: TextStyle(color: _mutedTextColor, height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            'Original: ${_formatarMoeda(_toDouble(item['valorOriginal']))}',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed:
                    _executandoAcao ? null : () => _editarLancamento(item),
                icon: Icon(Icons.edit_outlined, size: 18),
                label: Text('Editar'),
              ),
              ...acoes
                  .take(3)
                  .map(
                    (acao) => OutlinedButton(
                      onPressed:
                          _executandoAcao
                              ? null
                              : () => _executarAcao(acao, item),
                      child: Text(acao),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    final itens = List<Map<String, dynamic>>.from(_itensSomaveis);
    itens.sort((a, b) {
      final dataA = _parseDataBr(a['vencimento']?.toString()) ?? DateTime(9999);
      final dataB = _parseDataBr(b['vencimento']?.toString()) ?? DateTime(9999);
      return dataA.compareTo(dataB);
    });
    if (itens.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Calendário sem lançamentos',
        subtitle: 'Nenhuma previsão encontrada para o período selecionado.',
      );
    }
    final itensPorData = <String, List<Map<String, dynamic>>>{};
    for (final item in itens) {
      final data = item['vencimento']?.toString() ?? '-';
      itensPorData.putIfAbsent(data, () => <Map<String, dynamic>>[]).add(item);
    }
    return Column(
      children:
          itensPorData.entries.map((entry) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.calendar_today_outlined,
                          color: _accentColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((item) => _buildCalendarioItem(item)),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCalendarioItem(Map<String, dynamic> item) {
    final tipoEntrada = item['tipo'] == 'receber';
    final valorPrevisto = _toDouble(item['valorOriginal'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final diferenca = valorPrevisto - valorConfirmado;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _softBlueColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tipoEntrada ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: _accentColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item['descricao']?.toString() ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Previsto ${_formatarMoeda(valorPrevisto)} • Diferença ${_formatarMoeda(diferenca)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Text(
            _formatarMoeda(valorConfirmado),
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFluxo() {
    final fluxoPorMes = <String, Map<String, double>>{};
    for (final item in _itensSomaveis) {
      final data = _parseDataBr(item['vencimento']?.toString());
      final mes =
          data == null
              ? 'Sem competência'
              : '${data.year}-${data.month.toString().padLeft(2, '0')}';
      final valor = _toDouble(item['valorRestante'] ?? item['valor']);
      final registro = fluxoPorMes.putIfAbsent(
        mes,
        () => <String, double>{'entradas': 0, 'saidas': 0},
      );
      if (item['tipo'] == 'receber') {
        registro['entradas'] = (registro['entradas'] ?? 0) + valor;
      } else {
        registro['saidas'] = (registro['saidas'] ?? 0) + valor;
      }
    }
    if (fluxoPorMes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.query_stats_outlined,
        title: 'Fluxo previsto vazio',
        subtitle: 'Nenhuma entrada ou saída prevista para o período.',
      );
    }
    final mesesOrdenados = fluxoPorMes.keys.toList()..sort();
    return Column(
      children:
          mesesOrdenados.map((mes) {
            final entrada = fluxoPorMes[mes]?['entradas'] ?? 0;
            final saida = fluxoPorMes[mes]?['saidas'] ?? 0;
            final saldo = entrada - saida;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        mes,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Saldo: ${_formatarMoeda(saldo)}',
                        style: TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  _buildFluxoBarra(entrada: entrada, saida: saida),
                  SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _fluxoValor(
                          'Entradas',
                          entrada,
                          Icons.south_west_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _fluxoValor(
                          'Saídas',
                          saida,
                          Icons.north_east_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFluxoBarra({required double entrada, required double saida}) {
    final total = entrada + saida;
    final percentualEntrada = total <= 0 ? 0.0 : entrada / total;
    final percentualSaida = total <= 0 ? 0.0 : saida / total;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 30,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _borderColor,
            borderRadius: BorderRadius.circular(999),
          ),
          clipBehavior: Clip.antiAlias,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Row(
                children: <Widget>[
                  AnimatedContainer(
                    duration: Duration(milliseconds: 650),
                    width: constraints.maxWidth * percentualEntrada * value,
                    height: 30,
                    color: _accentColor,
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 650),
                    width: constraints.maxWidth * percentualSaida * value,
                    height: 30,
                    color: Color(0xFFE11D48),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _fluxoValor(String label, double value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softBlueColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 18),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatarMoeda(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValoresConfirmados() {
    if (_itensConfirmados.isEmpty) {
      return _buildEmptyState(
        icon: Icons.verified_outlined,
        title: 'Nenhum valor confirmado',
        subtitle: 'As liquidações confirmadas aparecerão aqui.',
      );
    }
    return Column(
      children:
          _itensConfirmados.map((item) {
            final tipoEntrada = item['tipo'] == 'receber';
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _softBlueColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      tipoEntrada
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: _accentColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item['descricao']?.toString() ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${item['contato']} • ${item['data']} • ${item['formaPagamento']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _formatarMoeda(_toDouble(item['valorConfirmado'])),
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _softBlueColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 15),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 34),
          SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: SixMobilePalette.error,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'Agenda indisponível',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.35),
          ),
          SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed:
                _carregando ? null : () => _consultar(mostrarFeedback: true),
            icon: Icon(Icons.refresh_rounded),
            label: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhes(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SixMobilePalette.activeBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    item['descricao']?.toString() ?? 'Detalhes',
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 14),
                  _detalheLinha('Contato', item['contato']?.toString() ?? '-'),
                  _detalheLinha(
                    'Vencimento',
                    item['vencimento']?.toString() ?? '-',
                  ),
                  _detalheLinha('Status', item['status']?.toString() ?? '-'),
                  _detalheLinha(
                    'Forma de recebimento',
                    item['formaPagamento']?.toString() ?? '-',
                  ),
                  _detalheLinha(
                    'Valor original',
                    _formatarMoeda(_toDouble(item['valorOriginal'])),
                  ),
                  _detalheLinha(
                    'Valor confirmado',
                    _formatarMoeda(_toDouble(item['valorConfirmado'])),
                  ),
                  _detalheLinha(
                    'Valor em aberto',
                    _formatarMoeda(_toDouble(item['valorRestante'])),
                  ),
                  if ((item['observacoes']?.toString() ?? '').isNotEmpty)
                    _detalheLinha(
                      'Observações',
                      item['observacoes'].toString(),
                    ),
                  SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Fechar'),
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

  Widget _detalheLinha(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _somar(List<Map<String, dynamic>> itens, String tipo, String campo) {
    return itens
        .where((item) => item['tipo'] == tipo)
        .fold<double>(
          0,
          (soma, item) => soma + _toDouble(item[campo] ?? item['valor']),
        );
  }

  String _acaoLabel(String? acao) {
    switch ((acao ?? '').toUpperCase()) {
      case 'EDITAR':
      case 'ALTERAR':
        return 'Editar';
      case 'REGISTRAR_RECEBIMENTO':
      case 'RECEBER':
      case 'REGISTRAR_PAGAMENTO':
      case 'PAGAR':
        return 'Liquidar';
      case 'REGISTRAR_PARCIAL':
        return 'Registrar parcial';
      case 'DETALHAR':
      case 'DETALHES':
        return 'Detalhes';
      default:
        return '';
    }
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PAGO':
        return 'Pago';
      case 'RECEBIDO':
        return 'Recebido';
      case 'PARCIAL':
        return 'Parcial';
      case 'CANCELADO':
        return 'Cancelado';
      case 'VENCIDO':
        return 'Vencido';
      case 'VENCE_HOJE':
        return 'Vence hoje';
      case 'PREVISTO':
        return 'Previsto';
      default:
        return 'Pendente';
    }
  }

  String _formaPagamentoLabel(String? formaPagamento) {
    final String normalizada = (formaPagamento ?? '').trim();
    final String? descricaoCodigo =
        _descricaoPorCodigoTipoFormaPagamento[normalizada.toLowerCase()];
    if (descricaoCodigo != null && descricaoCodigo.trim().isNotEmpty) {
      return descricaoCodigo;
    }
    switch (normalizada.toUpperCase()) {
      case 'BOLETO':
        return _descricaoTipoRecebimentoOuFallback('tipo5', 'Boleto');
      case 'TRANSFERENCIA':
        return _descricaoTipoRecebimentoOuFallback('tipo8', 'Transferência');
      case 'CARTAO_CREDITO':
        return _descricaoTipoRecebimentoOuFallback(
          'tipo3',
          'Cartão de crédito',
        );
      case 'CARTAO_DEBITO':
        return _descricaoTipoRecebimentoOuFallback('tipo4', 'Cartão de débito');
      case 'DINHEIRO':
        return _descricaoTipoRecebimentoOuFallback('tipo1', 'Dinheiro');
      case 'DEBITO_AUTOMATICO':
        return _descricaoTipoRecebimentoOuFallback(
          'tipo7',
          'Débito automático',
        );
      default:
        return normalizada.isNotEmpty ? normalizada : 'Pix';
    }
  }

  String? _codigoTipoRecebimentoItem(Map<String, dynamic> item) {
    final codigo =
        item['codigoTipoRecebimento']?.toString().trim().toLowerCase();
    if (codigo != null && RegExp(r'^tipo(10|[1-9])$').hasMatch(codigo)) {
      return codigo;
    }
    return _codigoTipoPorFormaPagamentoAntiga(
      item['formaPagamento']?.toString(),
    );
  }

  String? _codigoTipoPorFormaPagamentoAntiga(String? formaPagamento) {
    switch ((formaPagamento ?? '').trim().toUpperCase()) {
      case 'DINHEIRO':
        return 'tipo1';
      case 'PIX':
        return 'tipo2';
      case 'CARTAO_CREDITO':
        return 'tipo3';
      case 'CARTAO_DEBITO':
        return 'tipo4';
      case 'BOLETO':
        return 'tipo5';
      case 'DEBITO_AUTOMATICO':
        return 'tipo7';
      case 'TRANSFERENCIA':
        return 'tipo8';
      default:
        return null;
    }
  }

  String _descricaoTipoRecebimentoOuFallback(String codigo, String fallback) {
    final descricao =
        _descricaoPorCodigoTipoFormaPagamento[codigo.trim().toLowerCase()];
    return descricao != null && descricao.trim().isNotEmpty
        ? descricao
        : fallback;
  }

  String _empresaNome(dynamic empresa) {
    if (empresa is Map<String, dynamic>) {
      return empresa['nome']?.toString() ?? '';
    }
    return empresa?.toString() ?? '';
  }

  DateTime? _parseDataBr(String? data) {
    if (data == null || data.trim().isEmpty) return null;
    final partes = data.split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    return DateTime(ano, mes, dia);
  }

  String _formatarDataIsoParaBr(String? dataIso) {
    if (dataIso == null || dataIso.trim().isEmpty) return '-';
    try {
      final data = DateTime.parse(dataIso);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    } catch (_) {
      return dataIso;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final texto = value.trim();
      final normalizado =
          texto.contains(',') && texto.contains('.')
              ? texto.replaceAll('.', '').replaceAll(',', '.')
              : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }

  String _formatarMoeda(double valor) {
    final negativo = valor < 0;
    final absoluto = valor.abs();
    final partes = absoluto.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final decimal = partes[1];
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      final indexInvertido = inteiro.length - i;
      buffer.write(inteiro[i]);
      if (indexInvertido > 1 && indexInvertido % 3 == 1) buffer.write('.');
    }
    final prefixo = negativo ? r'-R$ ' : r'R$ ';
    return '$prefixo${buffer.toString()},$decimal';
  }
}

class _AgendaMobileFiltro {
  const _AgendaMobileFiltro({
    required this.tipo,
    required this.status,
    required this.formasPagamento,
  });
  final String tipo;
  final String status;
  final Set<String> formasPagamento;
}

class _AgendaParcialResultado {
  const _AgendaParcialResultado({
    required this.valor,
    required this.codigoTipoRecebimento,
    required this.observacao,
  });

  final double valor;
  final String codigoTipoRecebimento;
  final String observacao;
}

class _AgendaParcialBottomSheet extends StatefulWidget {
  const _AgendaParcialBottomSheet({
    required this.valorAberto,
    required this.valorAbertoFormatado,
    required this.formasDisponiveis,
    required this.codigoTipoPorDescricaoFormaPagamento,
    required this.formaInicial,
  });

  final double valorAberto;
  final String valorAbertoFormatado;
  final List<String> formasDisponiveis;
  final Map<String, String> codigoTipoPorDescricaoFormaPagamento;
  final String formaInicial;

  @override
  State<_AgendaParcialBottomSheet> createState() =>
      _AgendaParcialBottomSheetState();
}

class _AgendaParcialBottomSheetState extends State<_AgendaParcialBottomSheet> {
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  late String _formaSelecionada = widget.formaInicial;
  String? _erroValor;

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: _AgendaFinanceiraMobileScreenState._backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _AgendaFinanceiraMobileScreenState._borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Registrar parcial',
                style: TextStyle(
                  color: _AgendaFinanceiraMobileScreenState._titleTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Valor em aberto: ${widget.valorAbertoFormatado}',
                style: TextStyle(
                  color: _AgendaFinanceiraMobileScreenState._mutedTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _valorController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                cursorColor: _AgendaFinanceiraMobileScreenState._accentColor,
                style: TextStyle(
                  color: _AgendaFinanceiraMobileScreenState._titleTextColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor parcial',
                  errorText: _erroValor,
                  filled: true,
                  fillColor: _AgendaFinanceiraMobileScreenState._surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _AgendaFinanceiraMobileScreenState._borderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _AgendaFinanceiraMobileScreenState._borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _AgendaFinanceiraMobileScreenState._accentColor,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Tipo de recebimento',
                style: TextStyle(
                  color: _AgendaFinanceiraMobileScreenState._mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    widget.formasDisponiveis.map((String forma) {
                      final bool selecionado = forma == _formaSelecionada;
                      return ChoiceChip(
                        selected: selecionado,
                        label: Text(forma),
                        avatar:
                            selecionado
                                ? Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: SixMobilePalette.onPrimary,
                                )
                                : Icon(Icons.payments_outlined, size: 16),
                        selectedColor:
                            _AgendaFinanceiraMobileScreenState._primaryColor,
                        backgroundColor: SixMobilePalette.softNeutralSurface,
                        side: BorderSide(
                          color:
                              selecionado
                                  ? _AgendaFinanceiraMobileScreenState
                                      ._primaryColor
                                  : _AgendaFinanceiraMobileScreenState
                                      ._borderColor,
                        ),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color:
                              selecionado
                                  ? SixMobilePalette.onPrimary
                                  : _AgendaFinanceiraMobileScreenState
                                      ._titleTextColor,
                          fontWeight: FontWeight.w800,
                        ),
                        onSelected:
                            (_) => setState(() => _formaSelecionada = forma),
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _observacaoController,
                minLines: 2,
                maxLines: 3,
                cursorColor: _AgendaFinanceiraMobileScreenState._accentColor,
                style: TextStyle(
                  color: _AgendaFinanceiraMobileScreenState._titleTextColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Observação',
                  filled: true,
                  fillColor: _AgendaFinanceiraMobileScreenState._surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _AgendaFinanceiraMobileScreenState._borderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _AgendaFinanceiraMobileScreenState._borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _AgendaFinanceiraMobileScreenState._accentColor,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: Icon(Icons.check_rounded),
                      label: Text('Salvar'),
                      onPressed: _salvar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvar() {
    final double valorDigitado = _toDouble(_valorController.text);
    if (valorDigitado <= 0) {
      setState(() => _erroValor = 'Informe um valor maior que zero.');
      return;
    }
    if (valorDigitado >= widget.valorAberto) {
      setState(() => _erroValor = 'Informe um valor menor que o aberto.');
      return;
    }
    final String? codigoTipo =
        widget.codigoTipoPorDescricaoFormaPagamento[_formaSelecionada];
    if (codigoTipo == null || codigoTipo.trim().isEmpty) {
      setState(() => _erroValor = 'Selecione um tipo de recebimento.');
      return;
    }
    Navigator.of(context).pop(
      _AgendaParcialResultado(
        valor: valorDigitado,
        codigoTipoRecebimento: codigoTipo,
        observacao: _observacaoController.text.trim(),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final String texto = value.trim();
      final String normalizado =
          texto.contains(',') && texto.contains('.')
              ? texto.replaceAll('.', '').replaceAll(',', '.')
              : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }
}

class _ResumoAgendaCardData {
  const _ResumoAgendaCardData(this.title, this.value, this.icon, this.color);
  final String title;
  final double value;
  final IconData icon;
  final Color color;
}
