import 'package:flutter/material.dart';
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

class _AgendaFinanceiraWebState extends State<AgendaFinanceiraWeb>
    with SingleTickerProviderStateMixin {
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

  void _onAtualizarPressed() {
    _consultarLancamentos(mostrarFeedback: true);
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

    await _consultarLancamentos();
  }

  Future<void> _onEditarLancamentoPressed({
    Map<String, dynamic>? itemBase,
  }) async {
    final item =
        itemBase ?? _lancamentoSelecionado ?? _itensFiltrados.firstOrNull;
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

  final ScrollController _mainScrollController = ScrollController();
  final AgendaFinanceiraLancamentoService _consultaService =
      AgendaFinanceiraLancamentoService();
  late final AnimationController _fabMenuController;

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

  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  String _origemSelecionada = 'Todas';
  String _empresaSelecionada = 'Todas';
  bool _mostrarSomenteCriticos = false;

  int _abaSelecionada = 0;
  Map<String, dynamic>? _lancamentoSelecionado;
  double _resumoCardsProgress = 0.0;
  int _resumoAtualizacaoVersao = 0;
  bool _isConsultando = false;
  Map<String, double> _resumoValoresBaseAnimacao = <String, double>{};

  final List<String> _abas = const ['Agenda', 'Calendário', 'Fluxo previsto'];

  final List<Map<String, dynamic>> _empresas = <Map<String, dynamic>>[
    <String, dynamic>{'id': 'all', 'nome': 'Todas'},
  ];

  final List<Map<String, dynamic>> _cardsResumo = <Map<String, dynamic>>[
    <String, dynamic>{
      'titulo': 'Receber hoje',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.south_west_rounded,
      'ajuda': 'Sem dados carregados.',
    },
    <String, dynamic>{
      'titulo': 'Pagar hoje',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.north_east_rounded,
      'ajuda': 'Sem dados carregados.',
    },
    <String, dynamic>{
      'titulo': 'Vencidos a receber',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.warning_amber_rounded,
      'ajuda': 'Sem dados carregados.',
    },
    <String, dynamic>{
      'titulo': 'Vencidos a pagar',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.error_outline_rounded,
      'ajuda': 'Sem dados carregados.',
    },
    <String, dynamic>{
      'titulo': 'Saldo previsto da semana',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.query_stats_rounded,
      'ajuda': 'Sem dados carregados.',
    },
    <String, dynamic>{
      'titulo': 'Saldo previsto do mês',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.account_balance_wallet_outlined,
      'ajuda': 'Sem dados carregados.',
    },
    <String, dynamic>{
      'titulo': 'Apenas Confirmados',
      'valor': 'R\$ 0,00',
      'valorNumerico': 0.0,
      'icone': Icons.verified_rounded,
      'ajuda': 'Sem dados carregados.',
    },
  ];

  final List<Map<String, dynamic>> _gruposAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _calendarioAgenda = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _fluxoPrevistoAgenda =
      <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _sincronizarLancamentoSelecionado();
    _mainScrollController.addListener(_onMainScroll);
    _fabMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consultarLancamentos();
    });
  }

  @override
  void dispose() {
    _fabMenuController.dispose();
    _mainScrollController.removeListener(_onMainScroll);
    _mainScrollController.dispose();
    super.dispose();
  }

  void _sincronizarLancamentoSelecionado() {
    final String? idSelecionadoAtual =
        _lancamentoSelecionado?['id']?.toString();

    if (idSelecionadoAtual != null && idSelecionadoAtual.isNotEmpty) {
      for (final grupo in _gruposAgenda) {
        final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
        final encontrado = itens.firstWhere(
          (item) => item['id']?.toString() == idSelecionadoAtual,
          orElse: () => <String, dynamic>{},
        );
        if (encontrado.isNotEmpty) {
          _lancamentoSelecionado = encontrado;
          return;
        }
      }
    }

    for (final grupo in _gruposAgenda) {
      final itens = (grupo['itens'] as List).cast<Map<String, dynamic>>();
      if (itens.isNotEmpty) {
        _lancamentoSelecionado = itens.first;
        return;
      }
    }

    _lancamentoSelecionado = null;
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
                  ? 'Endpoint de consulta ainda não publicado. Exibindo dados locais.'
                  : 'Falha ao consultar lançamentos (${e.statusCode}). Exibindo dados locais.',
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
              'Não foi possível consultar agora. Exibindo dados locais.',
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
    final periodo = _periodoParaRequest(_periodoSelecionado);

    return AgendaFinanceiraConsultaRequest(
      periodo: periodo,
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo:
            _tipoSelecionado == 'Todos'
                ? 'TODOS'
                : _tipoSelecionado.toUpperCase(),
        status: _statusFiltroParaBackend(),
        origens: _origensFiltroParaBackend(),
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

  List<String> _statusFiltroParaBackend() {
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

  List<String> _origensFiltroParaBackend() {
    switch (_origemSelecionada) {
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
    final valoresBaseAnimacao = _mapaValoresResumo(_cardsResumo);
    final novosCardsResumo = _mapearResumoCards(
      payload['resumo'] is Map<String, dynamic>
          ? payload['resumo'] as Map<String, dynamic>
          : null,
      payload['confirmados'] is Map<String, dynamic>
          ? payload['confirmados'] as Map<String, dynamic>
          : null,
    );
    final novosGruposAgenda = _mapearGruposAgenda(payload['gruposAgenda']);
    final novoCalendario = _mapearCalendario(payload['calendario']);
    final novoFluxo = _mapearFluxoPrevisto(payload['fluxoPrevisto']);
    final empresasResposta = _extrairEmpresas(novosGruposAgenda);

    setState(() {
      _resumoValoresBaseAnimacao = valoresBaseAnimacao;
      _resumoAtualizacaoVersao++;

      _cardsResumo
        ..clear()
        ..addAll(novosCardsResumo);

      _gruposAgenda
        ..clear()
        ..addAll(novosGruposAgenda);

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
          empresasResposta
              .map(
                (nome) => <String, dynamic>{
                  'id': nome.toLowerCase().replaceAll(' ', '-'),
                  'nome': nome,
                },
              )
              .toList(),
        );

      if (!_empresas.any((e) => e['nome'] == _empresaSelecionada)) {
        _empresaSelecionada = 'Todas';
      }

      _sincronizarLancamentoSelecionado();
    });
  }

  List<Map<String, dynamic>> _mapearResumoCards(
    Map<String, dynamic>? resumo,
    Map<String, dynamic>? confirmados,
  ) {
    final dados = resumo ?? <String, dynamic>{};
    final dadosConfirmados = confirmados ?? <String, dynamic>{};

    final receberHoje = _toDoubleDynamic(dados['receberHoje']);
    final pagarHoje = _toDoubleDynamic(dados['pagarHoje']);
    final vencidosReceber = _toDoubleDynamic(dados['vencidosReceber']);
    final vencidosPagar = _toDoubleDynamic(dados['vencidosPagar']);
    final saldoSemana = _toDoubleDynamic(dados['saldoPrevistoSemana']);
    final saldoMes = _toDoubleDynamic(dados['saldoPrevistoMes']);
    final qtdHoje = _toIntDynamic(dados['quantidadeLancamentosHoje']);
    final qtdVencidos = _toIntDynamic(dados['quantidadeVencidos']);
    final qtdConfirmados = _toIntDynamic(
      dadosConfirmados['quantidadeOperacoes'],
    );
    final saldoConfirmado = _toDoubleDynamic(
      dadosConfirmados['saldoConfirmado'],
    );
    final totalRecebidoConfirmado = _toDoubleDynamic(
      dadosConfirmados['totalRecebidoConfirmado'],
    );
    final totalPagoConfirmado = _toDoubleDynamic(
      dadosConfirmados['totalPagoConfirmado'],
    );

    return <Map<String, dynamic>>[
      {
        'titulo': 'Receber hoje',
        'valor': _formatarMoeda(receberHoje),
        'valorNumerico': receberHoje,
        'icone': Icons.south_west_rounded,
        'ajuda': '$qtdHoje lançamento(s) previstos para entrada no dia.',
      },
      {
        'titulo': 'Pagar hoje',
        'valor': _formatarMoeda(pagarHoje),
        'valorNumerico': pagarHoje,
        'icone': Icons.north_east_rounded,
        'ajuda': '$qtdHoje lançamento(s) previstos para saída no dia.',
      },
      {
        'titulo': 'Vencidos a receber',
        'valor': _formatarMoeda(vencidosReceber),
        'valorNumerico': vencidosReceber,
        'icone': Icons.warning_amber_rounded,
        'ajuda': '$qtdVencidos lançamento(s) em atraso para cobrança.',
      },
      {
        'titulo': 'Vencidos a pagar',
        'valor': _formatarMoeda(vencidosPagar),
        'valorNumerico': vencidosPagar,
        'icone': Icons.error_outline_rounded,
        'ajuda': '$qtdVencidos lançamento(s) em atraso para pagamento.',
      },
      {
        'titulo': 'Saldo previsto da semana',
        'valor': _formatarMoeda(saldoSemana),
        'valorNumerico': saldoSemana,
        'icone': Icons.query_stats_rounded,
        'ajuda': 'Entradas previstas menos saídas previstas.',
      },
      {
        'titulo': 'Saldo previsto do mês',
        'valor': _formatarMoeda(saldoMes),
        'valorNumerico': saldoMes,
        'icone': Icons.account_balance_wallet_outlined,
        'ajuda': 'Indicador consolidado do período atual.',
      },
      {
        'titulo': 'Apenas Confirmados',
        'valor': _formatarMoeda(saldoConfirmado),
        'valorNumerico': saldoConfirmado,
        'icone': Icons.verified_rounded,
        'ajuda':
            '$qtdConfirmados operação(ões) quitada(s). '
            'Recebido: ${_formatarMoeda(totalRecebidoConfirmado)} | '
            'Pago: ${_formatarMoeda(totalPagoConfirmado)}',
      },
    ];
  }

  Map<String, double> _mapaValoresResumo(List<Map<String, dynamic>> cards) {
    final mapa = <String, double>{};
    for (final card in cards) {
      final titulo = card['titulo']?.toString().trim() ?? '';
      if (titulo.isEmpty) {
        continue;
      }
      mapa[titulo] = _toDoubleDynamic(card['valorNumerico'] ?? card['valor']);
    }
    return mapa;
  }

  List<Map<String, dynamic>> _mapearGruposAgenda(dynamic gruposRaw) {
    if (gruposRaw is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> grupos = <Map<String, dynamic>>[];

    for (final grupo in gruposRaw) {
      if (grupo is! Map<String, dynamic>) {
        continue;
      }

      final itensRaw = grupo['itens'];
      final List<Map<String, dynamic>> itens =
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

  List<String> _extrairEmpresas(List<Map<String, dynamic>> grupos) {
    final Set<String> nomes = <String>{};

    for (final grupo in grupos) {
      final itens =
          (grupo['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final item in itens) {
        final nome = item['empresa']?.toString() ?? '';
        if (nome.trim().isNotEmpty) {
          nomes.add(nome.trim());
        }
      }
    }

    final lista = nomes.toList()..sort();
    return lista;
  }

  Map<String, dynamic> _mapearItemResumo(Map<String, dynamic> item) {
    final tipoBackend = item['tipo']?.toString().toUpperCase() ?? '';
    final empresa = item['empresa'];
    final nomeEmpresa =
        empresa is Map<String, dynamic>
            ? empresa['nome']?.toString() ?? ''
            : '';

    final acoesRaw = item['acoesDisponiveis'];
    final List<String> acoes =
        acoesRaw is List
            ? acoesRaw
                .map((acao) => _acaoBackendParaLabel(acao?.toString()))
                .where((acao) => acao.isNotEmpty)
                .toList()
            : <String>[];

    return <String, dynamic>{
      'id': item['idLancamento']?.toString() ?? '',
      'tipo': tipoBackend == 'RECEBER' ? 'receber' : 'pagar',
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
              : (tipoBackend == 'RECEBER'
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

  String _formatarDataIsoParaBr(String? dataIso) {
    if (dataIso == null || dataIso.trim().isEmpty) {
      return _formatarDataBr(DateTime.now());
    }

    try {
      final data = DateTime.parse(dataIso);
      return _formatarDataBr(data);
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

  void _alternarMenuFab() {
    if (_fabMenuController.isCompleted) {
      _fabMenuController.reverse();
      return;
    }
    _fabMenuController.forward();
  }

  void _executarAcaoFab(VoidCallback acao) {
    acao();
    _fabMenuController.reverse();
  }

  void _onMainScroll() {
    if (!_mainScrollController.hasClients) return;
    if (_mainScrollController.positions.length != 1) return;

    final novoProgresso = (_mainScrollController.offset / 180).clamp(0.0, 1.0);

    if ((novoProgresso - _resumoCardsProgress).abs() < 0.02) return;
    setState(() => _resumoCardsProgress = novoProgresso);
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
              _origemSelecionada == 'Todas' ||
              item['origem'] == _origemSelecionada;

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

  List<Map<String, dynamic>> _itensPorGrupo(String grupo) {
    final grupoEncontrado = _gruposAgenda.firstWhere(
      (g) => g['grupo'] == grupo,
      orElse: () => {'itens': <Map<String, dynamic>>[]},
    );

    return (grupoEncontrado['itens'] as List)
        .cast<Map<String, dynamic>>()
        .where(
          (item) =>
              _itensFiltrados.any((filtrado) => filtrado['id'] == item['id']),
        )
        .toList();
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
              _buildHeaderAction(
                context,
                icon: Icons.add_card_rounded,
                label: 'Novo lançamento',
                onPressed: _onNovoLancamentoPressed,
              ),
              _buildHeaderAction(
                context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'Exportar PDF',
              ),
              _buildHeaderAction(
                context,
                icon: Icons.notifications_active_outlined,
                label: 'Cobranças',
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

  Widget _buildHeaderAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(170, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildResumoCards(BuildContext context) {
    final mostrarLinhaUnica = _resumoCardsProgress > 0.30;
    final double alturaReservada = mostrarLinhaUnica ? 126 : 220;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(minHeight: alturaReservada),
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child:
            mostrarLinhaUnica
                ? _buildResumoCardsLinhaUnica(context)
                : _buildResumoCardsGrade(context),
      ),
    );
  }

  Widget _buildResumoCardsGrade(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('resumo-cards-grade'),
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth =
            width > 1500
                ? (width - 40) / 3
                : width > 1000
                ? (width - 24) / 2
                : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              _cardsResumo.map((card) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildResumoCard(context, card),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildResumoCardsLinhaUnica(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('resumo-cards-linha-unica'),
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth =
            width > 1600
                ? 250.0
                : width > 1200
                ? 220.0
                : 200.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_cardsResumo.length, (index) {
              final card = _cardsResumo[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _cardsResumo.length - 1 ? 0 : 12,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildResumoCard(context, card),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildResumoCard(BuildContext context, Map<String, dynamic> card) {
    final theme = Theme.of(context);
    final titulo = card['titulo'] as String;
    final valorAtual = _toDoubleDynamic(card['valorNumerico'] ?? card['valor']);
    final valorInicial = _resumoValoresBaseAnimacao[titulo] ?? valorAtual;
    final ajuda = card['ajuda']?.toString() ?? '';

    return TweenAnimationBuilder<double>(
      key: ValueKey('resumo-card-pulse-$titulo-$_resumoAtualizacaoVersao'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, progresso, _) {
        final destaque = (1 - progresso).clamp(0.0, 1.0);
        final escala = 1 + (0.012 * destaque);
        final elevacao = 2 + (2.2 * destaque);
        final corBorda = theme.colorScheme.primary.withValues(
          alpha: 0.08 + (0.14 * destaque),
        );
        final corSombra = theme.colorScheme.primary.withValues(
          alpha: 0.04 + (0.10 * destaque),
        );

        return Transform.scale(
          scale: escala,
          child: Card(
            elevation: elevacao,
            shadowColor: corSombra,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: corBorda),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
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
                          titulo,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          key: ValueKey(
                            'resumo-card-valor-$titulo-$_resumoAtualizacaoVersao',
                          ),
                          tween: Tween<double>(
                            begin: valorInicial,
                            end: valorAtual,
                          ),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, valorAnimado, _) {
                            return Text(
                              _formatarMoeda(valorAnimado),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ajuda,
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
          ),
        );
      },
    );
  }

  Widget _buildToolbarFiltros(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: LayoutBuilder(
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
                  value: _periodoSelecionado,
                  items: _periodos,
                  onChanged:
                      (value) => setState(() => _periodoSelecionado = value!),
                  width: campoLargo,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Tipo',
                  value: _tipoSelecionado,
                  items: _tipos,
                  onChanged:
                      (value) => setState(() => _tipoSelecionado = value!),
                  width: campoMedio,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Status',
                  value: _statusSelecionado,
                  items: _statusDisponiveis,
                  onChanged:
                      (value) => setState(() => _statusSelecionado = value!),
                  width: campoMedio,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Origem',
                  value: _origemSelecionada,
                  items: _origens,
                  onChanged:
                      (value) => setState(() => _origemSelecionada = value!),
                  width: campoLargo,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Empresa',
                  value: _empresaSelecionada,
                  items: _empresas.map((e) => e['nome'] as String).toList(),
                  onChanged:
                      (value) => setState(() => _empresaSelecionada = value!),
                  width: campoLargo,
                ),
                FilterChip(
                  selected: _mostrarSomenteCriticos,
                  onSelected:
                      (value) =>
                          setState(() => _mostrarSomenteCriticos = value),
                  label: const Text('Somente críticos'),
                  avatar: const Icon(Icons.priority_high_rounded, size: 18),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _isConsultando
                          ? null
                          : () => _consultarLancamentos(mostrarFeedback: true),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Buscar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        onChanged: onChanged,
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
            onSelected: (_) => setState(() => _abaSelecionada = index),
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
                    'Nenhum lançamento encontrado com os filtros atuais.',
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

            if (empilhar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLancamentoBadges(context, item, corTipo, corStatus),
                  const SizedBox(height: 14),
                  _buildLancamentoConteudo(context, item),
                  const SizedBox(height: 14),
                  _buildLancamentoValorEAcoes(context, item, corTipo),
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
                    Expanded(child: _buildLancamentoConteudo(context, item)),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 280,
                      child: _buildLancamentoValorEAcoes(
                        context,
                        item,
                        corTipo,
                      ),
                    ),
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
            _buildMiniInfo(
              context,
              Icons.person_outline,
              item['contato'] as String,
            ),
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
          'R\$ ${(item['valor'] as double).toStringAsFixed(2)}',
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumo por dia com volume de lançamentos e criticidade.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _calendarioAgenda.isEmpty
                      ? const Center(
                        child: Text('Nenhum dado de calendário no período.'),
                      )
                      : ListView.separated(
                        itemCount: _calendarioAgenda.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final dia = _calendarioAgenda[index];
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
    final barras = _fluxoPrevistoAgenda;
    final double maxValor =
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text(
              'Fluxo previsto',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumo visual das entradas e saídas esperadas para apoiar decisões de caixa.',
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
                        'Saldo previsto: R\$ ${saldo.toStringAsFixed(2)}',
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
        Text('$label • R\$ ${valor.toStringAsFixed(2)}'),
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
    final item = _lancamentoSelecionado ?? _itensFiltrados.firstOrNull;
    return _buildDetalheLancamento(context, item);
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
    final totalReceber = _itensFiltrados
        .where((i) => i['tipo'] == 'receber')
        .fold<double>(0, (soma, i) => soma + (i['valor'] as double));
    final totalPagar = _itensFiltrados
        .where((i) => i['tipo'] == 'pagar')
        .fold<double>(0, (soma, i) => soma + (i['valor'] as double));
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
              'R\$ ${(item['valor'] as double).toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: corTipo,
              ),
            ),
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
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir (em breve)'),
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
              'Ações rápidas',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  (item['acoes'] as List).map((acao) {
                    return OutlinedButton(
                      onPressed:
                          () => _executarAcaoLancamento(acao.toString(), item),
                      child: Text(acao.toString()),
                    );
                  }).toList(),
            ),
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
            _buildIndicadorTexto('Alertas financeiros', '2 cobranças críticas'),
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
            const Divider(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Abrir origem'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.attach_file_outlined),
                  label: const Text('Comprovante'),
                ),
              ],
            ),
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
            'R\$ ${valor.toStringAsFixed(2)}',
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

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        floatingActionButton: _buildFloatingActions(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(child: conteudo),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(child: conteudo),
    );
  }

  Widget _buildFloatingActions() {
    final itens = <
      ({String heroTag, IconData icon, String label, VoidCallback onPressed})
    >[
      (
        heroTag: 'fab-voltar-agenda-financeira',
        icon: Icons.arrow_back_rounded,
        label: 'Voltar',
        onPressed: _voltarTelaAnterior,
      ),
      (
        heroTag: 'fab-novo-lancamento-agenda-financeira',
        icon: Icons.add_rounded,
        label: 'Novo lançamento',
        onPressed: _onNovoLancamentoPressed,
      ),
      (
        heroTag: 'fab-atualizar-agenda-financeira',
        icon: Icons.refresh_rounded,
        label: 'Atualizar',
        onPressed: _onAtualizarPressed,
      ),
    ];

    const double espacoVertical = 72;
    const double alturaBase = 56;

    return SizedBox(
      width: 260,
      height: alturaBase + (itens.length * espacoVertical) + 12,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ...List<Widget>.generate(itens.length, (index) {
            final item = itens[index];
            final inicio = index * 0.12;
            final fim = (inicio + 0.60).clamp(0.0, 1.0);
            final animacao = CurvedAnimation(
              parent: _fabMenuController,
              curve: Interval(inicio, fim, curve: Curves.easeOutCubic),
              reverseCurve: Curves.easeInCubic,
            );

            final deslocamentoBase = (index + 1) * espacoVertical;

            return AnimatedBuilder(
              animation: _fabMenuController,
              builder: (context, _) {
                final visivel = _fabMenuController.value > 0.01;
                return Positioned(
                  right: 0,
                  bottom: deslocamentoBase * animacao.value,
                  child: IgnorePointer(
                    ignoring: !visivel,
                    child: Opacity(
                      opacity: animacao.value,
                      child: Transform.scale(
                        scale: 0.92 + (0.08 * animacao.value),
                        alignment: Alignment.bottomRight,
                        child: FloatingActionButton.extended(
                          heroTag: item.heroTag,
                          onPressed: () => _executarAcaoFab(item.onPressed),
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: 'fab-menu-agenda-financeira',
              onPressed: _alternarMenuFab,
              child: RotationTransition(
                turns: Tween<double>(begin: 0.0, end: 0.125).animate(
                  CurvedAnimation(
                    parent: _fabMenuController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull on List<Map<String, dynamic>> {
  Map<String, dynamic>? get firstOrNull => isEmpty ? null : first;
}
