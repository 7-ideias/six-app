import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _filtrosCacheKey = 'six.agendaFinanceiraWeb.filtros.v1';

  final AgendaFinanceiraLancamentoService _service = AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesFinanceiras = AgendaFinanceiraAcoesFinanceiras();
  final ScrollController _scrollController = ScrollController();

  final List<String> _periodos = const <String>['Hoje', 'Próximos 7 dias', 'Este mês', 'Próximo mês', 'Personalizado'];
  final List<String> _tipos = const <String>['Todos', 'Receber', 'Pagar'];
  final List<String> _status = const <String>['Todos', 'Previsto', 'Pendente', 'Vence hoje', 'Vencido', 'Pago', 'Recebido', 'Parcial', 'Cancelado'];
  final List<String> _origens = const <String>['Todas', 'Venda', 'Ordem de serviço', 'Despesa manual', 'Compra', 'Parcela', 'Movimentação de caixa'];
  final List<String> _abas = const <String>['Agenda', 'Calendário', 'Fluxo previsto'];

  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  String _origemSelecionada = 'Todas';
  String _empresaSelecionada = 'Todas';
  bool _somenteCriticosSelecionado = false;
  DateTime? _dataInicioPersonalizada;
  DateTime? _dataFimPersonalizada;

  String _periodoBusca = 'Próximos 7 dias';
  String _tipoBusca = 'Todos';
  String _statusBusca = 'Todos';
  String _origemBusca = 'Todas';
  String _empresaBusca = 'Todas';
  bool _somenteCriticosBusca = false;
  DateTime? _dataInicioPersonalizadaBusca;
  DateTime? _dataFimPersonalizadaBusca;

  bool _isConsultando = false;
  bool _isExecutandoAcao = false;
  int _abaSelecionada = 0;
  DateTime? _ultimaConsultaEm;
  Map<String, dynamic>? _lancamentoSelecionado;

  final List<Map<String, dynamic>> _empresas = <Map<String, dynamic>>[<String, dynamic>{'id': 'all', 'nome': 'Todas'}];
  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];

  bool get _temFiltrosPendentes =>
      _periodoBusca != _periodoSelecionado ||
      _tipoBusca != _tipoSelecionado ||
      _statusBusca != _statusSelecionado ||
      _origemBusca != _origemSelecionada ||
      _empresaBusca != _empresaSelecionada ||
      _somenteCriticosBusca != _somenteCriticosSelecionado ||
      _datasPersonalizadasDiferentes;

  bool get _datasPersonalizadasDiferentes {
    final comparaDatas = _periodoBusca == 'Personalizado' || _periodoSelecionado == 'Personalizado';
    if (!comparaDatas) return false;
    return !_mesmaData(_dataInicioPersonalizadaBusca, _dataInicioPersonalizada) || !_mesmaData(_dataFimPersonalizadaBusca, _dataFimPersonalizada);
  }

  List<Map<String, dynamic>> get _itensFiltrados {
    return _gruposAgenda.expand((grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>()).where((item) {
      final bateTipo = _tipoSelecionado == 'Todos' || (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') || (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
      final bateStatus = _statusSelecionado == 'Todos' || item['status'] == _statusSelecionado;
      final bateOrigem = _origemSelecionada == 'Todas' || item['origem'] == _origemSelecionada;
      final empresaDoItem = item['empresa']?.toString() ?? '';
      final bateEmpresa = _empresaSelecionada == 'Todas' || empresaDoItem.isEmpty || empresaDoItem == _empresaSelecionada;
      final bateCritico = !_somenteCriticosSelecionado || item['status'] == 'Vencido' || item['status'] == 'Vence hoje';
      return bateTipo && bateStatus && bateOrigem && bateEmpresa && bateCritico;
    }).toList();
  }

  List<Map<String, dynamic>> get _itensSomaveisFiltrados => _itensFiltrados.where((item) => item['status'] != 'Cancelado').toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializarTela());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializarTela() async {
    await _carregarFiltrosDoCache();
    if (!mounted) return;
    await _consultarLancamentos();
  }

  Future<void> _carregarFiltrosDoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_filtrosCacheKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final periodo = _valorCacheValido(decoded['periodo'], _periodos, _periodoSelecionado);
      final tipo = _valorCacheValido(decoded['tipo'], _tipos, _tipoSelecionado);
      final status = _valorCacheValido(decoded['status'], _status, _statusSelecionado);
      final origem = _valorCacheValido(decoded['origem'], _origens, _origemSelecionada);
      final empresa = _valorCacheLivre(decoded['empresa'], _empresaSelecionada);
      final somenteCriticos = decoded['somenteCriticos'] is bool ? decoded['somenteCriticos'] as bool : _somenteCriticosSelecionado;
      final inicioCache = _parseDataIso(decoded['dataInicioPersonalizada']);
      final fimCache = _parseDataIso(decoded['dataFimPersonalizada']);
      final padrao = _intervaloPersonalizadoPadrao();
      final inicio = inicioCache ?? (periodo == 'Personalizado' ? padrao.start : null);
      final fim = fimCache ?? (periodo == 'Personalizado' ? padrao.end : null);
      if (!mounted) return;
      setState(() {
        _periodoSelecionado = periodo;
        _tipoSelecionado = tipo;
        _statusSelecionado = status;
        _origemSelecionada = origem;
        _empresaSelecionada = empresa;
        _somenteCriticosSelecionado = somenteCriticos;
        _dataInicioPersonalizada = inicio;
        _dataFimPersonalizada = fim;
        _periodoBusca = periodo;
        _tipoBusca = tipo;
        _statusBusca = status;
        _origemBusca = origem;
        _empresaBusca = empresa;
        _somenteCriticosBusca = somenteCriticos;
        _dataInicioPersonalizadaBusca = inicio;
        _dataFimPersonalizadaBusca = fim;
      });
    } catch (_) {}
  }

  Future<void> _salvarFiltrosNoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filtrosCacheKey, jsonEncode(<String, dynamic>{
        'periodo': _periodoSelecionado,
        'tipo': _tipoSelecionado,
        'status': _statusSelecionado,
        'origem': _origemSelecionada,
        'empresa': _empresaSelecionada,
        'somenteCriticos': _somenteCriticosSelecionado,
        'dataInicioPersonalizada': _dataInicioPersonalizada?.toIso8601String(),
        'dataFimPersonalizada': _dataFimPersonalizada?.toIso8601String(),
      }));
    } catch (_) {}
  }

  Future<void> _onPeriodoBuscaChanged(String? value) async {
    if (value == null) return;
    if (value != 'Personalizado') {
      setState(() => _periodoBusca = value);
      return;
    }
    final intervaloAtual = _intervaloPersonalizadoBuscaAtual();
    setState(() {
      _periodoBusca = 'Personalizado';
      _dataInicioPersonalizadaBusca = intervaloAtual.start;
      _dataFimPersonalizadaBusca = intervaloAtual.end;
    });
    await _selecionarPeriodoPersonalizadoBusca();
  }

  Future<void> _selecionarPeriodoPersonalizadoBusca() async {
    final intervaloAtual = _intervaloPersonalizadoBuscaAtual();
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: intervaloAtual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecione o período da pesquisa',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (!mounted || range == null) return;
    setState(() {
      _periodoBusca = 'Personalizado';
      _dataInicioPersonalizadaBusca = DateTime(range.start.year, range.start.month, range.start.day);
      _dataFimPersonalizadaBusca = DateTime(range.end.year, range.end.month, range.end.day);
    });
  }

  Future<void> _onNovoLancamentoPressed() async {
    final empresasLancamento = _empresas.map((e) => e['nome'] as String).where((nome) => nome != 'Todas').toList();
    final empresas = empresasLancamento.isEmpty ? <String>['Empresa'] : empresasLancamento;
    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada: _empresaSelecionada == 'Todas' ? empresas.first : _empresaSelecionada,
      empresas: empresas,
    );
    if (!mounted || item == null) return;
    await _consultarLancamentos(mostrarFeedback: true);
  }

  Future<void> _onEditarLancamentoPressed({Map<String, dynamic>? itemBase}) async {
    final item = itemBase ?? _lancamentoSelecionado;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um lançamento para editar.')));
      return;
    }
    final empresasLancamento = _empresas.map((e) => e['nome'] as String).where((nome) => nome != 'Todas').toList();
    final empresaAtual = item['empresa']?.toString().trim() ?? '';
    if (empresaAtual.isNotEmpty && !empresasLancamento.contains(empresaAtual)) empresasLancamento.add(empresaAtual);
    final empresas = empresasLancamento.isEmpty ? <String>['Empresa'] : empresasLancamento;
    final itemAtualizado = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada: empresaAtual.isNotEmpty ? empresaAtual : empresas.first,
      empresas: empresas,
      modoEdicao: true,
      lancamentoInicial: item,
    );
    if (!mounted || itemAtualizado == null) return;
    await _consultarLancamentos(mostrarFeedback: true);
  }

  Future<void> _aplicarFiltrosPendentesEConsultar() async {
    if (_isConsultando) return;
    if (_periodoBusca == 'Personalizado' && (_dataInicioPersonalizadaBusca == null || _dataFimPersonalizadaBusca == null)) {
      await _selecionarPeriodoPersonalizadoBusca();
      if (!mounted || _dataInicioPersonalizadaBusca == null || _dataFimPersonalizadaBusca == null) return;
    }
    setState(() {
      _periodoSelecionado = _periodoBusca;
      _tipoSelecionado = _tipoBusca;
      _statusSelecionado = _statusBusca;
      _origemSelecionada = _origemBusca;
      _empresaSelecionada = _empresaBusca;
      _somenteCriticosSelecionado = _somenteCriticosBusca;
      _dataInicioPersonalizada = _dataInicioPersonalizadaBusca;
      _dataFimPersonalizada = _dataFimPersonalizadaBusca;
    });
    await _consultarLancamentos(mostrarFeedback: true);
    await _salvarFiltrosNoCache();
  }

  Future<void> _consultarLancamentos({bool mostrarFeedback = false}) async {
    if (_isConsultando) return;
    setState(() => _isConsultando = true);
    try {
      final payload = await _service.consultarLancamentos(_buildConsultaRequest());
      if (!mounted) return;
      _aplicarConsultaBackend(payload);
      if (mostrarFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Consulta atualizada: ${_itensFiltrados.length} lançamento(s).')));
      }
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted || !mostrarFeedback) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao consultar lançamentos (${e.statusCode}).')));
    } catch (_) {
      if (!mounted || !mostrarFeedback) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível consultar agora.')));
    } finally {
      if (mounted) setState(() => _isConsultando = false);
    }
  }

  Future<void> _executarAcaoLancamento(String acao, Map<String, dynamic> item) async {
    final comando = acao.trim().toLowerCase();
    if (comando == 'detalhes' || comando == 'detalhar') {
      setState(() => _lancamentoSelecionado = item);
      return;
    }
    if (comando == 'editar' || comando == 'editar lançamento') {
      await _onEditarLancamentoPressed(itemBase: item);
      return;
    }
    if (comando == 'receber' || comando == 'pagar') {
      await _confirmarBaixaTotal(item, comando == 'receber' ? 'Receber' : 'Pagar');
      return;
    }
    if (comando == 'registrar parcial') {
      await _registrarParcial(item);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ação "$acao" será integrada no backend.')));
  }

  Future<void> _confirmarBaixaTotal(Map<String, dynamic> item, String labelAcao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$labelAcao lançamento'),
        content: Text('Confirmar $labelAcao de ${_formatarMoeda(item['valor'] as double)} para "${item['descricao']}"?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(labelAcao)),
        ],
      ),
    );
    if (confirmado != true) return;
    await _executarComFeedback(() async {
      await _acoesFinanceiras.executarTotal(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraLiquidacaoRequest(
          tipoLiquidacao: 'TOTAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: item['valor'] as double,
          formaPagamentoRealizada: _formaPagamentoLabelParaBackend(item['formaPagamento']?.toString() ?? 'Pix'),
          observacoes: 'Confirmação realizada pela agenda financeira.',
          referenciaExterna: item['id']?.toString(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$labelAcao registrado com sucesso.')));
    });
  }

  Future<void> _registrarParcial(Map<String, dynamic> item) async {
    final valorController = TextEditingController();
    final observacaoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final valor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar parcial'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text('Valor aberto: ${_formatarMoeda(item['valor'] as double)}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
              validator: (value) {
                final valor = _toDoubleDynamic(value);
                if (valor <= 0) return 'Informe um valor maior que zero.';
                if (valor >= (item['valor'] as double)) return 'Informe um valor menor que o total aberto.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: observacaoController, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Observação')),
          ]),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, _toDoubleDynamic(valorController.text));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    final observacao = observacaoController.text.trim();
    valorController.dispose();
    observacaoController.dispose();
    if (valor == null) return;
    await _executarComFeedback(() async {
      await _acoesFinanceiras.executarAbatimento(
        idLancamento: item['id'].toString(),
        request: AgendaFinanceiraParcialRequest(
          tipoLiquidacao: 'PARCIAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada: _formaPagamentoLabelParaBackend(item['formaPagamento']?.toString() ?? 'Pix'),
          observacoes: observacao.isEmpty ? 'Lançamento parcial registrado pela agenda financeira.' : observacao,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcial registrada com sucesso.')));
    });
  }

  Future<void> _executarComFeedback(Future<void> Function() action) async {
    if (_isExecutandoAcao) return;
    setState(() => _isExecutandoAcao = true);
    try {
      await action();
      await _consultarLancamentos(mostrarFeedback: false);
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir a ação (${e.statusCode}).')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível concluir a ação.')));
    } finally {
      if (mounted) setState(() => _isExecutandoAcao = false);
    }
  }

  AgendaFinanceiraConsultaRequest _buildConsultaRequest() {
    return AgendaFinanceiraConsultaRequest(
      periodo: _periodoParaRequest(_periodoSelecionado),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo: _tipoSelecionado == 'Todos' ? 'TODOS' : _tipoSelecionado.toUpperCase(),
        status: _statusFiltroParaBackend(_statusSelecionado),
        origens: _origensFiltroParaBackend(_origemSelecionada),
        categorias: <String>[],
        formasPagamento: <String>[],
        clienteFornecedor: null,
        somenteCriticos: _somenteCriticosSelecionado,
      ),
      visaoSelecionada: _visaoSelecionadaParaBackend(),
    );
  }

  AgendaFinanceiraPeriodoRequest _periodoParaRequest(String periodo) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    switch (periodo) {
      case 'Hoje':
        return AgendaFinanceiraPeriodoRequest(modo: 'HOJE', dataInicio: hoje, dataFim: hoje);
      case 'Este mês':
        return AgendaFinanceiraPeriodoRequest(modo: 'ESTE_MES', dataInicio: DateTime(hoje.year, hoje.month, 1), dataFim: DateTime(hoje.year, hoje.month + 1, 0));
      case 'Próximo mês':
        return AgendaFinanceiraPeriodoRequest(modo: 'PROXIMO_MES', dataInicio: DateTime(hoje.year, hoje.month + 1, 1), dataFim: DateTime(hoje.year, hoje.month + 2, 0));
      case 'Personalizado':
        final padrao = _intervaloPersonalizadoPadrao();
        return AgendaFinanceiraPeriodoRequest(modo: 'PERSONALIZADO', dataInicio: _dataInicioPersonalizada ?? padrao.start, dataFim: _dataFimPersonalizada ?? padrao.end);
      default:
        return AgendaFinanceiraPeriodoRequest(modo: 'PROXIMOS_7_DIAS', dataInicio: hoje, dataFim: hoje.add(const Duration(days: 7)));
    }
  }

  List<String> _statusFiltroParaBackend(String status) {
    switch (status) {
      case 'Previsto': return <String>['PREVISTO'];
      case 'Pendente': return <String>['PENDENTE'];
      case 'Vence hoje': return <String>['VENCE_HOJE'];
      case 'Vencido': return <String>['VENCIDO'];
      case 'Pago': return <String>['PAGO'];
      case 'Recebido': return <String>['RECEBIDO'];
      case 'Parcial': return <String>['PARCIAL'];
      case 'Cancelado': return <String>['CANCELADO'];
      default: return <String>[];
    }
  }

  List<String> _origensFiltroParaBackend(String origem) {
    switch (origem) {
      case 'Venda': return <String>['VENDA'];
      case 'Ordem de serviço': return <String>['ORDEM_SERVICO'];
      case 'Despesa manual': return <String>['DESPESA_MANUAL'];
      case 'Compra': return <String>['COMPRA'];
      case 'Parcela': return <String>['PARCELA'];
      case 'Movimentação de caixa': return <String>['MOVIMENTACAO_CAIXA'];
      default: return <String>[];
    }
  }

  String _visaoSelecionadaParaBackend() {
    switch (_abaSelecionada) {
      case 1: return 'CALENDARIO';
      case 2: return 'FLUXO_PREVISTO';
      default: return 'AGENDA';
    }
  }

  void _aplicarConsultaBackend(Map<String, dynamic> payload) {
    final novosGrupos = _mapearGruposAgenda(payload['gruposAgenda']);
    final empresasResposta = _extrairEmpresas(novosGrupos);
    setState(() {
      _gruposAgenda..clear()..addAll(novosGrupos);
      _empresas
        ..clear()
        ..add(<String, dynamic>{'id': 'all', 'nome': 'Todas'})
        ..addAll(empresasResposta.map((nome) => <String, dynamic>{'id': nome.toLowerCase().replaceAll(' ', '-'), 'nome': nome}));
      if (!_empresas.any((e) => e['nome'] == _empresaSelecionada)) {
        _empresaSelecionada = 'Todas';
        _empresaBusca = 'Todas';
      }
      _ultimaConsultaEm = DateTime.now();
      _sincronizarLancamentoSelecionado();
    });
  }

  List<Map<String, dynamic>> _mapearGruposAgenda(dynamic gruposRaw) {
    if (gruposRaw is! List) return <Map<String, dynamic>>[];
    final grupos = <Map<String, dynamic>>[];
    for (final grupo in gruposRaw) {
      if (grupo is! Map<String, dynamic>) continue;
      final itensRaw = grupo['itens'];
      final itens = itensRaw is List ? itensRaw.whereType<Map<String, dynamic>>().map(_mapearItemResumo).toList() : <Map<String, dynamic>>[];
      grupos.add(<String, dynamic>{'grupo': grupo['titulo']?.toString() ?? 'Lançamentos', 'descricao': grupo['descricao']?.toString() ?? 'Lançamentos financeiros do período.', 'itens': itens});
    }
    return grupos;
  }

  Map<String, dynamic> _mapearItemResumo(Map<String, dynamic> item) {
    final tipoBackend = item['tipo']?.toString().toUpperCase() ?? '';
    final empresa = item['empresa'];
    final nomeEmpresa = empresa is Map<String, dynamic> ? empresa['nome']?.toString() ?? '' : empresa?.toString() ?? '';
    final acoesRaw = item['acoesDisponiveis'];
    final acoes = acoesRaw is List ? acoesRaw.map((acao) => _acaoBackendParaLabel(acao?.toString())).where((acao) => acao.isNotEmpty).toList() : <String>[];
    final tipo = tipoBackend == 'RECEBER' ? 'receber' : 'pagar';
    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'tipo': tipo,
      'descricao': item['descricao']?.toString() ?? 'Sem descrição',
      'contato': item['nomeContato']?.toString() ?? 'Não informado',
      'valor': _toDoubleDynamic(item['valor']),
      'vencimento': _formatarDataIsoParaBr(item['dataVencimento']?.toString()),
      'status': _statusBackendParaLabel(item['status']?.toString()),
      'origem': _origemBackendParaLabel(item['origem']?.toString()),
      'formaPagamento': _formaPagamentoBackendParaLabel(item['formaPagamento']?.toString()),
      'empresa': nomeEmpresa,
      'categoria': item['categoria']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'recorrente': item['recorrente'] == true,
      'historico': <String>['Lançamento consultado na agenda financeira.', if (item['recorrente'] == true) 'Lançamento recorrente.'],
      'acoes': acoes.isNotEmpty ? acoes : (tipo == 'receber' ? <String>['Receber', 'Registrar parcial', 'Detalhes'] : <String>['Pagar', 'Registrar parcial', 'Detalhes']),
    };
  }

  String _statusBackendParaLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PREVISTO': return 'Previsto';
      case 'PENDENTE': return 'Pendente';
      case 'VENCE_HOJE': return 'Vence hoje';
      case 'VENCIDO': return 'Vencido';
      case 'PAGO': return 'Pago';
      case 'RECEBIDO': return 'Recebido';
      case 'PARCIAL': return 'Parcial';
      case 'CANCELADO': return 'Cancelado';
      default: return 'Pendente';
    }
  }

  String _origemBackendParaLabel(String? origem) {
    switch ((origem ?? '').toUpperCase()) {
      case 'VENDA': return 'Venda';
      case 'ORDEM_SERVICO': return 'Ordem de serviço';
      case 'DESPESA_MANUAL': return 'Despesa manual';
      case 'COMPRA': return 'Compra';
      case 'PARCELA': return 'Parcela';
      case 'MOVIMENTACAO_CAIXA': return 'Movimentação de caixa';
      default: return 'Despesa manual';
    }
  }

  String _formaPagamentoBackendParaLabel(String? formaPagamento) {
    switch ((formaPagamento ?? '').toUpperCase()) {
      case 'PIX': return 'Pix';
      case 'BOLETO': return 'Boleto';
      case 'TRANSFERENCIA': return 'Transferência';
      case 'CARTAO_CREDITO': return 'Cartão de crédito';
      case 'CARTAO_DEBITO': return 'Cartão de débito';
      case 'DEBITO_AUTOMATICO': return 'Débito automático';
      case 'DINHEIRO': return 'Dinheiro';
      default: return 'Pix';
    }
  }

  String _acaoBackendParaLabel(String? acao) {
    switch ((acao ?? '').toUpperCase()) {
      case 'REGISTRAR_RECEBIMENTO':
      case 'RECEBER': return 'Receber';
      case 'REGISTRAR_PAGAMENTO':
      case 'PAGAR': return 'Pagar';
      case 'ENVIAR_COBRANCA': return 'Enviar cobrança';
      case 'REGISTRAR_PARCIAL': return 'Registrar parcial';
      case 'REAGENDAR_VENCIMENTO': return 'Reagendar';
      case 'CANCELAR': return 'Cancelar';
      case 'DETALHAR':
      case 'DETALHES': return 'Detalhes';
      default: return '';
    }
  }

  void _sincronizarLancamentoSelecionado() {
    final idAtual = _lancamentoSelecionado?['id']?.toString();
    final itens = _itensFiltrados;
    if (idAtual != null && idAtual.isNotEmpty) {
      for (final item in itens) {
        if (item['id']?.toString() == idAtual) {
          _lancamentoSelecionado = item;
          return;
        }
      }
    }
    _lancamentoSelecionado = itens.isEmpty ? null : itens.first;
  }

  List<String> _extrairEmpresas(List<Map<String, dynamic>> grupos) {
    final nomes = <String>{};
    for (final grupo in grupos) {
      final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
      for (final item in itens) {
        final nome = item['empresa']?.toString().trim() ?? '';
        if (nome.isNotEmpty) nomes.add(nome);
      }
    }
    final lista = nomes.toList()..sort();
    return lista;
  }

  DateTimeRange _intervaloPersonalizadoPadrao() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return DateTimeRange(start: DateTime(hoje.year, hoje.month, 1), end: DateTime(hoje.year, hoje.month + 1, 0));
  }

  DateTimeRange _intervaloPersonalizadoBuscaAtual() {
    final padrao = _intervaloPersonalizadoPadrao();
    return DateTimeRange(start: _dataInicioPersonalizadaBusca ?? _dataInicioPersonalizada ?? padrao.start, end: _dataFimPersonalizadaBusca ?? _dataFimPersonalizada ?? padrao.end);
  }

  bool _mesmaData(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _parseDataIso(dynamic value) {
    final texto = value?.toString().trim();
    if (texto == null || texto.isEmpty) return null;
    final data = DateTime.tryParse(texto);
    if (data == null) return null;
    return DateTime(data.year, data.month, data.day);
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

  String _labelPeriodoPersonalizado({bool busca = false}) {
    final inicio = busca ? _dataInicioPersonalizadaBusca : _dataInicioPersonalizada;
    final fim = busca ? _dataFimPersonalizadaBusca : _dataFimPersonalizada;
    if (inicio == null || fim == null) return 'Selecionar período';
    return '${_formatarDataBr(inicio)} até ${_formatarDataBr(fim)}';
  }

  String _formatarDataIsoParaBr(String? dataIso) {
    if (dataIso == null || dataIso.trim().isEmpty) return _formatarDataBr(DateTime.now());
    try {
      return _formatarDataBr(DateTime.parse(dataIso));
    } catch (_) {
      return _formatarDataBr(DateTime.now());
    }
  }

  String _formatarDataBr(DateTime data) => '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  double _toDoubleDynamic(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final texto = value.trim();
      final normalizado = texto.contains(',') && texto.contains('.') ? texto.replaceAll('.', '').replaceAll(',', '.') : texto.contains(',') ? texto.replaceAll(',', '.') : texto;
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
    for (int i = 0; i < inteiro.length; i++) {
      final indexInvertido = inteiro.length - i;
      buffer.write(inteiro[i]);
      if (indexInvertido > 1 && indexInvertido % 3 == 1) buffer.write('.');
    }
    return '${negativo ? '-R\$ ' : 'R\$ '}${buffer.toString()},$decimal';
  }

  String _formatarHora(DateTime? data) => data == null ? 'Ainda não consultado' : 'Atualizado às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  Color _corTipo(String tipo) => tipo == 'receber' ? const Color(0xFF0F9D58) : const Color(0xFFC66A00);

  Color _corStatus(String status) {
    switch (status) {
      case 'Vencido': return const Color(0xFFC62828);
      case 'Vence hoje': return const Color(0xFFEF6C00);
      case 'Pago':
      case 'Recebido': return const Color(0xFF2E7D32);
      case 'Parcial': return const Color(0xFF6A1B9A);
      case 'Cancelado': return const Color(0xFF616161);
      default: return const Color(0xFF1565C0);
    }
  }

  String _formaPagamentoLabelParaBackend(String label) {
    switch (label.toLowerCase()) {
      case 'boleto': return 'BOLETO';
      case 'transferência': return 'TRANSFERENCIA';
      case 'cartão de crédito': return 'CARTAO_CREDITO';
      case 'cartão de débito': return 'CARTAO_DEBITO';
      case 'débito automático': return 'DEBITO_AUTOMATICO';
      case 'dinheiro': return 'DINHEIRO';
      default: return 'PIX';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conteudo = LayoutBuilder(builder: (context, viewportConstraints) {
      final alturaDisponivelArea = viewportConstraints.maxHeight - 360;
      final alturaArea = alturaDisponivelArea < 420 ? 420.0 : alturaDisponivelArea;
      return SingleChildScrollView(
        controller: _scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: <Widget>[
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildToolbarFiltros(context),
              if (_isConsultando || _isExecutandoAcao) ...<Widget>[const SizedBox(height: 10), const LinearProgressIndicator(minHeight: 3)],
              const SizedBox(height: 16),
              _buildResumoCards(context),
              const SizedBox(height: 22),
              Align(alignment: Alignment.centerLeft, child: _buildAbas(context)),
              const SizedBox(height: 16),
              SizedBox(
                height: alturaArea,
                child: LayoutBuilder(builder: (context, constraints) {
                  final larguraEstreita = constraints.maxWidth < 1380;
                  if (larguraEstreita) return Column(children: <Widget>[Expanded(child: _buildAreaPrincipal(context)), const SizedBox(height: 14), SizedBox(height: constraints.maxHeight * 0.50, child: _buildPainelDetalheUnificado(context))]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[Expanded(flex: 8, child: _buildAreaPrincipal(context)), const SizedBox(width: 16), SizedBox(width: 420, child: _buildPainelDetalheUnificado(context))]);
                }),
              ),
            ]),
          ),
        ),
      );
    });
    return Scaffold(backgroundColor: theme.colorScheme.surfaceContainerLowest, floatingActionButton: FloatingActionButton.extended(onPressed: _isExecutandoAcao ? null : _onNovoLancamentoPressed, icon: const Icon(Icons.add), label: const Text('Novo lançamento')), body: SafeArea(child: conteudo));
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final periodoTexto = _periodoSelecionado == 'Personalizado' ? _labelPeriodoPersonalizado() : _periodoSelecionado;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: <Color>[theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.surfaceContainerHighest.withOpacity(0.75)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 16, spacing: 20, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Wrap(spacing: 14, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
              CircleAvatar(radius: 26, backgroundColor: theme.colorScheme.primary, child: const Icon(Icons.calendar_month_rounded, color: Colors.white)),
              Text('Agenda Financeira', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              _buildChipInfo(context, icon: Icons.store_mall_directory_outlined, text: _empresaSelecionada),
              _buildChipInfo(context, icon: Icons.tune_rounded, text: periodoTexto),
              _buildChipInfo(context, icon: Icons.access_time_rounded, text: _formatarHora(_ultimaConsultaEm)),
            ]),
            const SizedBox(height: 14),
            Text('Central operacional para acompanhar recebimentos, pagamentos, atrasos, previsões de caixa e ações imediatas do financeiro.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
          ]),
        ),
        Wrap(spacing: 12, runSpacing: 12, children: <Widget>[OutlinedButton.icon(onPressed: _voltarTelaAnterior, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Voltar')), FilledButton.icon(onPressed: _onNovoLancamentoPressed, icon: const Icon(Icons.add_card_rounded), label: const Text('Novo lançamento'))]),
      ]),
    );
  }

  Widget _buildChipInfo(BuildContext context, {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: theme.colorScheme.outlineVariant)), child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))]));
  }

  Widget _buildToolbarFiltros(BuildContext context) {
    final theme = Theme.of(context);
    final destaque = _temFiltrosPendentes;
    return Card(elevation: destaque ? 5 : 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: destaque ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: destaque ? 1.4 : 1)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
      _buildDropdownBox(context, label: 'Período', value: _periodoBusca, items: _periodos, onChanged: _onPeriodoBuscaChanged, width: 190),
      if (_periodoBusca == 'Personalizado') _buildBotaoPeriodoPersonalizado(context),
      _buildDropdownBox(context, label: 'Tipo', value: _tipoBusca, items: _tipos, onChanged: (value) => setState(() => _tipoBusca = value!), width: 160),
      _buildDropdownBox(context, label: 'Status', value: _statusBusca, items: _status, onChanged: (value) => setState(() => _statusBusca = value!), width: 160),
      _buildDropdownBox(context, label: 'Origem', value: _origemBusca, items: _origens, onChanged: (value) => setState(() => _origemBusca = value!), width: 190),
      _buildDropdownBox(context, label: 'Empresa', value: _empresaBusca, items: _empresas.map((e) => e['nome'] as String).toList(), onChanged: (value) => setState(() => _empresaBusca = value!), width: 190),
      FilterChip(selected: _somenteCriticosBusca, onSelected: (value) => setState(() => _somenteCriticosBusca = value), label: const Text('Somente críticos'), avatar: const Icon(Icons.priority_high_rounded, size: 18)),
      _buildBotaoBuscar(context),
    ])));
  }

  Widget _buildBotaoPeriodoPersonalizado(BuildContext context) => OutlinedButton.icon(onPressed: _isConsultando ? null : _selecionarPeriodoPersonalizadoBusca, icon: const Icon(Icons.date_range_rounded), label: Text(_labelPeriodoPersonalizado(busca: true)));
  Widget _buildBotaoBuscar(BuildContext context) => _temFiltrosPendentes ? FilledButton.icon(onPressed: _isConsultando ? null : _aplicarFiltrosPendentesEConsultar, icon: const Icon(Icons.manage_search_rounded), label: const Text('Buscar alterações')) : OutlinedButton.icon(onPressed: _isConsultando ? null : _aplicarFiltrosPendentesEConsultar, icon: const Icon(Icons.search_rounded), label: const Text('Buscar'));

  Widget _buildDropdownBox(BuildContext context, {required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged, required double width}) {
    final safeValue = items.contains(value) ? value : items.first;
    return SizedBox(width: width, child: DropdownButtonFormField<String>(value: safeValue, isExpanded: true, onChanged: _isConsultando ? null : onChanged, decoration: InputDecoration(labelText: label, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1))).toList()));
  }

  Widget _buildResumoCards(BuildContext context) {
    final cards = <Map<String, dynamic>>[
      <String, dynamic>{'titulo': 'Receber hoje', 'valor': _somarItensHoje('receber'), 'icone': Icons.south_west_rounded, 'ajuda': 'Entradas do dia, sem lançamentos cancelados.'},
      <String, dynamic>{'titulo': 'Pagar hoje', 'valor': _somarItensHoje('pagar'), 'icone': Icons.north_east_rounded, 'ajuda': 'Saídas do dia, sem lançamentos cancelados.'},
      <String, dynamic>{'titulo': 'Vencidos a receber', 'valor': _somarItensVencidos('receber'), 'icone': Icons.warning_amber_rounded, 'ajuda': 'Cobranças vencidas consideradas no período.'},
      <String, dynamic>{'titulo': 'Vencidos a pagar', 'valor': _somarItensVencidos('pagar'), 'icone': Icons.error_outline_rounded, 'ajuda': 'Pagamentos vencidos considerados no período.'},
      <String, dynamic>{'titulo': 'Saldo previsto', 'valor': _somarItens('receber') - _somarItens('pagar'), 'icone': Icons.query_stats_rounded, 'ajuda': 'Entradas menos saídas. Cancelados não entram na soma.'},
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width > 1500 ? (width - 48) / 4 : width > 1080 ? (width - 24) / 3 : width > 680 ? (width - 12) / 2 : width;
      return Wrap(spacing: 12, runSpacing: 12, children: cards.map((card) => SizedBox(width: cardWidth, child: _buildResumoCard(context, card))).toList());
    });
  }

  Widget _buildResumoCard(BuildContext context, Map<String, dynamic> card) {
    final theme = Theme.of(context);
    final valor = card['valor'] as double;
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: theme.colorScheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(18), child: Row(children: <Widget>[Container(width: 52, height: 52, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(18)), child: Icon(card['icone'] as IconData, color: theme.colorScheme.primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(card['titulo'] as String, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(_formatarMoeda(valor), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)), const SizedBox(height: 6), Text(card['ajuda'] as String, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))]))])));
  }

  Widget _buildAbas(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.colorScheme.outlineVariant)), child: Wrap(spacing: 6, runSpacing: 6, children: List.generate(_abas.length, (index) => ChoiceChip(selected: _abaSelecionada == index, label: Text(_abas[index]), onSelected: (_) => setState(() => _abaSelecionada = index)))));
  }

  Widget _buildAreaPrincipal(BuildContext context) {
    switch (_abaSelecionada) {
      case 1: return _buildCalendario(context);
      case 2: return _buildFluxoPrevisto(context);
      default: return _buildListaAgenda(context);
    }
  }

  List<Map<String, dynamic>> _itensPorGrupo(String grupo) {
    final grupoEncontrado = _gruposAgenda.firstWhere((g) => g['grupo'] == grupo, orElse: () => <String, dynamic>{'itens': <Map<String, dynamic>>[]});
    final idsFiltrados = _itensFiltrados.map((item) => item['id']).toSet();
    return (grupoEncontrado['itens'] as List).cast<Map<String, dynamic>>().where((item) => idsFiltrados.contains(item['id'])).toList();
  }

  Widget _buildListaAgenda(BuildContext context) {
    final gruposVisiveis = _gruposAgenda.where((grupo) => _itensPorGrupo(grupo['grupo'] as String).isNotEmpty).toList();
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(18), child: gruposVisiveis.isEmpty ? const Center(child: Text('Nenhum lançamento encontrado com os filtros aplicados.')) : ListView.separated(itemCount: gruposVisiveis.length, separatorBuilder: (_, __) => const SizedBox(height: 20), itemBuilder: (context, index) {
      final grupo = gruposVisiveis[index];
      final nome = grupo['grupo'] as String;
      final itens = _itensPorGrupo(nome);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(nome, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(grupo['descricao'] as String, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 14), ...itens.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildLancamentoCard(context, item)))]);
    })));
  }

  Widget _buildLancamentoCard(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final corTipo = _corTipo(item['tipo'] as String);
    final corStatus = _corStatus(item['status'] as String);
    final selecionado = _lancamentoSelecionado?['id'] == item['id'];
    final cancelado = item['status'] == 'Cancelado';
    return InkWell(onTap: () => setState(() => _lancamentoSelecionado = item), borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: cancelado ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.52) : selecionado ? theme.colorScheme.primary.withOpacity(0.05) : theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selecionado ? theme.colorScheme.primary : cancelado ? _corStatus('Cancelado').withOpacity(0.55) : theme.colorScheme.outlineVariant, width: selecionado ? 1.6 : 1)), child: LayoutBuilder(builder: (context, constraints) {
      final empilhar = constraints.maxWidth < 980;
      final conteudo = _buildLancamentoConteudo(context, item);
      final valor = _buildLancamentoValorEAcoes(context, item, cancelado ? _corStatus('Cancelado') : corTipo);
      if (empilhar) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[_buildLancamentoBadges(context, item, corTipo, corStatus), const SizedBox(height: 14), conteudo, const SizedBox(height: 14), valor]);
      return Column(children: <Widget>[_buildLancamentoBadges(context, item, corTipo, corStatus), const SizedBox(height: 14), Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: conteudo), const SizedBox(width: 18), SizedBox(width: 310, child: valor)])]);
    })));
  }

  Widget _buildLancamentoBadges(BuildContext context, Map<String, dynamic> item, Color corTipo, Color corStatus) {
    final theme = Theme.of(context);
    return Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: corTipo.withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(item['tipo'] == 'receber' ? Icons.south_west_rounded : Icons.north_east_rounded, size: 18, color: corTipo), const SizedBox(width: 8), Text(item['tipo'] == 'receber' ? 'Receber' : 'Pagar', style: TextStyle(fontWeight: FontWeight.w800, color: corTipo))])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: corStatus.withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Text(item['status'] as String, style: TextStyle(fontWeight: FontWeight.w800, color: corStatus))),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)), child: Text(item['origem'] as String, style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant))),
      if (item['recorrente'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.20))), child: Text('Recorrente', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary))),
    ]);
  }

  Widget _buildLancamentoConteudo(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(item['descricao'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 10), Wrap(spacing: 16, runSpacing: 10, children: <Widget>[_buildMiniInfo(context, Icons.person_outline, item['contato'] as String), _buildMiniInfo(context, Icons.event_outlined, 'Vence em ${item['vencimento']}'), _buildMiniInfo(context, Icons.credit_card_outlined, item['formaPagamento'] as String), _buildMiniInfo(context, Icons.category_outlined, item['categoria'] as String)]), const SizedBox(height: 12), Text(item['observacoes'] as String, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4))]);
  }

  Widget _buildLancamentoValorEAcoes(BuildContext context, Map<String, dynamic> item, Color corTipo) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[Text(_formatarMoeda(item['valor'] as double), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: corTipo)), const SizedBox(height: 12), Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: (item['acoes'] as List).take(3).map((acao) => OutlinedButton(onPressed: _isExecutandoAcao ? null : () => _executarAcaoLancamento(acao.toString(), item), child: Text(acao.toString()))).toList())]);
  }

  Widget _buildMiniInfo(BuildContext context, IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6), Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600))]);

  Widget _buildCalendario(BuildContext context) {
    final agrupado = <String, Map<String, dynamic>>{};
    for (final item in _itensFiltrados) {
      final data = item['vencimento']?.toString() ?? '-';
      final dia = agrupado.putIfAbsent(data, () => <String, dynamic>{'data': data, 'quantidade': 0, 'receber': 0.0, 'pagar': 0.0});
      dia['quantidade'] = (dia['quantidade'] as int) + 1;
      if (!_deveSomarLancamento(item)) continue;
      if (item['tipo'] == 'receber') {
        dia['receber'] = (dia['receber'] as double) + (item['valor'] as double);
      } else {
        dia['pagar'] = (dia['pagar'] as double) + (item['valor'] as double);
      }
    }
    final dias = agrupado.values.toList()..sort((a, b) => (a['data'] as String).compareTo(b['data'] as String));
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(18), child: dias.isEmpty ? const Center(child: Text('Nenhum dado de calendário no período.')) : ListView.separated(itemCount: dias.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) {
      final dia = dias[index];
      return ListTile(title: Text(dia['data'] as String), subtitle: Text('${dia['quantidade']} lançamento(s)'), trailing: Text('${_formatarMoeda(dia['receber'] as double)} / ${_formatarMoeda(dia['pagar'] as double)}'));
    })));
  }

  Widget _buildFluxoPrevisto(BuildContext context) {
    final entradas = _somarItens('receber');
    final saidas = _somarItens('pagar');
    final saldo = entradas - saidas;
    final theme = Theme.of(context);
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(18), child: ListView(children: <Widget>[Text('Fluxo previsto', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 16), Text('Entradas: ${_formatarMoeda(entradas)}'), const SizedBox(height: 8), Text('Saídas: ${_formatarMoeda(saidas)}'), const Divider(height: 28), Text('Saldo previsto: ${_formatarMoeda(saldo)}', style: TextStyle(fontWeight: FontWeight.w900, color: saldo >= 0 ? const Color(0xFF0F9D58) : const Color(0xFFC62828)))])));
  }

  Widget _buildPainelDetalheUnificado(BuildContext context) {
    final item = _lancamentoSelecionado;
    final theme = Theme.of(context);
    if (item == null) return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Selecione um lançamento para visualizar os detalhes.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)))));
    final corTipo = _corTipo(item['tipo'] as String);
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(18), child: ListView(children: <Widget>[Text('Detalhe do lançamento', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 20), Text(item['descricao'] as String, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 14), Text(_formatarMoeda(item['valor'] as double), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: corTipo)), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: <Widget>[FilledButton.icon(onPressed: _isConsultando ? null : () => _onEditarLancamentoPressed(itemBase: item), icon: const Icon(Icons.edit_outlined), label: const Text('Editar lançamento'))]), const SizedBox(height: 18), _buildLinhaDetalhe('Contato', item['contato'] as String), _buildLinhaDetalhe('Vencimento', item['vencimento'] as String), _buildLinhaDetalhe('Status', item['status'] as String), _buildLinhaDetalhe('Origem', item['origem'] as String), _buildLinhaDetalhe('Forma de pagamento', item['formaPagamento'] as String), _buildLinhaDetalhe('Empresa', item['empresa'] as String), _buildLinhaDetalhe('Categoria', item['categoria'] as String), const Divider(height: 28), Text('Observações', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(item['observacoes'] as String, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45))])));
  }

  Widget _buildLinhaDetalhe(String label, String valor) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[SizedBox(width: 150, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600))), Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)))]));
  }
}
