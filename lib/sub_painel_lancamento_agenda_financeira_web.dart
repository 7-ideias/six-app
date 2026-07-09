import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final TextEditingController _idContatoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _valorConfirmadoController =
      TextEditingController(text: '0,00');
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _documentoFiscalController =
      TextEditingController();
  final TextEditingController _centroCustoController = TextEditingController();
  final TextEditingController _dataOperacaoController = TextEditingController();
  final TextEditingController _dataVencimentoController = TextEditingController();
  final TextEditingController _dataCompetenciaController = TextEditingController();

  bool _isLoading = false;
  bool _statusQuitada = false;
  bool _bloquearTipoStatusPorConfirmacao = false;
  String? _idLancamentoEdicao;
  String? _uuidOperacaoAppEdicao;

  String _tipoSelecionado = 'Pagar';
  String _statusSelecionado = 'Pendente';
  String _origemSelecionada = 'Despesa manual';
  String _empresaSelecionada = '';
  String _formaPagamentoSelecionada = 'Pix';

  DateTime _dataOperacao = DateTime.now();
  DateTime _dataVencimento = DateTime.now();
  DateTime _dataCompetencia = DateTime.now();

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

  List<String> _formasPagamento = List<String>.from(_formasPagamentoPadrao);
  bool _carregandoTiposRecebimento = false;

  bool get _bloquearTipoStatus =>
      widget.modoEdicao && _bloquearTipoStatusPorConfirmacao;

  @override
  void initState() {
    super.initState();
    final List<String> empresas =
        widget.empresas.isEmpty ? <String>['Empresa'] : widget.empresas;
    _empresaSelecionada = empresas.contains(widget.empresaSelecionada)
        ? widget.empresaSelecionada
        : empresas.first;

    if (widget.modoEdicao && widget.lancamentoInicial != null) {
      _preencherCamposEdicao(widget.lancamentoInicial!);
    }

    _sincronizarTextosData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTiposRecebimentoAtivos();
    });
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _contatoController.dispose();
    _idContatoController.dispose();
    _categoriaController.dispose();
    _valorController.dispose();
    _valorConfirmadoController.dispose();
    _responsavelController.dispose();
    _observacoesController.dispose();
    _referenciaController.dispose();
    _documentoFiscalController.dispose();
    _centroCustoController.dispose();
    _dataOperacaoController.dispose();
    _dataVencimentoController.dispose();
    _dataCompetenciaController.dispose();
    super.dispose();
  }

  void _preencherCamposEdicao(Map<String, dynamic> item) {
    _idLancamentoEdicao = item['id']?.toString();
    _uuidOperacaoAppEdicao =
        item['uuidOperacaoApp']?.toString() ?? item['id']?.toString();

    final String tipoItem = item['tipo']?.toString().toLowerCase() ?? '';
    if (tipoItem == 'receber') {
      _tipoSelecionado = 'Receber';
    } else if (tipoItem == 'pagar') {
      _tipoSelecionado = 'Pagar';
    }

    final String status = item['status']?.toString() ?? '';
    if (_status.contains(status)) _statusSelecionado = status;

    final double valorConfirmado = _toDoubleDynamic(item['valorConfirmado']);
    final double valorRestante = _toDoubleDynamic(item['valorRestante']);
    final String statusNormalizado = _normalizarSemAcento(status).toUpperCase();
    _statusQuitada = statusNormalizado == 'PAGO' ||
        statusNormalizado == 'RECEBIDO' ||
        (valorConfirmado > 0 && valorRestante <= 0);
    _bloquearTipoStatusPorConfirmacao = _statusQuitada;

    final String origem = item['origem']?.toString() ?? '';
    if (_origens.contains(origem)) _origemSelecionada = origem;
    _alinharOrigemComTipo(_tipoSelecionado);

    final String formaPagamento = item['formaPagamento']?.toString() ?? '';
    if (formaPagamento.trim().isNotEmpty) {
      _formaPagamentoSelecionada = _formaPagamentoLabel(formaPagamento);
      if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
        _formasPagamento = <String>[_formaPagamentoSelecionada, ..._formasPagamento];
      }
    }

    final String empresa = item['empresa']?.toString() ?? '';
    if (widget.empresas.contains(empresa)) _empresaSelecionada = empresa;

    final dynamic valorOriginal = item['valorOriginal'] ??
        item['valorTotalOperacao'] ??
        item['valorTotal'] ??
        item['valor'];
    _descricaoController.text = item['descricao']?.toString() ?? '';
    _contatoController.text = item['contato']?.toString() ?? '';
    _idContatoController.text = item['idContato']?.toString() ?? '';
    _categoriaController.text = item['categoria']?.toString() ?? '';
    _valorController.text = _formatarValorParaCampo(valorOriginal);
    _valorConfirmadoController.text = _formatarValorParaCampo(valorConfirmado);
    _responsavelController.text = item['responsavel']?.toString() ?? '';
    _observacoesController.text = item['observacoes']?.toString() ?? '';
    _referenciaController.text = item['referenciaExterna']?.toString() ?? '';
    _documentoFiscalController.text = item['documentoFiscal']?.toString() ?? '';
    _centroCustoController.text = item['centroDeCusto']?.toString() ?? '';

    _dataVencimento = _parseData(item['vencimento'], fallback: _dataVencimento);
    _dataOperacao = _parseData(item['dataOperacao'], fallback: _dataVencimento);
    _dataCompetencia =
        _parseData(item['dataCompetencia'], fallback: _dataVencimento);
  }

  Future<void> _carregarTiposRecebimentoAtivos() async {
    setState(() => _carregandoTiposRecebimento = true);
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<String> formas =
          _montarFormasPagamentoAtivas(informacoes.tiposRecebimento);
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasPagamento = formas;
        if (!_formasPagamento.contains(_formaPagamentoSelecionada)) {
          _formaPagamentoSelecionada = _formasPagamento.first;
        }
      });
    } catch (_) {
      // Mantém os valores padrão para não impedir o lançamento caso o endpoint falhe.
    } finally {
      if (mounted) setState(() => _carregandoTiposRecebimento = false);
    }
  }

  List<String> _montarFormasPagamentoAtivas(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos = tipos
        .where((TiposRecebimento tipo) => tipo.ativo)
        .toList()
      ..sort((TiposRecebimento a, TiposRecebimento b) =>
          a.ordemExibicao.compareTo(b.ordemExibicao));

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

  String _formaPagamentoLabel(String value) {
    switch (value.trim().toUpperCase()) {
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
        return value.trim().isEmpty ? 'Pix' : value;
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

  String _formatarValorParaCampo(dynamic valor) {
    if (valor is num) return valor.toStringAsFixed(2).replaceAll('.', ',');
    final String texto = valor?.toString().trim() ?? '';
    final double? numero = double.tryParse(texto.replaceAll(',', '.'));
    if (numero != null) return numero.toStringAsFixed(2).replaceAll('.', ',');
    return texto;
  }

  double _toDouble(String text) {
    final String normalizado = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0;
  }

  double _toDoubleDynamic(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return _toDouble(value);
    return 0;
  }

  DateTime _normalizarData(DateTime data) => DateTime(data.year, data.month, data.day);

  DateTime _parseData(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return _normalizarData(value);
    final String texto = value.toString().trim();
    if (texto.isEmpty) return fallback;
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

  void _sincronizarTextosData() {
    _dataOperacaoController.text = _formatarDataBr(_dataOperacao);
    _dataVencimentoController.text = _formatarDataBr(_dataVencimento);
    _dataCompetenciaController.text = _formatarDataBr(_dataCompetencia);
  }

  String _formatarDataBr(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
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
    if (tipo == 'Receber' && _statusSelecionado == 'Pago') {
      _statusSelecionado = 'Recebido';
    } else if (tipo == 'Pagar' && _statusSelecionado == 'Recebido') {
      _statusSelecionado = 'Pago';
    }
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
    return _backendPorDescricaoFormaPagamento[_formaPagamentoSelecionada] ??
        _backendFormaPagamentoPorDescricao(_formaPagamentoSelecionada);
  }

  LancamentoAgendaFinanceiraRequest _buildRequest() {
    final double valorTotal = _toDouble(_valorController.text);
    final String idLocal = _uuidOperacaoAppEdicao ?? DateTime.now().millisecondsSinceEpoch.toString();
    final String tipoOperacao = _tipoOperacaoParaBackend();
    final String origem = _origemParaBackend();
    final String formaPagamento = _formaPagamentoParaBackend();
    final String contatoIdDigitado = _idContatoController.text.trim();
    final String contatoNome = _contatoController.text.trim();
    final bool isReceber = _tipoSelecionado == 'Receber';

    final Map<String, dynamic> payload = <String, dynamic>{
      'agendaFinanceira': <String, dynamic>{
        'tipoFiltro': tipoOperacao,
        'statusFiltro': _statusPadraoPorTipo(),
        'origemFiltro': origem,
        'empresaFiltro': _empresaSelecionada,
        'formaPrevistaPagamento': formaPagamento,
      },
      'contato': <String, dynamic>{
        'id': contatoIdDigitado,
        'nome': contatoNome,
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
      idCliente: isReceber && contatoIdDigitado.isNotEmpty ? contatoIdDigitado : null,
      nomeCliente: isReceber && contatoNome.isNotEmpty ? contatoNome : null,
      idFornecedor: !isReceber && contatoIdDigitado.isNotEmpty ? contatoIdDigitado : null,
      nomeFornecedor: !isReceber && contatoNome.isNotEmpty ? contatoNome : null,
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_toDouble(_valorController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor maior que zero.')),
      );
      return;
    }

    final LancamentoAgendaFinanceiraRequest request = _buildRequest();
    setState(() => _isLoading = true);
    String? idGerado;
    String? aviso;

    try {
      final LancamentoAgendaFinanceiraResponse response = widget.modoEdicao
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.modoEdicao ? 'Erro ao atualizar lançamento: ${e.statusCode}' : 'Erro ao salvar lançamento: ${e.statusCode}')),
        );
        return;
      }
    } catch (_) {
      aviso = widget.modoEdicao
          ? 'Não foi possível confirmar a API no momento. Alterações mantidas localmente.'
          : 'Não foi possível confirmar a API no momento. Payload foi montado e mantido localmente.';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(aviso ?? (widget.modoEdicao ? 'Lançamento atualizado com sucesso.' : 'Lançamento salvo com sucesso.'))),
    );
    final String idRetorno = idGerado ?? _idLancamentoEdicao ?? request.uuidOperacaoApp;
    Navigator.of(context).pop(request.toAgendaItem(idFallback: idRetorno));
  }

  Future<void> _confirmarExcluirLancamento() async {
    final String? id = _idLancamentoEdicao;
    if (!widget.modoEdicao || id == null || id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento ainda não possui identificador para exclusão.')),
      );
      return;
    }

    final bool confirmado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            final ColorScheme colorScheme = Theme.of(dialogContext).colorScheme;
            return AlertDialog(
              title: const Text('Excluir lançamento?'),
              content: const Text('Esta ação vai apagar de forma definitiva este lançamento financeiro. Essa operação não pode ser desfeita.'),
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
        ) ??
        false;

    if (confirmado) await _excluirLancamento(id);
  }

  Future<void> _excluirLancamento(String idLancamento) async {
    setState(() => _isLoading = true);
    try {
      final LancamentoAgendaFinanceiraResponse response = await _service.excluirLancamento(idLancamento);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento excluído definitivamente.')),
      );
      Navigator.of(context).pop(<String, dynamic>{
        'id': response.id.isEmpty ? idLancamento : response.id,
        'deleted': true,
        'status': response.status,
      });
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir lançamento: ${e.statusCode}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o lançamento agora.')),
      );
    }
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: _inputDecoration(label, hintText: hintText),
      validator: requiredField
          ? (String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null
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
          ? (String? v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
      onTap: !enabled
          ? null
          : () async {
              final DateTime? selecionada = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selecionada == null) return;
              onChanged(_normalizarData(selecionada));
              _sincronizarTextosData();
              setState(() {});
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
    final List<String> safeItems = items.isEmpty ? <String>['Pix'] : items;
    final String safeValue = safeItems.contains(value) ? value : safeItems.first;
    return DropdownButtonFormField<String>(
      value: safeValue,
      onChanged: enabled ? onChanged : null,
      decoration: _inputDecoration(label),
      items: safeItems
          .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(),
    );
  }

  Widget _buildAvisoLancamentoConfirmado() {
    if (!_bloquearTipoStatus) return const SizedBox.shrink();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool telaGrande = constraints.maxWidth >= 1080;
        final bool telaMedia = constraints.maxWidth >= 760;
        double largura(double grande, double media) =>
            telaGrande ? grande : (telaMedia ? media : double.infinity);

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
                      SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Tipo', value: _tipoSelecionado, items: _tipos, enabled: !_bloquearTipoStatus, onChanged: (String? v) => setState(() => _aplicarTipoSelecionado(v!)))),
                      SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Status', value: _statusSelecionado, items: _status, enabled: !_bloquearTipoStatus, onChanged: (String? v) => setState(() => _statusSelecionado = v!))),
                      SizedBox(width: largura(320, 300), child: _buildTextField(controller: _descricaoController, label: 'Descrição', requiredField: true)),
                      SizedBox(width: largura(260, 220), child: _buildTextField(controller: _valorController, label: 'Valor total', requiredField: true, enabled: !_bloquearTipoStatus, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      SizedBox(width: largura(260, 220), child: _buildTextField(controller: _valorConfirmadoController, label: 'Valor confirmado', enabled: false, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      SizedBox(width: largura(260, 220), child: _buildDateField(label: 'Data de vencimento', controller: _dataVencimentoController, initialDate: _dataVencimento, requiredField: true, onChanged: (DateTime date) => _dataVencimento = date)),
                      SizedBox(width: largura(260, 220), child: _buildDateField(label: 'Data da operação', controller: _dataOperacaoController, initialDate: _dataOperacao, requiredField: true, onChanged: (DateTime date) => _dataOperacao = date)),
                      SizedBox(width: largura(260, 220), child: _buildDateField(label: 'Competência', controller: _dataCompetenciaController, initialDate: _dataCompetencia, onChanged: (DateTime date) => _dataCompetencia = date)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Classificação e filtros',
                  subtitle: 'Informações usadas para segmentação por origem, empresa e forma prevista de pagamento.',
                  icon: Icons.filter_alt_outlined,
                  child: Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
                    SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Origem', value: _origemSelecionada, items: _origens, onChanged: (String? v) => setState(() => _origemSelecionada = v!))),
                    SizedBox(width: largura(260, 220), child: _buildDropdownField(label: 'Empresa', value: _empresaSelecionada, items: widget.empresas.isEmpty ? <String>['Empresa'] : widget.empresas, onChanged: (String? v) => setState(() => _empresaSelecionada = v!))),
                    SizedBox(
                      width: largura(300, 260),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: <Widget>[
                          _buildDropdownField(
                            label: 'Forma prevista de pagamento',
                            value: _formaPagamentoSelecionada,
                            items: _formasPagamento,
                            onChanged: (String? v) => setState(() => _formaPagamentoSelecionada = v!),
                          ),
                          if (_carregandoTiposRecebimento)
                            const Padding(
                              padding: EdgeInsets.only(right: 36),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _categoriaController, label: 'Categoria')),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _centroCustoController, label: 'Centro de custo')),
                    SizedBox(width: largura(240, 220), child: _buildTextField(controller: _documentoFiscalController, label: 'Documento fiscal')),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Contato e responsabilidade',
                  subtitle: 'Dados opcionais exibidos nos cards da agenda e usados para cobrança/pagamento.',
                  icon: Icons.person_outline,
                  child: Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
                    SizedBox(width: largura(260, 220), child: _buildTextField(controller: _idContatoController, label: _tipoSelecionado == 'Receber' ? 'ID do cliente' : 'ID do fornecedor')),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _contatoController, label: _tipoSelecionado == 'Receber' ? 'Cliente' : 'Fornecedor')),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _responsavelController, label: 'Responsável')),
                    SizedBox(width: largura(320, 280), child: _buildTextField(controller: _referenciaController, label: 'Referência externa')),
                    SizedBox(width: largura(900, 680), child: _buildTextField(controller: _observacoesController, label: 'Observações', maxLines: 3)),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Status de confirmação',
                  subtitle: 'Marque apenas se o lançamento já nasceu quitado.',
                  icon: Icons.verified_outlined,
                  child: Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
                    FilterChip(
                      selected: _statusQuitada,
                      onSelected: _bloquearTipoStatus
                          ? null
                          : (bool value) {
                              setState(() {
                                _statusQuitada = value;
                                if (value) {
                                  _statusSelecionado = _tipoSelecionado == 'Receber' ? 'Recebido' : 'Pago';
                                  _valorConfirmadoController.text = _valorController.text;
                                } else {
                                  _statusSelecionado = 'Pendente';
                                  _valorConfirmadoController.text = '0,00';
                                }
                              });
                            },
                      label: Text(_tipoSelecionado == 'Receber' ? 'Já recebido' : 'Já pago'),
                      avatar: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    ),
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
