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
        textoDaAppBar:
            modoEdicao
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
  final TextEditingController _documentoFiscalController =
      TextEditingController();
  final TextEditingController _centroCustoController = TextEditingController();
  final TextEditingController _quantidadeParcelasController =
      TextEditingController(text: '12');
  final TextEditingController _dataOperacaoController = TextEditingController();
  final TextEditingController _dataVencimentoController =
      TextEditingController();
  final TextEditingController _dataCompetenciaController =
      TextEditingController();
  final TextEditingController _inicioRecorrenciaController =
      TextEditingController();
  final TextEditingController _fimRecorrenciaController =
      TextEditingController();

  bool _isLoading = false;
  bool _recorrente = false;
  bool _statusQuitada = false;
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

  @override
  void initState() {
    super.initState();
    _empresaSelecionada =
        widget.empresas.contains(widget.empresaSelecionada)
            ? widget.empresaSelecionada
            : widget.empresas.first;

    if (widget.modoEdicao && widget.lancamentoInicial != null) {
      _preencherCamposEdicao(widget.lancamentoInicial!);
    }

    _garantirRecorrenciaConsistente();
    _sincronizarTextosData();
  }

  void _preencherCamposEdicao(Map<String, dynamic> item) {
    _idLancamentoEdicao = item['id']?.toString();
    _uuidOperacaoAppEdicao =
        item['uuidOperacaoApp']?.toString() ?? item['id']?.toString();

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
    _statusQuitada = status == 'Pago' || status == 'Recebido';

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
    _dataCompetencia = _parseData(
      item['dataCompetencia'],
      fallback: _dataVencimento,
    );

    _recorrente = _itemIndicaRecorrencia(item);
    _frequenciaRecorrencia = _normalizarFrequencia(
      item['frequenciaRecorrencia'],
      fallback: _frequenciaRecorrencia,
    );
    _inicioRecorrencia = _parseData(
      item['recorrenciaInicio'],
      fallback: _dataVencimento,
    );
    _fimRecorrencia =
        item['recorrenciaFim'] != null
            ? _parseData(item['recorrenciaFim'], fallback: _dataVencimento)
            : null;

    final quantidadeParcelas = item['quantidadeParcelas'];
    if (quantidadeParcelas is num && quantidadeParcelas > 0) {
      _quantidadeParcelasController.text =
          quantidadeParcelas.toInt().toString();
    }
  }

  bool _itemIndicaRecorrencia(Map<String, dynamic> item) {
    if (item['recorrente'] == true) return true;

    final quantidade = item['quantidadeParcelas'];
    if (quantidade is num && quantidade > 1) return true;

    final frequencia = item['frequenciaRecorrencia']?.toString().trim() ?? '';
    if (frequencia.isEmpty) return false;
    final normalizada = _normalizarSemAcento(frequencia).toUpperCase();
    return normalizada != 'NAO RECORRENTE' && normalizada != 'NAO_RECORRENTE';
  }

  DateTime _parseData(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return _normalizarData(value);

    final texto = value.toString().trim();
    if (texto.isEmpty) return fallback;

    if (texto.contains('/')) {
      final partes = texto.split('/');
      if (partes.length == 3) {
        final dia = int.tryParse(partes[0]);
        final mes = int.tryParse(partes[1]);
        final ano = int.tryParse(partes[2]);
        if (dia != null && mes != null && ano != null) {
          return DateTime(ano, mes, dia);
        }
      }
    }

    final iso = DateTime.tryParse(texto);
    return iso == null ? fallback : _normalizarData(iso);
  }

  DateTime _normalizarData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  String _formatarValorParaCampo(dynamic valor) {
    if (valor is num) return valor.toStringAsFixed(2).replaceAll('.', ',');

    final texto = valor?.toString().trim() ?? '';
    if (texto.isEmpty) return '';

    final numero = double.tryParse(texto);
    if (numero != null) return numero.toStringAsFixed(2).replaceAll('.', ',');

    return texto;
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

  String _normalizarFrequencia(dynamic value, {String fallback = 'Mensal'}) {
    final texto = value?.toString().trim() ?? '';
    if (texto.isEmpty) return fallback;

    final normalizado = _normalizarSemAcento(texto).toUpperCase();
    switch (normalizado) {
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
      case 'NAO RECORRENTE':
      case 'NAO_RECORRENTE':
        return fallback;
      default:
        return _frequencias.contains(texto) ? texto : fallback;
    }
  }

  bool _origemSugerePagar(String origem) {
    return origem == 'Despesa manual' || origem == 'Compra';
  }

  bool _origemSugereReceber(String origem) {
    return origem == 'Venda' || origem == 'Ordem de serviço';
  }

  String _origemPadraoPorTipo(String tipo) {
    return tipo == 'Receber' ? 'Venda' : 'Despesa manual';
  }

  void _alinharOrigemComTipo(String tipo) {
    if (tipo == 'Receber' && _origemSugerePagar(_origemSelecionada)) {
      _origemSelecionada = _origemPadraoPorTipo(tipo);
    } else if (tipo == 'Pagar' && _origemSugereReceber(_origemSelecionada)) {
      _origemSelecionada = _origemPadraoPorTipo(tipo);
    }
  }

  void _aplicarTipoSelecionado(String tipo) {
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

  int _toInt(String text) {
    return int.tryParse(text.trim()) ?? 0;
  }

  double _toDouble(String text) {
    final normalizado = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0;
  }

  int _quantidadeParcelasInformada() {
    final quantidade = _toInt(_quantidadeParcelasController.text);
    return quantidade > 0 ? quantidade : 1;
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
        final meses = _mesesPorFrequencia(frequencia);
        return _somarMesesPreservandoDia(inicio, meses * incremento);
    }
  }

  void _garantirRecorrenciaConsistente({bool recalcularFim = false}) {
    if (!_recorrente) {
      _fimRecorrencia = null;
      return;
    }

    _inicioRecorrencia = _normalizarData(_inicioRecorrencia);
    if (_quantidadeParcelasInformada() <= 0) {
      _quantidadeParcelasController.text = '12';
    }

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
        if (_quantidadeParcelasInformada() <= 1) {
          _quantidadeParcelasController.text = '12';
        }
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

  void _sincronizarTextosData() {
    _dataOperacaoController.text = _formatarDataBr(_dataOperacao);
    _dataVencimentoController.text = _formatarDataBr(_dataVencimento);
    _dataCompetenciaController.text = _formatarDataBr(_dataCompetencia);
    _inicioRecorrenciaController.text = _formatarDataBr(_inicioRecorrencia);
    _fimRecorrenciaController.text =
        _fimRecorrencia != null ? _formatarDataBr(_fimRecorrencia!) : '';
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: _inputDecoration(label, hintText: hintText),
      validator:
          requiredField
              ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              }
              : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required DateTime initialDate,
    required ValueChanged<DateTime> onChanged,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(label),
      validator:
          requiredField
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
              : null,
      onTap: () async {
        final selecionada = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

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
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: _inputDecoration(label),
      items:
          items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.request_page_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.modoEdicao
                        ? 'Editar lançamento financeiro'
                        : 'Novo lançamento financeiro',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.modoEdicao
                        ? 'Atualize os campos e envie para persistir alterações no backend.'
                        : 'Cadastro completo com suporte a recorrência e payload preparado para backend.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              _isLoading
                  ? (widget.modoEdicao ? 'Atualizando...' : 'Enviando...')
                  : 'Pronto para salvar',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusPadraoPorTipo() {
    if (_statusQuitada) {
      return _tipoSelecionado == 'Receber' ? 'Recebido' : 'Pago';
    }
    return _statusSelecionado;
  }

  String _tipoOperacaoParaBackend() {
    return _tipoSelecionado.toUpperCase();
  }

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
    final idLocal =
        _uuidOperacaoAppEdicao ?? DateTime.now().millisecondsSinceEpoch.toString();
    final tipoOperacao = _tipoOperacaoParaBackend();
    final origem = _origemParaBackend();
    final formaPagamento = _formaPagamentoParaBackend();
    final contatoIdDigitado = _idContatoController.text.trim();
    final contatoNome = _contatoController.text.trim();
    final contatoIdPayload =
        contatoIdDigitado.isEmpty ? 'contato-$idLocal' : contatoIdDigitado;
    final contatoIdOuNull = contatoIdDigitado.isEmpty ? null : contatoIdDigitado;
    final contatoNomeOuNull = contatoNome.isEmpty ? null : contatoNome;
    final isReceber = _tipoSelecionado == 'Receber';
    final quantidadeParcelas = _recorrente ? _quantidadeParcelasInformada() : 1;
    final recorrenciaInicio = _recorrente ? _inicioRecorrencia : _dataVencimento;
    final recorrenciaFim =
        _recorrente
            ? (_fimRecorrencia ??
                _calcularFimRecorrencia(
                  inicio: recorrenciaInicio,
                  frequencia: _frequenciaRecorrencia,
                  quantidadeParcelas: quantidadeParcelas,
                ))
            : _dataVencimento;
    final frequenciaRecorrencia =
        _recorrente ? _frequenciaRecorrencia : 'Nao recorrente';
    final diaVencimentoRecorrencia = _dataVencimento.day;

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
      referenciaExterna:
          _referenciaController.text.trim().isEmpty
              ? null
              : _referenciaController.text.trim(),
      documentoFiscal:
          _documentoFiscalController.text.trim().isEmpty
              ? null
              : _documentoFiscalController.text.trim(),
      centroDeCusto:
          _centroCustoController.text.trim().isEmpty
              ? null
              : _centroCustoController.text.trim(),
      valorTotalProdutos: 0,
      valorTotalServicos: 0,
      valorTotalOperacao: valorTotal,
      observacoes:
          _observacoesController.text.trim().isEmpty
              ? null
              : _observacoesController.text.trim(),
      recorrente: _recorrente,
      frequenciaRecorrencia: frequenciaRecorrencia,
      recorrenciaInicio: recorrenciaInicio,
      recorrenciaFim: recorrenciaFim,
      quantidadeParcelas: quantidadeParcelas,
      diaVencimentoRecorrencia: diaVencimentoRecorrencia,
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

    if (_recorrente) {
      _garantirRecorrenciaConsistente(recalcularFim: _fimRecorrencia == null);
      _sincronizarTextosData();

      if (_quantidadeParcelasInformada() <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe a quantidade de parcelas da recorrência.'),
          ),
        );
        return;
      }

      if (_fimRecorrencia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o fim da recorrência.')),
        );
        return;
      }

      if (_fimRecorrencia!.isBefore(_inicioRecorrencia)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O fim da recorrência não pode ser anterior ao início.'),
          ),
        );
        return;
      }
    }

    final request = _buildRequest();

    setState(() => _isLoading = true);

    String? idGerado;
    String? aviso;

    try {
      final response =
          widget.modoEdicao
              ? await _service.editarLancamento(
                _idLancamentoEdicao ?? request.uuidOperacaoApp,
                request,
              )
              : await _service.cadastrarLancamento(request);
      idGerado = response.id;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501) {
        aviso =
            widget.modoEdicao
                ? 'Endpoint de edição ainda não publicado. Alterações mantidas localmente.'
                : 'Endpoint de lançamento financeiro ainda não publicado. Payload foi montado e mantido localmente.';
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.modoEdicao
                  ? 'Erro ao atualizar lançamento: ${e.statusCode}'
                  : 'Erro ao salvar lançamento: ${e.statusCode}',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    } catch (_) {
      aviso =
          widget.modoEdicao
              ? 'Não foi possível confirmar a API no momento. Alterações mantidas localmente.'
              : 'Não foi possível confirmar a API no momento. Payload foi montado e mantido localmente.';
    }

    if (!mounted) return;

    if (aviso != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.modoEdicao
                ? 'Lançamento atualizado com sucesso.'
                : 'Lançamento salvo com sucesso.',
          ),
        ),
      );
    }

    final idRetorno = idGerado ?? _idLancamentoEdicao ?? request.uuidOperacaoApp;
    Navigator.of(context).pop(request.toAgendaItem(idFallback: idRetorno));
  }

  String _formatarDataBr(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Widget _buildActionsBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          const Text(
            'Revise os dados do lançamento antes de concluir.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _salvar,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading
                      ? (widget.modoEdicao ? 'Atualizando...' : 'Salvando...')
                      : (widget.modoEdicao
                          ? 'Atualizar lançamento'
                          : 'Salvar lançamento'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecorrenciaResumo() {
    final theme = Theme.of(context);
    if (!_recorrente) return const SizedBox.shrink();

    final quantidade = _quantidadeParcelasInformada();
    final fim = _fimRecorrencia;
    final fimTexto = fim == null ? 'fim não definido' : _formatarDataBr(fim);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Serão consideradas $quantidade parcela(s), frequência $_frequenciaRecorrencia, de ${_formatarDataBr(_inicioRecorrencia)} até $fimTexto.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool telaGrande = constraints.maxWidth >= 1080;
        final bool telaMedia = constraints.maxWidth >= 760;

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
                  subtitle:
                      'Campos que alimentam filtros e detalhes da Agenda Financeira.',
                  icon: Icons.badge_outlined,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDropdownField(
                          label: 'Tipo',
                          value: _tipoSelecionado,
                          items: _tipos,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _aplicarTipoSelecionado(value));
                          },
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDropdownField(
                          label: 'Status',
                          value: _statusSelecionado,
                          items: _status,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _statusSelecionado = value);
                          },
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 300 : double.infinity),
                        child: _buildTextField(
                          controller: _descricaoController,
                          label: 'Descrição',
                          hintText: 'Ex.: Conta de internet da loja',
                          requiredField: true,
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildTextField(
                          controller: _valorController,
                          label: 'Valor total',
                          hintText: 'Ex.: 329,00',
                          requiredField: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
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
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDateField(
                          label: 'Data da operação',
                          controller: _dataOperacaoController,
                          initialDate: _dataOperacao,
                          requiredField: true,
                          onChanged: (date) => _dataOperacao = date,
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDateField(
                          label: 'Competência',
                          controller: _dataCompetenciaController,
                          initialDate: _dataCompetencia,
                          onChanged: (date) => _dataCompetencia = date,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Classificação e filtros',
                  subtitle:
                      'Informações usadas para segmentação por origem, empresa e método de pagamento.',
                  icon: Icons.filter_alt_outlined,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDropdownField(
                          label: 'Origem',
                          value: _origemSelecionada,
                          items: _origens,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _origemSelecionada = value);
                          },
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDropdownField(
                          label: 'Empresa',
                          value: _empresaSelecionada,
                          items: widget.empresas,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _empresaSelecionada = value);
                          },
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildDropdownField(
                          label: 'Forma de pagamento',
                          value: _formaPagamentoSelecionada,
                          items: _formasPagamento,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _formaPagamentoSelecionada = value);
                          },
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 280 : double.infinity),
                        child: _buildTextField(
                          controller: _categoriaController,
                          label: 'Categoria',
                          hintText: 'Ex.: Infraestrutura',
                          requiredField: true,
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 280 : double.infinity),
                        child: _buildTextField(
                          controller: _centroCustoController,
                          label: 'Centro de custo',
                          hintText: 'Ex.: Operação da loja',
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 240
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildTextField(
                          controller: _documentoFiscalController,
                          label: 'Documento fiscal',
                          hintText: 'Ex.: NF 5561',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Contato e responsabilidade',
                  subtitle:
                      'Dados exibidos nos cards da agenda e usados para cobrança/pagamento.',
                  icon: Icons.person_outline,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildTextField(
                          controller: _idContatoController,
                          label:
                              _tipoSelecionado == 'Receber'
                                  ? 'ID do cliente'
                                  : 'ID do fornecedor',
                          hintText:
                              _tipoSelecionado == 'Receber'
                                  ? 'Ex.: cli-001'
                                  : 'Ex.: forn-001',
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 280 : double.infinity),
                        child: _buildTextField(
                          controller: _contatoController,
                          label:
                              _tipoSelecionado == 'Receber'
                                  ? 'Cliente'
                                  : 'Fornecedor',
                          hintText:
                              _tipoSelecionado == 'Receber'
                                  ? 'Ex.: João da Silva'
                                  : 'Ex.: Connect Fibra',
                          requiredField: true,
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 280 : double.infinity),
                        child: _buildTextField(
                          controller: _responsavelController,
                          label: 'Responsável',
                          hintText: 'Ex.: Carlos Lima',
                          requiredField: true,
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 280 : double.infinity),
                        child: _buildTextField(
                          controller: _referenciaController,
                          label: 'Referência externa',
                          hintText: 'Ex.: Contrato 2026-04',
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 900
                                : (telaMedia ? 680 : double.infinity),
                        child: _buildTextField(
                          controller: _observacoesController,
                          label: 'Observações',
                          hintText:
                              'Ex.: Confirmar se o débito automático foi processado.',
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Recorrência e status',
                  subtitle:
                      'Configuração de despesas/receitas recorrentes e quitação.',
                  icon: Icons.repeat_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          FilterChip(
                            selected: _recorrente,
                            onSelected: _onRecorrenteChanged,
                            label: const Text('Lançamento recorrente'),
                            avatar: const Icon(Icons.repeat_rounded, size: 18),
                          ),
                          FilterChip(
                            selected: _statusQuitada,
                            onSelected: (value) {
                              setState(() {
                                _statusQuitada = value;
                                if (value) {
                                  _statusSelecionado = _statusPadraoPorTipo();
                                }
                              });
                            },
                            label: const Text('Marcar como quitada'),
                            avatar: const Icon(
                              Icons.verified_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      if (_recorrente) ...<Widget>[
                        _buildRecorrenciaResumo(),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: <Widget>[
                            SizedBox(
                              width:
                                  telaGrande
                                      ? 260
                                      : (telaMedia ? 220 : double.infinity),
                              child: _buildDropdownField(
                                label: 'Frequência',
                                value: _frequenciaRecorrencia,
                                items: _frequencias,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _frequenciaRecorrencia = value;
                                    _recalcularFimRecorrencia();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width:
                                  telaGrande
                                      ? 260
                                      : (telaMedia ? 220 : double.infinity),
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
                              width:
                                  telaGrande
                                      ? 260
                                      : (telaMedia ? 220 : double.infinity),
                              child: _buildDateField(
                                label: 'Fim da recorrência',
                                controller: _fimRecorrenciaController,
                                initialDate:
                                    _fimRecorrencia ?? _inicioRecorrencia,
                                requiredField: true,
                                onChanged: (date) => _fimRecorrencia = date,
                              ),
                            ),
                            SizedBox(
                              width:
                                  telaGrande
                                      ? 220
                                      : (telaMedia ? 220 : double.infinity),
                              child: _buildTextField(
                                controller: _quantidadeParcelasController,
                                label: 'Qtd. parcelas',
                                keyboardType: TextInputType.number,
                                requiredField: true,
                                onChanged: (_) {
                                  setState(_recalcularFimRecorrencia);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
