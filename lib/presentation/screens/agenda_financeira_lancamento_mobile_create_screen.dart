import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/date_selector_mobile_bottom_sheet.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

class AgendaFinanceiraLancamentoMobileCreateScreen extends StatefulWidget {
  const AgendaFinanceiraLancamentoMobileCreateScreen({
    super.key,
    this.service,
    this.caixaApiClient,
  });

  final AgendaFinanceiraLancamentoService? service;
  final CaixaApiClient? caixaApiClient;

  @override
  State<AgendaFinanceiraLancamentoMobileCreateScreen> createState() =>
      _AgendaFinanceiraLancamentoMobileCreateScreenState();
}

class _AgendaFinanceiraLancamentoMobileCreateScreenState
    extends State<AgendaFinanceiraLancamentoMobileCreateScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;
  static Color get _softBlueColor => SixMobilePalette.softAccentSurface;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AgendaFinanceiraLancamentoService _service =
      widget.service ?? AgendaFinanceiraLancamentoService();
  late final CaixaApiClient _caixaApiClient =
      widget.caixaApiClient ?? HttpCaixaApiClient();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _documentoFiscalController =
      TextEditingController();
  final TextEditingController _centroCustoController = TextEditingController();

  static const List<String> _tipos = <String>['Pagar', 'Receber'];

  String _tipoSelecionado = 'Pagar';
  String _statusSelecionado = 'Pendente';
  String _origemSelecionada = 'Despesa manual';
  String _codigoTipoRecebimentoSelecionado = '';
  final String _empresa = 'Empresa';
  List<String> _formasPagamento = <String>[];
  final Map<String, String> _codigoTipoPorDescricaoFormaPagamento =
      <String, String>{};
  final Map<String, String> _descricaoPorCodigoTipoFormaPagamento =
      <String, String>{};

  DateTime _dataOperacao = _inicioHoje();
  DateTime _dataVencimento = _inicioHoje();
  DateTime _dataCompetencia = _inicioHoje();

  bool _salvando = false;
  bool _carregandoTiposRecebimento = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTiposRecebimentoAtivos();
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

  static DateTime _inicioHoje() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: 'Novo lançamento',
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      scrollEffectOffset: 24,
      scrolledSurfaceOpacity: 0.66,
      leading: IconButton(
        tooltip: 'Voltar',
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: _salvando ? null : () => Navigator.of(context).maybePop(),
      ),
      bottomNavigationBar: _buildBottomBar(),
      bodyBuilder: _buildContent,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 112),
          children: <Widget>[
            SixStaggeredEntry(child: _buildHeaderCard()),
            SizedBox(height: 14),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 60),
              child: _buildMainSection(),
            ),
            SizedBox(height: 14),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 110),
              child: _buildValueSection(),
            ),
            SizedBox(height: 14),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 160),
              child: _buildDateSection(),
            ),
            SizedBox(height: 14),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 210),
              child: _buildContactSection(),
            ),
            SizedBox(height: 14),
            SixStaggeredEntry(
              delay: Duration(milliseconds: 260),
              child: _buildExtraSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0x33FFFFFF)),
            ),
            child: Icon(
              Icons.add_card_rounded,
              color: SixMobilePalette.onPrimary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Novo lançamento financeiro',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cadastre uma previsão a pagar ou receber na agenda.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    return _buildSection(
      title: 'Dados principais',
      subtitle: 'Informações usadas nos filtros e na lista da agenda.',
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        _buildTypeSelector(),
        SizedBox(height: 12),
        _textField(
          controller: _descricaoController,
          label: 'Descrição',
          icon: Icons.notes_outlined,
          validator:
              (String? value) =>
                  (value ?? '').trim().isEmpty ? 'Informe a descrição.' : null,
        ),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _selectorTile(
                label: 'Status',
                value: _statusSelecionado,
                icon: Icons.flag_outlined,
                onTap:
                    () => _selecionarValor(
                      titulo: 'Selecionar status',
                      opcoes: _statusParaTipo(),
                      selecionado: _statusSelecionado,
                      onSelected: (String value) => _statusSelecionado = value,
                    ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _selectorTile(
                label: 'Origem',
                value: _origemSelecionada,
                icon: Icons.source_outlined,
                onTap:
                    () => _selecionarValor(
                      titulo: 'Selecionar origem',
                      opcoes: _origensParaTipo(),
                      selecionado: _origemSelecionada,
                      onSelected: (String value) => _origemSelecionada = value,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueSection() {
    return _buildSection(
      title: 'Valores e pagamento',
      subtitle: 'Defina o valor previsto e a forma de pagamento esperada.',
      icon: Icons.account_balance_wallet_outlined,
      children: <Widget>[
        _textField(
          controller: _valorController,
          label: 'Valor total',
          icon: Icons.attach_money_rounded,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator:
              (String? value) =>
                  _toDouble(value) <= 0
                      ? 'Informe um valor maior que zero.'
                      : null,
        ),
        SizedBox(height: 12),
        _selectorTile(
          label:
              _carregandoTiposRecebimento
                  ? 'Carregando formas...'
                  : 'Forma prevista de pagamento',
          value: _formaPagamentoSelecionadaLabel(),
          icon: Icons.payments_outlined,
          onTap:
              _carregandoTiposRecebimento || _formasPagamento.isEmpty
                  ? null
                  : () => _selecionarValor(
                    titulo: 'Forma prevista de pagamento',
                    opcoes: _formasPagamento,
                    selecionado: _formaPagamentoSelecionadaLabel(),
                    onSelected: (String value) {
                      _codigoTipoRecebimentoSelecionado =
                          _codigoTipoPorDescricaoFormaPagamento[value] ??
                          _codigoTipoRecebimentoSelecionado;
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return _buildSection(
      title: 'Datas',
      subtitle: 'Organize operação, competência e vencimento.',
      icon: Icons.calendar_month_outlined,
      children: <Widget>[
        _selectorTile(
          label: 'Vencimento',
          value: _formatarDataBr(_dataVencimento),
          icon: Icons.event_available_outlined,
          onTap:
              () => _selecionarData(
                titulo: 'Data de vencimento',
                atual: _dataVencimento,
                onSelected: (DateTime value) => _dataVencimento = value,
              ),
        ),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _selectorTile(
                label: 'Competência',
                value: _formatarDataBr(_dataCompetencia),
                icon: Icons.event_note_outlined,
                onTap:
                    () => _selecionarData(
                      titulo: 'Data de competência',
                      atual: _dataCompetencia,
                      onSelected: (DateTime value) => _dataCompetencia = value,
                    ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _selectorTile(
                label: 'Operação',
                value: _formatarDataBr(_dataOperacao),
                icon: Icons.today_outlined,
                onTap:
                    () => _selecionarData(
                      titulo: 'Data da operação',
                      atual: _dataOperacao,
                      onSelected: (DateTime value) => _dataOperacao = value,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contato e classificação',
      subtitle: 'Identifique o cliente, fornecedor e agrupamento financeiro.',
      icon: Icons.person_outline,
      children: <Widget>[
        _textField(
          controller: _contatoController,
          label: _tipoSelecionado == 'Receber' ? 'Cliente' : 'Fornecedor',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 12),
        _textField(
          controller: _categoriaController,
          label: 'Categoria',
          icon: Icons.sell_outlined,
        ),
        SizedBox(height: 12),
        _textField(
          controller: _responsavelController,
          label: 'Responsável',
          icon: Icons.badge_outlined,
        ),
        SizedBox(height: 12),
        _textField(
          controller: _centroCustoController,
          label: 'Centro de custo',
          icon: Icons.account_tree_outlined,
        ),
      ],
    );
  }

  Widget _buildExtraSection() {
    return _buildSection(
      title: 'Informações adicionais',
      subtitle: 'Campos opcionais para conciliação e observações.',
      icon: Icons.more_horiz_outlined,
      children: <Widget>[
        _textField(
          controller: _referenciaController,
          label: 'Referência',
          icon: Icons.tag_outlined,
        ),
        SizedBox(height: 12),
        _textField(
          controller: _documentoFiscalController,
          label: 'Documento fiscal',
          icon: Icons.description_outlined,
        ),
        SizedBox(height: 12),
        _textField(
          controller: _observacoesController,
          label: 'Observações',
          icon: Icons.notes_outlined,
          minLines: 3,
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children:
          _tipos.map((String tipo) {
            final bool selected = tipo == _tipoSelecionado;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: tipo == _tipos.first ? 8 : 0),
                child: InkWell(
                  onTap:
                      _salvando
                          ? null
                          : () {
                            setState(() {
                              _tipoSelecionado = tipo;
                              _alinharCamposComTipo(tipo);
                            });
                          },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: selected ? _primaryColor : _softBlueColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? _primaryColor : _borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          tipo == 'Receber'
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color:
                              selected
                                  ? SixMobilePalette.onPrimary
                                  : _accentColor,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            tipo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  selected
                                      ? SixMobilePalette.onPrimary
                                      : _titleTextColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow.withValues(alpha: 0.70),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _softBlueColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _accentColor, size: 19),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
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
      enabled: !_salvando,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: SixMobilePalette.softNeutralSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _accentColor, width: 1.4),
        ),
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
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: _accentColor, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: _mutedTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded),
                label: Text('Cancelar'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon:
                    _salvando
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SixMobilePalette.onPrimary,
                          ),
                        )
                        : Icon(Icons.check_rounded),
                label: Text(_salvando ? 'Salvando...' : 'Salvar lançamento'),
              ),
            ),
          ],
        ),
      ),
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder:
          (BuildContext context) => _AgendaMobileOptionSheet(
            title: titulo,
            values: opcoes,
            selected: selecionado,
          ),
    );
    if (result == null || !mounted) return;
    setState(() => onSelected(result));
  }

  Future<void> _selecionarData({
    required String titulo,
    required DateTime atual,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = _inicioHoje().add(Duration(days: 3650));
    final DateTime initial =
        atual.isBefore(firstDate)
            ? firstDate
            : (atual.isAfter(lastDate) ? lastDate : atual);
    final DateTime? selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext context) {
        return DateSelectorMobileBottomSheet(
          title: titulo,
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
          applyButtonLabel: 'Aplicar data',
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => onSelected(_normalizarData(selected)));
  }

  Future<void> _carregarTiposRecebimentoAtivos() async {
    setState(() => _carregandoTiposRecebimento = true);
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<String> formas = _montarFormasPagamentoAtivas(
        informacoes.tiposRecebimento,
      );
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasPagamento = formas;
        if (!_descricaoPorCodigoTipoFormaPagamento.containsKey(
          _codigoTipoRecebimentoSelecionado,
        )) {
          _codigoTipoRecebimentoSelecionado =
              _codigoTipoPorDescricaoFormaPagamento[_formasPagamento.first] ??
              '';
        }
      });
    } catch (_) {
      // Sem fallback local: as formas de recebimento devem vir do backend.
    } finally {
      if (mounted) setState(() => _carregandoTiposRecebimento = false);
    }
  }

  List<String> _montarFormasPagamentoAtivas(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos =
        tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()..sort(
          (TiposRecebimento a, TiposRecebimento b) =>
              a.ordemExibicao.compareTo(b.ordemExibicao),
        );
    final List<String> descricoes = <String>[];
    final Map<String, String> codigosPorDescricao = <String, String>{};
    final Map<String, String> descricoesPorCodigo = <String, String>{};
    for (final TiposRecebimento tipo in ativos) {
      final String codigo = tipo.codigoTipo.trim().toLowerCase();
      if (!_codigoTipoValido(codigo)) continue;
      final String descricao =
          tipo.descricaoExibicao.trim().isNotEmpty
              ? tipo.descricaoExibicao.trim()
              : codigo;
      if (descricao.trim().isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      codigosPorDescricao[descricao] = codigo;
      descricoesPorCodigo[codigo] = descricao;
    }
    if (descricoes.isNotEmpty) {
      _codigoTipoPorDescricaoFormaPagamento
        ..clear()
        ..addAll(codigosPorDescricao);
      _descricaoPorCodigoTipoFormaPagamento
        ..clear()
        ..addAll(descricoesPorCodigo);
    }
    return descricoes;
  }

  bool _codigoTipoValido(String codigo) {
    return RegExp(r'^tipo(10|[1-9])$').hasMatch(codigo.trim().toLowerCase());
  }

  Future<void> _salvar() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final double valorTotal = _toDouble(_valorController.text);
    if (valorTotal <= 0) {
      _mostrarSnack('Informe um valor maior que zero.');
      return;
    }
    if (_codigoTipoRecebimentoSelecionado.trim().isEmpty) {
      _mostrarSnack('Carregue e selecione uma forma de pagamento.');
      return;
    }

    final LancamentoAgendaFinanceiraRequest request = _buildRequest(valorTotal);
    setState(() => _salvando = true);
    try {
      final LancamentoAgendaFinanceiraResponse response = await _service
          .cadastrarLancamento(request);
      if (!mounted) return;
      _mostrarSnack('Lançamento salvo com sucesso.');
      final String idRetorno =
          response.id.isEmpty ? request.uuidOperacaoApp : response.id;
      Navigator.of(context).pop(request.toAgendaItem(idFallback: idRetorno));
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      _mostrarSnack('Erro ao salvar lançamento (${e.statusCode}).');
    } catch (_) {
      if (!mounted) return;
      _mostrarSnack('Não foi possível salvar o lançamento.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  LancamentoAgendaFinanceiraRequest _buildRequest(double valorTotal) {
    final bool isReceber = _tipoSelecionado == 'Receber';
    final String tipoOperacao = isReceber ? 'RECEBER' : 'PAGAR';
    final String origem = _origemParaBackend(
      _origemSelecionada,
      _tipoSelecionado,
    );
    final String formaPagamento = _formaPagamentoParaBackend();
    final String contatoNome = _contatoController.text.trim();
    final String statusBackend = _statusParaBackend(_statusSelecionado);
    final bool statusQuitada = _statusEstaQuitada(statusBackend);
    final String uuid = 'mobile-${DateTime.now().microsecondsSinceEpoch}';

    final Map<String, dynamic> payload = <String, dynamic>{
      'agendaFinanceira': <String, dynamic>{
        'tipoFiltro': tipoOperacao,
        'statusFiltro': statusBackend,
        'origemFiltro': origem,
        'empresaFiltro': _empresa,
        'formaPrevistaPagamento': formaPagamento,
      },
      'contato': <String, dynamic>{'nome': contatoNome},
      'origem': 'mobile',
    };

    return LancamentoAgendaFinanceiraRequest(
      uuidOperacaoApp: uuid,
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
      idCliente: null,
      nomeCliente: isReceber && contatoNome.isNotEmpty ? contatoNome : null,
      idFornecedor: null,
      nomeFornecedor: !isReceber && contatoNome.isNotEmpty ? contatoNome : null,
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
      recorrente: false,
      frequenciaRecorrencia: 'NAO_RECORRENTE',
      recorrenciaInicio: _dataVencimento,
      recorrenciaFim: _dataVencimento,
      quantidadeParcelas: 1,
      diaVencimentoRecorrencia: _dataVencimento.day,
      payloadOriginalJson: payload,
    );
  }

  List<String> _statusParaTipo() {
    if (_tipoSelecionado == 'Receber') {
      return <String>['Previsto', 'Pendente', 'Recebido'];
    }
    return <String>['Previsto', 'Pendente', 'Pago'];
  }

  List<String> _origensParaTipo() {
    if (_tipoSelecionado == 'Receber') {
      return <String>['Venda', 'Ordem de serviço', 'Parcela'];
    }
    return <String>[
      'Despesa manual',
      'Compra',
      'Parcela',
      'Movimentação de caixa',
    ];
  }

  void _alinharCamposComTipo(String tipo) {
    final List<String> statusPermitidos = _statusParaTipo();
    if (!statusPermitidos.contains(_statusSelecionado)) {
      _statusSelecionado = 'Pendente';
    }
    final List<String> origensPermitidas = _origensParaTipo();
    if (!origensPermitidas.contains(_origemSelecionada)) {
      _origemSelecionada = tipo == 'Receber' ? 'Venda' : 'Despesa manual';
    }
  }

  String _formaPagamentoParaBackend() {
    return _codigoTipoRecebimentoSelecionado.trim().toLowerCase();
  }

  String _formaPagamentoSelecionadaLabel() {
    if (_codigoTipoRecebimentoSelecionado.trim().isEmpty) {
      return _carregandoTiposRecebimento
          ? 'Carregando...'
          : 'Selecione uma forma';
    }
    return _descricaoPorCodigoTipoFormaPagamento[_codigoTipoRecebimentoSelecionado
            .trim()
            .toLowerCase()] ??
        _codigoTipoRecebimentoSelecionado;
  }

  String _statusParaBackend(String status) {
    switch (status) {
      case 'Pago':
        return 'PAGO';
      case 'Recebido':
        return 'RECEBIDO';
      case 'Previsto':
        return 'PREVISTO';
      default:
        return 'PENDENTE';
    }
  }

  bool _statusEstaQuitada(String status) {
    return status == 'PAGO' || status == 'RECEBIDO';
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

  DateTime _normalizarData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  String _formatarDataBr(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final String texto = value.trim();
      final String normalizado =
          texto.contains(',') && texto.contains('.')
              ? texto.replaceAll('.', '').replaceAll(',', '.')
              : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }
}

class _AgendaMobileOptionSheet extends StatelessWidget {
  const _AgendaMobileOptionSheet({
    required this.title,
    required this.values,
    required this.selected,
  });

  final String title;
  final List<String> values;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: SixMobilePalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: SixMobilePalette.activeBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Toque em uma opção para aplicar.',
              style: TextStyle(color: SixMobilePalette.mutedText, fontSize: 13),
            ),
            SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: values.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String value = values[index];
                  final bool isSelected = value == selected;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).pop(value),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? SixMobilePalette.primary
                                : SixMobilePalette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              isSelected
                                  ? SixMobilePalette.primary
                                  : SixMobilePalette.border,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color:
                                isSelected
                                    ? SixMobilePalette.onPrimary
                                    : SixMobilePalette.accent,
                            size: 19,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? SixMobilePalette.onPrimary
                                        : SixMobilePalette.titleText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
