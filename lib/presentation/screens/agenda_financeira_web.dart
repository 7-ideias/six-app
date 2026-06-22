import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final AgendaFinanceiraLancamentoService _consultaService =
      AgendaFinanceiraLancamentoService();
  final ScrollController _mainScrollController = ScrollController();

  final List<String> _periodos = const [
    'Hoje',
    'Próximos 7 dias',
    'Este mês',
    'Próximo mês',
    'Personalizado',
  ];

  final List<String> _tipos = const ['Todos', 'Receber', 'Pagar'];

  final List<String> _statusDisponiveis = const [
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

  final List<String> _origens = const [
    'Todas',
    'Venda',
    'Ordem de serviço',
    'Despesa manual',
    'Compra',
    'Parcela',
    'Movimentação de caixa',
  ];

  final List<String> _abas = const ['Agenda', 'Calendário', 'Fluxo previsto'];

  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  String _origemSelecionada = 'Todas';
  String _empresaSelecionada = 'Todas';
  bool _mostrarSomenteCriticos = false;

  String _periodoBusca = 'Próximos 7 dias';
  String _tipoBusca = 'Todos';
  String _statusBusca = 'Todos';
  String _origemBusca = 'Todas';
  String _empresaBusca = 'Todas';
  bool _somenteCriticosBusca = false;

  bool _isConsultando = false;
  int _abaSelecionada = 0;
  DateTime? _ultimaConsultaEm;
  Map<String, dynamic>? _lancamentoSelecionado;

  final List<Map<String, dynamic>> _empresas = <Map<String, dynamic>>[
    <String, dynamic>{'id': 'all', 'nome': 'Todas'},
  ];
  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _calendarioAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _fluxoPrevistoAgenda =
      <Map<String, dynamic>>[];

  bool get _temFiltrosPendentes =>
      _periodoBusca != _periodoSelecionado ||
      _tipoBusca != _tipoSelecionado ||
      _statusBusca != _statusSelecionado ||
      _origemBusca != _origemSelecionada ||
      _empresaBusca != _empresaSelecionada ||
      _somenteCriticosBusca != _mostrarSomenteCriticos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarTela();
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
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
      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final periodo = _valorCacheValido(
        decoded['periodo'],
        _periodos,
        _periodoSelecionado,
      );
      final tipo = _valorCacheValido(decoded['tipo'], _tipos, _tipoSelecionado);
      final status = _valorCacheValido(
        decoded['status'],
        _statusDisponiveis,
        _statusSelecionado,
      );
      final origem = _valorCacheValido(
        decoded['origem'],
        _origens,
        _origemSelecionada,
      );
      final empresa = _valorCacheLivre(decoded['empresa'], _empresaSelecionada);
      final somenteCriticos =
          decoded['somenteCriticos'] is bool
              ? decoded['somenteCriticos'] as bool
              : _mostrarSomenteCriticos;

      if (!mounted) return;

      setState(() {
        _periodoSelecionado = periodo;
        _tipoSelecionado = tipo;
        _statusSelecionado = status;
        _origemSelecionada = origem;
        _empresaSelecionada = empresa;
        _mostrarSomenteCriticos = somenteCriticos;

        _periodoBusca = periodo;
        _tipoBusca = tipo;
        _statusBusca = status;
        _origemBusca = origem;
        _empresaBusca = empresa;
        _somenteCriticosBusca = somenteCriticos;
      });
    } catch (_) {
      // Cache inválido não deve impedir a abertura da agenda financeira.
    }
  }

  Future<void> _salvarFiltrosNoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _filtrosCacheKey,
        jsonEncode(<String, dynamic>{
          'periodo': _periodoSelecionado,
          'tipo': _tipoSelecionado,
          'status': _statusSelecionado,
          'origem': _origemSelecionada,
          'empresa': _empresaSelecionada,
          'somenteCriticos': _mostrarSomenteCriticos,
        }),
      );
    } catch (_) {
      // Falha no cache não deve bloquear a consulta financeira.
    }
  }

  String _valorCacheValido(
    dynamic value,
    List<String> valoresPermitidos,
    String fallback,
  ) {
    final texto = value?.toString().trim();
    if (texto == null || texto.isEmpty) return fallback;
    return valoresPermitidos.contains(texto) ? texto : fallback;
  }

  String _valorCacheLivre(dynamic value, String fallback) {
    final texto = value?.toString().trim();
    return texto == null || texto.isEmpty ? fallback : texto;
  }

  void _voltarTelaAnterior() {
    if (widget.embedded) {
      widget.onBack?.call();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
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

  Future<void> _onNovoLancamentoPressed() async {
    final empresasLancamento =
        _empresas
            .map((e) => e['nome'] as String)
            .where((nome) => nome != 'Todas')
            .toList();
    final empresas =
        empresasLancamento.isEmpty ? <String>['Empresa'] : empresasLancamento;

    final item = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada:
          _empresaSelecionada == 'Todas' ? empresas.first : _empresaSelecionada,
      empresas: empresas,
    );

    if (!mounted || item == null) {
      return;
    }

    await _consultarLancamentos(mostrarFeedback: true);
  }

  Future<void> _onEditarLancamentoPressed({
    Map<String, dynamic>? itemBase,
  }) async {
    final item = itemBase ?? _lancamentoSelecionado;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um lançamento para editar.')),
      );
      return;
    }

    final empresasLancamento =
        _empresas
            .map((e) => e['nome'] as String)
            .where((nome) => nome != 'Todas')
            .toList();
    final empresaAtual = item['empresa']?.toString().trim() ?? '';
    if (empresaAtual.isNotEmpty && !empresasLancamento.contains(empresaAtual)) {
      empresasLancamento.add(empresaAtual);
    }
    final empresas =
        empresasLancamento.isEmpty ? <String>['Empresa'] : empresasLancamento;

    final itemAtualizado = await showSubPainelLancamentoAgendaFinanceiraWeb(
      context,
      empresaSelecionada:
          empresaAtual.isNotEmpty ? empresaAtual : empresas.first,
      empresas: empresas,
      modoEdicao: true,
      lancamentoInicial: item,
    );

    if (!mounted || itemAtualizado == null) {
      return;
    }

    await _consultarLancamentos(mostrarFeedback: true);
  }

  void _marcarFiltroPendente(VoidCallback atualizacao) {
    setState(atualizacao);
  }

  Future<void> _aplicarFiltrosPendentesEConsultar() async {
    if (_isConsultando) {
      return;
    }

    setState(() {
      _periodoSelecionado = _periodoBusca;
      _tipoSelecionado = _tipoBusca;
      _statusSelecionado = _statusBusca;
      _origemSelecionada = _origemBusca;
      _empresaSelecionada = _empresaBusca;
      _mostrarSomenteCriticos = _somenteCriticosBusca;
    });

    await _consultarLancamentos(mostrarFeedback: true);
    await _salvarFiltrosNoCache();
  }

  Future<void> _consultarLancamentos({bool mostrarFeedback = false}) async {
    if (_isConsultando) {
      return;
    }

    setState(() => _isConsultando = true);

    try {
      final request = _buildConsultaRequest();
      final payload = await _consultaService.consultarLancamentos(request);

      if (!mounted) return;

      _aplicarConsultaBackend(payload);

      if (mostrarFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Consulta atualizada: ${_itensFiltrados.length} lançamento(s).',
            ),
          ),
        );
      }
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;

      if (mostrarFeedback) {
        final bool endpointNaoPublicado =
            e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              endpointNaoPublicado
                  ? 'Endpoint de consulta ainda não publicado. Exibindo dados já carregados.'
                  : 'Falha ao consultar lançamentos (${e.statusCode}). Exibindo dados já carregados.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (mostrarFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível consultar agora. Exibindo dados já carregados.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConsultando = false);
      }
    }
  }

  AgendaFinanceiraConsultaRequest _buildConsultaRequest() {
    return AgendaFinanceiraConsultaRequest(
      periodo: _periodoParaRequest(_periodoSelecionado),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo:
            _tipoSelecionado == 'Todos'
                ? 'TODOS'
                : _tipoSelecionado.toUpperCase(),
        status: _statusFiltroParaBackend(_statusSelecionado),
        origens: _origensFiltroParaBackend(_origemSelecionada),
        categorias: <String>[],
        formasPagamento: <String>[],
        clienteFornecedor: null,
        somenteCriticos: _mostrarSomenteCriticos,
      ),
      visaoSelecionada: _visaoSelecionadaParaBackend(),
    );
  }

  AgendaFinanceiraPeriodoRequest _periodoParaRequest(String periodo) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    switch (periodo) {
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
      case 'Personalizado':
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PERSONALIZADO',
          dataInicio: hoje,
          dataFim: hoje.add(const Duration(days: 7)),
        );
      default:
        return AgendaFinanceiraPeriodoRequest(
          modo: 'PROXIMOS_7_DIAS',
          dataInicio: hoje,
          dataFim: hoje.add(const Duration(days: 7)),
        );
    }
  }

  List<String> _statusFiltroParaBackend(String status) {
    switch (status) {
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

  List<String> _origensFiltroParaBackend(String origem) {
    switch (origem) {
      case 'Venda':
        return <String>['VENDA'];
      case 'Ordem de serviço':
        return <String>['ORDEM_SERVICO'];
      case 'Despesa manual':
        return <String>['DESPESA_MANUAL'];
      case 'Compra':
        return <String>['COMPRA'];
      case 'Parcela':
        return <String>['PARCELA'];
      case 'Movimentação de caixa':
        return <String>['MOVIMENTACAO_CAIXA'];
      default:
        return <String>[];
    }
  }

  String _visaoSelecionadaParaBackend() {
    switch (_abaSelecionada) {
      case 1:
        return 'CALENDARIO';
      case 2:
        return 'FLUXO_PREVISTO';
      default:
        return 'AGENDA';
    }
  }

  void _aplicarConsultaBackend(Map<String, dynamic> payload) {
    final novosGrupos = _mapearGruposAgenda(payload['gruposAgenda']);
    final novoCalendario = _mapearCalendario(payload['calendario']);
    final novoFluxo = _mapearFluxoPrevisto(payload['fluxoPrevisto']);
    final empresasResposta = _extrairEmpresas(novosGrupos);

    setState(() {
      _gruposAgenda
        ..clear()
        ..addAll(novosGrupos);
      _calendarioAgenda
        ..clear()
        ..addAll(novoCalendario);
      _fluxoPrevistoAgenda
        ..clear()
        ..addAll(novoFluxo);
      _empresas
        ..clear()
        ..add(<String, dynamic>{'id': 'all', 'nome': 'Todas'})
        ..addAll(
          empresasResposta.map(
            (nome) => <String, dynamic>{
              'id': nome.toLowerCase().replaceAll(' ', '-'),
              'nome': nome,
            },
          ),
        );

      if (!_empresas.any((e) => e['nome'] == _empresaSelecionada)) {
        _empresaSelecionada = 'Todas';
        _empresaBusca = 'Todas';
      }

      _ultimaConsultaEm = DateTime.now();
      _sincronizarLancamentoSelecionado();
    });
  }

  List<Map<String, dynamic>> _mapearGruposAgenda(dynamic gruposRaw) {
    if (gruposRaw is! List) {
      return <Map<String, dynamic>>[];
    }

    final grupos = <Map<String, dynamic>>[];
    for (final grupo in gruposRaw) {
      if (grupo is! Map<String, dynamic>) {
        continue;
      }

      final itensRaw = grupo['itens'];
      final itens =
          itensRaw is List
              ? itensRaw
                  .whereType<Map<String, dynamic>>()
                  .map(_mapearItemResumo)
                  .toList()
              : <Map<String, dynamic>>[];

      grupos.add(<String, dynamic>{
        'grupo': grupo['titulo']?.toString() ?? 'Lançamentos',
        'descricao':
            grupo['descricao']?.toString() ??
            'Lançamentos financeiros do período.',
        'itens': itens,
      });
    }

    return grupos;
  }

  List<Map<String, dynamic>> _mapearCalendario(dynamic calendarioRaw) {
    if (calendarioRaw is! List) {
      return <Map<String, dynamic>>[];
    }

    return calendarioRaw.whereType<Map<String, dynamic>>().map((dia) {
      return <String, dynamic>{
        'data': _formatarDataIsoParaBr(dia['data']?.toString()),
        'quantidadeLancamentos': _toIntDynamic(dia['quantidadeLancamentos']),
        'quantidadeCriticos': _toIntDynamic(dia['quantidadeCriticos']),
        'totalReceber': _toDoubleDynamic(dia['totalReceber']),
        'totalPagar': _toDoubleDynamic(dia['totalPagar']),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapearFluxoPrevisto(dynamic fluxoRaw) {
    if (fluxoRaw is! List) {
      return <Map<String, dynamic>>[];
    }

    return fluxoRaw.whereType<Map<String, dynamic>>().map((item) {
      return <String, dynamic>{
        'competencia': item['competencia']?.toString() ?? '',
        'totalEntradas': _toDoubleDynamic(item['totalEntradas']),
        'totalSaidas': _toDoubleDynamic(item['totalSaidas']),
        'saldoPrevisto': _toDoubleDynamic(item['saldoPrevisto']),
      };
    }).toList();
  }

  Map<String, dynamic> _mapearItemResumo(Map<String, dynamic> item) {
    final tipoBackend = item['tipo']?.toString().toUpperCase() ?? '';
    final empresa = item['empresa'];
    final nomeEmpresa =
        empresa is Map<String, dynamic>
            ? empresa['nome']?.toString() ?? ''
            : empresa?.toString() ?? '';

    final acoesRaw = item['acoesDisponiveis'];
    final acoes =
        acoesRaw is List
            ? acoesRaw
                .map((acao) => _acaoBackendParaLabel(acao?.toString()))
                .where((acao) => acao.isNotEmpty)
                .toList()
            : <String>[];
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
      'formaPagamento': _formaPagamentoBackendParaLabel(
        item['formaPagamento']?.toString(),
      ),
      'empresa': nomeEmpresa,
      'categoria': item['categoria']?.toString() ?? '',
      'responsavel': item['responsavel']?.toString() ?? '',
      'observacoes': item['observacaoResumida']?.toString() ?? '',
      'historico': <String>['Lançamento consultado na agenda financeira.'],
      'acoes':
          acoes.isNotEmpty
              ? acoes
              : (tipo == 'receber'
                  ? <String>['Receber', 'Detalhes']
                  : <String>['Pagar', 'Detalhes']),
    };
  }

  String _statusBackendParaLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PREVISTO':
        return 'Previsto';
      case 'PENDENTE':
        return 'Pendente';
      case 'VENCE_HOJE':
        return 'Vence hoje';
      case 'VENCIDO':
        return 'Vencido';
      case 'PAGO':
        return 'Pago';
      case 'RECEBIDO':
        return 'Recebido';
      case 'PARCIAL':
        return 'Parcial';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return 'Pendente';
    }
  }

  String _origemBackendParaLabel(String? origem) {
    switch ((origem ?? '').toUpperCase()) {
      case 'VENDA':
        return 'Venda';
      case 'ORDEM_SERVICO':
        return 'Ordem de serviço';
      case 'DESPESA_MANUAL':
        return 'Despesa manual';
      case 'COMPRA':
        return 'Compra';
      case 'PARCELA':
        return 'Parcela';
      case 'MOVIMENTACAO_CAIXA':
        return 'Movimentação de caixa';
      default:
        return 'Despesa manual';
    }
  }

  String _formaPagamentoBackendParaLabel(String? formaPagamento) {
    switch ((formaPagamento ?? '').toUpperCase()) {
      case 'PIX':
        return 'Pix';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'CARTAO_CREDITO':
        return 'Cartão de crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de débito';
      case 'DEBITO_AUTOMATICO':
        return 'Débito automático';
      case 'DINHEIRO':
        return 'Dinheiro';
      default:
        return 'Pix';
    }
  }

  String _acaoBackendParaLabel(String? acao) {
    switch ((acao ?? '').toUpperCase()) {
      case 'REGISTRAR_RECEBIMENTO':
      case 'RECEBER':
        return 'Receber';
      case 'REGISTRAR_PAGAMENTO':
      case 'PAGAR':
        return 'Pagar';
      case 'ENVIAR_COBRANCA':
        return 'Enviar cobrança';
      case 'REGISTRAR_PARCIAL':
        return 'Registrar parcial';
      case 'REAGENDAR_VENCIMENTO':
        return 'Reagendar';
      case 'CANCELAR':
        return 'Cancelar';
      case 'DETALHAR':
      case 'DETALHES':
        return 'Detalhes';
      default:
        return '';
    }
  }

  List<String> _extrairEmpresas(List<Map<String, dynamic>> grupos) {
    final nomes = <String>{};
    for (final grupo in grupos) {
      final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
      for (final item in itens) {
        final nome = item['empresa']?.toString().trim() ?? '';
        if (nome.isNotEmpty) {
          nomes.add(nome);
        }
      }
    }

    final lista = nomes.toList()..sort();
    return lista;
  }

  bool _deveSomarLancamento(Map<String, dynamic> item) {
    return item['status']?.toString() != 'Cancelado';
  }

  List<Map<String, dynamic>> get _itensFiltrados {
    return _gruposAgenda
        .expand(
          (grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>(),
        )
        .where((item) {
          final bateTipo =
              _tipoSelecionado == 'Todos' ||
              (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') ||
              (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');
          final bateStatus =
              _statusSelecionado == 'Todos' ||
              item['status'] == _statusSelecionado;
          final bateOrigem =
              _origemSelecionada == 'Todas' || item['origem'] == _origemSelecionada;
          final empresaDoItem = item['empresa']?.toString() ?? '';
          final bateEmpresa =
              _empresaSelecionada == 'Todas' ||
              empresaDoItem.isEmpty ||
              empresaDoItem == _empresaSelecionada;
          final bateCritico =
              !_mostrarSomenteCriticos ||
              item['status'] == 'Vencido' ||
              item['status'] == 'Vence hoje';

          return bateTipo &&
              bateStatus &&
              bateOrigem &&
              bateEmpresa &&
              bateCritico;
        })
        .toList();
  }

  List<Map<String, dynamic>> get _itensSomaveisFiltrados {
    return _itensFiltrados.where(_deveSomarLancamento).toList();
  }

  double _somarItens(String tipo) {
    return _itensSomaveisFiltrados
        .where((item) => item['tipo'] == tipo)
        .fold<double>(0, (soma, item) => soma + (item['valor'] as double));
  }

  double _somarItensHoje(String tipo) {
    final hoje = _formatarDataBr(DateTime.now());
    return _itensSomaveisFiltrados
        .where((item) => item['tipo'] == tipo && item['vencimento'] == hoje)
        .fold<double>(0, (soma, item) => soma + (item['valor'] as double));
  }

  double _somarItensVencidos(String tipo) {
    final hoje = DateTime.now();
    final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
    return _itensSomaveisFiltrados.where((item) {
      if (item['tipo'] != tipo) return false;
      final vencimento = _parseDataBr(item['vencimento']?.toString());
      return vencimento != null && vencimento.isBefore(dataHoje);
    }).fold<double>(0, (soma, item) => soma + (item['valor'] as double));
  }

  int get _quantidadeCanceladosVisiveis {
    return _itensFiltrados
        .where((item) => item['status'] == 'Cancelado')
        .length;
  }

  List<Map<String, dynamic>> get _calendarioFinanceiroCalculado {
    final agrupadoPorData = <String, Map<String, dynamic>>{};

    for (final item in _itensFiltrados) {
      final data = item['vencimento']?.toString() ?? '-';
      final dia = agrupadoPorData.putIfAbsent(
        data,
        () => <String, dynamic>{
          'data': data,
          'quantidadeLancamentos': 0,
          'quantidadeCriticos': 0,
          'totalReceber': 0.0,
          'totalPagar': 0.0,
        },
      );

      dia['quantidadeLancamentos'] =
          (dia['quantidadeLancamentos'] as int? ?? 0) + 1;
      if (item['status'] == 'Vencido' || item['status'] == 'Vence hoje') {
        dia['quantidadeCriticos'] =
            (dia['quantidadeCriticos'] as int? ?? 0) + 1;
      }

      if (!_deveSomarLancamento(item)) {
        continue;
      }

      final valor = item['valor'] as double? ?? 0;
      if (item['tipo'] == 'receber') {
        dia['totalReceber'] = (dia['totalReceber'] as double? ?? 0) + valor;
      } else {
        dia['totalPagar'] = (dia['totalPagar'] as double? ?? 0) + valor;
      }
    }

    final dias = agrupadoPorData.values.toList();
    dias.sort((a, b) {
      final dataA = _parseDataBr(a['data']?.toString());
      final dataB = _parseDataBr(b['data']?.toString());
      if (dataA == null && dataB == null) return 0;
      if (dataA == null) return 1;
      if (dataB == null) return -1;
      return dataA.compareTo(dataB);
    });
    return dias;
  }

  List<Map<String, dynamic>> get _fluxoPrevistoCalculado {
    final agrupadoPorCompetencia = <String, Map<String, dynamic>>{};

    for (final item in _itensFiltrados) {
      final competencia = _competenciaDoLancamento(item);
      final fluxo = agrupadoPorCompetencia.putIfAbsent(
        competencia,
        () => <String, dynamic>{
          'competencia': competencia,
          'totalEntradas': 0.0,
          'totalSaidas': 0.0,
          'saldoPrevisto': 0.0,
        },
      );

      if (!_deveSomarLancamento(item)) {
        continue;
      }

      final valor = item['valor'] as double? ?? 0;
      if (item['tipo'] == 'receber') {
        fluxo['totalEntradas'] =
            (fluxo['totalEntradas'] as double? ?? 0) + valor;
      } else {
        fluxo['totalSaidas'] = (fluxo['totalSaidas'] as double? ?? 0) + valor;
      }
      fluxo['saldoPrevisto'] =
          (fluxo['totalEntradas'] as double? ?? 0) -
          (fluxo['totalSaidas'] as double? ?? 0);
    }

    final fluxos = agrupadoPorCompetencia.values.toList();
    fluxos.sort(
      (a, b) =>
          (a['competencia']?.toString() ?? '').compareTo(
            b['competencia']?.toString() ?? '',
          ),
    );
    return fluxos;
  }

  String _competenciaDoLancamento(Map<String, dynamic> item) {
    final data = _parseDataBr(item['vencimento']?.toString());
    if (data == null) {
      return 'Sem competência';
    }

    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$ano-$mes';
  }

  List<Map<String, dynamic>> _buildCardsResumoData() {
    final receberHoje = _somarItensHoje('receber');
    final pagarHoje = _somarItensHoje('pagar');
    final vencidosReceber = _somarItensVencidos('receber');
    final vencidosPagar = _somarItensVencidos('pagar');
    final totalReceber = _somarItens('receber');
    final totalPagar = _somarItens('pagar');
    final saldo = totalReceber - totalPagar;
    final qtdCancelados = _quantidadeCanceladosVisiveis;
    final observacaoCancelados =
        qtdCancelados > 0
            ? ' $qtdCancelados cancelado(s) exibido(s), sem compor valores.'
            : '';

    return <Map<String, dynamic>>[
      {
        'titulo': 'Receber hoje',
        'valor': receberHoje,
        'icone': Icons.south_west_rounded,
        'ajuda': 'Entradas do dia, sem lançamentos cancelados.$observacaoCancelados',
      },
      {
        'titulo': 'Pagar hoje',
        'valor': pagarHoje,
        'icone': Icons.north_east_rounded,
        'ajuda': 'Saídas do dia, sem lançamentos cancelados.$observacaoCancelados',
      },
      {
        'titulo': 'Vencidos a receber',
        'valor': vencidosReceber,
        'icone': Icons.warning_amber_rounded,
        'ajuda': 'Cobranças vencidas consideradas no período.',
      },
      {
        'titulo': 'Vencidos a pagar',
        'valor': vencidosPagar,
        'icone': Icons.error_outline_rounded,
        'ajuda': 'Pagamentos vencidos considerados no período.',
      },
      {
        'titulo': 'Saldo previsto',
        'valor': saldo,
        'icone': Icons.query_stats_rounded,
        'ajuda': 'Entradas menos saídas. Cancelados não entram na soma.',
      },
    ];
  }

  List<Map<String, dynamic>> _itensPorGrupo(String grupo) {
    final grupoEncontrado = _gruposAgenda.firstWhere(
      (g) => g['grupo'] == grupo,
      orElse: () => {'itens': <Map<String, dynamic>>[]},
    );

    final idsFiltrados = _itensFiltrados.map((item) => item['id']).toSet();
    return (grupoEncontrado['itens'] as List)
        .cast<Map<String, dynamic>>()
        .where((item) => idsFiltrados.contains(item['id']))
        .toList();
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
    if (dataIso == null || dataIso.trim().isEmpty) {
      return _formatarDataBr(DateTime.now());
    }

    try {
      return _formatarDataBr(DateTime.parse(dataIso));
    } catch (_) {
      return _formatarDataBr(DateTime.now());
    }
  }

  String _formatarDataBr(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  double _toDoubleDynamic(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final texto = value.trim();
      final normalizado =
          texto.contains(',') && texto.contains('.')
              ? texto.replaceAll('.', '').replaceAll(',', '.')
              : texto.contains(',')
              ? texto.replaceAll(',', '.')
              : texto;
      return double.tryParse(normalizado) ?? 0;
    }

    return 0;
  }

  int _toIntDynamic(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
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
      if (indexInvertido > 1 && indexInvertido % 3 == 1) {
        buffer.write('.');
      }
    }

    final prefixo = negativo ? '-R\$ ' : 'R\$ ';
    return '$prefixo${buffer.toString()},$decimal';
  }

  String _formatarHora(DateTime? data) {
    if (data == null) {
      return 'Ainda não consultado';
    }
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return 'Atualizado às $hora:$minuto';
  }

  Color _corTipo(String tipo) {
    return tipo == 'receber'
        ? const Color(0xFF0F9D58)
        : const Color(0xFFC66A00);
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Vencido':
        return const Color(0xFFC62828);
      case 'Vence hoje':
        return const Color(0xFFEF6C00);
      case 'Pago':
      case 'Recebido':
        return const Color(0xFF2E7D32);
      case 'Parcial':
        return const Color(0xFF6A1B9A);
      case 'Cancelado':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Agenda Financeira',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _buildChipInfo(
                      context,
                      icon: Icons.store_mall_directory_outlined,
                      text: _empresaSelecionada,
                    ),
                    _buildChipInfo(
                      context,
                      icon: Icons.tune_rounded,
                      text: _periodoSelecionado,
                    ),
                    _buildChipInfo(
                      context,
                      icon: Icons.access_time_rounded,
                      text: _formatarHora(_ultimaConsultaEm),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Central operacional para acompanhar recebimentos, pagamentos, atrasos, previsões de caixa e ações imediatas do financeiro.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _voltarTelaAnterior,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _onNovoLancamentoPressed,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Novo lançamento'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(170, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipInfo(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResumoCards(BuildContext context) {
    final cards = _buildCardsResumoData();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth =
            width > 1500
                ? (width - 48) / 4
                : width > 1080
                ? (width - 24) / 3
                : width > 680
                ? (width - 12) / 2
                : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              cards.map((card) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildResumoCard(context, card),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildResumoCard(BuildContext context, Map<String, dynamic> card) {
    final theme = Theme.of(context);
    final valor = card['valor'] as double;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                card['icone'] as IconData,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['titulo'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarMoeda(valor),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card['ajuda'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildToolbarFiltros(BuildContext context) {
    final theme = Theme.of(context);
    final destaque = _temFiltrosPendentes;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow:
            destaque
                ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
                : const [],
      ),
      child: Card(
        elevation: destaque ? 5 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color:
                destaque
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
            width: destaque ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child:
                    destaque
                        ? _buildFiltrosPendentesBanner(context)
                        : const SizedBox.shrink(),
              ),
              if (destaque) const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final campoLargo = width > 1600 ? 220.0 : 190.0;
                  final campoMedio = width > 1600 ? 180.0 : 160.0;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildDropdownBox(
                        context,
                        label: 'Período',
                        value: _periodoBusca,
                        items: _periodos,
                        onChanged:
                            (value) => _marcarFiltroPendente(
                              () => _periodoBusca = value!,
                            ),
                        width: campoLargo,
                      ),
                      _buildDropdownBox(
                        context,
                        label: 'Tipo',
                        value: _tipoBusca,
                        items: _tipos,
                        onChanged:
                            (value) => _marcarFiltroPendente(
                              () => _tipoBusca = value!,
                            ),
                        width: campoMedio,
                      ),
                      _buildDropdownBox(
                        context,
                        label: 'Status',
                        value: _statusBusca,
                        items: _statusDisponiveis,
                        onChanged:
                            (value) => _marcarFiltroPendente(
                              () => _statusBusca = value!,
                            ),
                        width: campoMedio,
                      ),
                      _buildDropdownBox(
                        context,
                        label: 'Origem',
                        value: _origemBusca,
                        items: _origens,
                        onChanged:
                            (value) => _marcarFiltroPendente(
                              () => _origemBusca = value!,
                            ),
                        width: campoLargo,
                      ),
                      _buildDropdownBox(
                        context,
                        label: 'Empresa',
                        value: _empresaBusca,
                        items: _empresas.map((e) => e['nome'] as String).toList(),
                        onChanged:
                            (value) => _marcarFiltroPendente(
                              () => _empresaBusca = value!,
                            ),
                        width: campoLargo,
                      ),
                      FilterChip(
                        selected: _somenteCriticosBusca,
                        onSelected:
                            (value) => _marcarFiltroPendente(
                              () => _somenteCriticosBusca = value,
                            ),
                        label: const Text('Somente críticos'),
                        avatar: const Icon(Icons.priority_high_rounded, size: 18),
                      ),
                      _buildBotaoBuscar(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltrosPendentesBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('filtros-pendentes'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Filtros alterados. Clique em Buscar alterações para atualizar os resultados.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoBuscar(BuildContext context) {
    final label = _temFiltrosPendentes ? 'Buscar alterações' : 'Buscar';
    final icon =
        _temFiltrosPendentes ? Icons.manage_search_rounded : Icons.search_rounded;
    final onPressed = _isConsultando ? null : _aplicarFiltrosPendentesEConsultar;

    if (_temFiltrosPendentes) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(180, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDropdownBox(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double width,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        onChanged: _isConsultando ? null : onChanged,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items:
            items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildAbas(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(_abas.length, (index) {
          final selecionada = _abaSelecionada == index;
          return ChoiceChip(
            selected: selecionada,
            label: Text(_abas[index]),
            onSelected:
                (_) => setState(() {
                  _abaSelecionada = index;
                }),
          );
        }),
      ),
    );
  }

  Widget _buildAreaPrincipal(BuildContext context) {
    switch (_abaSelecionada) {
      case 1:
        return _buildCalendario(context);
      case 2:
        return _buildFluxoPrevisto(context);
      default:
        return _buildListaAgenda(context);
    }
  }

  Widget _buildListaAgenda(BuildContext context) {
    final gruposVisiveis =
        _gruposAgenda
            .where(
              (grupo) => _itensPorGrupo(grupo['grupo'] as String).isNotEmpty,
            )
            .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child:
            gruposVisiveis.isEmpty
                ? const Center(
                  child: Text(
                    'Nenhum lançamento encontrado com os filtros aplicados.',
                  ),
                )
                : ListView.separated(
                  itemCount: gruposVisiveis.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final grupo = gruposVisiveis[index];
                    final nome = grupo['grupo'] as String;
                    final itens = _itensPorGrupo(nome);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          grupo['descricao'] as String,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...itens.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLancamentoCard(context, item),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildLancamentoCard(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final corTipo = _corTipo(item['tipo'] as String);
    final corStatus = _corStatus(item['status'] as String);
    final selecionado = _lancamentoSelecionado?['id'] == item['id'];
    final cancelado = item['status'] == 'Cancelado';

    return InkWell(
      onTap: () => setState(() => _lancamentoSelecionado = item),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              selecionado
                  ? theme.colorScheme.primary.withOpacity(0.05)
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selecionado
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
            width: selecionado ? 1.6 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final empilhar = constraints.maxWidth < 980;
            final conteudo = _buildLancamentoConteudo(context, item);
            final valor = _buildLancamentoValorEAcoes(
              context,
              item,
              cancelado ? _corStatus('Cancelado') : corTipo,
            );

            if (empilhar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLancamentoBadges(context, item, corTipo, corStatus),
                  const SizedBox(height: 14),
                  conteudo,
                  const SizedBox(height: 14),
                  valor,
                ],
              );
            }

            return Column(
              children: [
                _buildLancamentoBadges(context, item, corTipo, corStatus),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: conteudo),
                    const SizedBox(width: 18),
                    SizedBox(width: 280, child: valor),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLancamentoBadges(
    BuildContext context,
    Map<String, dynamic> item,
    Color corTipo,
    Color corStatus,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: corTipo.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item['tipo'] == 'receber'
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 18,
                color: corTipo,
              ),
              const SizedBox(width: 8),
              Text(
                item['tipo'] == 'receber' ? 'Receber' : 'Pagar',
                style: TextStyle(fontWeight: FontWeight.w800, color: corTipo),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: corStatus.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item['status'] as String,
            style: TextStyle(fontWeight: FontWeight.w800, color: corStatus),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item['origem'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (item['status'] == 'Cancelado')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'Não soma nos totais',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLancamentoConteudo(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['descricao'] as String,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _buildMiniInfo(context, Icons.person_outline, item['contato'] as String),
            _buildMiniInfo(
              context,
              Icons.event_outlined,
              'Vence em ${item['vencimento']}',
            ),
            _buildMiniInfo(
              context,
              Icons.credit_card_outlined,
              item['formaPagamento'] as String,
            ),
            _buildMiniInfo(
              context,
              Icons.category_outlined,
              item['categoria'] as String,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item['observacoes'] as String,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLancamentoValorEAcoes(
    BuildContext context,
    Map<String, dynamic> item,
    Color corTipo,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatarMoeda(item['valor'] as double),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: corTipo,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children:
              (item['acoes'] as List).take(3).map((acao) {
                return OutlinedButton(
                  onPressed:
                      () => _executarAcaoLancamento(acao.toString(), item),
                  child: Text(acao.toString()),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _executarAcaoLancamento(String acao, Map<String, dynamic> item) {
    final comando = acao.trim().toLowerCase();

    if (comando == 'detalhes' || comando == 'detalhar') {
      setState(() => _lancamentoSelecionado = item);
      return;
    }

    if (comando == 'editar' || comando == 'editar lançamento') {
      _onEditarLancamentoPressed(itemBase: item);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ação "$acao" será integrada no backend.')),
    );
  }

  Widget _buildMiniInfo(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendario(BuildContext context) {
    final dias = _calendarioFinanceiroCalculado;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendário financeiro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumo por dia com volume de lançamentos e criticidade. Lançamentos cancelados aparecem na contagem, mas não entram nos valores.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  dias.isEmpty
                      ? const Center(
                        child: Text('Nenhum dado de calendário no período.'),
                      )
                      : ListView.separated(
                        itemCount: dias.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final dia = dias[index];
                          final bool critico =
                              (dia['quantidadeCriticos'] as int? ?? 0) > 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  critico
                                      ? const Color(0xFFFFF2F0)
                                      : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    critico
                                        ? const Color(0xFFE57373)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    dia['data']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${dia['quantidadeLancamentos']} lançamento(s)',
                                  ),
                                ),
                                Text(
                                  _formatarMoeda(dia['totalReceber'] as double),
                                  style: const TextStyle(
                                    color: Color(0xFF0F9D58),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatarMoeda(dia['totalPagar'] as double),
                                  style: const TextStyle(
                                    color: Color(0xFFC66A00),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
  }

  Widget _buildFluxoPrevisto(BuildContext context) {
    final barras = _fluxoPrevistoCalculado;
    final double maiorValorCalculado =
        barras.isEmpty
            ? 1
            : barras.fold<double>(
              0,
              (maxAtual, barra) => [
                maxAtual,
                (barra['totalEntradas'] as double? ?? 0),
                (barra['totalSaidas'] as double? ?? 0),
              ].reduce((a, b) => a > b ? a : b),
            );
    final double maxValor = maiorValorCalculado <= 0 ? 1 : maiorValorCalculado;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text(
              'Fluxo previsto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumo visual das entradas e saídas esperadas para apoiar decisões de caixa. Lançamentos cancelados não entram nos valores.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            if (barras.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text('Nenhum dado de fluxo previsto no período.'),
                ),
              ),
            ...barras.map((barra) {
              final entra = barra['totalEntradas'] as double? ?? 0;
              final sai = barra['totalSaidas'] as double? ?? 0;
              final saldo = barra['saldoPrevisto'] as double? ?? (entra - sai);

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barra['competencia']?.toString() ?? '-',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _buildBarraFluxo(
                        context,
                        label: 'Entradas',
                        valor: entra,
                        maxValor: maxValor,
                        color: const Color(0xFF0F9D58),
                      ),
                      const SizedBox(height: 10),
                      _buildBarraFluxo(
                        context,
                        label: 'Saídas',
                        valor: sai,
                        maxValor: maxValor,
                        color: const Color(0xFFC66A00),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Saldo previsto: ${_formatarMoeda(saldo)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color:
                              saldo >= 0
                                  ? const Color(0xFF0F9D58)
                                  : const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraFluxo(
    BuildContext context, {
    required String label,
    required double valor,
    required double maxValor,
    required Color color,
  }) {
    final double ratio = (valor / maxValor).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label • ${_formatarMoeda(valor)}'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 14,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPainelDetalheUnificado(BuildContext context) {
    return _buildDetalheLancamento(context, _lancamentoSelecionado);
  }

  Widget _buildDetalheLancamento(
    BuildContext context,
    Map<String, dynamic>? item,
  ) {
    final theme = Theme.of(context);

    if (item == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Center(
          child: Text('Selecione um lançamento para ver detalhes.'),
        ),
      );
    }

    final corTipo = _corTipo(item['tipo'] as String);
    final cancelado = item['status'] == 'Cancelado';
    final totalReceber = _somarItens('receber');
    final totalPagar = _somarItens('pagar');
    final saldo = totalReceber - totalPagar;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text(
              'Detalhe do lançamento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item['descricao'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatarMoeda(item['valor'] as double),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cancelado ? _corStatus('Cancelado') : corTipo,
              ),
            ),
            if (cancelado) ...[
              const SizedBox(height: 8),
              Text(
                'Este lançamento está cancelado e não compõe os totais financeiros.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed:
                      _isConsultando
                          ? null
                          : () => _onEditarLancamentoPressed(itemBase: item),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar lançamento'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildLinhaDetalhe('Contato', item['contato'] as String),
            _buildLinhaDetalhe('Vencimento', item['vencimento'] as String),
            _buildLinhaDetalhe('Status', item['status'] as String),
            _buildLinhaDetalhe('Origem', item['origem'] as String),
            _buildLinhaDetalhe(
              'Forma de pagamento',
              item['formaPagamento'] as String,
            ),
            _buildLinhaDetalhe('Empresa', item['empresa'] as String),
            _buildLinhaDetalhe('Categoria', item['categoria'] as String),
            _buildLinhaDetalhe('Responsável', item['responsavel'] as String),
            const Divider(height: 28),
            Text(
              'Resumo do período',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _buildIndicadorLateral('Total a receber', totalReceber),
            _buildIndicadorLateral('Total a pagar', totalPagar),
            _buildIndicadorLateral('Saldo previsto', saldo, destaque: true),
            if (_quantidadeCanceladosVisiveis > 0)
              _buildIndicadorTexto(
                'Cancelados fora da soma',
                '$_quantidadeCanceladosVisiveis lançamento(s)',
              ),
            const Divider(height: 28),
            Text(
              'Observações',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['observacoes'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const Divider(height: 28),
            Text(
              'Histórico',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...((item['historico'] as List).map(
              (evento) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(evento.toString())),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorLateral(
    String label,
    double valor, {
    bool destaque = false,
  }) {
    final color =
        destaque
            ? (valor >= 0 ? const Color(0xFF0F9D58) : const Color(0xFFC62828))
            : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatarMoeda(valor),
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorTexto(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget conteudo = LayoutBuilder(
      builder: (context, viewportConstraints) {
        final alturaDisponivelArea = viewportConstraints.maxHeight - 360;
        final alturaArea =
            alturaDisponivelArea < 420 ? 420.0 : alturaDisponivelArea;

        return SingleChildScrollView(
          controller: _mainScrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildResumoCards(context),
                  const SizedBox(height: 22),
                  _buildToolbarFiltros(context),
                  if (_isConsultando) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildAbas(context),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: alturaArea,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final larguraEstreita = constraints.maxWidth < 1380;

                        if (larguraEstreita) {
                          return Column(
                            children: [
                              Expanded(child: _buildAreaPrincipal(context)),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: constraints.maxHeight * 0.50,
                                child: _buildPainelDetalheUnificado(context),
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 8,
                              child: _buildAreaPrincipal(context),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 420,
                              child: _buildPainelDetalheUnificado(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onNovoLancamentoPressed,
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
      body: SafeArea(child: conteudo),
    );
  }
}
