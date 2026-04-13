import 'package:appplanilha/core/services/agenda_financeira_lancamento_service.dart';
import 'package:appplanilha/data/models/agenda_financeira_lancamento_model.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';

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
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return SubPainelLancamentoAgendaFinanceiraWeb(
        textoDaAppBar: 'Novo lançamento financeiro',
        body: _LancamentoAgendaFinanceiraWebBody(
          empresaSelecionada: empresaSelecionada,
          empresas: empresas,
        ),
      );
    },
  );
}

class _LancamentoAgendaFinanceiraWebBody extends StatefulWidget {
  const _LancamentoAgendaFinanceiraWebBody({
    required this.empresaSelecionada,
    required this.empresas,
  });

  final String empresaSelecionada;
  final List<String> empresas;

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

  static const List<String> _tipos = ['Pagar', 'Receber'];
  static const List<String> _status = [
    'Previsto',
    'Pendente',
    'Vence hoje',
    'Vencido',
    'Pago',
    'Recebido',
    'Parcial',
    'Cancelado',
  ];
  static const List<String> _origens = [
    'Venda',
    'Ordem de serviço',
    'Despesa manual',
    'Compra',
    'Parcela',
    'Movimentação de caixa',
  ];
  static const List<String> _formasPagamento = [
    'Pix',
    'Boleto',
    'Transferência',
    'Cartão de crédito',
    'Cartão de débito',
    'Débito automático',
    'Dinheiro',
  ];
  static const List<String> _frequencias = [
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
          onChanged(selecionada);
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
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
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
                children: const <Widget>[
                  Text(
                    'Novo lançamento de despesa',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cadastro completo com suporte a recorrência e payload preparado para backend.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
              _isLoading ? 'Enviando...' : 'Pronto para salvar',
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

  double _toDouble(String text) {
    final normalizado = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0;
  }

  int _toInt(String text) {
    return int.tryParse(text.trim()) ?? 0;
  }

  String _statusPadraoPorTipo() {
    if (_statusQuitada) {
      return _tipoSelecionado == 'Receber' ? 'Recebido' : 'Pago';
    }
    return _statusSelecionado;
  }

  LancamentoAgendaFinanceiraRequest _buildRequest() {
    final valorTotal = _toDouble(_valorController.text);
    final idLocal = DateTime.now().millisecondsSinceEpoch.toString();

    final payload = <String, dynamic>{
      'agendaFinanceira': {
        'tipoFiltro': _tipoSelecionado,
        'statusFiltro': _statusPadraoPorTipo(),
        'origemFiltro': _origemSelecionada,
        'empresaFiltro': _empresaSelecionada,
      },
      'contato': {
        'id': _idContatoController.text.trim(),
        'nome': _contatoController.text.trim(),
      },
      'recorrencia': {
        'recorrente': _recorrente,
        'frequencia': _recorrente ? _frequenciaRecorrencia : null,
        'inicio': _recorrente ? _inicioRecorrencia.toIso8601String() : null,
        'fim': _recorrente ? _fimRecorrencia?.toIso8601String() : null,
        'quantidadeParcelas':
            _recorrente ? _toInt(_quantidadeParcelasController.text) : null,
      },
    };

    return LancamentoAgendaFinanceiraRequest(
      uuidOperacaoApp: idLocal,
      descricao: _descricaoController.text.trim(),
      tipoOperacao: _tipoSelecionado.toLowerCase(),
      statusOperacao: _statusPadraoPorTipo(),
      dataOperacao: _dataOperacao,
      dataVencimento: _dataVencimento,
      dataCompetencia: _dataCompetencia,
      dataQuitacao: _statusQuitada ? DateTime.now() : null,
      statusQuitada: _statusQuitada,
      operacaoFinalizadaProntaCaixa: _statusQuitada,
      clientePediuParaApagar: false,
      origem: _origemSelecionada,
      formaPagamento: _formaPagamentoSelecionada,
      empresa: _empresaSelecionada,
      categoria: _categoriaController.text.trim(),
      idColaborador: 'web-user',
      nomeColaborador: _responsavelController.text.trim(),
      idCliente:
          _idContatoController.text.trim().isEmpty
              ? null
              : _idContatoController.text.trim(),
      nomeCliente:
          _contatoController.text.trim().isEmpty
              ? null
              : _contatoController.text.trim(),
      idFornecedor:
          _idContatoController.text.trim().isEmpty
              ? null
              : _idContatoController.text.trim(),
      nomeFornecedor:
          _contatoController.text.trim().isEmpty
              ? null
              : _contatoController.text.trim(),
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
      frequenciaRecorrencia: _recorrente ? _frequenciaRecorrencia : null,
      recorrenciaInicio: _recorrente ? _inicioRecorrencia : null,
      recorrenciaFim: _recorrente ? _fimRecorrencia : null,
      quantidadeParcelas:
          _recorrente ? _toInt(_quantidadeParcelasController.text) : null,
      diaVencimentoRecorrencia: _recorrente ? _dataVencimento.day : null,
      payloadOriginalJson: payload,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_toDouble(_valorController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor maior que zero.')),
      );
      return;
    }

    if (_recorrente && _toInt(_quantidadeParcelasController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a quantidade de parcelas da recorrência.'),
        ),
      );
      return;
    }

    final request = _buildRequest();

    setState(() => _isLoading = true);

    String? idGerado;
    String? aviso;

    try {
      final response = await _service.cadastrarLancamento(request);
      idGerado = response.id;
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501) {
        aviso =
            'Endpoint de lançamento financeiro ainda não publicado. Payload foi montado e mantido localmente.';
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar lançamento: ${e.statusCode}')),
        );
        setState(() => _isLoading = false);
        return;
      }
    } catch (_) {
      aviso =
          'Não foi possível confirmar a API no momento. Payload foi montado e mantido localmente.';
    }

    if (!mounted) {
      return;
    }

    if (aviso != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(aviso)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento salvo com sucesso.')),
      );
    }

    Navigator.of(context).pop(request.toAgendaItem(idFallback: idGerado));
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
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
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
                label: Text(_isLoading ? 'Salvando...' : 'Salvar lançamento'),
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
              children: [
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
                    children: [
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
                            setState(() {
                              _tipoSelecionado = value;
                              if (_statusQuitada) {
                                _statusSelecionado = _statusPadraoPorTipo();
                              }
                            });
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
                          onChanged: (date) => _dataVencimento = date,
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
                    children: [
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
                    children: [
                      SizedBox(
                        width:
                            telaGrande
                                ? 260
                                : (telaMedia ? 220 : double.infinity),
                        child: _buildTextField(
                          controller: _idContatoController,
                          label: 'ID do contato',
                          hintText: 'Ex.: cli-001',
                        ),
                      ),
                      SizedBox(
                        width:
                            telaGrande
                                ? 320
                                : (telaMedia ? 280 : double.infinity),
                        child: _buildTextField(
                          controller: _contatoController,
                          label: 'Contato (cliente/fornecedor)',
                          hintText: 'Ex.: Connect Fibra',
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
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilterChip(
                            selected: _recorrente,
                            onSelected:
                                (value) => setState(() => _recorrente = value),
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
                      if (_recorrente) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
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
                                  setState(
                                    () => _frequenciaRecorrencia = value,
                                  );
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
                                onChanged: (date) => _inicioRecorrencia = date,
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
