import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/design_system/components/web/sub_painel_web_general.dart';

class SubPainelLancamentoAgendaFinanceiraWeb extends SubPainelWebGeneral {
  const SubPainelLancamentoAgendaFinanceiraWeb({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

Future<Map<String, dynamic>?> showSubPainelLancamentoAgendaFinanceiraWeb(
  BuildContext context, {
  required String empresaSelecionada,
  required List<String> empresas,
  bool modoEdicao = false,
  Map<String, dynamic>? lancamentoInicial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return SubPainelLancamentoAgendaFinanceiraWeb(
        textoDaAppBar: modoEdicao
            ? 'Editar lançamento financeiro'
            : 'Novo lançamento financeiro',
        body: _LancamentoAgendaFinanceiraWebBody(
          empresaSelecionada: empresaSelecionada,
          empresas: empresas,
          modoEdicao: modoEdicao,
          lancamentoInicial: lancamentoInicial,
        ),
      );
    },
  );
}

class _LancamentoAgendaFinanceiraWebBody extends StatefulWidget {
  const _LancamentoAgendaFinanceiraWebBody({
    required this.empresaSelecionada,
    required this.empresas,
    required this.modoEdicao,
    this.lancamentoInicial,
  });

  final String empresaSelecionada;
  final List<String> empresas;
  final bool modoEdicao;
  final Map<String, dynamic>? lancamentoInicial;

  @override
  State<_LancamentoAgendaFinanceiraWebBody> createState() =>
      _LancamentoAgendaFinanceiraWebBodyState();
}

class _LancamentoAgendaFinanceiraWebBodyState
    extends State<_LancamentoAgendaFinanceiraWebBody> {
  final _formKey = GlobalKey<FormState>();
  final _service = AgendaFinanceiraLancamentoService();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final TextEditingController _idContatoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _documentoFiscalController = TextEditingController();
  final TextEditingController _centroCustoController = TextEditingController();
  final TextEditingController _quantidadeParcelasController = TextEditingController(text: '12');
  final TextEditingController _dataOperacaoController = TextEditingController();
  final TextEditingController _dataVencimentoController = TextEditingController();
  final TextEditingController _dataCompetenciaController = TextEditingController();
  final TextEditingController _inicioRecorrenciaController = TextEditingController();
  final TextEditingController _fimRecorrenciaController = TextEditingController();

  bool _isLoading = false;
  bool _recorrente = false;
  bool _statusQuitada = false;
  bool _bloquearTipoStatusPorConfirmacao = false;
  String? _idLancamentoEdicao;
  String? _uuidOperacaoAppEdicao;

  String _tipoSelecionado = 'Pagar';
  String _statusSelecionado = 'Pendente';
  String _origemSelecionada = 'Despesa manual';
  String _empresaSelecionada = '';
  String _formaPagamentoSelecionada = 'Pix';
  String _frequenciaRecorrencia = 'Mensal';

  DateTime _dataOperacao = DateTime.now();
  DateTime _dataVencimento = DateTime.now();
  DateTime _dataCompetencia = DateTime.now();
  DateTime _inicioRecorrencia = DateTime.now();
  DateTime? _fimRecorrencia;

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
  static const List<String> _formasPagamento = <String>[
    'Pix',
    'Boleto',
    'Transferência',
    'Cartão de crédito',
    'Cartão de débito',
    'Débito automático',
    'Dinheiro',
  ];
  static const List<String> _frequencias = <String>[
    'Diária',
    'Semanal',
    'Mensal',
    'Bimestral',
    'Trimestral',
    'Semestral',
    'Anual',
  ];

  bool get _bloquearTipoStatus => widget.modoEdicao && _bloquearTipoStatusPorConfirmacao;

  @override
  void initState() {
    super.initState();
    final empresas = widget.empresas.isEmpty ? <String>['Empresa'] : widget.empresas;
    _empresaSelecionada = empresas.contains(widget.empresaSelecionada)
        ? widget.empresaSelecionada
        : empresas.first;

    if (widget.modoEdicao && widget.lancamentoInicial != null) {
      _preencherCamposEdicao(widget.lancamentoInicial!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarDetalheLancamentoEdicao();
      });
    }

    _garantirRecorrenciaConsistente();
    _sincronizarTextosData();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _contatoController.dispose();
    _idContatoController.dispose();
    _categoriaController.dispose();
    _valorController.dispose();
    _responsavelController.dispose();
    _observacoesController.dispose();
    _referenciaController.dispose();
    _documentoFiscalController.dispose();
    _centroCustoController.dispose();
    _quantidadeParcelasController.dispose();
    _dataOperacaoController.dispose();
    _dataVencimentoController.dispose();
    _dataCompetenciaController.dispose();
    _inicioRecorrenciaController.dispose();
    _fimRecorrenciaController.dispose();
    super.dispose();
  }

  void _preencherCamposEdicao(Map<String, dynamic> item) {
    _idLancamentoEdicao = item['id']?.toString();
    _uuidOperacaoAppEdicao = item['uuidOperacaoApp']?.toString() ?? item['id']?.toString();

    final tipoItem = item['tipo']?.toString().toLowerCase() ?? '';
    if (tipoItem == 'receber') {
      _tipoSelecionado = 'Receber';
    } else if (tipoItem == 'pagar') {
      _tipoSelecionado = 'Pagar';
    }

    final status = item['status']?.toString() ?? '';
    if (_status.contains(status)) {
      _statusSelecionado = status;
    }

    final valorConfirmado = _toDoubleDynamic(item['valorConfirmado']);
    final valorRestante = _toDoubleDynamic(item['valorRestante']);
    final statusNormalizado = _normalizarSemAcento(status).toUpperCase();
    final confirmadoPorStatus = statusNormalizado == 'PAGO' || statusNormalizado == 'RECEBIDO';
    final confirmadoPorValores = valorConfirmado > 0 && valorRestante <= 0;

    _statusQuitada = confirmadoPorStatus || confirmadoPorValores;
    _bloquearTipoStatusPorConfirmacao = _statusQuitada;

    final origem = item['origem']?.toString() ?? '';
    if (_origens.contains(origem)) {
      _origemSelecionada = origem;
    }
    _alinharOrigemComTipo(_tipoSelecionado);

    final formaPagamento = item['formaPagamento']?.toString() ?? '';
    if (_formasPagamento.contains(formaPagamento)) {
      _formaPagamentoSelecionada = formaPagamento;
    }

    final empresa = item['empresa']?.toString() ?? '';
    if (widget.empresas.contains(empresa)) {
      _empresaSelecionada = empresa;
    }

    _descricaoController.text = item['descricao']?.toString() ?? '';
    _contatoController.text = item['contato']?.toString() ?? '';
    _idContatoController.text = item['idContato']?.toString() ?? '';
    _categoriaController.text = item['categoria']?.toString() ?? '';
    _valorController.text = _formatarValorParaCampo(item['valor']);
    _responsavelController.text = item['responsavel']?.toString() ?? '';
    _observacoesController.text = item['observacoes']?.toString() ?? '';
    _referenciaController.text = item['referenciaExterna']?.toString() ?? '';
    _documentoFiscalController.text = item['documentoFiscal']?.toString() ?? '';
    _centroCustoController.text = item['centroDeCusto']?.toString() ?? '';

    _dataVencimento = _parseData(item['vencimento'], fallback: _dataVencimento);
    _dataOperacao = _parseData(item['dataOperacao'], fallback: _dataVencimento);
    _dataCompetencia = _parseData(item['dataCompetencia'], fallback: _dataVencimento);

    _aplicarDadosRecorrencia(item, respeitarAusencia: true);
  }

  Future<void> _carregarDetalheLancamentoEdicao() async {
    final id = _idLancamentoEdicao;
    if (!widget.modoEdicao || id == null || id.trim().isEmpty) return;

    try {
      final detalhe = await _service.buscarDetalheLancamento(id);
      if (!mounted || detalhe.isEmpty) return;

      setState(() {
        _aplicarDadosRecorrencia(detalhe, respeitarAusencia: false);
        _garantirRecorrenciaConsistente();
        _sincronizarTextosData();
      });
    } catch (_) {
      // Se o detalhe não estiver disponível, mantém os dados já recebidos pela listagem.
    }
  }

  void _aplicarDadosRecorrencia(Map<String, dynamic> item, {required bool respeitarAusencia}) {
    final possuiCampoRecorrente = item.containsKey('recorrente');
    final quantidade = _toIntDynamic(item['quantidadeParcelas']);
    final frequencia = item['frequenciaRecorrencia']?.toString().trim() ?? '';
    final possuiDadosRecorrencia = quantidade > 1 ||
        frequencia.isNotEmpty ||
        item['recorrenciaInicio'] != null ||
        item['recorrenciaFim'] != null;

    if (!possuiCampoRecorrente && !possuiDadosRecorrencia && respeitarAusencia) return;

    _recorrente = item['recorrente'] == true || possuiDadosRecorrencia;
    _frequenciaRecorrencia = _normalizarFrequencia(item['frequenciaRecorrencia'], fallback: _frequenciaRecorrencia);

    final inicio = _parseDataOpcional(item['recorrenciaInicio']);
    if (inicio != null) {
      _inicioRecorrencia = inicio;
    } else if (_recorrente) {
      _inicioRecorrencia = _dataVencimento;
    }

    final fim = _parseDataOpcional(item['recorrenciaFim']);
    if (fim != null) _fimRecorrencia = fim;
    if (quantidade > 0) _quantidadeParcelasController.text = quantidade.toString();
  }

  DateTime _parseData(dynamic value, {required DateTime fallback}) =>
      _parseDataOpcional(value) ?? fallback;

  DateTime? _parseDataOpcional(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return _normalizarData(value);
    final texto = value.toString().trim();
    if (texto.isEmpty) return null;

    if (texto.contains('/')) {
      final partes = texto.split('/');
      if (partes.length == 3) {
        final dia = int.tryParse(partes[0]);
        final mes = int.tryParse(partes[1]);
        final ano = int.tryParse(partes[2]);
        if (dia != null && mes != null && ano != null) return DateTime(ano, mes, dia);
      }
    }

    final iso = DateTime.tryParse(texto);
    return iso == null ? null : _normalizarData(iso);
  }

  DateTime _normalizarData(DateTime data) => DateTime(data.year, data.month, data.day);

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

  String _normalizarFrequencia(dynamic value, {String fallback = 'Mensal'}) {
    final texto = value?.toString().trim() ?? '';
    if (texto.isEmpty) return fallback;
    switch (_normalizarSemAcento(texto).toUpperCase()) {
      case 'DIARIA':
      case 'DIARIO':
        return 'Diária';
      case 'SEMANAL':
        return 'Semanal';
      case 'MENSAL':
        return 'Mensal';
      case 'BIMESTRAL':
        return 'Bimestral';
      case 'TRIMESTRAL':
        return 'Trimestral';
      case 'SEMESTRAL':
        return 'Semestral';
      case 'ANUAL':
        return 'Anual';
      default:
        return _frequencias.contains(texto) ? texto : fallback;
    }
  }

  String _formatarValorParaCampo(dynamic valor) {
    if (valor is num) return valor.toStringAsFixed(2).replaceAll('.', ',');
    final texto = valor?.toString().trim() ?? '';
    final numero = double.tryParse(texto);
    if (numero != null) return numero.toStringAsFixed(2).replaceAll('.', ',');
    return texto;
  }

  int _toInt(String text) => int.tryParse(text.trim()) ?? 0;

  int _toIntDynamic(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  double _toDouble(String text) {
    final normalizado = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0;
  }

  double _toDoubleDynamic(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return _toDouble(value);
    return 0;
  }

  int _quantidadeParcelasInformada() {
    final quantidade = _toInt(_quantidadeParcelasController.text);
    return quantidade > 0 ? quantidade : 1;
  }

  bool _origemSugerePagar(String origem) => origem == 'Despesa manual' || origem == 'Compra';

  bool _origemSugereReceber(String origem) => origem == 'Venda' || origem == 'Ordem de serviço';

  String _origemPadraoPorTipo(String tipo) => tipo == 'Receber' ? 'Venda' : 'Despesa manual';

  void _alinharOrigemComTipo(String tipo) {
    if (tipo == 'Receber' && _origemSugerePagar(_origemSelecionada)) {
      _origemSelecionada = _origemPadraoPorTipo(tipo);
    } else if (tipo == 'Pagar' && _origemSugereReceber(_origemSelecionada)) {
      _origemSelecionada = _origemPadraoPorTipo(tipo);
    }
  }

  void _aplicarTipoSelecionado(String tipo) {
    if (_bloquearTipoStatus) return;
    _tipoSelecionado = tipo;
    _alinharOrigemComTipo(tipo);
    if (_statusQuitada) {
      _statusSelecionado = _statusPadraoPorTipo();
    } else if (tipo == 'Receber' && _statusSelecionado == 'Pago') {
      _statusSelecionado = 'Recebido';
    } else if (tipo == 'Pagar' && _statusSelecionado == 'Recebido') {
      _statusSelecionado = 'Pago';
    }
  }

  int _mesesPorFrequencia(String frequencia) {
    switch (frequencia) {
      case 'Bimestral':
        return 2;
      case 'Trimestral':
        return 3;
      case 'Semestral':
        return 6;
      case 'Anual':
        return 12;
      case 'Mensal':
        return 1;
      default:
        return 0;
    }
  }

  DateTime _somarMesesPreservandoDia(DateTime data, int meses) {
    final mesBaseZero = data.month - 1 + meses;
    final ano = data.year + (mesBaseZero ~/ 12);
    final mes = (mesBaseZero % 12) + 1;
    final ultimoDiaMes = DateUtils.getDaysInMonth(ano, mes);
    final dia = data.day > ultimoDiaMes ? ultimoDiaMes : data.day;
    return DateTime(ano, mes, dia);
  }

  DateTime _calcularFimRecorrencia({
    required DateTime inicio,
    required String frequencia,
    required int quantidadeParcelas,
  }) {
    final parcelas = quantidadeParcelas <= 0 ? 1 : quantidadeParcelas;
    final incremento = parcelas - 1;
    if (incremento <= 0) return _normalizarData(inicio);
    switch (frequencia) {
      case 'Diária':
        return _normalizarData(inicio.add(Duration(days: incremento)));
      case 'Semanal':
        return _normalizarData(inicio.add(Duration(days: incremento * 7)));
      default:
        return _somarMesesPreservandoDia(inicio, _mesesPorFrequencia(frequencia) * incremento);
    }
  }

  void _garantirRecorrenciaConsistente({bool recalcularFim = false}) {
    if (!_recorrente) {
      _fimRecorrencia = null;
      return;
    }
    _inicioRecorrencia = _normalizarData(_inicioRecorrencia);
    if (_quantidadeParcelasInformada() <= 0) _quantidadeParcelasController.text = '12';
    if (_fimRecorrencia == null || recalcularFim) {
      _fimRecorrencia = _calcularFimRecorrencia(
        inicio: _inicioRecorrencia,
        frequencia: _frequenciaRecorrencia,
        quantidadeParcelas: _quantidadeParcelasInformada(),
      );
    }
  }

  void _onRecorrenteChanged(bool value) {
    setState(() {
      _recorrente = value;
      if (_recorrente) {
        _inicioRecorrencia = _normalizarData(_dataVencimento);
        if (_quantidadeParcelasInformada() <= 1) _quantidadeParcelasController.text = '12';
        _garantirRecorrenciaConsistente(recalcularFim: true);
      } else {
        _fimRecorrencia = null;
      }
      _sincronizarTextosData();
    });
  }

  void _recalcularFimRecorrencia() {
    if (!_recorrente) return;
    _fimRecorrencia = _calcularFimRecorrencia(
      inicio: _inicioRecorrencia,
      frequencia: _frequenciaRecorrencia,
      quantidadeParcelas: _quantidadeParcelasInformada(),
    );
    _sincronizarTextosData();
  }

  void _sincronizarTextosData() {
    _dataOperacaoController.text = _formatarDataBr(_dataOperacao);
    _dataVencimentoController.text = _formatarDataBr(_dataVencimento);
    _dataCompetenciaController.text = _formatarDataBr(_dataCompetencia);
    _inicioRecorrenciaController.text = _formatarDataBr(_inicioRecorrencia);
    _fimRecorrenciaController.text = _fimRecorrencia != null ? _formatarDataBr(_fimRecorrencia!) : '';
  }

  String _formatarDataBr(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _statusPadraoPorTipo() {
    if (_statusQuitada) return _tipoSelecionado == 'Receber' ? 'Recebido' : 'Pago';
    return _statusSelecionado;
  }

  String _tipoOperacaoParaBackend() => _tipoSelecionado.toUpperCase();

  String _origemParaBackend() {
    switch (_origemSelecionada) {
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
        return _tipoSelecionado == 'Receber' ? 'VENDA' : 'DESPESA_MANUAL';
    }
  }

  String _formaPagamentoParaBackend() {
    switch (_formaPagamentoSelecionada) {
      case 'Pix':
        return 'PIX';
      case 'Boleto':
        return 'BOLETO';
      case 'Transferência':
        return 'TRANSFERENCIA';
      case 'Cartão de crédito':
        return 'CARTAO_CREDITO';
      case 'Cartão de débito':
        return 'CARTAO_DEBITO';
      case 'Débito automático':
        return 'DEBITO_AUTOMATICO';
      case 'Dinheiro':
        return 'DINHEIRO';
      default:
        return 'PIX';
    }
  }

  LancamentoAgendaFinanceiraRequest _buildRequest() {
    _garantirRecorrenciaConsistente(recalcularFim: _recorrente && _fimRecorrencia == null);
    final valorTotal = _toDouble(_valorController.text);
    final idLocal = _uuidOperacaoAppEdicao ?? DateTime.now().millisecondsSinceEpoch.toString();
    final tipoOperacao = _tipoOperacaoParaBackend();
    final origem = _origemParaBackend();
    final formaPagamento = _formaPagamentoParaBackend();
    final contatoIdDigitado = _idContatoController.text.trim();
    final contatoNome = _contatoController.text.trim();
    final contatoIdPayload = contatoIdDigitado.isEmpty ? 'contato-$idLocal' : contatoIdDigitado;
    final contatoIdOuNull = contatoIdDigitado.isEmpty ? null : contatoIdDigitado;
    final contatoNomeOuNull = contatoNome.isEmpty ? null : contatoNome;
    final isReceber = _tipoSelecionado == 'Receber';
    final quantidadeParcelas = _recorrente ? _quantidadeParcelasInformada() : 1;
    final recorrenciaInicio = _recorrente ? _inicioRecorrencia : _dataVencimento;
    final recorrenciaFim = _recorrente
        ? (_fimRecorrencia ?? _calcularFimRecorrencia(
            inicio: recorrenciaInicio,
            frequencia: _frequenciaRecorrencia,
            quantidadeParcelas: quantidadeParcelas,
          ))
        : _dataVencimento;
    final frequenciaRecorrencia = _recorrente ? _frequenciaRecorrencia : 'Nao recorrente';

    final payload = <String, dynamic>{
      'agendaFinanceira': <String, dynamic>{
        'tipoFiltro': tipoOperacao,
        'statusFiltro': _statusPadraoPorTipo(),
        'origemFiltro': origem,
        'empresaFiltro': _empresaSelecionada,
      },
      'contato': <String, dynamic>{'id': contatoIdPayload, 'nome': contatoNome},
      'recorrencia': <String, dynamic>{
        'recorrente': _recorrente,
        'frequencia': frequenciaRecorrencia,
        'inicio': recorrenciaInicio.toIso8601String(),
        'fim': recorrenciaFim.toIso8601String(),
        'quantidadeParcelas': quantidadeParcelas,
      },
    };

    return LancamentoAgendaFinanceiraRequest(
      uuidOperacaoApp: idLocal,
      descricao: _descricaoController.text.trim(),
      tipoOperacao: tipoOperacao,
      statusOperacao: _statusPadraoPorTipo(),
      dataOperacao: _dataOperacao,
      dataVencimento: _dataVencimento,
      dataCompetencia: _dataCompetencia,
      dataQuitacao: _statusQuitada ? DateTime.now() : null,
      statusQuitada: _statusQuitada,
      operacaoFinalizadaProntaCaixa: _statusQuitada,
      clientePediuParaApagar: false,
      origem: origem,
      formaPagamento: formaPagamento,
      empresa: _empresaSelecionada,
      categoria: _categoriaController.text.trim(),
      idColaborador: 'web-user',
      nomeColaborador: _responsavelController.text.trim(),
      idCliente: isReceber ? contatoIdOuNull : null,
      nomeCliente: isReceber ? contatoNomeOuNull : null,
      idFornecedor: isReceber ? null : contatoIdOuNull,
      nomeFornecedor: isReceber ? null : contatoNomeOuNull,
      referenciaExterna: _referenciaController.text.trim().isEmpty ? null : _referenciaController.text.trim(),
      documentoFiscal: _documentoFiscalController.text.trim().isEmpty ? null : _documentoFiscalController.text.trim(),
      centroDeCusto: _centroCustoController.text.trim().isEmpty ? null : _centroCustoController.text.trim(),
      valorTotalProdutos: 0,
      valorTotalServicos: 0,
      valorTotalOperacao: valorTotal,
      observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
      recorrente: _recorrente,
      frequenciaRecorrencia: frequenciaRecorrencia,
      recorrenciaInicio: recorrenciaInicio,
      recorrenciaFim: recorrenciaFim,
      quantidadeParcelas: quantidadeParcelas,
      diaVencimentoRecorrencia: _dataVencimento.day,
      payloadOriginalJson: payload,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_toDouble(_valorController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor maior que zero.')));
      return;
    }
    if (_recorrente) {
      _garantirRecorrenciaConsistente(recalcularFim: _fimRecorrencia == null);
      _sincronizarTextosData();
      if (_fimRecorrencia == null || _fimRecorrencia!.isBefore(_inicioRecorrencia)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revise o período da recorrência antes de salvar.')));
        return;
      }
    }

    final request = _buildRequest();
    setState(() => _isLoading = true);
    String? idGerado;
    String? aviso;

    try {
      final response = widget.modoEdicao
          ? await _service.editarLancamento(_idLancamentoEdicao ?? request.uuidOperacaoApp, request)
          : await _service.cadastrarLancamento(request);
      idGerado = response.id;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501) {
        aviso = widget.modoEdicao
            ? 'Endpoint de edição ainda não publicado. Alterações mantidas localmente.'
            : 'Endpoint de lançamento financeiro ainda não publicado. Payload foi montado e mantido localmente.';
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.modoEdicao ? 'Erro ao atualizar lançamento: ${e.statusCode}' : 'Erro ao salvar lançamento: ${e.statusCode}')));
        setState(() => _isLoading = false);
        return;
      }
    } catch (_) {
      aviso = widget.modoEdicao
          ? 'Não foi possível confirmar a API no momento. Alterações mantidas localmente.'
          : 'Não foi possível confirmar a API no momento. Payload foi montado e mantido localmente.';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso ?? (widget.modoEdicao ? 'Lançamento atualizado com sucesso.' : 'Lançamento salvo com sucesso.'))));
    final idRetorno = idGerado ?? _idLancamentoEdicao ?? request.uuidOperacaoApp;
    Navigator.of(context).pop(request.toAgendaItem(idFallback: idRetorno));
  }

  Future<void> _confirmarExcluirLancamento() async {
    final id = _idLancamentoEdicao;
    if (!widget.modoEdicao || id == null || id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento ainda não possui identificador para exclusão.')));
      return;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Excluir lançamento?'),
          content: Text(_recorrente
              ? 'Esta ação vai apagar de forma definitiva este lançamento e todas as ocorrências recorrentes exibidas na agenda. Essa operação não pode ser desfeita.'
              : 'Esta ação vai apagar de forma definitiva este lançamento financeiro. Essa operação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Excluir/apagar'),
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            ),
          ],
        );
      },
    );
    if (confirmado == true) await _excluirLancamento(id);
  }

  Future<void> _excluirLancamento(String idLancamento) async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.excluirLancamento(idLancamento);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento excluído definitivamente.')));
      Navigator.of(context).pop(<String, dynamic>{'id': response.id ?? idLancamento, 'deleted': true, 'status': response.status});
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir lançamento: ${e.statusCode}')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível excluir o lançamento agora.')));
    }
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22))),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.14))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 1.4)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
    int maxLines = 1,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      decoration: _inputDecoration(label, hintText: hintText),
      validator: requiredField
          ? (value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required DateTime initialDate,
    required ValueChanged<DateTime> onChanged,
    bool requiredField = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: _inputDecoration(label),
      validator: requiredField
          ? (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
      onTap: !enabled
          ? null
          : () async {
              final selecionada = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (selecionada != null) {
                onChanged(_normalizarData(selecionada));
                _sincronizarTextosData();
                setState(() {});
              }
            },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: safeValue,
      onChanged: enabled ? onChanged : null,
      decoration: _inputDecoration(label),
      items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
    );
  }

  Widget _buildAvisoLancamentoConfirmado() {
    if (!_bloquearTipoStatus) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este lançamento já foi confirmado em sua totalidade. Tipo, status e marcação de quitação ficam bloqueados para evitar inconsistência financeira.',
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.65))),
          ])),
        ]),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[colorScheme.primary, colorScheme.primary.withOpacity(0.88)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        widget.modoEdicao ? 'Editar lançamento financeiro' : 'Novo lançamento financeiro',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Widget _buildActionsBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outline.withOpacity(0.12))),
      child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16, children: <Widget>[
        const Text('Revise os dados do lançamento antes de concluir.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
          if (widget.modoEdicao)
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _confirmarExcluirLancamento,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Excluir/apagar'),
              style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error, side: BorderSide(color: colorScheme.error)),
            ),
          OutlinedButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: _isLoading ? null : _salvar,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_isLoading
                ? (widget.modoEdicao ? 'Atualizando...' : 'Salvando...')
                : (widget.modoEdicao ? 'Atualizar lançamento' : 'Salvar lançamento')),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRecorrenciaResumo() {
    if (!_recorrente) return const SizedBox.shrink();
    final quantidade = _quantidadeParcelasInformada();
    final fimTexto = _fimRecorrencia == null ? 'fim não definido' : _formatarDataBr(_fimRecorrencia!);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Serão consideradas $quantidade parcela(s), frequência $_frequenciaRecorrencia, de ${_formatarDataBr(_inicioRecorrencia)} até $fimTexto.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool telaGrande = constraints.maxWidth >= 1080;
        final bool telaMedia = constraints.maxWidth >= 760;
        double largura(double grande, double media) => telaGrande ? grande : (telaMedia ? media : double.infinity);

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Dados principais',
                  subtitle: 'Campos que alimentam filtros e detalhes da Agenda Financeira.',
                  icon: Icons.badge_outlined,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      if (_bloquearTipoStatus)
                        SizedBox(width: largura(1100, 680), child: _buildAvisoLancamentoConfirmado()),
                      SizedBox(
                        width: largura(260, 220),
                        child: _buildDropdownField(
                          label: 'Tipo',
                          value: _tipoSelecionado,
                          items: _tipos,
                          enabled: !_bloquearTipoStatus,
                          onChanged: (v) => setState(() => _aplicarTipoSelecionado(v!)),
                        ),
                      ),
                      SizedBox(
                        width: largura(260, 220),
                        child: _buildDropdownField(
                          label: 'Status',
                          value: _statusSelecionado,
                          items: _status,
                          enabled: !_bloquearTipoStatus,
                          onChanged: (v) => setState(() => _statusSelecionado = v!),
                        ),
                      ),
                      SizedBox(width: largura(320, 300), child: _buildTextField(controller: _descricaoController, label: 'Descrição', requiredField: true)),
                      SizedBox(width: largura(260, 220), child: _buildTextField(controller: _valorController, label: 'Valor total', requiredField: true, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      SizedBox(
                        width: largura(260, 220),
                        child: _buildDateField(
                          label: 'Data de vencimento',
                          controller: _dataVencimentoController,
                          initialDate: _dataVencimento,
                          requiredField: true,
                          onChanged: (date) {
                            _dataVencimento = date;
                            if (_recorrente) {
                              _inicioRecorrencia = date;
                              _recalcularFimRecorrencia();
                            }
                          },
                        ),
                      ),
                      SizedBox(width: largura(260, 220), child: _buildDateField(label: 'Data da operação', controller: _dataOperacaoController, initialDate: _dataOperacao, requiredField: true, onChanged: (date) => _dataOperacao = date)),
                      SizedBox(width: largura(260, 220), child: _buildDateField(label: 'Competência', controller: _dataCompetenciaController, initialDate: _dataCompetencia, onChanged: (date) => _dataCompetencia = date)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Classificação e filtros',
                  subtitle: 'Informações usadas para segmentação por origem, empresa e método de pagamento.',
                  icon: Icons.filter_alt_outlined,
                  child: Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
                    SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Origem', value: _origemSelecionada, items: _origens, onChanged: (v) => setState(() => _origemSelecionada = v!))),
                    SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Empresa', value: _empresaSelecionada, items: widget.empresas.isEmpty ? <String>['Empresa'] : widget.empresas, onChanged: (v) => setState(() => _empresaSelecionada = v!))),
                    SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Forma de pagamento', value: _formaPagamentoSelecionada, items: _formasPagamento, onChanged: (v) => setState(() => _formaPagamentoSelecionada = v!))),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _categoriaController, label: 'Categoria', requiredField: true)),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _centroCustoController, label: 'Centro de custo')),
                    SizedBox(width: largura(240, 220), child: _buildTextField(controller: _documentoFiscalController, label: 'Documento fiscal')),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Contato e responsabilidade',
                  subtitle: 'Dados exibidos nos cards da agenda e usados para cobrança/pagamento.',
                  icon: Icons.person_outline,
                  child: Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
                    SizedBox(width: largura(260, 220), child: _buildTextField(controller: _idContatoController, label: _tipoSelecionado == 'Receber' ? 'ID do cliente' : 'ID do fornecedor')),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _contatoController, label: _tipoSelecionado == 'Receber' ? 'Cliente' : 'Fornecedor', requiredField: true)),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _responsavelController, label: 'Responsável', requiredField: true)),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _referenciaController, label: 'Referência externa')),
                    SizedBox(width: largura(900, 680), child: _buildTextField(controller: _observacoesController, label: 'Observações', maxLines: 3)),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Recorrência e status',
                  subtitle: 'Configuração de despesas/receitas recorrentes e quitação.',
                  icon: Icons.repeat_rounded,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
                      FilterChip(
                        selected: _recorrente,
                        onSelected: _onRecorrenteChanged,
                        label: const Text('Lançamento recorrente'),
                        avatar: const Icon(Icons.repeat_rounded, size: 18),
                      ),
                      FilterChip(
                        selected: _statusQuitada,
                        onSelected: _bloquearTipoStatus
                            ? null
                            : (value) {
                                setState(() {
                                  _statusQuitada = value;
                                  if (value) _statusSelecionado = _statusPadraoPorTipo();
                                });
                              },
                        label: const Text('Marcar como quitada'),
                        avatar: const Icon(Icons.verified_rounded, size: 18),
                      ),
                    ]),
                    if (_recorrente) ...<Widget>[
                      _buildRecorrenciaResumo(),
                      const SizedBox(height: 16),
                      Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
                        SizedBox(
                          width: largura(260, 220),
                          child: _buildDropdownField(
                            label: 'Frequência',
                            value: _frequenciaRecorrencia,
                            items: _frequencias,
                            onChanged: (value) {
                              setState(() {
                                _frequenciaRecorrencia = value!;
                                _recalcularFimRecorrencia();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: largura(260, 220),
                          child: _buildDateField(
                            label: 'Início da recorrência',
                            controller: _inicioRecorrenciaController,
                            initialDate: _inicioRecorrencia,
                            requiredField: true,
                            onChanged: (date) {
                              _inicioRecorrencia = date;
                              _recalcularFimRecorrencia();
                            },
                          ),
                        ),
                        SizedBox(
                          width: largura(260, 220),
                          child: _buildDateField(
                            label: 'Fim da recorrência',
                            controller: _fimRecorrenciaController,
                            initialDate: _fimRecorrencia ?? _inicioRecorrencia,
                            requiredField: true,
                            onChanged: (date) => _fimRecorrencia = date,
                          ),
                        ),
                        SizedBox(width: largura(220, 220), child: _buildTextField(controller: _quantidadeParcelasController, label: 'Qtd. parcelas', keyboardType: TextInputType.number, requiredField: true, onChanged: (_) => setState(_recalcularFimRecorrencia))),
                      ]),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                _buildActionsBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}
