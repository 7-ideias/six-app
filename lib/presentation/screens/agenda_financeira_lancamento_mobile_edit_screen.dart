import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';

class AgendaFinanceiraLancamentoMobileEditScreen extends StatefulWidget {
  const AgendaFinanceiraLancamentoMobileEditScreen({
    super.key,
    required this.lancamento,
  });

  final Map<String, dynamic> lancamento;

  @override
  State<AgendaFinanceiraLancamentoMobileEditScreen> createState() =>
      _AgendaFinanceiraLancamentoMobileEditScreenState();
}

class _AgendaFinanceiraLancamentoMobileEditScreenState
    extends State<AgendaFinanceiraLancamentoMobileEditScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _softBlueColor = Color(0xFFEFF6FF);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AgendaFinanceiraLancamentoService _service = AgendaFinanceiraLancamentoService();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _documentoFiscalController = TextEditingController();
  final TextEditingController _centroCustoController = TextEditingController();

  final Map<String, String> _backendPorDescricaoFormaPagamento = <String, String>{
    'Pix': 'PIX',
    'Boleto': 'BOLETO',
    'Transferência': 'TRANSFERENCIA',
    'Cartão de crédito': 'CARTAO_CREDITO',
    'Cartão Crédito': 'CARTAO_CREDITO',
    'Cartão de débito': 'CARTAO_DEBITO',
    'Cartão Débito': 'CARTAO_DEBITO',
    'Débito automático': 'DEBITO_AUTOMATICO',
    'Dinheiro': 'DINHEIRO',
  };

  static const List<String> _tipos = <String>['Pagar', 'Receber'];
  static const List<String> _status = <String>[
    'Previsto',
    'Pendente',
    'Vence hoje',
    'Vencido',
    'Pago',
    'Recebido',
    'Parcial',
    'Cancelado',
  ];
  static const List<String> _origens = <String>[
    'Venda',
    'Ordem de serviço',
    'Despesa manual',
    'Compra',
    'Parcela',
    'Movimentação de caixa',
  ];
  static const List<String> _formasPagamentoPadrao = <String>[
    'Pix',
    'Boleto',
    'Transferência',
    'Cartão de crédito',
    'Cartão de débito',
    'Débito automático',
    'Dinheiro',
  ];

  String _idLancamento = '';
  String _uuidOperacaoApp = '';
  String _tipoSelecionado = 'Pagar';
  String _statusSelecionado = 'Pendente';
  String _origemSelecionada = 'Despesa manual';
  String _formaPagamentoSelecionada = 'Pix';
  String _empresa = 'Empresa';
  String? _idContato;
  String? _idCliente;
  String? _idFornecedor;
  String? _nomeCliente;
  String? _nomeFornecedor;

  DateTime _dataOperacao = DateTime.now();
  DateTime _dataVencimento = DateTime.now();
  DateTime _dataCompetencia = DateTime.now();

  bool _salvando = false;
  bool _carregandoDetalhe = false;
  bool _carregandoTiposRecebimento = false;
  bool _statusQuitada = false;
  double _valorConfirmado = 0;
  double _valorRestante = 0;
  Map<String, dynamic> _detalhe = <String, dynamic>{};
  List<String> _formasPagamento = List<String>.from(_formasPagamentoPadrao);

  @override
  void initState() {
    super.initState();
    _preencherComItem(widget.lancamento);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait(<Future<void>>[
        _carregarDetalhe(),
        _carregarTiposRecebimentoAtivos(),
      ]);
    });
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _contatoController.dispose();
    _categoriaController.dispose();
    _responsavelController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    _referenciaController.dispose();
    _documentoFiscalController.dispose();
    _centroCustoController.dispose();
    super.dispose();
  }

  void _preencherComItem(Map<String, dynamic> item) {
    _idLancamento = item['id']?.toString() ?? '';
    _uuidOperacaoApp = item['uuidOperacaoApp']?.toString() ?? _idLancamento;

    final String tipo = item['tipo']?.toString().toLowerCase() ?? '';
    _tipoSelecionado = tipo == 'receber' ? 'Receber' : 'Pagar';

    final String status = _statusLabel(item['status']?.toString());
    if (_status.contains(status)) _statusSelecionado = status;

    _origemSelecionada = _origemLabel(item['origem']?.toString(), _tipoSelecionado);
    _empresa = _texto(item['empresa'], fallback: 'Empresa');
    _formaPagamentoSelecionada = _formaPagamentoLabel(item['formaPagamento']?.toString());
    if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
      _formasPagamento = <String>[_formaPagamentoSelecionada, ..._formasPagamento];
    }

    _valorConfirmado = _toDouble(item['valorConfirmado']);
    _valorRestante = _toDouble(item['valorRestante']);
    _statusQuitada = _statusEstaQuitada(_statusSelecionado, _valorConfirmado, _valorRestante);

    final dynamic valorOriginal = item['valorOriginal'] ?? item['valorTotalOperacao'] ?? item['valorTotal'] ?? item['valor'];
    _descricaoController.text = _texto(item['descricao']);
    _contatoController.text = _texto(item['contato']);
    _categoriaController.text = _texto(item['categoria']);
    _responsavelController.text = _texto(item['responsavel']);
    _valorController.text = _formatarValorParaCampo(valorOriginal);
    _observacoesController.text = _texto(item['observacoes']);
    _referenciaController.text = _texto(item['referenciaExterna']);
    _documentoFiscalController.text = _texto(item['documentoFiscal']);
    _centroCustoController.text = _texto(item['centroDeCusto']);
    _idContato = item['idContato']?.toString();

    _dataVencimento = _parseData(item['vencimento'], fallback: _dataVencimento);
    _dataOperacao = _parseData(item['dataOperacao'], fallback: _dataVencimento);
    _dataCompetencia = _parseData(item['dataCompetencia'], fallback: _dataVencimento);
  }

  Future<void> _carregarDetalhe() async {
    if (_idLancamento.trim().isEmpty) return;
    setState(() => _carregandoDetalhe = true);
    try {
      final Map<String, dynamic> detalhe = await _service.buscarDetalheLancamento(_idLancamento);
      if (!mounted || detalhe.isEmpty) return;
      setState(() {
        _detalhe = detalhe;
        _preencherComDetalhe(detalhe);
      });
    } catch (_) {
      // Mantém os dados da listagem quando o detalhe não carregar.
    } finally {
      if (mounted) setState(() => _carregandoDetalhe = false);
    }
  }

  void _preencherComDetalhe(Map<String, dynamic> detalhe) {
    _idLancamento = _texto(detalhe['idLancamento'], fallback: _idLancamento);
    _uuidOperacaoApp = _uuidOperacaoApp.trim().isNotEmpty ? _uuidOperacaoApp : _idLancamento;

    final String tipo = _tipoLabel(detalhe['tipo']?.toString(), _tipoSelecionado);
    if (_tipos.contains(tipo)) _tipoSelecionado = tipo;

    final String status = _statusLabel(detalhe['status']?.toString());
    if (_status.contains(status)) _statusSelecionado = status;

    _descricaoController.text = _texto(detalhe['descricao'], fallback: _descricaoController.text);
    _valorController.text = _formatarValorParaCampo(
      detalhe['valorOriginal'] ?? _valorController.text,
    );
    _valorConfirmado = _toDouble(detalhe['valorPagoRecebido'] ?? _valorConfirmado);
    _valorRestante = _toDouble(detalhe['valorAberto'] ?? _valorRestante);
    _statusQuitada = _statusEstaQuitada(_statusSelecionado, _valorConfirmado, _valorRestante);

    _dataCompetencia = _parseData(detalhe['dataCompetencia'], fallback: _dataCompetencia);
    _dataVencimento = _parseData(detalhe['dataVencimento'], fallback: _dataVencimento);
    _dataOperacao = _parseData(detalhe['dataOperacao'], fallback: _dataOperacao);

    _formaPagamentoSelecionada = _formaPagamentoLabel(
      detalhe['formaPagamento']?.toString() ?? _formaPagamentoSelecionada,
    );
    if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
      _formasPagamento = <String>[_formaPagamentoSelecionada, ..._formasPagamento];
    }

    final Map<String, dynamic> contato = _mapa(detalhe['contato']);
    _contatoController.text = _texto(contato['nome'], fallback: _contatoController.text);
    _idContato = _texto(contato['id'], fallback: _idContato ?? '');
    final String contatoTipo = _texto(contato['tipo']).toUpperCase();
    if (contatoTipo == 'CLIENTE') {
      _idCliente = _idContato;
      _nomeCliente = _contatoController.text.trim();
      _idFornecedor = null;
      _nomeFornecedor = null;
    } else if (contatoTipo == 'FORNECEDOR') {
      _idFornecedor = _idContato;
      _nomeFornecedor = _contatoController.text.trim();
      _idCliente = null;
      _nomeCliente = null;
    }

    final Map<String, dynamic> categoria = _mapa(detalhe['categoria']);
    _categoriaController.text = _texto(
      categoria['nome'],
      fallback: _texto(categoria['descricao'], fallback: _categoriaController.text),
    );

    final Map<String, dynamic> empresa = _mapa(detalhe['empresa']);
    _empresa = _texto(empresa['nome'], fallback: _empresa);

    final Map<String, dynamic> origem = _mapa(detalhe['origem']);
    _origemSelecionada = _origemLabel(_texto(origem['tipo'], fallback: _origemSelecionada), _tipoSelecionado);
    _referenciaController.text = _texto(origem['id'], fallback: _referenciaController.text);

    final Map<String, dynamic> responsavel = _mapa(detalhe['responsavel']);
    _responsavelController.text = _texto(responsavel['nome'], fallback: _responsavelController.text);
    _observacoesController.text = _texto(detalhe['observacoes'], fallback: _observacoesController.text);
  }

  Future<void> _carregarTiposRecebimentoAtivos() async {
    setState(() => _carregandoTiposRecebimento = true);
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<String> formas = _montarFormasPagamentoAtivas(informacoes.tiposRecebimento);
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasPagamento = formas;
        if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
          _formasPagamento = <String>[_formaPagamentoSelecionada, ..._formasPagamento];
        }
      });
    } catch (_) {
      // Mantém os valores padrão para não bloquear a edição se o endpoint falhar.
    } finally {
      if (mounted) setState(() => _carregandoTiposRecebimento = false);
    }
  }

  List<String> _montarFormasPagamentoAtivas(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos = tipos
        .where((TiposRecebimento tipo) => tipo.ativo)
        .toList()
      ..sort(
        (TiposRecebimento a, TiposRecebimento b) =>
            a.ordemExibicao.compareTo(b.ordemExibicao),
      );

    final List<String> descricoes = <String>[];
    final Map<String, String> backendAtualizado =
        Map<String, String>.from(_backendPorDescricaoFormaPagamento);

    for (final TiposRecebimento tipo in ativos) {
      final String backend = _backendFormaPagamentoPorCodigoTipo(tipo.codigoTipo) ??
          _backendFormaPagamentoPorDescricao(tipo.descricaoExibicao);
      final String descricao = tipo.descricaoExibicao.trim().isNotEmpty
          ? tipo.descricaoExibicao.trim()
          : _formaPagamentoLabel(backend);
      if (descricao.trim().isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      backendAtualizado[descricao] = backend;
    }

    if (descricoes.isNotEmpty) {
      _backendPorDescricaoFormaPagamento
        ..clear()
        ..addAll(backendAtualizado);
    }
    return descricoes;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final double valorTotal = _toDouble(_valorController.text);
    if (valorTotal <= 0) {
      _mostrarSnack('Informe um valor maior que zero.');
      return;
    }

    final LancamentoAgendaFinanceiraRequest request = _buildRequest(valorTotal);
    setState(() => _salvando = true);
    try {
      final LancamentoAgendaFinanceiraResponse response = await _service.editarLancamento(
        _idLancamento.trim().isEmpty ? request.uuidOperacaoApp : _idLancamento,
        request,
      );
      if (!mounted) return;
      _mostrarSnack('Lançamento atualizado com sucesso.');
      Navigator.of(context).pop(request.toAgendaItem(idFallback: response.id.isEmpty ? _idLancamento : response.id));
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      _mostrarSnack('Erro ao atualizar lançamento (${e.statusCode}).');
    } catch (_) {
      if (!mounted) return;
      _mostrarSnack('Não foi possível atualizar o lançamento.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  LancamentoAgendaFinanceiraRequest _buildRequest(double valorTotal) {
    final bool isReceber = _tipoSelecionado == 'Receber';
    final String tipoOperacao = isReceber ? 'RECEBER' : 'PAGAR';
    final String origem = _origemParaBackend(_origemSelecionada, _tipoSelecionado);
    final String formaPagamento = _formaPagamentoParaBackend();
    final String contatoNome = _contatoController.text.trim();
    final String contatoId = _idContato?.trim() ?? '';
    final String statusBackend = _statusSelecionado;
    final bool statusQuitada = _statusEstaQuitada(statusBackend, _valorConfirmado, _valorRestante);

    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      _mapa(_detalhe['payloadOriginalJson']),
    );
    payload['agendaFinanceira'] = <String, dynamic>{
      'tipoFiltro': tipoOperacao,
      'statusFiltro': statusBackend,
      'origemFiltro': origem,
      'empresaFiltro': _empresa,
      'formaPrevistaPagamento': formaPagamento,
    };
    payload['contato'] = <String, dynamic>{
      'id': contatoId,
      'nome': contatoNome,
    };

    return LancamentoAgendaFinanceiraRequest(
      uuidOperacaoApp: _uuidOperacaoApp.trim().isEmpty ? _idLancamento : _uuidOperacaoApp,
      descricao: _descricaoController.text.trim(),
      tipoOperacao: tipoOperacao,
      statusOperacao: statusBackend,
      dataOperacao: _dataOperacao,
      dataVencimento: _dataVencimento,
      dataCompetencia: _dataCompetencia,
      dataQuitacao: statusQuitada ? DateTime.now() : null,
      statusQuitada: statusQuitada,
      operacaoFinalizadaProntaCaixa: statusQuitada,
      clientePediuParaApagar: false,
      origem: origem,
      formaPagamento: formaPagamento,
      empresa: _empresa,
      categoria: _categoriaController.text.trim(),
      idColaborador: 'mobile-user',
      nomeColaborador: _responsavelController.text.trim(),
      idCliente: isReceber && contatoId.isNotEmpty ? contatoId : _idCliente,
      nomeCliente: isReceber && contatoNome.isNotEmpty ? contatoNome : _nomeCliente,
      idFornecedor: !isReceber && contatoId.isNotEmpty ? contatoId : _idFornecedor,
      nomeFornecedor: !isReceber && contatoNome.isNotEmpty ? contatoNome : _nomeFornecedor,
      referenciaExterna: _referenciaController.text.trim().isEmpty ? null : _referenciaController.text.trim(),
      documentoFiscal: _documentoFiscalController.text.trim().isEmpty ? null : _documentoFiscalController.text.trim(),
      centroDeCusto: _centroCustoController.text.trim().isEmpty ? null : _centroCustoController.text.trim(),
      valorTotalProdutos: 0,
      valorTotalServicos: 0,
      valorTotalOperacao: valorTotal,
      observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
      recorrente: false,
      frequenciaRecorrencia: 'Nao recorrente',
      recorrenciaInicio: _dataVencimento,
      recorrenciaFim: _dataVencimento,
      quantidadeParcelas: 1,
      diaVencimentoRecorrencia: _dataVencimento.day,
      payloadOriginalJson: payload,
    );
  }

  Future<void> _selecionarValor({
    required String titulo,
    required List<String> opcoes,
    required String selecionado,
    required ValueChanged<String> onSelected,
  }) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _MobilePickerSheet(
          title: titulo,
          values: opcoes,
          selected: selecionado,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => onSelected(result));
  }

  Future<void> _selecionarData({
    required String titulo,
    required DateTime atual,
    required ValueChanged<DateTime> onSelected,
  }) async {
    DateTime selecionada = atual;
    final DateTime? result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 18),
              decoration: const BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _sheetHandle(),
                    const SizedBox(height: 16),
                    Text(titulo, style: const TextStyle(color: _titleTextColor, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    CalendarDatePicker(
                      initialDate: selecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: (DateTime value) => setModalState(() => selecionada = _normalizarData(value)),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(selecionada),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Aplicar data'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => onSelected(_normalizarData(result)));
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
        title: const Text('Editar lançamento', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: <Widget>[
                  _buildHeaderCard(),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Dados principais',
                    icon: Icons.receipt_long_outlined,
                    children: <Widget>[
                      _textField(
                        controller: _descricaoController,
                        label: 'Descrição',
                        icon: Icons.notes_outlined,
                        validator: (String? value) =>
                            (value ?? '').trim().isEmpty ? 'Informe a descrição.' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _selectorTile(
                              label: 'Tipo',
                              value: _tipoSelecionado,
                              icon: Icons.swap_vert_rounded,
                              onTap: () => _selecionarValor(
                                titulo: 'Selecionar tipo',
                                opcoes: _tipos,
                                selecionado: _tipoSelecionado,
                                onSelected: (String value) {
                                  _tipoSelecionado = value;
                                  _alinharOrigemComTipo(value);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _selectorTile(
                              label: 'Status',
                              value: _statusSelecionado,
                              icon: Icons.flag_outlined,
                              onTap: () => _selecionarValor(
                                titulo: 'Selecionar status',
                                opcoes: _status,
                                selecionado: _statusSelecionado,
                                onSelected: (String value) => _statusSelecionado = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _selectorTile(
                        label: 'Origem',
                        value: _origemSelecionada,
                        icon: Icons.source_outlined,
                        onTap: () => _selecionarValor(
                          titulo: 'Selecionar origem',
                          opcoes: _origens,
                          selecionado: _origemSelecionada,
                          onSelected: (String value) => _origemSelecionada = value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Valores e pagamento',
                    icon: Icons.account_balance_wallet_outlined,
                    children: <Widget>[
                      _textField(
                        controller: _valorController,
                        label: 'Valor original',
                        icon: Icons.attach_money_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (String? value) => _toDouble(value) <= 0 ? 'Informe um valor maior que zero.' : null,
                      ),
                      const SizedBox(height: 12),
                      _selectorTile(
                        label: _carregandoTiposRecebimento ? 'Forma prevista carregando...' : 'Forma prevista de pagamento',
                        value: _formaPagamentoSelecionada,
                        icon: Icons.payments_outlined,
                        onTap: _carregandoTiposRecebimento
                            ? null
                            : () => _selecionarValor(
                                  titulo: 'Forma prevista de pagamento',
                                  opcoes: _formasPagamento,
                                  selecionado: _formaPagamentoSelecionada,
                                  onSelected: (String value) => _formaPagamentoSelecionada = value,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(child: _metricTile('Confirmado', _formatarMoeda(_valorConfirmado))),
                          const SizedBox(width: 10),
                          Expanded(child: _metricTile('Em aberto', _formatarMoeda(_valorRestante))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Datas',
                    icon: Icons.calendar_month_outlined,
                    children: <Widget>[
                      _selectorTile(
                        label: 'Competência',
                        value: _formatarDataBr(_dataCompetencia),
                        icon: Icons.event_note_outlined,
                        onTap: () => _selecionarData(
                          titulo: 'Data de competência',
                          atual: _dataCompetencia,
                          onSelected: (DateTime value) => _dataCompetencia = value,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _selectorTile(
                        label: 'Vencimento',
                        value: _formatarDataBr(_dataVencimento),
                        icon: Icons.event_available_outlined,
                        onTap: () => _selecionarData(
                          titulo: 'Data de vencimento',
                          atual: _dataVencimento,
                          onSelected: (DateTime value) => _dataVencimento = value,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _selectorTile(
                        label: 'Operação',
                        value: _formatarDataBr(_dataOperacao),
                        icon: Icons.today_outlined,
                        onTap: () => _selecionarData(
                          titulo: 'Data da operação',
                          atual: _dataOperacao,
                          onSelected: (DateTime value) => _dataOperacao = value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Contato e classificação',
                    icon: Icons.person_outline,
                    children: <Widget>[
                      _textField(controller: _contatoController, label: _tipoSelecionado == 'Receber' ? 'Cliente' : 'Fornecedor', icon: Icons.person_outline),
                      const SizedBox(height: 12),
                      _textField(controller: _categoriaController, label: 'Categoria', icon: Icons.sell_outlined),
                      const SizedBox(height: 12),
                      _textField(controller: _responsavelController, label: 'Responsável', icon: Icons.badge_outlined),
                      const SizedBox(height: 12),
                      _textField(controller: _centroCustoController, label: 'Centro de custo', icon: Icons.account_tree_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Informações adicionais',
                    icon: Icons.more_horiz_outlined,
                    children: <Widget>[
                      _textField(controller: _referenciaController, label: 'Referência', icon: Icons.tag_outlined),
                      const SizedBox(height: 12),
                      _textField(controller: _documentoFiscalController, label: 'Documento fiscal', icon: Icons.description_outlined),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _observacoesController,
                        label: 'Observações',
                        icon: Icons.notes_outlined,
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_carregandoDetalhe) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 3)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: _surfaceColor,
            boxShadow: <BoxShadow>[
              BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -6)),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x220B1F3A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Editar lançamento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  _descricaoController.text.trim().isEmpty ? 'Atualize as informações do lançamento.' : _descricaoController.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD7E3F5), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
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
          Row(
            children: <Widget>[
              Icon(icon, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _accentColor, width: 1.4)),
      ),
    );
  }

  Widget _selectorTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: _salvando ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: _accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _mutedTextColor),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: _softBlueColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _alinharOrigemComTipo(String tipo) {
    if (tipo == 'Receber' && (_origemSelecionada == 'Despesa manual' || _origemSelecionada == 'Compra')) {
      _origemSelecionada = 'Venda';
    } else if (tipo == 'Pagar' && (_origemSelecionada == 'Venda' || _origemSelecionada == 'Ordem de serviço')) {
      _origemSelecionada = 'Despesa manual';
    }
  }

  String? _backendFormaPagamentoPorCodigoTipo(String codigoTipo) {
    switch (codigoTipo.trim().toLowerCase()) {
      case 'tipo1':
        return 'DINHEIRO';
      case 'tipo2':
        return 'PIX';
      case 'tipo3':
        return 'CARTAO_CREDITO';
      case 'tipo4':
        return 'CARTAO_DEBITO';
      case 'tipo5':
        return 'BOLETO';
      case 'tipo6':
        return 'TRANSFERENCIA';
      case 'tipo7':
        return 'DEBITO_AUTOMATICO';
      default:
        return null;
    }
  }

  String _backendFormaPagamentoPorDescricao(String descricao) {
    final String normalizado = _normalizarSemAcento(descricao).toUpperCase();
    if (normalizado.contains('PIX')) return 'PIX';
    if (normalizado.contains('BOLETO')) return 'BOLETO';
    if (normalizado.contains('CREDITO')) return 'CARTAO_CREDITO';
    if (normalizado.contains('DEBITO AUTOMATICO')) return 'DEBITO_AUTOMATICO';
    if (normalizado.contains('DEBITO')) return 'CARTAO_DEBITO';
    if (normalizado.contains('TRANSFER')) return 'TRANSFERENCIA';
    if (normalizado.contains('DINHEIRO')) return 'DINHEIRO';
    return normalizado.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  String _formaPagamentoLabel(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
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
        return (value ?? '').trim().isEmpty ? 'Pix' : value!.trim();
    }
  }

  String _formaPagamentoParaBackend() {
    return _backendPorDescricaoFormaPagamento[_formaPagamentoSelecionada] ??
        _backendFormaPagamentoPorDescricao(_formaPagamentoSelecionada);
  }

  String _tipoLabel(String? value, String fallback) {
    switch ((value ?? '').toUpperCase()) {
      case 'RECEBER':
        return 'Receber';
      case 'PAGAR':
        return 'Pagar';
      default:
        return fallback;
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
      case 'CANCELADA':
        return 'Cancelado';
      case 'VENCIDO':
        return 'Vencido';
      case 'VENCE_HOJE':
        return 'Vence hoje';
      case 'PREVISTO':
        return 'Previsto';
      case 'PENDENTE':
        return 'Pendente';
      default:
        return (status ?? '').trim().isEmpty ? 'Pendente' : status!.trim();
    }
  }

  bool _statusEstaQuitada(String status, double valorConfirmado, double valorRestante) {
    final String normalizado = _normalizarSemAcento(status).toUpperCase();
    return normalizado == 'PAGO' || normalizado == 'RECEBIDO' || (valorConfirmado > 0 && valorRestante <= 0);
  }

  String _origemLabel(String? value, String tipo) {
    switch ((value ?? '').toUpperCase()) {
      case 'VENDA':
        return 'Venda';
      case 'ORDEM_SERVICO':
      case 'ORDEM DE SERVIÇO':
      case 'ORDEM_DE_SERVICO':
        return 'Ordem de serviço';
      case 'COMPRA':
        return 'Compra';
      case 'PARCELA':
        return 'Parcela';
      case 'MOVIMENTACAO_CAIXA':
      case 'MOVIMENTAÇÃO DE CAIXA':
        return 'Movimentação de caixa';
      case 'DESPESA_MANUAL':
        return 'Despesa manual';
      default:
        final String raw = value?.trim() ?? '';
        if (_origens.contains(raw)) return raw;
        return tipo == 'Receber' ? 'Venda' : 'Despesa manual';
    }
  }

  String _origemParaBackend(String origem, String tipo) {
    switch (origem) {
      case 'Venda':
        return 'VENDA';
      case 'Ordem de serviço':
        return 'ORDEM_SERVICO';
      case 'Despesa manual':
        return 'DESPESA_MANUAL';
      case 'Compra':
        return 'COMPRA';
      case 'Parcela':
        return 'PARCELA';
      case 'Movimentação de caixa':
        return 'MOVIMENTACAO_CAIXA';
      default:
        return tipo == 'Receber' ? 'VENDA' : 'DESPESA_MANUAL';
    }
  }

  String _normalizarSemAcento(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  DateTime _normalizarData(DateTime data) => DateTime(data.year, data.month, data.day);

  DateTime _parseData(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return _normalizarData(value);
    final String texto = value.toString().trim();
    if (texto.isEmpty || texto == '-') return fallback;
    if (texto.contains('/')) {
      final List<String> partes = texto.split('/');
      if (partes.length == 3) {
        final int? dia = int.tryParse(partes[0]);
        final int? mes = int.tryParse(partes[1]);
        final int? ano = int.tryParse(partes[2]);
        if (dia != null && mes != null && ano != null) return DateTime(ano, mes, dia);
      }
    }
    final DateTime? data = DateTime.tryParse(texto);
    return data == null ? fallback : _normalizarData(data);
  }

  String _formatarDataBr(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _formatarValorParaCampo(dynamic valor) {
    if (valor is num) return valor.toStringAsFixed(2).replaceAll('.', ',');
    final String texto = valor?.toString().trim() ?? '';
    final double numero = _toDouble(texto);
    if (numero > 0) return numero.toStringAsFixed(2).replaceAll('.', ',');
    return texto;
  }

  String _formatarMoeda(double valor) {
    final bool negativo = valor < 0;
    final double absoluto = valor.abs();
    final List<String> partes = absoluto.toStringAsFixed(2).split('.');
    final String inteiro = partes[0];
    final String decimal = partes[1];
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < inteiro.length; i++) {
      final int indexInvertido = inteiro.length - i;
      buffer.write(inteiro[i]);
      if (indexInvertido > 1 && indexInvertido % 3 == 1) buffer.write('.');
    }
    final String prefixo = negativo ? r'-R$ ' : r'R$ ';
    return '$prefixo${buffer.toString()},$decimal';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final String normalizado = value.trim().contains(',') && value.trim().contains('.')
          ? value.trim().replaceAll('.', '').replaceAll(',', '.')
          : value.trim().replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }

  String _texto(dynamic value, {String fallback = ''}) {
    final String texto = value?.toString().trim() ?? '';
    return texto.isEmpty || texto == '-' ? fallback : texto;
  }

  Map<String, dynamic> _mapa(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999)),
    ),
  );
}

class _MobilePickerSheet extends StatelessWidget {
  const _MobilePickerSheet({
    required this.title,
    required this.values,
    required this.selected,
  });

Need file new lengthy but created. Need update agenda mobile import and _editarLancamento. Need maybe new file issue: _formKey.currentState!.validate maybe form state null? ok.
Need need not include web import? _novoLancamento uses web so keep web import. Add import new screen. Update _editarLancamento.
Need modify small file; need fetch current SHA? agenda mobile sha af980... since no changes yet. Need full update? Could patch not available, need full content. Updating full 1650 lines hard. But maybe use python? We don't have repo local. Could use GitHub.fetch raw whole via fetch? We can use api_tool.read_resource for /response/turn208 etc but all chunks. Need reconstruct full from GitHub? Better use Python in analysis to request raw? No internet in python. Could use GitHub.fetch with raw, perhaps resource lines all in structured content? Maybe api_tool.read_resource on response/turn? It truncated? But maybe resource full? /response/turn??? We have fetch_file chunks but not complete line by line? Need update entire file. Could use search? maybe update with replace only impossible. But we can fetch blob entire? Use fetch_file encoding base64 maybe returns full? Could use fetch_blob? It might truncate visible, but resource contains full maybe can read all via api_tool. Need use fetch_file encoding utf-8 full gave first 260 only? Actually because start. We can fetch raw full with no ranges, then use api_tool.read_resource? Let's do full fetch_file no start maybe returns truncated but resource can read. Then use api_tool.read_resource in analysis? Commentary. Need access content maybe. We can use api_tool.read_resource with response URI. We can patch manually? Maybe easier create a second screen and then need just small edit. But update_file still full. We can get full content resource via api_tool.read_resource maybe 1600 lines. We'll retrieve chunks and programmatically modify mentally? Could use GitHub.fetch raw, then maybe response has structuredContent content full line 4 but not easy. Use api_tool.read_resource on /response/turn218? Let's fetch full file. 
