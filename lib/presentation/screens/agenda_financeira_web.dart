import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';

class AgendaFinanceiraWeb extends StatefulWidget {
  const AgendaFinanceiraWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AgendaFinanceiraWeb> createState() => _AgendaFinanceiraWebState();
}

class _AgendaFinanceiraWebState extends State<AgendaFinanceiraWeb> {
  final AgendaFinanceiraLancamentoService _service = AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesService = AgendaFinanceiraAcoesFinanceiras();

  final List<String> _abas = const <String>[
    'Agenda',
    'Calendário',
    'Fluxo previsto',
    'Valores confirmados',
  ];
  final List<String> _periodos = const <String>['Hoje', 'Próximos 7 dias', 'Este mês', 'Próximo mês'];
  final List<String> _tipos = const <String>['Todos', 'Receber', 'Pagar'];
  final List<String> _status = const <String>['Todos', 'Previsto', 'Pendente', 'Vence hoje', 'Vencido', 'Pago', 'Recebido', 'Parcial', 'Cancelado'];

  int _abaSelecionada = 0;
  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';

  bool _carregando = false;
  bool _executandoAcao = false;
  DateTime? _ultimaConsultaEm;

  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _itensConfirmados = <Map<String, dynamic>>[];
  Map<String, dynamic> _totaisConfirmados = <String, dynamic>{};
  Map<String, dynamic>? _selecionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consultar());
  }

  List<Map<String, dynamic>> get _itensAgenda {
    return _gruposAgenda
        .expand((grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>())
        .where((item) {
          final tipoOk = _tipoSelecionado == 'Todos' ||
              (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') ||
              (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
          final statusOk = _statusSelecionado == 'Todos' || item['status'] == _statusSelecionado;
          return tipoOk && statusOk;
        })
        .toList();
  }

  List<Map<String, dynamic>> get _itensSomaveis =>
      _itensAgenda.where((item) => item['status']?.toString() != 'Cancelado').toList();

  double get _totalReceberPrevisto => _somar(_itensSomaveis, 'receber', 'valorRestante');
  double get _totalPagarPrevisto => _somar(_itensSomaveis, 'pagar', 'valorRestante');
  double get _saldoPrevisto => _totalReceberPrevisto - _totalPagarPrevisto;
  double get _totalRecebidoConfirmado => _toDouble(_totaisConfirmados['totalRecebidoConfirmado']);
  double get _totalPagoConfirmado => _toDouble(_totaisConfirmados['totalPagoConfirmado']);
  double get _saldoConfirmado => _toDouble(_totaisConfirmados['saldoConfirmado']);

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
      _selecionado = _itensAgenda.isEmpty ? null : _itensAgenda.first;

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
          'itens': itensRaw is List ? itensRaw.whereType<Map<String, dynamic>>().map(_mapearItemAgenda).toList() : <Map<String, dynamic>>[],
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

    _totaisConfirmados = totais is Map<String, dynamic> ? Map<String, dynamic>.from(totais) : <String, dynamic>{};
    _itensConfirmados
      ..clear()
      ..addAll(itens is List ? itens.whereType<Map<String, dynamic>>().map(_mapearItemConfirmado).toList() : <Map<String, dynamic>>[]);
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
      'acoes': acoes.isNotEmpty
          ? acoes
          : (tipo == 'receber'
              ? <String>['Receber', 'Registrar parcial', 'Detalhes']
              : <String>['Pagar', 'Registrar parcial', 'Detalhes']),
    };
  }

  Map<String, dynamic> _mapearItemConfirmado(Map<String, dynamic> item) {
    final tipo = item['tipo']?.toString().toUpperCase() == 'PAGAR' ? 'pagar' : 'receber';
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valorOriginal': _toDouble(item['valorOriginal']),
      'valorConfirmado': _toDouble(item['valorConfirmado']),
      'valorRestante': _toDouble(item['valorRestante']),
      'data': _formatarDataIsoParaBr((item['dataUltimaConfirmacao'] ?? item['dataVencimento'])?.toString()),
      'status': _statusLabel(item['status']?.toString()),
      'formaPagamento': _formaPagamentoLabel(item['formaPagamento']?.toString()),
      'empresa': item['empresa']?.toString() ?? '',
      'quantidadeConfirmacoes': item['quantidadeConfirmacoes'] ?? item['quantidadeLiquidacoes'] ?? 1,
    };
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
        if ((confirmado['valorConfirmado'] as double? ?? 0) > 0 && (confirmado['valorRestante'] as double? ?? 0) > 0) {
          item['status'] = 'Parcial';
        }
      }
    }
  }

  Future<void> _executarAcao(String acao, Map<String, dynamic> item) async {
    final comando = acao.trim().toLowerCase();
    if (comando == 'detalhes') {
      setState(() => _selecionado = item);
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
    if (comando == 'receber' || comando == 'pagar') {
      await _confirmarTotal(item, comando == 'receber' ? 'Receber' : 'Pagar');
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
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label lançamento'),
        content: Text('Confirmar $label de ${_formatarMoeda(_toDouble(item['valorRestante'] ?? item['valor']))}?'),
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
          valorLiquidado: _toDouble(item['valorRestante'] ?? item['valor']),
          formaPagamentoRealizada: _formaPagamentoBackend(item['formaPagamento']?.toString() ?? 'Pix'),
          observacoes: 'Confirmação realizada pela agenda financeira.',
          referenciaExterna: item['id']?.toString(),
        ),
      );
      await _consultar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label registrado com sucesso.')));
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
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Future<void> _novoLancamento() async {
    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(context, empresaSelecionada: 'Empresa', empresas: const <String>['Empresa']);
    if (!mounted || item == null) return;
    await _consultar(mostrarFeedback: true);
  }

  Future<void> _editarLancamento(Map<String, dynamic> item) async {
    final empresaAtual = _empresaNome(item['empresa']).trim();
    final empresas = <String>[empresaAtual.isEmpty ? 'Empresa' : empresaAtual];

    final itemAtualizado = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada: empresas.first,
      empresas: empresas,
      modoEdicao: true,
      lancamentoInicial: item,
    );

    if (!mounted || itemAtualizado == null) return;
    await _consultar(mostrarFeedback: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoLancamento,
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _consultar(mostrarFeedback: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _buildHeader(theme),
              const SizedBox(height: 14),
              _buildFiltros(theme),
              if (_carregando || _executandoAcao) ...const <Widget>[SizedBox(height: 10), LinearProgressIndicator(minHeight: 3)],
              const SizedBox(height: 14),
              _buildResumo(theme),
              const SizedBox(height: 18),
              _buildAbas(theme),
              const SizedBox(height: 16),
              _buildConteudoAba(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Agenda Financeira', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(_ultimaConsultaEm == null
                    ? 'Ainda não consultado'
                    : 'Atualizado às ${_ultimaConsultaEm!.hour.toString().padLeft(2, '0')}:${_ultimaConsultaEm!.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
            Wrap(spacing: 8, children: <Widget>[
              OutlinedButton.icon(
                onPressed: widget.embedded ? widget.onBack : () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar'),
              ),
              FilledButton.icon(onPressed: () => _consultar(mostrarFeedback: true), icon: const Icon(Icons.refresh), label: const Text('Atualizar')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
          _dropdown('Período', _periodoSelecionado, _periodos, (value) => setState(() => _periodoSelecionado = value!)),
          _dropdown('Tipo', _tipoSelecionado, _tipos, (value) => setState(() => _tipoSelecionado = value!)),
          _dropdown('Status', _statusSelecionado, _status, (value) => setState(() => _statusSelecionado = value!)),
          FilledButton.icon(onPressed: _carregando ? null : () => _consultar(mostrarFeedback: true), icon: const Icon(Icons.search), label: const Text('Buscar')),
        ]),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: _carregando ? null : onChanged,
      ),
    );
  }

  Widget _buildResumo(ThemeData theme) {
    final cards = <Map<String, dynamic>>[
      {'titulo': 'A receber aberto', 'valor': _totalReceberPrevisto, 'icone': Icons.south_west_rounded},
      {'titulo': 'A pagar aberto', 'valor': _totalPagarPrevisto, 'icone': Icons.north_east_rounded},
      {'titulo': 'Saldo previsto', 'valor': _saldoPrevisto, 'icone': Icons.query_stats_rounded},
      {'titulo': 'Recebido confirmado', 'valor': _totalRecebidoConfirmado, 'icone': Icons.verified_rounded},
      {'titulo': 'Pago confirmado', 'valor': _totalPagoConfirmado, 'icone': Icons.task_alt_rounded},
      {'titulo': 'Saldo confirmado', 'valor': _saldoConfirmado, 'icone': Icons.account_balance_wallet_rounded},
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((card) => SizedBox(width: 260, child: _cardResumo(theme, card))).toList(),
    );
  }

  Widget _cardResumo(ThemeData theme, Map<String, dynamic> card) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: <Widget>[
          Icon(card['icone'] as IconData, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(card['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_formatarMoeda(card['valor'] as double), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildAbas(ThemeData theme) {
    return SegmentedButton<int>(
      segments: List<ButtonSegment<int>>.generate(
        _abas.length,
        (index) => ButtonSegment<int>(value: index, label: Text(_abas[index]), icon: index == _abaSelecionada ? const Icon(Icons.check, size: 16) : null),
      ),
      selected: <int>{_abaSelecionada},
      onSelectionChanged: (value) => setState(() => _abaSelecionada = value.first),
    );
  }

  Widget _buildConteudoAba(ThemeData theme) {
    switch (_abaSelecionada) {
      case 1:
        return _buildCalendario(theme);
      case 2:
        return _buildFluxo(theme);
      case 3:
        return _buildValoresConfirmados(theme);
      default:
        return _buildAgenda(theme);
    }
  }

  Widget _buildAgenda(ThemeData theme) {
    if (_itensAgenda.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum lançamento encontrado.')));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _itensAgenda.map((item) => _cardLancamento(theme, item)).toList(),
    );
  }

  Widget _cardLancamento(ThemeData theme, Map<String, dynamic> item) {
    final tipoEntrada = item['tipo'] == 'receber';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            Chip(label: Text(tipoEntrada ? 'Receber' : 'Pagar')),
            Chip(label: Text(item['status']?.toString() ?? '-')),
            if (_toDouble(item['valorConfirmado']) > 0) Chip(label: Text('Confirmado: ${_formatarMoeda(_toDouble(item['valorConfirmado']))}')),
            if (_toDouble(item['valorRestante']) > 0) Chip(label: Text('Aberto: ${_formatarMoeda(_toDouble(item['valorRestante']))}')),
          ]),
          const SizedBox(height: 8),
          Text(item['descricao']?.toString() ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('${item['contato']} • Vence em ${item['vencimento']} • ${item['formaPagamento']}'),
          const SizedBox(height: 8),
          Text('Original: ${_formatarMoeda(_toDouble(item['valorOriginal']))}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
              ...(item['acoes'] as List).take(4).map((acao) => OutlinedButton(
                onPressed: _executandoAcao ? null : () => _executarAcao(acao.toString(), item),
                child: Text(acao.toString()),
              )),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildValoresConfirmados(ThemeData theme) {
    if (_itensConfirmados.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum valor confirmado no período.')));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Valores confirmados', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ..._itensConfirmados.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(item['tipo'] == 'receber' ? Icons.south_west_rounded : Icons.north_east_rounded),
            title: Text(item['descricao']?.toString() ?? ''),
            subtitle: Text('${item['contato']} • ${item['data']} • Restante: ${_formatarMoeda(_toDouble(item['valorRestante']))}'),
            trailing: Text(_formatarMoeda(_toDouble(item['valorConfirmado'])), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        )),
      ],
    );
  }

  Widget _buildCalendario(ThemeData theme) {
    final porDia = <String, double>{};
    for (final item in _itensSomaveis) {
      final data = item['vencimento']?.toString() ?? '-';
      porDia[data] = (porDia[data] ?? 0) + _toDouble(item['valorRestante'] ?? item['valor']);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: porDia.entries.map((entry) => ListTile(title: Text(entry.key), trailing: Text(_formatarMoeda(entry.value)))).toList()),
      ),
    );
  }

  Widget _buildFluxo(ThemeData theme) {
    final porMes = <String, double>{};
    for (final item in _itensSomaveis) {
      final data = _parseDataBr(item['vencimento']?.toString());
      final mes = data == null ? 'Sem competência' : '${data.year}-${data.month.toString().padLeft(2, '0')}';
      final valor = _toDouble(item['valorRestante'] ?? item['valor']);
      porMes[mes] = (porMes[mes] ?? 0) + (item['tipo'] == 'receber' ? valor : -valor);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: porMes.entries.map((entry) => ListTile(title: Text(entry.key), trailing: Text(_formatarMoeda(entry.value)))).toList()),
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
        return 'Receber';
      case 'REGISTRAR_PAGAMENTO':
      case 'PAGAR':
        return 'Pagar';
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
      default:
        return 'Pix';
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
    return '${negativo ? '-R\$ ' : 'R\$ '}${buffer.toString()},$decimal';
  }
}
