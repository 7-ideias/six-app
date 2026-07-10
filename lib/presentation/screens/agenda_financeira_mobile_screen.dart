import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';

import 'agenda_financeira_lancamento_mobile_edit_screen.dart';

class AgendaFinanceiraMobileScreen extends StatefulWidget {
  const AgendaFinanceiraMobileScreen({super.key});

  @override
  State<AgendaFinanceiraMobileScreen> createState() =>
      _AgendaFinanceiraMobileScreenState();
}

class _AgendaFinanceiraMobileScreenState extends State<AgendaFinanceiraMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _softBlueColor = Color(0xFFEFF6FF);

  final AgendaFinanceiraLancamentoService _service = AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesService = AgendaFinanceiraAcoesFinanceiras();
  final ScrollController _periodosScrollController = ScrollController();

  final List<String> _abas = const <String>[
    'Agenda',
    'Calendário',
    'Fluxo previsto',
    'Valores confirmados',
  ];
  final List<String> _periodos = const <String>[
    'Hoje',
    'Próximos 7 dias',
    'Este mês',
    'Próximo mês',
  ];
  final List<String> _tipos = const <String>['Todos', 'Receber', 'Pagar'];
  final List<String> _status = const <String>[
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

  int _abaSelecionada = 0;
  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';

  bool _carregando = false;
  bool _executandoAcao = false;
  bool _dicaPeriodosExecutada = false;
  DateTime? _ultimaConsultaEm;

  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _itensConfirmados = <Map<String, dynamic>>[];
  Map<String, dynamic> _totaisConfirmados = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consultar();
      _executarDicaScrollPeriodos();
    });
  }

  @override
  void dispose() {
    _periodosScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _itensAgenda {
    return _gruposAgenda
        .expand((grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>())
        .where((item) {
          final tipoOk = _tipoSelecionado == 'Todos' ||
              (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') ||
              (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
          final statusOk = _statusSelecionado == 'Todos' ||
              item['status'] == _statusSelecionado;
          return tipoOk && statusOk;
        })
        .toList();
  }

  List<Map<String, dynamic>> get _itensSomaveis =>
      _itensAgenda.where((item) => item['status']?.toString() != 'Cancelado').toList();

  double get _totalReceberPrevisto => _somar(_itensSomaveis, 'receber', 'valorRestante');
  double get _totalPagarPrevisto => _somar(_itensSomaveis, 'pagar', 'valorRestante');
  double get _totalRecebidoConfirmado => _toDouble(_totaisConfirmados['totalRecebidoConfirmado']);
  double get _totalPagoConfirmado => _toDouble(_totaisConfirmados['totalPagoConfirmado']);
  double get _saldoPrevisto =>
      (_totalRecebidoConfirmado + _totalReceberPrevisto) -
      (_totalPagoConfirmado + _totalPagarPrevisto);
  double get _saldoConfirmado => _toDouble(
        _totaisConfirmados['saldoConfirmado'] ??
            (_totalRecebidoConfirmado - _totalPagoConfirmado),
      );

  Future<void> _executarDicaScrollPeriodos() async {
    if (_dicaPeriodosExecutada) return;
    _dicaPeriodosExecutada = true;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || !_periodosScrollController.hasClients) return;
    final double maxOffset = _periodosScrollController.position.maxScrollExtent;
    if (maxOffset <= 0) return;
    final double hintOffset = maxOffset < 46 ? maxOffset : 46;
    try {
      await _periodosScrollController.animateTo(
        hintOffset,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted || !_periodosScrollController.hasClients) return;
      await _periodosScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
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
      if (mostrarFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agenda atualizada: ${_itensAgenda.length} lançamento(s).')),
        );
      }
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao consultar agenda (${e.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível consultar a agenda financeira.')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  AgendaFinanceiraConsultaRequest _buildRequest() {
    return AgendaFinanceiraConsultaRequest(
      periodo: _periodoRequest(),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo: _tipoSelecionado == 'Todos' ? 'TODOS' : _tipoSelecionado.toUpperCase(),
        status: _statusFiltro(),
        origens: const <String>[],
        categorias: const <String>[],
        formasPagamento: const <String>[],
        clienteFornecedor: null,
        somenteCriticos: false,
      ),
      visaoSelecionada: _abas[_abaSelecionada].toUpperCase().replaceAll(' ', '_'),
    );
  }

  AgendaFinanceiraPeriodoRequest _periodoRequest() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    switch (_periodoSelecionado) {
      case 'Hoje':
        return AgendaFinanceiraPeriodoRequest(modo: 'HOJE', dataInicio: hoje, dataFim: hoje);
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
          dataFim: hoje.add(const Duration(days: 7)),
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
          'itens': itensRaw is List
              ? itensRaw.whereType<Map<String, dynamic>>().map(_mapearItemAgenda).toList()
              : <Map<String, dynamic>>[],
        });
      }
    }
    _gruposAgenda
      ..clear()
      ..addAll(grupos);
  }

  void _aplicarConfirmados(Map<String, dynamic> payload) {
    final totais = payload['totais'];
    final itens = payload['itens'];
    _totaisConfirmados = totais is Map<String, dynamic>
        ? Map<String, dynamic>.from(totais)
        : <String, dynamic>{};
    _itensConfirmados
      ..clear()
      ..addAll(
        itens is List
            ? itens.whereType<Map<String, dynamic>>().map(_mapearItemConfirmado).toList()
            : <Map<String, dynamic>>[],
      );
  }

  Map<String, dynamic> _mapearItemAgenda(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    final valorOriginal = _toDouble(item['valorOriginal'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final valorRestante = _toDouble(item['valorRestante'] ?? (valorOriginal - valorConfirmado));
    final acoesRaw = item['acoesDisponiveis'];
    final acoes = acoesRaw is List
        ? acoesRaw.map((acao) => _acaoLabel(acao?.toString())).where((acao) => acao.isNotEmpty).toList()
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
      'formaPagamento': _formaPagamentoLabel(item['formaPagamento']?.toString()),
      'empresa': _empresaNome(item['empresa']),
      'categoria': item['categoria']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'acoes': acoes.isNotEmpty ? acoes : <String>['Liquidar', 'Registrar parcial', 'Detalhes'],
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
      'dataOperacao': item['dataOperacao']?.toString(),
      'dataCompetencia': item['dataCompetencia']?.toString(),
    };
  }

  Map<String, dynamic> _mapearItemConfirmado(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'uuidOperacaoApp': item['uuidOperacaoApp']?.toString(),
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': _toDouble(item['valorOriginal']),
      'valorConfirmado': _toDouble(item['valorConfirmado']),
      'valorRestante': _toDouble(item['valorRestante']),
      'data': _formatarDataIsoParaBr((item['dataUltimaConfirmacao'] ?? item['dataVencimento'])?.toString()),
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'formaPagamento': _formaPagamentoLabel(item['formaPagamento']?.toString()),
      'empresa': item['empresa']?.toString() ?? '',
      'quantidadeConfirmacoes': item['quantidadeConfirmacoes'] ?? item['quantidadeLiquidacoes'] ?? 1,
      'liquidacoes': _mapearLiquidacoes(item['liquidacoes']),
      'acoes': <String>['Detalhes'],
    };
  }

  List<Map<String, dynamic>> _mapearLiquidacoes(dynamic raw) {
    return raw is List
        ? raw.whereType<Map<String, dynamic>>().map((item) => Map<String, dynamic>.from(item)).toList()
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
        item['liquidacoes'] = confirmado['liquidacoes'] ?? <Map<String, dynamic>>[];
        item['quantidadeConfirmacoes'] = confirmado['quantidadeConfirmacoes'] ?? 0;
        if (_toDouble(confirmado['valorConfirmado']) > 0 && _toDouble(confirmado['valorRestante']) > 0) {
          item['status'] = 'Parcial';
        }
      }
    }
  }

  Future<void> _novoLancamento() async {
    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada: 'Empresa',
      empresas: const <String>['Empresa'],
    );
    if (!mounted || item == null) return;
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _editarLancamento(Map<String, dynamic> item) async {
    final itemAtualizado = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => AgendaFinanceiraLancamentoMobileEditScreen(lancamento: item),
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
      await _confirmarTotal(item, item['tipo'] == 'pagar' ? 'Pagar' : 'Receber');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ação "$acao" ainda não implementada.')));
  }

  Future<void> _registrarParcial(Map<String, dynamic> item) async {
    final valorController = TextEditingController();
    final observacaoController = TextEditingController();
    String? erroValor;
    final valor = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar parcial'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Valor em aberto: ${_formatarMoeda(_toDouble(item['valorRestante'] ?? item['valor']))}'),
              const SizedBox(height: 12),
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Valor parcial', errorText: erroValor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: observacaoController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observação'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final valorDigitado = _toDouble(valorController.text);
                final valorAberto = _toDouble(item['valorRestante'] ?? item['valor']);
                if (valorDigitado <= 0) {
                  setDialogState(() => erroValor = 'Informe um valor maior que zero.');
                  return;
                }
                if (valorDigitado >= valorAberto) {
                  setDialogState(() => erroValor = 'Informe um valor menor que o aberto.');
                  return;
                }
                Navigator.of(dialogContext).pop(valorDigitado);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    final observacao = observacaoController.text.trim();
    valorController.dispose();
    observacaoController.dispose();
    if (valor == null) return;
    await _executarComLoading(() async {
      await _acoesService.executarAbatimento(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraParcialRequest(
          tipoLiquidacao: 'PARCIAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada: _formaPagamentoBackend(item['formaPagamento']?.toString() ?? 'Pix'),
          observacoes: observacao.isEmpty ? 'Lançamento parcial registrado pela agenda financeira.' : observacao,
        ),
      );
      await _consultar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcial registrada com sucesso.')));
    });
  }

  Future<void> _confirmarTotal(Map<String, dynamic> item, String label) async {
    final valor = _toDouble(item['valorRestante'] ?? item['valor']);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liquidar lançamento'),
        content: Text('Confirmar liquidação de ${_formatarMoeda(valor)}?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(label)),
        ],
      ),
    );
    if (confirmado != true) return;
    await _executarComLoading(() async {
      await _acoesService.executarTotal(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraLiquidacaoRequest(
          tipoLiquidacao: 'TOTAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada: _formaPagamentoBackend(item['formaPagamento']?.toString() ?? 'Pix'),
          observacoes: 'Liquidação realizada pela agenda financeira.',
          referenciaExterna: item['id']?.toString(),
        ),
      );
      await _consultar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento liquidado com sucesso.')));
    });
  }

  Future<void> _executarComLoading(Future<void> Function() action) async {
    if (_executandoAcao) return;
    setState(() => _executandoAcao = true);
    try {
      await action();
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha na ação (${e.statusCode}).')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível executar a ação.')));
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Agenda financeira',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : () => _consultar(mostrarFeedback: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Novo lançamento',
            onPressed: _executandoAcao ? null : _novoLancamento,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _consultar(mostrarFeedback: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              SixStaggeredEntry(child: _buildHeaderCard()),
              const SizedBox(height: 12),
              SixStaggeredEntry(delay: const Duration(milliseconds: 60), child: _buildFilterCard()),
              if (_carregando || _executandoAcao) ...const <Widget>[
                SizedBox(height: 10),
                LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 14),
              SixStaggeredEntry(delay: const Duration(milliseconds: 110), child: _buildResumo()),
              const SizedBox(height: 16),
              SixStaggeredEntry(delay: const Duration(milliseconds: 160), child: _buildTabs()),
              const SizedBox(height: 12),
              SixStaggeredEntry(delay: const Duration(milliseconds: 210), child: _buildConteudoAba()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x1F0B1F3A), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Agenda financeira',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _ultimaConsultaEm == null
                      ? 'Previsões e confirmações do período.'
                      : 'Atualizado às ${_ultimaConsultaEm!.hour.toString().padLeft(2, '0')}:${_ultimaConsultaEm!.minute.toString().padLeft(2, '0')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD7E3F5), fontSize: 12.5, height: 1.25),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPeriodosSelector(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _smallInfoChip(Icons.swap_vert_rounded, _tipoSelecionado),
              _smallInfoChip(Icons.flag_outlined, _statusSelecionado),
              OutlinedButton.icon(
                onPressed: _carregando ? null : _abrirFiltros,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Filtros'),
              ),
              FilledButton.icon(
                onPressed: _carregando ? null : () => _consultar(mostrarFeedback: true),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Buscar'),
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 34),
            itemCount: _periodos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final periodo = _periodos[index];
              final selected = periodo == _periodoSelecionado;
              return ChoiceChip(
                selected: selected,
                visualDensity: VisualDensity.compact,
                label: Text(periodo),
                onSelected: _carregando
                    ? null
                    : (_) {
                        setState(() => _periodoSelecionado = periodo);
                      },
                selectedColor: _primaryColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
                avatar: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[Color(0x00FFFFFF), _surfaceColor],
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: SixPulsingBadge(
                    child: Icon(Icons.chevron_right_rounded, color: _accentColor, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: _titleTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _abrirFiltros() async {
    String tipoTemp = _tipoSelecionado;
    String statusTemp = _statusSelecionado;
    final result = await showModalBottomSheet<_AgendaMobileFiltro>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 18),
              decoration: const BoxDecoration(
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
                          decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Filtrar agenda', style: TextStyle(color: _titleTextColor, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      _buildFilterOptions(
                        title: 'Tipo',
                        values: _tipos,
                        selected: tipoTemp,
                        onSelected: (value) => setModalState(() => tipoTemp = value),
                      ),
                      const SizedBox(height: 16),
                      _buildFilterOptions(
                        title: 'Status',
                        values: _status,
                        selected: statusTemp,
                        onSelected: (value) => setModalState(() => statusTemp = value),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(_AgendaMobileFiltro(tipo: tipoTemp, status: statusTemp)),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Aplicar filtros'),
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
    });
  }

  Widget _buildFilterOptions({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = value == selected;
            return ChoiceChip(
              selected: isSelected,
              label: Text(value),
              onSelected: (_) => onSelected(value),
              selectedColor: _primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : _titleTextColor, fontWeight: FontWeight.w700),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResumo() {
    final cards = <_ResumoAgendaCardData>[
      _ResumoAgendaCardData('A receber aberto', _totalReceberPrevisto, Icons.south_west_rounded),
      _ResumoAgendaCardData('A pagar aberto', _totalPagarPrevisto, Icons.north_east_rounded),
      _ResumoAgendaCardData('Saldo previsto', _saldoPrevisto, Icons.query_stats_rounded),
      _ResumoAgendaCardData('Recebido confirmado', _totalRecebidoConfirmado, Icons.verified_rounded),
      _ResumoAgendaCardData('Pago confirmado', _totalPagoConfirmado, Icons.task_alt_rounded),
      _ResumoAgendaCardData('Saldo confirmado', _saldoConfirmado, Icons.account_balance_wallet_rounded),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 520 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) => SizedBox(width: itemWidth, child: _buildResumoCard(card))).toList(),
        );
      },
    );
  }

  Widget _buildResumoCard(_ResumoAgendaCardData card) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(card.icon, color: _accentColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: card.value),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Text(
                    _formatarMoeda(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _titleTextColor, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
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
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final aba = _abas[index];
          final selected = index == _abaSelecionada;
          return ChoiceChip(
            selected: selected,
            label: Text(aba),
            onSelected: (_) => setState(() => _abaSelecionada = index),
            selectedColor: _primaryColor,
            labelStyle: TextStyle(color: selected ? Colors.white : _titleTextColor, fontWeight: FontWeight.w800),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _abas.length,
      ),
    );
  }

  Widget _buildConteudoAba() {
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
        subtitle: 'Ajuste os filtros ou cadastre um novo lançamento financeiro.',
      );
    }
    return Column(children: _itensAgenda.map(_buildLancamentoCard).toList());
  }

  Widget _buildLancamentoCard(Map<String, dynamic> item) {
    final tipoEntrada = item['tipo'] == 'receber';
    final valorAberto = _toDouble(item['valorRestante'] ?? item['valor']);
    final valorConfirmado = _toDouble(item['valorConfirmado']);
    final acoes = item['acoes'] is List
        ? (item['acoes'] as List).cast<dynamic>().map((acao) => acao.toString()).toList()
        : <String>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(tipoEntrada ? 'Receber' : 'Pagar', tipoEntrada ? Icons.south_west_rounded : Icons.north_east_rounded),
              _pill(item['status']?.toString() ?? '-', Icons.flag_outlined),
              if (valorConfirmado > 0) _pill('Confirmado: ${_formatarMoeda(valorConfirmado)}', Icons.verified_outlined),
              if (valorAberto > 0) _pill('Aberto: ${_formatarMoeda(valorAberto)}', Icons.pending_actions_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Text(item['descricao']?.toString() ?? '', style: const TextStyle(color: _titleTextColor, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(
            '${item['contato']} • Vence em ${item['vencimento']} • ${item['formaPagamento']}',
            style: const TextStyle(color: _mutedTextColor, height: 1.35),
          ),
          const SizedBox(height: 10),
          Text('Original: ${_formatarMoeda(_toDouble(item['valorOriginal']))}', style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _executandoAcao ? null : () => _editarLancamento(item),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
              ...acoes.take(3).map(
                    (acao) => OutlinedButton(
                      onPressed: _executandoAcao ? null : () => _executarAcao(acao, item),
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
      children: itensPorData.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: _borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.calendar_today_outlined, color: _accentColor, size: 18),
                    const SizedBox(width: 8),
                    Text(entry.key, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(tipoEntrada ? Icons.south_west_rounded : Icons.north_east_rounded, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item['descricao']?.toString() ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Previsto ${_formatarMoeda(valorPrevisto)} • Diferença ${_formatarMoeda(diferenca)}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_formatarMoeda(valorConfirmado), style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFluxo() {
    final fluxoPorMes = <String, Map<String, double>>{};
    for (final item in _itensSomaveis) {
      final data = _parseDataBr(item['vencimento']?.toString());
      final mes = data == null ? 'Sem competência' : '${data.year}-${data.month.toString().padLeft(2, '0')}';
      final valor = _toDouble(item['valorRestante'] ?? item['valor']);
      final registro = fluxoPorMes.putIfAbsent(mes, () => <String, double>{'entradas': 0, 'saidas': 0});
      if (item['tipo'] == 'receber') {
        registro['entradas'] = (registro['entradas'] ?? 0) + valor;
      } else {
        registro['saidas'] = (registro['saidas'] ?? 0) + valor;
      }
    }
    if (fluxoPorMes.isEmpty) {
      return _buildEmptyState(icon: Icons.query_stats_outlined, title: 'Fluxo previsto vazio', subtitle: 'Nenhuma entrada ou saída prevista para o período.');
    }
    final mesesOrdenados = fluxoPorMes.keys.toList()..sort();
    return Column(
      children: mesesOrdenados.map((mes) {
        final entrada = fluxoPorMes[mes]?['entradas'] ?? 0;
        final saida = fluxoPorMes[mes]?['saidas'] ?? 0;
        final saldo = entrada - saida;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: _borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(mes, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
                  Text('Saldo: ${_formatarMoeda(saldo)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 14),
              _buildFluxoBarra(entrada: entrada, saida: saida),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _fluxoValor('Entradas', entrada, Icons.south_west_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _fluxoValor('Saídas', saida, Icons.north_east_rounded)),
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
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(999)),
          clipBehavior: Clip.antiAlias,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Row(
                children: <Widget>[
                  AnimatedContainer(duration: const Duration(milliseconds: 650), width: constraints.maxWidth * percentualEntrada * value, height: 30, color: _accentColor),
                  AnimatedContainer(duration: const Duration(milliseconds: 650), width: constraints.maxWidth * percentualSaida * value, height: 30, color: const Color(0xFFE11D48)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_formatarMoeda(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildValoresConfirmados() {
    if (_itensConfirmados.isEmpty) {
      return _buildEmptyState(icon: Icons.verified_outlined, title: 'Nenhum valor confirmado', subtitle: 'As liquidações confirmadas aparecerão aqui.');
    }
    return Column(
      children: _itensConfirmados.map((item) {
        final tipoEntrada = item['tipo'] == 'receber';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: _borderColor)),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(tipoEntrada ? Icons.south_west_rounded : Icons.north_east_rounded, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item['descricao']?.toString() ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${item['contato']} • ${item['data']} • ${item['formaPagamento']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(_formatarMoeda(_toDouble(item['valorConfirmado'])), style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 15),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _titleTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: _borderColor)),
      child: Column(
        children: <Widget>[
          Icon(icon, color: _accentColor, size: 34),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _titleTextColor, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _mutedTextColor, height: 1.35)),
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 18),
          decoration: const BoxDecoration(color: _backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999))),
                  ),
                  const SizedBox(height: 18),
                  Text(item['descricao']?.toString() ?? 'Detalhes', style: const TextStyle(color: _titleTextColor, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _detalheLinha('Contato', item['contato']?.toString() ?? '-'),
                  _detalheLinha('Vencimento', item['vencimento']?.toString() ?? '-'),
                  _detalheLinha('Status', item['status']?.toString() ?? '-'),
                  _detalheLinha('Forma de recebimento', item['formaPagamento']?.toString() ?? '-'),
                  _detalheLinha('Valor original', _formatarMoeda(_toDouble(item['valorOriginal']))),
                  _detalheLinha('Valor confirmado', _formatarMoeda(_toDouble(item['valorConfirmado']))),
                  _detalheLinha('Valor em aberto', _formatarMoeda(_toDouble(item['valorRestante']))),
                  if ((item['observacoes']?.toString() ?? '').isNotEmpty) _detalheLinha('Observações', item['observacoes'].toString()),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: _mutedTextColor, fontWeight: FontWeight.w800))),
          Expanded(child: Text(value, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  double _somar(List<Map<String, dynamic>> itens, String tipo, String campo) {
    return itens.where((item) => item['tipo'] == tipo).fold<double>(0, (soma, item) => soma + _toDouble(item[campo] ?? item['valor']));
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
    switch ((formaPagamento ?? '').toUpperCase()) {
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'CARTAO_CREDITO':
        return 'Cartão de crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de débito';
      case 'DINHEIRO':
        return 'Dinheiro';
      case 'DEBITO_AUTOMATICO':
        return 'Débito automático';
      default:
        return formaPagamento?.trim().isNotEmpty == true ? formaPagamento!.trim() : 'Pix';
    }
  }

  String _formaPagamentoBackend(String label) {
    switch (label.toLowerCase()) {
      case 'boleto':
        return 'BOLETO';
      case 'transferência':
        return 'TRANSFERENCIA';
      case 'cartão de crédito':
        return 'CARTAO_CREDITO';
      case 'cartão de débito':
        return 'CARTAO_DEBITO';
      case 'dinheiro':
        return 'DINHEIRO';
      case 'débito automático':
        return 'DEBITO_AUTOMATICO';
      default:
        return 'PIX';
    }
  }

  String _empresaNome(dynamic empresa) {
    if (empresa is Map<String, dynamic>) return empresa['nome']?.toString() ?? '';
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
      final normalizado = texto.contains(',') && texto.contains('.')
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
  const _AgendaMobileFiltro({required this.tipo, required this.status});
  final String tipo;
  final String status;
}

class _ResumoAgendaCardData {
  const _ResumoAgendaCardData(this.title, this.value, this.icon);
  final String title;
  final double value;
  final IconData icon;
}
