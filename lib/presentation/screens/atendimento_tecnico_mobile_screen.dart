import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/date_selector_mobile_bottom_sheet.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import '../utils/atendimento_tecnico_foto_payload.dart';
import 'cliente_usuario_cadastro_mobile_screen.dart';
import 'produto_list_mobile_screen.dart';

class AtendimentoTecnicoMobileScreen extends StatefulWidget {
  const AtendimentoTecnicoMobileScreen({
    super.key,
    this.service,
    this.clienteApiClient,
    this.colaboradorApiClient,
  });

  final AtendimentoTecnicoService? service;
  final ClienteUsuarioApiClient? clienteApiClient;
  final ColaboradorUsuarioApiClient? colaboradorApiClient;

  @override
  State<AtendimentoTecnicoMobileScreen> createState() =>
      _AtendimentoTecnicoMobileScreenState();
}

class _AtendimentoTecnicoMobileScreenState
    extends State<AtendimentoTecnicoMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _onPrimaryColor => SixMobilePalette.onPrimary;
  static Color get _heroSupportingTextColor =>
      SixMobilePalette.heroSupportingText;
  static Color get _heroShadowColor => SixMobilePalette.heroShadow;
  static Color get _cardShadowColor => SixMobilePalette.navigationShadow;

  late final AtendimentoTecnicoService _service;
  late final ClienteUsuarioApiClient _clienteApiClient;
  late final ColaboradorUsuarioApiClient _colaboradorApiClient;
  final List<_AtendimentoItemMobile> _itens = <_AtendimentoItemMobile>[];
  final List<AtendimentoTecnicoFotoInput> _fotos =
      <AtendimentoTecnicoFotoInput>[];
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _tipoEquipamentoController =
      TextEditingController(text: 'SMARTPHONE');
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _acessoriosController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();

  List<ClienteUsuario> _clientes = <ClienteUsuario>[];
  List<_ResponsavelTecnicoMobile> _responsaveis = <_ResponsavelTecnicoMobile>[];
  ClienteUsuario? _clienteSelecionado;
  _ResponsavelTecnicoMobile? _responsavelSelecionado;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  int _etapaAtual = 0;
  DateTime _validadeOrcamentoEm = _defaultDate();
  DateTime _vencimentoFinanceiroEm = _defaultDate();
  DateTime _dataEntregaPrevista = _defaultDate();

  int get _quantidadeItens => _itens.fold<int>(
    0,
    (int total, _AtendimentoItemMobile item) => total + item.quantidade,
  );

  double get _totalItens => _itens.fold<double>(
    0,
    (double total, _AtendimentoItemMobile item) => total + item.total,
  );

  static DateTime _inicioHoje() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _defaultDate() => _inicioHoje().add(Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AtendimentoTecnicoService();
    _clienteApiClient =
        widget.clienteApiClient ?? HttpClienteUsuarioApiClient();
    _colaboradorApiClient =
        widget.colaboradorApiClient ?? HttpColaboradorUsuarioApiClient();
    _carregarDados();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _tipoEquipamentoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _imeiController.dispose();
    _acessoriosController.dispose();
    _defeitoController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final response = await _clienteApiClient.listarClientesUsuario();
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _colaboradorApiClient.listarTecnicosAssistenciaTecnica();
      final List<_ResponsavelTecnicoMobile> responsaveis = _montarResponsaveis(
        colaboradores,
      );

      if (!mounted) return;
      setState(() {
        _clientes = response.clientes
            .where((cliente) => cliente.ativo)
            .toList();
        _responsaveis = responsaveis;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.toString();
        _carregando = false;
      });
    }
  }

  List<_ResponsavelTecnicoMobile> _montarResponsaveis(
    List<ColaboradorUsuarioResumo> colaboradores,
  ) {
    final Map<String, _ResponsavelTecnicoMobile> mapa =
        <String, _ResponsavelTecnicoMobile>{};

    void add(_ResponsavelTecnicoMobile responsavel) {
      final String key = responsavel.id.trim().isNotEmpty
          ? responsavel.id.trim()
          : responsavel.nome.toLowerCase().trim();
      if (key.isEmpty || mapa.containsKey(key)) return;
      mapa[key] = responsavel;
    }

    for (final ColaboradorUsuarioResumo colaborador in colaboradores) {
      if (!colaborador.ehTecnicoAssistenciaTecnica) continue;
      final String id = colaborador.idUnicoPessoal.trim().isNotEmpty
          ? colaborador.idUnicoPessoal.trim()
          : colaborador.email.trim();
      final String nome = colaborador.nomeDeGuerra.trim().isNotEmpty
          ? colaborador.nomeDeGuerra.trim()
          : colaborador.nome.trim().isNotEmpty
          ? colaborador.nome.trim()
          : colaborador.email.trim();
      if (id.isEmpty && nome.isEmpty) continue;

      final String subtitulo = <String>[
        'Colaborador',
        colaborador.email,
        colaborador.celularDeAcesso,
      ].where((String item) => item.trim().isNotEmpty).join(' • ');

      add(
        _ResponsavelTecnicoMobile(
          id: id.isEmpty ? nome : id,
          nome: nome.isEmpty ? 'Colaborador' : nome,
          subtitulo: subtitulo,
        ),
      );
    }

    return mapa.values.toList(growable: false);
  }

  Future<void> _selecionarValidadeOrcamento() async {
    final data = await _selecionarData(
      initialDate: _validadeOrcamentoEm,
      title: 'Validade do orçamento',
      applyButtonLabel: 'Aplicar data',
    );
    if (data == null) return;
    setState(() => _validadeOrcamentoEm = data);
  }

  Future<void> _selecionarVencimentoFinanceiro() async {
    final data = await _selecionarData(
      initialDate: _vencimentoFinanceiroEm,
      title: 'Vencimento financeiro',
      applyButtonLabel: 'Aplicar vencimento',
    );
    if (data == null) return;
    setState(() => _vencimentoFinanceiroEm = data);
  }

  Future<void> _selecionarDataEntregaPrevista() async {
    final data = await _selecionarData(
      initialDate: _dataEntregaPrevista,
      title: 'Entrega prevista',
      applyButtonLabel: 'Aplicar entrega',
      firstDate: DateTime(2000),
    );
    if (data == null) return;
    setState(() => _dataEntregaPrevista = data);
  }

  Future<DateTime?> _selecionarData({
    required DateTime initialDate,
    required String title,
    required String applyButtonLabel,
    DateTime? firstDate,
  }) async {
    final inicio = _inicioHoje();
    final primeiraData = firstDate ?? inicio;
    final initial = initialDate.isBefore(primeiraData)
        ? primeiraData
        : initialDate;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (context) {
        return DateSelectorMobileBottomSheet(
          title: title,
          initialDate: initial,
          firstDate: primeiraData,
          lastDate: inicio.add(Duration(days: 365)),
          applyButtonLabel: applyButtonLabel,
        );
      },
    );

    if (selected == null) return null;
    return DateTime(selected.year, selected.month, selected.day);
  }

  Future<void> _abrirSelecaoCliente() async {
    final Object? result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (context) {
        return AtendimentoTecnicoClienteSelectorMobile(
          clientes: _clientes,
          clienteSelecionado: _clienteSelecionado,
        );
      },
    );

    if (result == null || !mounted) return;
    if (result is _CadastrarClienteAtendimentoAction) {
      await _cadastrarClientePeloAtendimento();
      return;
    }
    if (result is ClienteUsuario) {
      setState(() => _clienteSelecionado = result);
    }
  }

  Future<void> _cadastrarClientePeloAtendimento() async {
    final ClienteUsuario? cliente = await Navigator.of(context)
        .push<ClienteUsuario>(
          MaterialPageRoute<ClienteUsuario>(
            builder: (_) => ClienteUsuarioCadastroMobileScreen(
              apiClient: _clienteApiClient,
              returnSavedCliente: true,
            ),
          ),
        );

    if (cliente == null || !mounted) return;
    setState(() {
      final List<ClienteUsuario> clientes = _clientes
          .where((ClienteUsuario item) => item.id != cliente.id)
          .toList();
      clientes.insert(0, cliente);
      _clientes = clientes;
      _clienteSelecionado = cliente;
    });
  }

  Future<void> _abrirSelecaoResponsavel() async {
    if (_responsaveis.isEmpty) {
      _mostrarMensagem('Nenhum responsável técnico disponível para seleção.');
      return;
    }

    final _ResponsavelTecnicoMobile? responsavel =
        await showModalBottomSheet<_ResponsavelTecnicoMobile>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Color(0x66000000),
          builder: (context) {
            return _AtendimentoTecnicoResponsavelSelectorMobile(
              responsaveis: _responsaveis,
              responsavelSelecionado: _responsavelSelecionado,
            );
          },
        );

    if (responsavel == null || !mounted) return;
    setState(() => _responsavelSelecionado = responsavel);
  }

  Future<void> _abrirSelecaoItens() async {
    final dynamic result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (_) => ProdutolistMobileScreen(
          isSelecao: true,
          permitirSelecaoMultipla: true,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final List<ProdutoModel> produtos = result is List
        ? result.whereType<ProdutoModel>().toList(growable: false)
        : <ProdutoModel>[if (result is ProdutoModel) result];
    if (produtos.isEmpty) return;

    setState(() {
      for (final ProdutoModel produto in produtos) {
        _adicionarProduto(produto);
      }
    });
  }

  void _adicionarProduto(ProdutoModel produto) {
    final bool servico = _ehServico(produto);
    final String tipoCodigo = servico ? 'SERVICE' : 'PRODUCT';
    final String chave =
        '$tipoCodigo:${produto.id ?? produto.codigoDeBarras}:${produto.nomeProduto}';
    final int index = _itens.indexWhere((item) => item.chave == chave);

    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
      );
      return;
    }

    _itens.add(
      _AtendimentoItemMobile(
        chave: chave,
        idSku: produto.id ?? produto.codigoDeBarras,
        descricao: produto.nomeProduto.trim().isEmpty
            ? 'Item sem nome'
            : produto.nomeProduto,
        tipoItemId: servico ? 20 : 10,
        tipoCodigo: tipoCodigo,
        quantidade: 1,
        valorUnitario: produto.precoVenda,
        desconto: 0,
        movimentaEstoque: !servico,
      ),
    );
  }

  bool _ehServico(ProdutoModel produto) {
    final String tipo = produto.tipoProduto.trim().toUpperCase();
    return tipo == 'SERVICO' || tipo == 'SERVIÇO' || tipo == 'SERVICE';
  }

  void _alterarQuantidade(_AtendimentoItemMobile item, int delta) {
    setState(() {
      final int index = _itens.indexWhere(
        (element) => element.chave == item.chave,
      );
      if (index < 0) return;
      final int quantidade = _itens[index].quantidade + delta;
      if (quantidade <= 0) {
        _itens.removeAt(index);
        return;
      }
      _itens[index] = _itens[index].copyWith(quantidade: quantidade);
    });
  }

  void _removerItem(_AtendimentoItemMobile item) {
    setState(
      () => _itens.removeWhere((element) => element.chave == item.chave),
    );
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final cliente = _clienteSelecionado;
    if (cliente == null) {
      _mostrarMensagem('Selecione um cliente antes de iniciar o atendimento.');
      return;
    }

    if (_defeitoController.text.trim().isEmpty) {
      _mostrarMensagem('Informe o defeito relatado pelo cliente.');
      return;
    }
    final DateTime inicioHoje = _inicioHoje();
    if (_validadeOrcamentoEm.isBefore(inicioHoje)) {
      _mostrarMensagem(
        'A validade do orçamento não pode ser anterior à data atual.',
      );
      return;
    }
    if (_vencimentoFinanceiroEm.isBefore(inicioHoje)) {
      _mostrarMensagem(
        'O vencimento financeiro não pode ser anterior à data atual.',
      );
      return;
    }
    final _ResponsavelTecnicoMobile? responsavel = _responsavelSelecionado;

    setState(() => _salvando = true);
    try {
      final atendimento = await _service.criar(
        AtendimentoTecnicoCreateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          dataEntregaPrevista: _dataEntregaPrevista,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: cliente.id,
          nomeClienteSnapshot: cliente.nome,
          idTecnicoResponsavel: responsavel?.id,
          nomeTecnicoResponsavelSnapshot: responsavel?.nome,
          equipamento: AtendimentoTecnicoEquipamentoModel(
            tipo: _textoOuNulo(_tipoEquipamentoController.text),
            marca: _textoOuNulo(_marcaController.text),
            modelo: _textoOuNulo(_modeloController.text),
            numeroSerie: _textoOuNulo(_numeroSerieController.text),
            imei: _textoOuNulo(_imeiController.text),
            acessorios: _textoOuNulo(_acessoriosController.text),
            observacoesEntrada: _textoOuNulo(_acessoriosController.text),
          ),
          defeitoRelatado: _textoOuNulo(_defeitoController.text),
          diagnosticoTecnico: _textoOuNulo(_diagnosticoController.text),
          fotos: List<AtendimentoTecnicoFotoInput>.unmodifiable(_fotos),
          itens: _itens
              .map((item) => item.toInput(responsavel: responsavel))
              .toList(growable: false),
        ),
        dataVencimentoEm: _vencimentoFinanceiroEm,
      );

      if (!mounted) return;
      _limparFormulario();
      _mostrarMensagem(
        atendimento.numero.trim().isEmpty
            ? 'Atendimento técnico iniciado.'
            : 'Atendimento ${atendimento.numero} iniciado.',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível iniciar o atendimento: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _limparFormulario() {
    setState(() {
      _clienteSelecionado = null;
      _responsavelSelecionado = null;
      _descricaoController.clear();
      _tipoEquipamentoController.text = 'SMARTPHONE';
      _marcaController.clear();
      _modeloController.clear();
      _numeroSerieController.clear();
      _imeiController.clear();
      _acessoriosController.clear();
      _defeitoController.clear();
      _diagnosticoController.clear();
      _itens.clear();
      _fotos.clear();
      _etapaAtual = 0;
      _validadeOrcamentoEm = _defaultDate();
      _vencimentoFinanceiroEm = _defaultDate();
      _dataEntregaPrevista = _defaultDate();
    });
  }

  String? _textoOuNulo(String value) {
    final texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  String _formatarData(DateTime value) {
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _formatarMoeda(double value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  String _itemsCountLabel(int count) {
    final String fallback = count == 1 ? '1 item' : '$count itens';
    final String key = count == 1
        ? 'procedimentos.itemCount.one'
        : 'procedimentos.itemCount.other';
    return _t(key, fallback).replaceAll('{count}', count.toString());
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}',
    );

    return SixMobilePageShell(
      title: _t(
        'atendimentoTecnico.mobile.createTitle',
        'Novo atendimento técnico',
      ),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _t('common.back', 'Voltar'),
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: _etapaAtual > 0
            ? () => setState(() => _etapaAtual--)
            : () => Navigator.of(context).maybePop(),
      ),
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
      child: RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
          children: <Widget>[
            _buildHeader(),
            SizedBox(height: 16),
            if (_carregando)
              _buildLoadingCard()
            else if (_erro != null)
              _buildErrorCard()
            else
              _buildFormCard(),
          ],
        ),
      ),
    );
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  Widget _buildHeader() {
    final String? responsavel = _responsavelSelecionado?.nome;
    final String subtitle = responsavel != null && responsavel.trim().isNotEmpty
        ? '${_t('atendimentoTecnico.mobile.responsible', 'Responsável')}: $responsavel'
        : '${_t('atendimentoTecnico.journey.step', 'Etapa')} ${_etapaAtual + 1}/5 • ${_journeyStepTitle(_etapaAtual)}';
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _heroShadowColor,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _t(
                    'atendimentoTecnico.mobile.createHeaderTitle',
                    'Iniciar assistência',
                  ),
                  style: TextStyle(
                    color: _onPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _heroSupportingTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return _card(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Carregando clientes e responsáveis...')),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Não foi possível carregar os dados',
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            _erro ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _mutedTextColor),
          ),
          SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _carregarDados,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _journeyProgressCard(),
        SizedBox(height: 14),
        if (_etapaAtual == 4)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 50),
            child: _contextChipsCard(),
          ),
        if (_etapaAtual == 4) SizedBox(height: 14),
        if (_etapaAtual == 0)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 90),
            child: _sectionCard(
              title: _t(
                'atendimentoTecnico.mobile.mainDataSection',
                'Dados principais',
              ),
              icon: Icons.assignment_outlined,
              children: <Widget>[
                _clienteSelectorField(),
                SizedBox(height: 12),
                _responsavelSelectorField(),
                SizedBox(height: 12),
                TextField(
                  controller: _descricaoController,
                  decoration: _inputDecoration(
                    label: _t(
                      'atendimentoTecnico.mobile.internalDescription',
                      'Descrição interna',
                    ),
                    hint: _t(
                      'atendimentoTecnico.mobile.internalDescriptionHint',
                      'Ex.: Troca de tela iPhone 11',
                    ),
                    icon: Icons.notes_outlined,
                  ),
                ),
              ],
            ),
          ),
        if (_etapaAtual == 0) SizedBox(height: 14),
        if (_etapaAtual == 1)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 130),
            child: _sectionCard(
              title: _t('atendimentoTecnico.equipment', 'Equipamento'),
              icon: Icons.devices_other_outlined,
              children: <Widget>[
                TextField(
                  controller: _tipoEquipamentoController,
                  decoration: _inputDecoration(
                    label: _t(
                      'atendimentoTecnico.mobile.equipmentType',
                      'Tipo de equipamento',
                    ),
                    icon: Icons.devices_other_outlined,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _marcaController,
                        decoration: _inputDecoration(
                          label: _t('atendimentoTecnico.mobile.brand', 'Marca'),
                          icon: Icons.business_outlined,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _modeloController,
                        decoration: _inputDecoration(
                          label: _t(
                            'atendimentoTecnico.mobile.model',
                            'Modelo',
                          ),
                          icon: Icons.category_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _numeroSerieController,
                        decoration: _inputDecoration(
                          label: _t(
                            'atendimentoTecnico.mobile.serialNumber',
                            'Nº série',
                          ),
                          icon: Icons.confirmation_number_outlined,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _imeiController,
                        decoration: _inputDecoration(
                          label: _t('atendimentoTecnico.mobile.imei', 'IMEI'),
                          icon: Icons.qr_code_2_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _acessoriosController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: _t(
                      'atendimentoTecnico.mobile.accessoriesNotes',
                      'Acessórios / observações',
                    ),
                    hint: _t(
                      'atendimentoTecnico.mobile.accessoriesNotesHint',
                      'Ex.: sem carregador, com capa, tela trincada...',
                    ),
                    icon: Icons.cable_outlined,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        if (_etapaAtual == 1) SizedBox(height: 14),
        if (_etapaAtual == 2)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 170),
            child: _sectionCard(
              title: _t(
                'atendimentoTecnico.mobile.technicalReportSection',
                'Relato técnico',
              ),
              icon: Icons.report_problem_outlined,
              children: <Widget>[
                TextField(
                  controller: _defeitoController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    label: _t(
                      'atendimentoTecnico.mobile.customerIssue',
                      'Defeito relatado pelo cliente',
                    ),
                    hint: _t(
                      'atendimentoTecnico.mobile.customerIssueHint',
                      'Descreva o problema informado no balcão.',
                    ),
                    icon: Icons.report_problem_outlined,
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _diagnosticoController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    label: _t(
                      'atendimentoTecnico.mobile.initialDiagnosis',
                      'Diagnóstico técnico inicial',
                    ),
                    hint: _t(
                      'atendimentoTecnico.mobile.initialDiagnosisHint',
                      'Opcional neste primeiro momento.',
                    ),
                    icon: Icons.engineering_outlined,
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 14),
                _photosSectionMobile(),
              ],
            ),
          ),
        if (_etapaAtual == 2) SizedBox(height: 14),
        if (_etapaAtual == 3)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 210),
            child: _datesCard(),
          ),
        if (_etapaAtual == 3) SizedBox(height: 14),
        if (_etapaAtual == 3)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 250),
            child: _financialPreviewCard(),
          ),
        if (_etapaAtual == 3) SizedBox(height: 14),
        if (_etapaAtual == 3)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 290),
            child: _itensSection(),
          ),
        if (_etapaAtual == 4) _reviewCardMobile(),
        SizedBox(height: 18),
        if (_etapaAtual == 4)
          SixStaggeredEntry(
            delay: Duration(milliseconds: 330),
            child: _saveButton(),
          ),
        if (_etapaAtual < 4) _journeyNavigation(),
      ],
    );
  }

  String _journeyStepTitle(int index) {
    const List<String> fallbacks = <String>[
      'Cliente',
      'Equipamento',
      'Registro',
      'Orçamento',
      'Revisão',
    ];
    return _t('atendimentoTecnico.journey.step.$index', fallbacks[index]);
  }

  String _journeyStepDescription(int index) {
    const List<String> fallbacks = <String>[
      'Identifique o cliente e quem será responsável.',
      'Registre os dados do equipamento recebido.',
      'Descreva o problema e adicione até 10 fotos.',
      'Monte os itens, valores e datas do serviço.',
      'Confira tudo antes de iniciar o atendimento.',
    ];
    return _t(
      'atendimentoTecnico.journey.step.$index.description',
      fallbacks[index],
    );
  }

  Widget _journeyProgressCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _journeyStepTitle(_etapaAtual),
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            _journeyStepDescription(_etapaAtual),
            style: TextStyle(color: _mutedTextColor, height: 1.35),
          ),
          SizedBox(height: 16),
          Row(
            children: List<Widget>.generate(5, (int index) {
              final bool done = index < _etapaAtual;
              final bool active = index == _etapaAtual;
              return Expanded(
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: active ? 28 : 22,
                      height: active ? 28 : 22,
                      decoration: BoxDecoration(
                        color: done || active
                            ? _primaryColor
                            : _softSurfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done || active ? _primaryColor : _borderColor,
                        ),
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : _journeyStepIcon(index),
                        size: active ? 15 : 12,
                        color: done || active
                            ? _onPrimaryColor
                            : _mutedTextColor,
                      ),
                    ),
                    if (index < 4)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < _etapaAtual
                              ? _primaryColor
                              : _borderColor,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _journeyStepIcon(int index) {
    return switch (index) {
      0 => Icons.person_outline_rounded,
      1 => Icons.devices_other_outlined,
      2 => Icons.photo_camera_outlined,
      3 => Icons.request_quote_outlined,
      _ => Icons.task_alt_rounded,
    };
  }

  Widget _journeyNavigation() {
    return Row(
      children: <Widget>[
        if (_etapaAtual > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _etapaAtual--),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(_t('common.back', 'Voltar')),
            ),
          ),
        if (_etapaAtual > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _avancarEtapa,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(_t('common.continue', 'Continuar')),
          ),
        ),
      ],
    );
  }

  void _avancarEtapa() {
    if (_etapaAtual == 0 && _clienteSelecionado == null) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.validation.customerRequired',
          'Selecione um cliente para continuar.',
        ),
      );
      return;
    }
    if (_etapaAtual == 2 && _defeitoController.text.trim().isEmpty) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.validation.issueRequired',
          'Informe o defeito relatado para continuar.',
        ),
      );
      return;
    }
    if (_etapaAtual == 3) {
      final DateTime hoje = _inicioHoje();
      if (_validadeOrcamentoEm.isBefore(hoje) ||
          _vencimentoFinanceiroEm.isBefore(hoje)) {
        _mostrarMensagem(
          _t(
            'atendimentoTecnico.validation.datesInvalid',
            'Revise as datas: validade e vencimento não podem estar no passado.',
          ),
        );
        return;
      }
    }
    if (_etapaAtual < 4) {
      setState(() => _etapaAtual++);
    }
  }

  Widget _photosSectionMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _t('atendimentoTecnico.photos.title', 'Fotos do serviço'),
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    _t(
                      'atendimentoTecnico.photos.hint',
                      'Registre o estado do equipamento. Máximo de 10 fotos.',
                    ),
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _softAccentSurfaceColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_fotos.length}/${AtendimentoTecnicoFotoPayload.maxFotos}',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 116,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              if (_fotos.length < AtendimentoTecnicoFotoPayload.maxFotos)
                _addPhotoTileMobile(),
              ..._fotos.asMap().entries.map(
                (MapEntry<int, AtendimentoTecnicoFotoInput> entry) =>
                    _photoTileMobile(entry.key, entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addPhotoTileMobile() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: _selecionarFotosMobile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 104,
          decoration: BoxDecoration(
            color: _softSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_a_photo_outlined, color: _accentColor),
              const SizedBox(height: 7),
              Text(
                _t('atendimentoTecnico.photos.add', 'Adicionar'),
                style: TextStyle(
                  color: _titleTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoTileMobile(int index, AtendimentoTecnicoFotoInput foto) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              AtendimentoTecnicoFotoPayload.previewBytes(foto),
              width: 104,
              height: 116,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _fotos.removeAt(index)),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarFotosMobile() async {
    if (_fotos.length >= AtendimentoTecnicoFotoPayload.maxFotos) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.photos.limit',
          'O limite é de 10 fotos por atendimento.',
        ),
      );
      return;
    }
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(_t('atendimentoTecnico.photos.camera', 'Câmera')),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(_t('atendimentoTecnico.photos.gallery', 'Galeria')),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (source == null || !mounted) return;

    try {
      final List<XFile> arquivos;
      if (source == ImageSource.camera) {
        final XFile? arquivo = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 72,
        );
        arquivos = arquivo == null ? <XFile>[] : <XFile>[arquivo];
      } else {
        arquivos = await _imagePicker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 72,
        );
      }
      final int restantes =
          AtendimentoTecnicoFotoPayload.maxFotos - _fotos.length;
      final List<AtendimentoTecnicoFotoInput> adicionadas =
          <AtendimentoTecnicoFotoInput>[];
      for (final XFile arquivo in arquivos.take(restantes)) {
        adicionadas.add(await AtendimentoTecnicoFotoPayload.fromXFile(arquivo));
      }
      if (!mounted || adicionadas.isEmpty) return;
      setState(() => _fotos.addAll(adicionadas));
    } on AtendimentoTecnicoFotoException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(_photoErrorMessage(error.code));
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.photos.readError',
          'Não foi possível carregar a foto selecionada.',
        ),
      );
    }
  }

  String _photoErrorMessage(String code) {
    return switch (code) {
      'PHOTO_TOO_LARGE' => _t(
        'atendimentoTecnico.photos.tooLarge',
        'A foto ficou muito grande. Tente outra imagem ou reduza a resolução.',
      ),
      'PHOTO_FORMAT_UNSUPPORTED' => _t(
        'atendimentoTecnico.photos.formatUnsupported',
        'Use fotos nos formatos JPG ou PNG.',
      ),
      _ => _t(
        'atendimentoTecnico.photos.invalid',
        'A foto selecionada não é válida.',
      ),
    };
  }

  Widget _reviewCardMobile() {
    return _sectionCard(
      title: _t('atendimentoTecnico.journey.reviewTitle', 'Revisão final'),
      icon: Icons.fact_check_outlined,
      children: <Widget>[
        _reviewLineMobile(
          Icons.person_outline_rounded,
          _t('atendimentoTecnico.customer', 'Cliente'),
          _clienteSelecionado?.nome ?? '-',
        ),
        _reviewLineMobile(
          Icons.devices_other_outlined,
          _t('atendimentoTecnico.equipment', 'Equipamento'),
          <String>[
            _tipoEquipamentoController.text,
            _marcaController.text,
            _modeloController.text,
          ].where((String value) => value.trim().isNotEmpty).join(' • '),
        ),
        _reviewLineMobile(
          Icons.report_problem_outlined,
          _t('atendimentoTecnico.mobile.customerIssue', 'Defeito'),
          _defeitoController.text.trim(),
        ),
        _reviewLineMobile(
          Icons.photo_camera_outlined,
          _t('atendimentoTecnico.photos.title', 'Fotos do serviço'),
          _t(
            'atendimentoTecnico.photos.count',
            '${_fotos.length} de 10 adicionadas',
          ),
        ),
        _reviewLineMobile(
          Icons.request_quote_outlined,
          _t('atendimentoTecnico.mobile.quoteChip', 'Orçamento'),
          '${_itemsCountLabel(_quantidadeItens)} • ${_formatarMoeda(_totalItens)}',
          showDivider: false,
        ),
      ],
    );
  }

  Widget _reviewLineMobile(
    IconData icon,
    String label,
    String value, {
    bool showDivider = true,
  }) {
    final String normalized = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: _borderColor))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 19, color: _accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  normalized,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextChipsCard() {
    return _card(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _contextChip(
            _t('atendimentoTecnico.mobile.serviceChip', 'Assistência'),
            Icons.handyman_outlined,
          ),
          _contextChip(
            _t('atendimentoTecnico.mobile.quoteChip', 'Orçamento'),
            Icons.request_quote_outlined,
          ),
          _contextChip(
            _itens.isEmpty
                ? _t('atendimentoTecnico.mobile.noItemsChip', 'Sem itens')
                : _itemsCountLabel(_quantidadeItens),
            Icons.inventory_2_outlined,
          ),
          _contextChip(
            _formatarMoeda(_totalItens),
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _contextChip(String label, IconData icon) {
    return Container(
      constraints: BoxConstraints(maxWidth: 190),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: _accentColor),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _sectionIcon(icon),
              SizedBox(width: 10),
              Expanded(child: _sectionTitle(title)),
            ],
          ),
          SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _softAccentSurfaceColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: _accentColor, size: 19),
    );
  }

  Widget _datesCard() {
    return _sectionCard(
      title: _t('atendimentoTecnico.mobile.datesSection', 'Datas'),
      icon: Icons.calendar_month_outlined,
      children: <Widget>[
        _dateTile(
          label: _t('atendimentoTecnico.expectedDelivery', 'Entrega prevista'),
          value: _formatarData(_dataEntregaPrevista),
          onTap: _selecionarDataEntregaPrevista,
        ),
        SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _dateTile(
                label: _t('atendimentoTecnico.mobile.validity', 'Validade'),
                value: _formatarData(_validadeOrcamentoEm),
                onTap: _selecionarValidadeOrcamento,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _dateTile(
                label: _t(
                  'atendimentoTecnico.mobile.financialDueDate',
                  'Vencimento financeiro',
                ),
                value: _formatarData(_vencimentoFinanceiroEm),
                onTap: _selecionarVencimentoFinanceiro,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _financialPreviewCard() {
    final _PaymentStampData stamp = _paymentStampData();
    return _sectionCard(
      title: _t(
        'atendimentoTecnico.mobile.financialPreviewSection',
        'Prévia financeira',
      ),
      icon: Icons.payments_outlined,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                _t(
                  'atendimentoTecnico.mobile.financialPreviewDescription',
                  'O valor fica em aberto até registrar um recebimento.',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            SizedBox(width: 10),
            _paymentStamp(stamp),
          ],
        ),
        SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool singleColumn = constraints.maxWidth < 330;
            final double cardWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: cardWidth,
                  child: _financialValueCard(
                    title: _t(
                      'atendimentoTecnico.mobile.valorOriginal',
                      'Valor original',
                    ),
                    value: _totalItens,
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _financialValueCard(
                    title: _t(
                      'atendimentoTecnico.mobile.valorConfirmado',
                      'Confirmado',
                    ),
                    value: 0,
                    icon: Icons.verified_outlined,
                  ),
                ),
                SizedBox(
                  width: singleColumn ? cardWidth : constraints.maxWidth,
                  child: _financialValueCard(
                    title: _t(
                      'atendimentoTecnico.mobile.valorEmAberto',
                      'Em aberto',
                    ),
                    value: _totalItens,
                    icon: Icons.account_balance_wallet_outlined,
                    highlighted: _totalItens > 0,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  _PaymentStampData _paymentStampData() {
    if (_totalItens <= 0) {
      return _PaymentStampData(
        label: _t('atendimentoTecnico.mobile.paymentStampNoValue', 'SEM VALOR'),
        color: _mutedTextColor,
      );
    }

    return _PaymentStampData(
      label: _t('atendimentoTecnico.mobile.paymentStampOpen', 'EM ABERTO'),
      color: _accentColor,
    );
  }

  Widget _paymentStamp(_PaymentStampData stamp) {
    return Semantics(
      label:
          '${_t('atendimentoTecnico.filters.paymentStatus.label', 'Status pagamento')}: ${stamp.label}',
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.12,
          child: Opacity(
            opacity: 0.94,
            child: Container(
              constraints: BoxConstraints(maxWidth: 118),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: stamp.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: stamp.color, width: 2.2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: stamp.color.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                stamp.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: stamp.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _financialValueCard({
    required String title,
    required double value,
    required IconData icon,
    bool highlighted = false,
  }) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Color borderColor = highlighted
        ? SixMobilePalette.highlightedBorder
        : _borderColor;
    final Color foregroundColor = highlighted ? _accentColor : _titleTextColor;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? _softAccentSurfaceColor : _softSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          _smallIconBox(
            icon,
            foreground: highlighted ? _accentColor : _titleTextColor,
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
                    color: _mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                reduceMotion
                    ? _moneyText(value, foregroundColor)
                    : TweenAnimationBuilder<double>(
                        key: ValueKey<String>('finance_${title}_$value'),
                        tween: Tween<double>(begin: 0, end: value),
                        duration: Duration(milliseconds: 620),
                        curve: Curves.easeOutCubic,
                        builder:
                            (
                              BuildContext context,
                              double animatedValue,
                              Widget? child,
                            ) {
                              return _moneyText(animatedValue, foregroundColor);
                            },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallIconBox(IconData icon, {Color? foreground}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SixMobilePalette.iconSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: foreground ?? _accentColor, size: 18),
    );
  }

  Widget _moneyText(double value, Color color) {
    return Text(
      _formatarMoeda(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _salvando ? null : _salvar,
        icon: _salvando
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.3),
              )
            : Icon(Icons.playlist_add_check_rounded),
        label: Text(
          _salvando
              ? _t(
                  'atendimentoTecnico.mobile.savingService',
                  'Iniciando atendimento...',
                )
              : _t(
                  'atendimentoTecnico.mobile.startServiceAction',
                  'Iniciar atendimento técnico',
                ),
        ),
      ),
    );
  }

  Widget _itensSection() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.inventory_2_outlined, color: _accentColor),
              SizedBox(width: 8),
              Expanded(child: _sectionTitle('Produtos e serviços')),
              Text(
                _formatarMoeda(_totalItens),
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_itens.isEmpty) _emptyItens() else ..._itens.map(_itemTile),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _salvando ? null : _abrirSelecaoItens,
              icon: Icon(Icons.add_shopping_cart_rounded),
              label: Text('Adicionar produto ou serviço'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItens() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        'Nenhum produto ou serviço vinculado. Você pode iniciar com ou sem itens.',
        style: TextStyle(color: _mutedTextColor, height: 1.35),
      ),
    );
  }

  Widget _itemTile(_AtendimentoItemMobile item) {
    final bool servico = item.isServico;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _softAccentSurfaceColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    servico
                        ? Icons.handyman_outlined
                        : Icons.inventory_2_outlined,
                    color: _accentColor,
                    size: 21,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${servico ? 'Serviço' : 'Produto'} • ${_formatarMoeda(item.valorUnitario)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _salvando ? null : () => _removerItem(item),
                  icon: Icon(Icons.delete_outline_rounded),
                  color: SixMobilePalette.error,
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                _quantityButton(
                  icon: Icons.remove_rounded,
                  onTap: _salvando ? null : () => _alterarQuantidade(item, -1),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${item.quantidade}',
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _quantityButton(
                  icon: Icons.add_rounded,
                  onTap: _salvando ? null : () => _alterarQuantidade(item, 1),
                ),
                Spacer(),
                Text(
                  _formatarMoeda(item.total),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: _softAccentSurfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: _accentColor, size: 20),
        ),
      ),
    );
  }

  Widget _clienteSelectorField() {
    final ClienteUsuario? cliente = _clienteSelecionado;
    final bool hasSelection = cliente != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _abrirSelecaoCliente,
        child: InputDecorator(
          isEmpty: false,
          decoration: _inputDecoration(
            label: 'Cliente',
            icon: Icons.person_search_outlined,
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            hasSelection ? cliente.nome : 'Selecione um cliente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasSelection ? _titleTextColor : _mutedTextColor,
              fontWeight: hasSelection ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _responsavelSelectorField() {
    final _ResponsavelTecnicoMobile? responsavel = _responsavelSelecionado;
    final bool hasSelection = responsavel != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _abrirSelecaoResponsavel,
        child: InputDecorator(
          isEmpty: false,
          decoration: _inputDecoration(
            label: 'Responsável técnico',
            icon: Icons.engineering_outlined,
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            hasSelection ? responsavel.nome : 'Selecione o responsável',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasSelection ? _titleTextColor : _mutedTextColor,
              fontWeight: hasSelection ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _titleTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _softSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Icon(Icons.event_outlined, size: 17, color: _accentColor),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool alignLabelWithHint = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null ? null : Icon(icon, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _softSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accentColor, width: 1.4),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}

class _PaymentStampData {
  const _PaymentStampData({required this.label, required this.color});

  final String label;
  final Color color;
}

class _AtendimentoItemMobile {
  const _AtendimentoItemMobile({
    required this.chave,
    required this.idSku,
    required this.descricao,
    required this.tipoItemId,
    required this.tipoCodigo,
    required this.quantidade,
    required this.valorUnitario,
    required this.desconto,
    required this.movimentaEstoque,
  });

  final String chave;
  final String? idSku;
  final String descricao;
  final int tipoItemId;
  final String tipoCodigo;
  final int quantidade;
  final double valorUnitario;
  final double desconto;
  final bool movimentaEstoque;

  bool get isServico {
    final String normalizado = tipoCodigo.trim().toUpperCase();
    return normalizado == 'SERVICE' ||
        normalizado == 'SERVICO' ||
        normalizado == 'SERVIÇO';
  }

  double get total => (quantidade * valorUnitario) - desconto;

  _AtendimentoItemMobile copyWith({int? quantidade}) {
    return _AtendimentoItemMobile(
      chave: chave,
      idSku: idSku,
      descricao: descricao,
      tipoItemId: tipoItemId,
      tipoCodigo: tipoCodigo,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario,
      desconto: desconto,
      movimentaEstoque: movimentaEstoque,
    );
  }

  AtendimentoTecnicoItemInput toInput({
    _ResponsavelTecnicoMobile? responsavel,
  }) {
    return AtendimentoTecnicoItemInput(
      tipoItemId: tipoItemId,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      desconto: desconto,
      idTecnicoResponsavel: responsavel?.id,
      nomeTecnicoResponsavel: responsavel?.nome,
      movimentaEstoque: movimentaEstoque,
    );
  }
}

class _ResponsavelTecnicoMobile {
  const _ResponsavelTecnicoMobile({
    required this.id,
    required this.nome,
    required this.subtitulo,
  });

  final String id;
  final String nome;
  final String subtitulo;
}

class _AtendimentoTecnicoResponsavelSelectorMobile extends StatefulWidget {
  const _AtendimentoTecnicoResponsavelSelectorMobile({
    required this.responsaveis,
    required this.responsavelSelecionado,
  });

  final List<_ResponsavelTecnicoMobile> responsaveis;
  final _ResponsavelTecnicoMobile? responsavelSelecionado;

  @override
  State<_AtendimentoTecnicoResponsavelSelectorMobile> createState() =>
      _AtendimentoTecnicoResponsavelSelectorMobileState();
}

class _AtendimentoTecnicoResponsavelSelectorMobileState
    extends State<_AtendimentoTecnicoResponsavelSelectorMobile> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ResponsavelTecnicoMobile> get _responsaveisFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.responsaveis;
    return widget.responsaveis
        .where((_ResponsavelTecnicoMobile item) {
          final String source = _normalize('${item.nome} ${item.subtitulo}');
          return source.contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<_ResponsavelTecnicoMobile> responsaveis =
            _responsaveisFiltrados;

        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.activeBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SixMobilePalette.softAccentSurface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.engineering_outlined,
                          color: _accentColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Responsável técnico',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Selecione um técnico autorizado para assistência.',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) =>
                        setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar responsável',
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filter = '');
                              },
                            ),
                      filled: true,
                      fillColor: _surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _accentColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: responsaveis.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(18, 0, 18, 22),
                          itemBuilder: (BuildContext context, int index) {
                            final _ResponsavelTecnicoMobile responsavel =
                                responsaveis[index];
                            final bool selected = _isSelected(responsavel);
                            return _ResponsavelSelectorItem(
                              responsavel: responsavel,
                              selected: selected,
                              onTap: () =>
                                  Navigator.of(context).pop(responsavel),
                            );
                          },
                          separatorBuilder: (_, __) => SizedBox(height: 10),
                          itemCount: responsaveis.length,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 22),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            'Nenhum responsável encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
        ),
      ],
    );
  }

  bool _isSelected(_ResponsavelTecnicoMobile responsavel) {
    final _ResponsavelTecnicoMobile? selected = widget.responsavelSelecionado;
    if (selected == null) return false;
    return selected.id == responsavel.id;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ResponsavelSelectorItem extends StatelessWidget {
  const _ResponsavelSelectorItem({
    required this.responsavel,
    required this.selected,
    required this.onTap,
  });

  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _iconSurfaceColor => SixMobilePalette.iconSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _highlightedBorderColor =>
      SixMobilePalette.highlightedBorder;

  final _ResponsavelTecnicoMobile responsavel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? _softAccentSurfaceColor : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _highlightedBorderColor : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? _accentColor.withValues(alpha: 0.12)
                    : _iconSurfaceColor,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: selected ? _accentColor : _titleTextColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      responsavel.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (responsavel.subtitulo.trim().isNotEmpty) ...<Widget>[
                      SizedBox(height: 4),
                      Text(
                        responsavel.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _mutedTextColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: Duration(milliseconds: 140),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _accentColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AtendimentoTecnicoClienteSelectorMobile extends StatefulWidget {
  const AtendimentoTecnicoClienteSelectorMobile({
    super.key,
    required this.clientes,
    required this.clienteSelecionado,
  });

  final List<ClienteUsuario> clientes;
  final ClienteUsuario? clienteSelecionado;

  @override
  State<AtendimentoTecnicoClienteSelectorMobile> createState() =>
      _AtendimentoTecnicoClienteSelectorMobileState();
}

class _CadastrarClienteAtendimentoAction {
  const _CadastrarClienteAtendimentoAction();
}

class _AtendimentoTecnicoClienteSelectorMobileState
    extends State<AtendimentoTecnicoClienteSelectorMobile> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<ClienteUsuario> get _clientesFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) {
      return widget.clientes;
    }

    return widget.clientes
        .where((ClienteUsuario cliente) {
          final String source = _normalize(
            '${cliente.nome} ${cliente.telefone} ${cliente.email} ${cliente.documento}',
          );
          return source.contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<ClienteUsuario> clientes = _clientesFiltrados;

        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.activeBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SixMobilePalette.softAccentSurface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.person_search_outlined,
                          color: _accentColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Selecionar cliente',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Busque e toque para vincular ao atendimento.',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const _CadastrarClienteAtendimentoAction()),
                      icon: Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        context.t(
                          'atendimentoTecnico.client.create',
                          fallback: 'Cadastrar cliente',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) =>
                        setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente',
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filter = '');
                              },
                            ),
                      filled: true,
                      fillColor: _surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _accentColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: clientes.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(18, 0, 18, 22),
                          itemBuilder: (BuildContext context, int index) {
                            final ClienteUsuario cliente = clientes[index];
                            final bool selected = _isSelected(cliente);
                            return _ClienteSelectorItem(
                              cliente: cliente,
                              selected: selected,
                              onTap: () => Navigator.of(context).pop(cliente),
                            );
                          },
                          separatorBuilder: (_, __) => SizedBox(height: 10),
                          itemCount: clientes.length,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 22),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SixMobilePalette.softAccentSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.search_off_rounded, color: _accentColor),
              ),
              SizedBox(height: 12),
              Text(
                'Nenhum cliente encontrado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Tente buscar por nome, telefone, e-mail ou documento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _mutedTextColor, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSelected(ClienteUsuario cliente) {
    final ClienteUsuario? selected = widget.clienteSelecionado;
    if (selected == null) {
      return false;
    }
    return selected.id == cliente.id;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ClienteSelectorItem extends StatelessWidget {
  const _ClienteSelectorItem({
    required this.cliente,
    required this.selected,
    required this.onTap,
  });

  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _iconSurfaceColor => SixMobilePalette.iconSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _highlightedBorderColor =>
      SixMobilePalette.highlightedBorder;

  final ClienteUsuario cliente;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String subtitle = _subtitle(cliente);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? _softAccentSurfaceColor : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _highlightedBorderColor : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? _accentColor.withValues(alpha: 0.12)
                    : _iconSurfaceColor,
                child: Text(
                  _initials(cliente.nome),
                  style: TextStyle(
                    color: selected ? _accentColor : _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _mutedTextColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: Duration(milliseconds: 140),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _accentColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(ClienteUsuario cliente) {
    return <String>[
      cliente.telefone,
      cliente.email,
      cliente.documento,
    ].where((String value) => value.trim().isNotEmpty).join(' • ');
  }

  static String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(' ')
        .where((String item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'CL';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0x33FFFFFF)),
      ),
      child: Icon(
        Icons.build_circle_rounded,
        color: SixMobilePalette.onPrimary,
      ),
    );
  }
}
