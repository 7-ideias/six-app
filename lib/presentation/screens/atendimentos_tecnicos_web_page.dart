import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/dominio_models.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/web/six_web_animated_dialog.dart';
import '../theme/web_theme_tokens.dart';
import '../utils/atendimento_tecnico_foto_payload.dart';
import 'pdv_cliente_identificacao_dialog.dart';
import 'produto_lista_sub_painel_web.dart';

class AtendimentosTecnicosWebPage extends StatefulWidget {
  const AtendimentosTecnicosWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AtendimentosTecnicosWebPage> createState() =>
      _AtendimentosTecnicosWebPageState();
}

class _AtendimentosTecnicosWebPageState
    extends State<AtendimentosTecnicosWebPage> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final ClienteUsuarioApiClient _clienteApiClient =
      HttpClienteUsuarioApiClient();
  final ColaboradorUsuarioApiClient _colaboradorApiClient =
      HttpColaboradorUsuarioApiClient();

  final TextEditingController _clienteController = TextEditingController();
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

  final List<_AtendimentoItemDraft> _itens = <_AtendimentoItemDraft>[];
  final List<AtendimentoTecnicoFotoInput> _fotos =
      <AtendimentoTecnicoFotoInput>[];
  final ImagePicker _imagePicker = ImagePicker();

  late Future<_AtendimentoTecnicoViewState> _future;
  DateTime _validadeOrcamentoEm = _defaultValidadeOrcamento();
  DateTime _vencimentoFinanceiroEm = _defaultVencimentoFinanceiro();
  DateTime _dataEntregaPrevista = _defaultValidadeOrcamento();
  String? _clienteSelecionadoId;
  _ResponsavelTecnicoWeb? _responsavelSelecionado;
  bool _salvando = false;
  int _etapaAtual = 0;

  static DateTime _inicioHoje() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _defaultValidadeOrcamento() {
    return _inicioHoje().add(const Duration(days: 7));
  }

  static DateTime _defaultVencimentoFinanceiro() {
    return _inicioHoje().add(const Duration(days: 7));
  }

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  @override
  void dispose() {
    _clienteController.dispose();
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

  Future<_AtendimentoTecnicoViewState> _carregar() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _service.buscarDominiosBase(),
      _clienteApiClient.listarClientesUsuario(),
      _colaboradorApiClient.listarTecnicosAssistenciaTecnica(),
    ]);
    final List<_ResponsavelTecnicoWeb> responsaveis = _montarResponsaveis(
      results[2] as List<ColaboradorUsuarioResumo>,
    );
    _responsavelSelecionado = _resolverResponsavelSelecionado(responsaveis);

    return _AtendimentoTecnicoViewState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      clientes: (results[1] as ClienteUsuarioListResponse).clientes,
      responsaveis: responsaveis,
    );
  }

  void _recarregar() {
    setState(() => _future = _carregar());
  }

  void _limparFormulario() {
    _clienteSelecionadoId = null;
    _clienteController.clear();
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
    _validadeOrcamentoEm = _defaultValidadeOrcamento();
    _vencimentoFinanceiroEm = _defaultVencimentoFinanceiro();
    _dataEntregaPrevista = _defaultValidadeOrcamento();
    _itens.clear();
    _fotos.clear();
    _etapaAtual = 0;
  }

  ClienteUsuario? _clienteSelecionado(List<ClienteUsuario> clientes) {
    final id = _clienteSelecionadoId;
    if (id == null || id.isEmpty) return null;
    for (final cliente in clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  List<_ResponsavelTecnicoWeb> _montarResponsaveis(
    List<ColaboradorUsuarioResumo> colaboradores,
  ) {
    final Map<String, _ResponsavelTecnicoWeb> mapa =
        <String, _ResponsavelTecnicoWeb>{};

    void add(_ResponsavelTecnicoWeb responsavel) {
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
        'Técnico autorizado',
        colaborador.email,
        colaborador.celularDeAcesso,
      ].where((String item) => item.trim().isNotEmpty).join(' • ');

      add(
        _ResponsavelTecnicoWeb(
          id: id.isEmpty ? nome : id,
          nome: nome.isEmpty ? 'Técnico autorizado' : nome,
          subtitulo: subtitulo,
        ),
      );
    }

    return mapa.values.toList(growable: false);
  }

  _ResponsavelTecnicoWeb? _resolverResponsavelSelecionado(
    List<_ResponsavelTecnicoWeb> responsaveis,
  ) {
    if (responsaveis.isEmpty) return null;
    final _ResponsavelTecnicoWeb? atual = _responsavelSelecionado;
    if (atual == null) return responsaveis.first;
    return responsaveis.firstWhere(
      (_ResponsavelTecnicoWeb item) => item.id == atual.id,
      orElse: () => responsaveis.first,
    );
  }

  Future<void> _abrirIdentificacaoCliente(List<ClienteUsuario> clientes) async {
    final atual = _clienteSelecionado(clientes);
    final result = await showSixWebCustomerIdentificationDialog(
      context: context,
      clienteAtual: atual,
      apiClient: _clienteApiClient,
    );

    if (!mounted || result == null) return;

    if (result.limpar) {
      setState(() {
        _clienteSelecionadoId = null;
        _clienteController.clear();
      });
      return;
    }

    final cliente = result.cliente;
    if (cliente == null) return;
    setState(() {
      _clienteSelecionadoId = cliente.id;
      _clienteController.text = cliente.nome;
    });
  }

  Future<void> _abrirSelecaoResponsavel(
    List<_ResponsavelTecnicoWeb> responsaveis,
  ) async {
    if (responsaveis.isEmpty) {
      _mostrarMensagem('Nenhum responsável técnico disponível para seleção.');
      return;
    }

    final _ResponsavelTecnicoWeb? result =
        await showSixWebAnimatedDialog<_ResponsavelTecnicoWeb>(
          context: context,
          builder: (_) => _ResponsavelTecnicoWebSelectorDialog(
            responsaveis: responsaveis,
            responsavelSelecionado: _responsavelSelecionado,
          ),
        );

    if (!mounted || result == null) return;
    setState(() => _responsavelSelecionado = result);
  }

  Future<void> _selecionarValidadeOrcamento() async {
    final data = await _selecionarData(
      initialDate: _validadeOrcamentoEm,
      helpText: 'Validade do orçamento',
    );
    if (data == null) return;
    setState(() => _validadeOrcamentoEm = data);
  }

  Future<void> _selecionarVencimentoFinanceiro() async {
    final data = await _selecionarData(
      initialDate: _vencimentoFinanceiroEm,
      helpText: 'Vencimento financeiro',
    );
    if (data == null) return;
    setState(() => _vencimentoFinanceiroEm = data);
  }

  Future<void> _selecionarDataEntregaPrevista() async {
    final data = await _selecionarData(
      initialDate: _dataEntregaPrevista,
      helpText: 'Entrega prevista',
      firstDate: DateTime(2000),
    );
    if (data == null) return;
    setState(() => _dataEntregaPrevista = data);
  }

  Future<DateTime?> _selecionarData({
    required DateTime initialDate,
    required String helpText,
    DateTime? firstDate,
  }) async {
    final inicio = _inicioHoje();
    final primeiraData = firstDate ?? inicio;
    final data = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(primeiraData)
          ? primeiraData
          : initialDate,
      firstDate: primeiraData,
      lastDate: inicio.add(const Duration(days: 365)),
      helpText: helpText,
    );
    if (data == null) return null;
    return DateTime(data.year, data.month, data.day);
  }

  Future<void> _abrirSelecaoItens(String tipoInicial) async {
    final result = await showProdutoListaSelecaoWebDialog<dynamic>(
      context: context,
      permitirSelecaoMultipla: true,
      tipoInicial: tipoInicial,
      widthFactor: 0.88,
      heightFactor: 0.86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    );

    if (!mounted || result == null) return;
    if (result is ProdutoModel) {
      setState(() => _adicionarProdutoSemSetState(result));
      return;
    }
    if (result is List) {
      final produtos = result.whereType<ProdutoModel>().toList(growable: false);
      if (produtos.isEmpty) return;
      setState(() {
        for (final produto in produtos) {
          _adicionarProdutoSemSetState(produto);
        }
      });
    }
  }

  void _adicionarProdutoSemSetState(ProdutoModel produto) {
    final chave = _chaveProduto(produto);
    final index = _itens.indexWhere((item) => item.chave == chave);
    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
      );
      return;
    }

    _itens.add(
      _AtendimentoItemDraft(
        chave: chave,
        idSku: produto.id ?? produto.codigoDeBarras,
        descricao: produto.nomeProduto,
        tipoCodigo: _ehServico(produto) ? 'SERVICE' : 'PRODUCT',
        quantidade: 1,
        valorUnitario: produto.precoVenda,
      ),
    );
  }

  void _alterarQuantidade(_AtendimentoItemDraft item, int delta) {
    setState(() {
      final index = _itens.indexWhere(
        (elemento) => elemento.chave == item.chave,
      );
      if (index < 0) return;
      final quantidade = _itens[index].quantidade + delta;
      if (quantidade <= 0) {
        _itens.removeAt(index);
        return;
      }
      _itens[index] = _itens[index].copyWith(quantidade: quantidade);
    });
  }

  void _removerItem(_AtendimentoItemDraft item) {
    setState(
      () => _itens.removeWhere((elemento) => elemento.chave == item.chave),
    );
  }

  String _chaveProduto(ProdutoModel produto) {
    final tipo = _ehServico(produto) ? 'SERVICE' : 'PRODUCT';
    final id = produto.id?.trim();
    if (id != null && id.isNotEmpty) return '$tipo:$id';
    final codigo = produto.codigoDeBarras.trim();
    if (codigo.isNotEmpty) return '$tipo:$codigo';
    return '$tipo:${produto.nomeProduto}:${produto.precoVenda}';
  }

  bool _ehServico(ProdutoModel produto) {
    final tipo = produto.tipoProduto.trim().toUpperCase();
    return tipo == 'SERVICO' || tipo == 'SERVIÇO' || tipo == 'SERVICE';
  }

  double get _totalProdutos => _itens
      .where((item) => item.tipoCodigo == 'PRODUCT')
      .fold<double>(0, (total, item) => total + item.total);

  double get _totalServicos => _itens
      .where((item) => item.tipoCodigo == 'SERVICE')
      .fold<double>(0, (total, item) => total + item.total);

  double get _totalAtendimento => _totalProdutos + _totalServicos;

  Future<void> _salvarAtendimento(List<ClienteUsuario> clientes) async {
    if (_salvando) return;
    final cliente = _clienteSelecionado(clientes);
    if (cliente == null) {
      _mostrarMensagem('Selecione um cliente cadastrado antes de salvar.');
      return;
    }
    if (_defeitoController.text.trim().isEmpty) {
      _mostrarMensagem('Informe o defeito relatado pelo cliente.');
      return;
    }

    final inicioHoje = _inicioHoje();
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
    final _ResponsavelTecnicoWeb? responsavel = _responsavelSelecionado;

    setState(() => _salvando = true);
    try {
      await _service.criar(
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
      setState(_limparFormulario);
      _recarregar();
      _mostrarMensagem(
        'Atendimento técnico criado com vencimento financeiro definido.',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível criar o atendimento: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _textoOuNulo(String value) {
    final texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  String _formatarMoeda(double value) =>
      context.read<LocaleSettingsProvider>().formatCurrency(value);

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  int _totalClientesAtivos(List<ClienteUsuario> clientes) =>
      clientes.where((cliente) => cliente.ativo).length;

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final content = FutureBuilder<_AtendimentoTecnicoViewState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading(theme);
        }
        if (snapshot.hasError) {
          return _AtendimentoTecnicoErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }
        final state = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 980;
            final horizontalPadding = isCompact ? 16.0 : 28.0;
            return Container(
              color: tokens.workspaceBackground,
              child: Column(
                children: <Widget>[
                  _buildHeader(theme, state, isCompact),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      10,
                    ),
                    child: _buildResumoOperacao(theme, state, isCompact),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        16,
                      ),
                      child: _buildFluxoAtendimento(
                        theme,
                        state,
                        isCompact: isCompact,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos técnicos'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      body: content,
    );
  }

  Widget _buildLoading(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      color: tokens.workspaceBackground,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 12),
              Text(
                'Carregando atendimentos técnicos...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    _AtendimentoTecnicoViewState state,
    bool isCompact,
  ) {
    final tokens = WebThemeTokens.of(context);
    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tokens.selectedBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.selectedBorder),
          ),
          child: Icon(
            Icons.build_circle_outlined,
            color: tokens.info,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Atendimentos técnicos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Fluxo com cliente, equipamento, diagnóstico, itens e vencimento financeiro.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _headerButton(theme, Icons.refresh_rounded, 'Atualizar', _recarregar),
        _headerBadge(
          theme,
          '${_totalClientesAtivos(state.clientes)} clientes',
          Icons.people_alt_outlined,
        ),
        if (widget.onBack != null) _closeButton(context),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(bottom: BorderSide(color: tokens.cardBorder)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              children: <Widget>[
                titleBlock,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                actions,
              ],
            ),
    );
  }

  Widget _buildResumoOperacao(
    ThemeData theme,
    _AtendimentoTecnicoViewState state,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isCompact
            ? constraints.maxWidth
            : ((constraints.maxWidth - 36) / 4).clamp(190.0, 360.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Clientes ativos',
              value: '${_totalClientesAtivos(state.clientes)}',
              helper: 'Disponíveis para vínculo',
              icon: Icons.people_alt_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Entrega prevista',
              value: _formatarData(_dataEntregaPrevista),
              helper: 'Prazo de término',
              icon: Icons.event_available_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Vencimento financeiro',
              value: _formatarData(_vencimentoFinanceiroEm),
              helper: 'Data da cobrança',
              icon: Icons.account_balance_wallet_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Novo total',
              value: _formatarMoeda(_totalAtendimento),
              helper: 'Itens deste atendimento',
              icon: Icons.payments_outlined,
              highlight: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFluxoAtendimento(
    ThemeData theme,
    _AtendimentoTecnicoViewState state, {
    required bool isCompact,
  }) {
    final tokens = WebThemeTokens.of(context);
    final cliente = _clienteSelecionado(state.clientes);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _sectionHeader(
          theme,
          title: _journeyStepTitleWeb(_etapaAtual),
          subtitle: _journeyStepDescriptionWeb(_etapaAtual),
          icon: _journeyStepIconWeb(_etapaAtual),
        ),
        const SizedBox(height: 18),
        _journeyProgressWeb(theme, isCompact: isCompact),
        const SizedBox(height: 18),
        if (_etapaAtual == 0)
          _buildClienteSelecionadoCard(theme, state.clientes, cliente),
        if (_etapaAtual == 0) const SizedBox(height: 14),
        if (_etapaAtual == 0)
          _buildResponsavelSelecionadoCard(
            theme,
            state.responsaveis,
            _responsavelSelecionado,
          ),
        if (_etapaAtual == 0) const SizedBox(height: 18),
        _buildFormGrid(
          children: <Widget>[
            if (_etapaAtual == 0)
              TextField(
                controller: _descricaoController,
                decoration: _inputDecoration(
                  theme,
                  label: 'Descrição interna',
                  hint: 'Ex.: Troca de tela iPhone 11',
                  icon: Icons.notes_outlined,
                ),
              ),
            if (_etapaAtual == 3)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selecionarValidadeOrcamento,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    theme,
                    label: 'Validade do orçamento',
                    helper:
                        'Obrigatório. O orçamento não pode ficar indeterminado.',
                    icon: Icons.event_outlined,
                  ),
                  child: Text(
                    _formatarData(_validadeOrcamentoEm),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (_etapaAtual == 3)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selecionarVencimentoFinanceiro,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    theme,
                    label: 'Vencimento financeiro',
                    helper: 'Data prevista para cobrança/recebimento.',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  child: Text(
                    _formatarData(_vencimentoFinanceiroEm),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (_etapaAtual == 3)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selecionarDataEntregaPrevista,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    theme,
                    label: 'Entrega prevista',
                    helper: 'Data prevista para entrega ou término.',
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                  child: Text(
                    _formatarData(_dataEntregaPrevista),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (_etapaAtual == 1)
              TextField(
                controller: _tipoEquipamentoController,
                decoration: _inputDecoration(
                  theme,
                  label: 'Tipo de equipamento',
                  icon: Icons.devices_other_outlined,
                ),
              ),
            if (_etapaAtual == 1)
              TextField(
                controller: _marcaController,
                decoration: _inputDecoration(
                  theme,
                  label: 'Marca',
                  icon: Icons.business_outlined,
                ),
              ),
            if (_etapaAtual == 1)
              TextField(
                controller: _modeloController,
                decoration: _inputDecoration(
                  theme,
                  label: 'Modelo',
                  icon: Icons.category_outlined,
                ),
              ),
            if (_etapaAtual == 1)
              TextField(
                controller: _numeroSerieController,
                decoration: _inputDecoration(
                  theme,
                  label: 'Número de série',
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
            if (_etapaAtual == 1)
              TextField(
                controller: _imeiController,
                decoration: _inputDecoration(
                  theme,
                  label: 'IMEI',
                  icon: Icons.qr_code_2_outlined,
                ),
              ),
          ],
        ),
        if (_etapaAtual == 1) const SizedBox(height: 14),
        if (_etapaAtual == 1)
          TextField(
            controller: _acessoriosController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration(
              theme,
              label: 'Acessórios / observações de entrada',
              hint: 'Ex.: capa, película quebrada, sem carregador...',
              icon: Icons.cable_outlined,
              alignLabelWithHint: true,
            ),
          ),
        if (_etapaAtual == 2) const SizedBox(height: 14),
        if (_etapaAtual == 2)
          TextField(
            controller: _defeitoController,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDecoration(
              theme,
              label: 'Defeito relatado pelo cliente',
              hint: 'Descreva o problema informado no balcão.',
              icon: Icons.report_problem_outlined,
              alignLabelWithHint: true,
            ),
          ),
        if (_etapaAtual == 2) const SizedBox(height: 14),
        if (_etapaAtual == 2)
          TextField(
            controller: _diagnosticoController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration(
              theme,
              label: 'Diagnóstico técnico inicial',
              hint: 'Opcional neste primeiro teste.',
              icon: Icons.engineering_outlined,
              alignLabelWithHint: true,
            ),
          ),
        if (_etapaAtual == 2) const SizedBox(height: 18),
        if (_etapaAtual == 2) _buildPhotosSectionWeb(theme),
        if (_etapaAtual == 3) const SizedBox(height: 22),
        if (_etapaAtual == 3) _buildItensSection(theme, isCompact: isCompact),
        if (_etapaAtual == 4) _buildReviewWeb(theme, state.clientes),
        const SizedBox(height: 22),
        if (_etapaAtual == 4)
          _buildResumoSalvar(theme, state.clientes, isCompact: isCompact),
        if (_etapaAtual < 4)
          _journeyNavigationWeb(theme, state.clientes, isCompact: isCompact),
      ],
    );

    return Card(
      elevation: 0,
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: content),
      ),
    );
  }

  String _journeyStepTitleWeb(int index) {
    const List<String> values = <String>[
      '1. Cliente e responsável',
      '2. Equipamento recebido',
      '3. Registro técnico e fotos',
      '4. Orçamento e prazos',
      '5. Revisão e abertura',
    ];
    return _t('atendimentoTecnico.journey.web.step.$index', values[index]);
  }

  String _journeyStepDescriptionWeb(int index) {
    const List<String> values = <String>[
      'Comece identificando o cliente e o técnico que conduzirá o serviço.',
      'Registre as informações necessárias para reconhecer o equipamento.',
      'Descreva o problema e documente o estado de entrada com até 10 fotos.',
      'Adicione produtos e serviços, defina vencimento, validade e entrega.',
      'Confira os dados consolidados antes de criar o atendimento.',
    ];
    return _t(
      'atendimentoTecnico.journey.web.step.$index.description',
      values[index],
    );
  }

  IconData _journeyStepIconWeb(int index) {
    return switch (index) {
      0 => Icons.person_search_outlined,
      1 => Icons.devices_other_outlined,
      2 => Icons.add_a_photo_outlined,
      3 => Icons.request_quote_outlined,
      _ => Icons.fact_check_outlined,
    };
  }

  Widget _journeyProgressWeb(ThemeData theme, {required bool isCompact}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing = 10;
        final double width = isCompact
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 4) / 5;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List<Widget>.generate(5, (int index) {
            final bool active = index == _etapaAtual;
            final bool done = index < _etapaAtual;
            return SizedBox(
              width: width,
              child: InkWell(
                onTap: index < _etapaAtual
                    ? () => setState(() => _etapaAtual = index)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: active
                        ? tokens.selectedBackground
                        : tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active || done
                          ? tokens.selectedBorder
                          : tokens.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: active || done ? tokens.info : tokens.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active || done
                                ? tokens.info
                                : tokens.cardBorder,
                          ),
                        ),
                        child: Icon(
                          done
                              ? Icons.check_rounded
                              : _journeyStepIconWeb(index),
                          size: 16,
                          color: active || done
                              ? theme.colorScheme.onPrimary
                              : tokens.mutedText,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _journeyShortLabelWeb(index),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: active
                                ? tokens.primaryText
                                : tokens.secondaryText,
                            fontWeight: active
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  String _journeyShortLabelWeb(int index) {
    const List<String> labels = <String>[
      'Cliente',
      'Equipamento',
      'Registro',
      'Orçamento',
      'Revisão',
    ];
    return _t('atendimentoTecnico.journey.step.$index', labels[index]);
  }

  Widget _journeyNavigationWeb(
    ThemeData theme,
    List<ClienteUsuario> clientes, {
    required bool isCompact,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: <Widget>[
          if (_etapaAtual > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _etapaAtual--),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(_t('common.back', 'Voltar')),
            ),
          FilledButton.icon(
            onPressed: () => _avancarEtapaWeb(clientes),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(_t('common.continue', 'Continuar')),
          ),
        ],
      ),
    );
  }

  void _avancarEtapaWeb(List<ClienteUsuario> clientes) {
    if (_etapaAtual == 0 && _clienteSelecionado(clientes) == null) {
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

  Widget _buildPhotosSectionWeb(ThemeData theme) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.selectedBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.photo_camera_outlined, color: tokens.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _t('atendimentoTecnico.photos.title', 'Fotos do serviço'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _t(
                        'atendimentoTecnico.photos.hint',
                        'JPG ou PNG. As fotos também serão exibidas no PDF do atendimento.',
                      ),
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Text(
                  '${_fotos.length}/${AtendimentoTecnicoFotoPayload.maxFotos}',
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double tileWidth = constraints.maxWidth < 560
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  if (_fotos.length < AtendimentoTecnicoFotoPayload.maxFotos)
                    SizedBox(
                      width: tileWidth,
                      height: 132,
                      child: _addPhotoTileWeb(tokens),
                    ),
                  ..._fotos.asMap().entries.map(
                    (MapEntry<int, AtendimentoTecnicoFotoInput> entry) =>
                        SizedBox(
                          width: tileWidth,
                          height: 132,
                          child: _photoTileWeb(tokens, entry.key, entry.value),
                        ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _addPhotoTileWeb(WebThemeTokens tokens) {
    return InkWell(
      onTap: _selecionarFotosWeb,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: tokens.selectedBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_photo_alternate_outlined, color: tokens.info),
            const SizedBox(height: 8),
            Text(
              _t('atendimentoTecnico.photos.select', 'Selecionar fotos'),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _t('atendimentoTecnico.photos.remaining', 'até 10 imagens'),
              style: TextStyle(color: tokens.secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoTileWeb(
    WebThemeTokens tokens,
    int index,
    AtendimentoTecnicoFotoInput foto,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            AtendimentoTecnicoFotoPayload.previewBytes(foto),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: 7,
          right: 42,
          bottom: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                foto.nomeArquivo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 7,
          top: 7,
          child: IconButton.filled(
            tooltip: _t('common.remove', 'Remover'),
            onPressed: () => setState(() => _fotos.removeAt(index)),
            icon: const Icon(Icons.close_rounded, size: 17),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.66),
              foregroundColor: Colors.white,
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selecionarFotosWeb() async {
    if (_fotos.length >= AtendimentoTecnicoFotoPayload.maxFotos) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.photos.limit',
          'O limite é de 10 fotos por atendimento.',
        ),
      );
      return;
    }
    try {
      final List<XFile> arquivos = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
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
      _mostrarMensagem(_photoErrorMessageWeb(error.code));
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.photos.readError',
          'Não foi possível carregar as fotos selecionadas.',
        ),
      );
    }
  }

  String _photoErrorMessageWeb(String code) {
    return switch (code) {
      'PHOTO_TOO_LARGE' => _t(
        'atendimentoTecnico.photos.tooLarge',
        'Uma foto ficou muito grande. Reduza a resolução e tente novamente.',
      ),
      'PHOTO_FORMAT_UNSUPPORTED' => _t(
        'atendimentoTecnico.photos.formatUnsupported',
        'Use fotos nos formatos JPG ou PNG.',
      ),
      _ => _t(
        'atendimentoTecnico.photos.invalid',
        'Uma das fotos selecionadas não é válida.',
      ),
    };
  }

  Widget _buildReviewWeb(ThemeData theme, List<ClienteUsuario> clientes) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ClienteUsuario? cliente = _clienteSelecionado(clientes);
    final List<_ReviewItemWeb> items = <_ReviewItemWeb>[
      _ReviewItemWeb(
        icon: Icons.person_outline_rounded,
        label: _t('atendimentoTecnico.customer', 'Cliente'),
        value: cliente?.nome ?? '-',
      ),
      _ReviewItemWeb(
        icon: Icons.engineering_outlined,
        label: _t('atendimentoTecnico.responsible', 'Responsável'),
        value: _responsavelSelecionado?.nome ?? '-',
      ),
      _ReviewItemWeb(
        icon: Icons.devices_other_outlined,
        label: _t('atendimentoTecnico.equipment', 'Equipamento'),
        value: <String>[
          _tipoEquipamentoController.text,
          _marcaController.text,
          _modeloController.text,
        ].where((String value) => value.trim().isNotEmpty).join(' • '),
      ),
      _ReviewItemWeb(
        icon: Icons.report_problem_outlined,
        label: _t('atendimentoTecnico.issue', 'Defeito relatado'),
        value: _defeitoController.text,
      ),
      _ReviewItemWeb(
        icon: Icons.photo_camera_outlined,
        label: _t('atendimentoTecnico.photos.title', 'Fotos do serviço'),
        value: '${_fotos.length} / 10',
      ),
      _ReviewItemWeb(
        icon: Icons.payments_outlined,
        label: _t('atendimentoTecnico.total', 'Valor total'),
        value: _formatarMoeda(_totalAtendimento),
      ),
      _ReviewItemWeb(
        icon: Icons.event_available_outlined,
        label: _t('atendimentoTecnico.expectedDelivery', 'Entrega prevista'),
        value: _formatarData(_dataEntregaPrevista),
      ),
      _ReviewItemWeb(
        icon: Icons.inventory_2_outlined,
        label: _t('atendimentoTecnico.items', 'Itens'),
        value: '${_itens.length}',
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth < 680
              ? constraints.maxWidth
              : (constraints.maxWidth - 14) / 2;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: items
                .map(
                  (_ReviewItemWeb item) => SizedBox(
                    width: width,
                    child: _reviewTileWeb(theme, tokens, item),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }

  Widget _reviewTileWeb(
    ThemeData theme,
    WebThemeTokens tokens,
    _ReviewItemWeb item,
  ) {
    final String value = item.value.trim().isEmpty ? '-' : item.value.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(item.icon, color: tokens.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
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

  Widget _buildClienteSelecionadoCard(
    ThemeData theme,
    List<ClienteUsuario> clientes,
    ClienteUsuario? cliente,
  ) {
    final selected = cliente != null;
    final tokens = WebThemeTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _abrirIdentificacaoCliente(clientes),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? tokens.selectedBackground : tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? tokens.selectedBorder : tokens.cardBorder,
                  ),
                ),
                child: Icon(
                  selected
                      ? Icons.check_circle_outline_rounded
                      : Icons.person_search_outlined,
                  color: selected ? tokens.info : tokens.mutedText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      selected ? cliente.nome : 'Identificar cliente',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected
                          ? '${cliente.telefone.isEmpty ? 'sem telefone' : cliente.telefone} • ${cliente.email.isEmpty ? 'sem e-mail' : cliente.email}'
                          : 'Clique para buscar e selecionar um cliente cadastrado.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _abrirIdentificacaoCliente(clientes),
                icon: Icon(
                  selected ? Icons.swap_horiz_rounded : Icons.search_rounded,
                ),
                label: Text(selected ? 'Trocar cliente' : 'Buscar cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsavelSelecionadoCard(
    ThemeData theme,
    List<_ResponsavelTecnicoWeb> responsaveis,
    _ResponsavelTecnicoWeb? responsavel,
  ) {
    final bool selected = responsavel != null;
    final tokens = WebThemeTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _abrirSelecaoResponsavel(responsaveis),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? tokens.selectedBackground : tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? tokens.selectedBorder : tokens.cardBorder,
                  ),
                ),
                child: Icon(
                  selected
                      ? Icons.engineering_rounded
                      : Icons.engineering_outlined,
                  color: selected ? tokens.info : tokens.mutedText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      selected
                          ? responsavel.nome
                          : 'Selecionar responsável técnico',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected
                          ? responsavel.subtitulo
                          : 'Apenas ADMIN ou colaboradores com permissão técnica aparecem aqui.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _abrirSelecaoResponsavel(responsaveis),
                icon: Icon(
                  selected ? Icons.swap_horiz_rounded : Icons.search_rounded,
                ),
                label: Text(
                  selected ? 'Trocar responsável' : 'Buscar responsável',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItensSection(ThemeData theme, {required bool isCompact}) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final title = _sectionHeader(
                theme,
                title: 'Itens do orçamento/serviço',
                subtitle:
                    'Adicione peças/produtos e mão de obra no mesmo atendimento.',
                icon: Icons.inventory_2_outlined,
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _abrirSelecaoItens('PRODUTO'),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Adicionar peça'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _abrirSelecaoItens('SERVICO'),
                    icon: const Icon(Icons.handyman_outlined),
                    label: const Text('Adicionar serviço'),
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    title,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (_itens.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nenhum item adicionado. Você pode abrir o atendimento só com o diagnóstico e incluir os itens depois.',
                style: TextStyle(color: tokens.secondaryText),
              ),
            )
          else
            Column(
              children: _itens
                  .map(
                    (item) => _buildItemRow(theme, item, isCompact: isCompact),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    ThemeData theme,
    _AtendimentoItemDraft item, {
    required bool isCompact,
  }) {
    final isServico = item.tipoCodigo == 'SERVICE';
    final tokens = WebThemeTokens.of(context);
    final icon = Icon(
      isServico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
      color: isServico ? tokens.info : tokens.warning,
    );
    final info = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.descricao,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            '${isServico ? 'Serviço' : 'Produto/peça'} • ${_formatarMoeda(item.valorUnitario)}',
            style: TextStyle(fontSize: 12, color: tokens.secondaryText),
          ),
        ],
      ),
    );
    final quantity = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: () => _alterarQuantidade(item, -1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          item.quantidade.toString(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        IconButton(
          onPressed: () => _alterarQuantidade(item, 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[icon, const SizedBox(width: 10), info]),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    quantity,
                    const Spacer(),
                    Text(
                      _formatarMoeda(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      tooltip: 'Remover item',
                      onPressed: () => _removerItem(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: <Widget>[
                icon,
                const SizedBox(width: 10),
                info,
                quantity,
                SizedBox(
                  width: 104,
                  child: Text(
                    _formatarMoeda(item.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: () => _removerItem(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
    );
  }

  Widget _buildResumoSalvar(
    ThemeData theme,
    List<ClienteUsuario> clientes, {
    required bool isCompact,
  }) {
    final tokens = WebThemeTokens.of(context);
    final metrics = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _metricChip(
          theme,
          _formatarData(_validadeOrcamentoEm),
          'validade orçamento',
          Icons.event_available_outlined,
        ),
        _metricChip(
          theme,
          _formatarData(_vencimentoFinanceiroEm),
          'vencimento financeiro',
          Icons.account_balance_wallet_outlined,
        ),
        _metricChip(
          theme,
          _formatarData(_dataEntregaPrevista),
          'entrega prevista',
          Icons.assignment_turned_in_outlined,
        ),
        _metricChip(
          theme,
          _formatarMoeda(_totalProdutos),
          'produtos',
          Icons.inventory_2_outlined,
        ),
        _metricChip(
          theme,
          _formatarMoeda(_totalServicos),
          'serviços',
          Icons.handyman_outlined,
        ),
        _metricChip(
          theme,
          _formatarMoeda(_totalAtendimento),
          'total',
          Icons.payments_outlined,
        ),
      ],
    );
    final action = FilledButton.icon(
      onPressed: _salvando ? null : () => _salvarAtendimento(clientes),
      icon: _salvando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_rounded),
      label: Text(_salvando ? 'Salvando...' : 'Criar atendimento'),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.selectedBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.selectedBorder),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                metrics,
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: action),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: metrics),
                const SizedBox(width: 12),
                action,
              ],
            ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tokens.selectedBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.selectedBorder),
          ),
          child: Icon(icon, color: tokens.info, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
                )
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String label,
    IconData? icon,
    String? hint,
    String? helper,
    bool alignLabelWithHint = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null ? null : Icon(icon, color: tokens.info),
      filled: true,
      fillColor: tokens.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.info, width: 1.4),
      ),
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required double width,
    required String label,
    required String value,
    required String helper,
    required IconData icon,
    bool highlight = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    final bool emphasize = highlight;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: emphasize ? tokens.selectedBackground : tokens.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: emphasize ? tokens.selectedBorder : tokens.cardBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: emphasize
                    ? tokens.selectedBackground
                    : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: emphasize ? tokens.selectedBorder : tokens.cardBorder,
                ),
              ),
              child: Icon(icon, color: tokens.info, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: emphasize
                          ? tokens.secondaryText
                          : tokens.mutedText,
                      fontSize: 12,
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

  Widget _headerButton(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) {
    final tokens = WebThemeTokens.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        backgroundColor: tokens.surface,
        foregroundColor: tokens.info,
        side: BorderSide(color: tokens.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (widget.onBack != null) {
            widget.onBack!.call();
            return;
          }
          Navigator.of(context).maybePop();
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: tokens.danger, size: 24),
        ),
      ),
    );
  }

  Widget _headerBadge(ThemeData theme, String label, IconData icon) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: tokens.mutedText),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: tokens.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tokens.info),
          const SizedBox(width: 7),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: tokens.secondaryText)),
        ],
      ),
    );
  }
}

class _AtendimentoTecnicoErrorState extends StatelessWidget {
  const _AtendimentoTecnicoErrorState({
    required this.mensagem,
    required this.onRetry,
  });

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 42),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os atendimentos.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsavelTecnicoWebSelectorDialog extends StatefulWidget {
  const _ResponsavelTecnicoWebSelectorDialog({
    required this.responsaveis,
    required this.responsavelSelecionado,
  });

  final List<_ResponsavelTecnicoWeb> responsaveis;
  final _ResponsavelTecnicoWeb? responsavelSelecionado;

  @override
  State<_ResponsavelTecnicoWebSelectorDialog> createState() =>
      _ResponsavelTecnicoWebSelectorDialogState();
}

class _ResponsavelTecnicoWebSelectorDialogState
    extends State<_ResponsavelTecnicoWebSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ResponsavelTecnicoWeb> get _responsaveisFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.responsaveis;
    return widget.responsaveis
        .where((_ResponsavelTecnicoWeb item) {
          return _normalize('${item.nome} ${item.subtitulo}').contains(term);
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
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<_ResponsavelTecnicoWeb> responsaveis = _responsaveisFiltrados;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: tokens.surfaceElevated,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tokens.selectedBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.selectedBorder),
                    ),
                    child: Icon(Icons.engineering_outlined, color: tokens.info),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Responsável técnico',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Selecione um técnico autorizado para assistência.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: tokens.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (String value) => setState(() => _filter = value),
                decoration: InputDecoration(
                  hintText: 'Buscar responsável',
                  prefixIcon: Icon(Icons.search_rounded, color: tokens.info),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: tokens.inputBackground,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: responsaveis.isEmpty
                    ? _buildEmpty(theme)
                    : ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          final _ResponsavelTecnicoWeb responsavel =
                              responsaveis[index];
                          final bool selected =
                              widget.responsavelSelecionado?.id ==
                              responsavel.id;
                          return _buildItem(theme, responsavel, selected);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: responsaveis.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Nenhum responsável encontrado.',
        textAlign: TextAlign.center,
        style: TextStyle(color: tokens.secondaryText),
      ),
    );
  }

  Widget _buildItem(
    ThemeData theme,
    _ResponsavelTecnicoWeb responsavel,
    bool selected,
  ) {
    final tokens = WebThemeTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(responsavel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? tokens.selectedBackground : tokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor: selected
                    ? tokens.selectedBackground
                    : tokens.surfaceMuted,
                child: Icon(Icons.person_outline_rounded, color: tokens.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      responsavel.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (responsavel.subtitulo.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        responsavel.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 140),
                child: Icon(Icons.check_circle_rounded, color: tokens.info),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ReviewItemWeb {
  const _ReviewItemWeb({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _AtendimentoTecnicoViewState {
  const _AtendimentoTecnicoViewState({
    required this.dominios,
    required this.clientes,
    required this.responsaveis,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<ClienteUsuario> clientes;
  final List<_ResponsavelTecnicoWeb> responsaveis;
}

class _ResponsavelTecnicoWeb {
  const _ResponsavelTecnicoWeb({
    required this.id,
    required this.nome,
    required this.subtitulo,
  });

  final String id;
  final String nome;
  final String subtitulo;
}

class _AtendimentoItemDraft {
  const _AtendimentoItemDraft({
    required this.chave,
    required this.idSku,
    required this.descricao,
    required this.tipoCodigo,
    required this.quantidade,
    required this.valorUnitario,
  });

  final String chave;
  final String idSku;
  final String descricao;
  final String tipoCodigo;
  final int quantidade;
  final double valorUnitario;

  double get total => quantidade * valorUnitario;

  _AtendimentoItemDraft copyWith({int? quantidade}) {
    return _AtendimentoItemDraft(
      chave: chave,
      idSku: idSku,
      descricao: descricao,
      tipoCodigo: tipoCodigo,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario,
    );
  }

  AtendimentoTecnicoItemInput toInput({_ResponsavelTecnicoWeb? responsavel}) {
    final produto = tipoCodigo == 'PRODUCT';
    return AtendimentoTecnicoItemInput(
      tipoItemId: produto ? 10 : 20,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      idTecnicoResponsavel: responsavel?.id,
      nomeTecnicoResponsavel: responsavel?.nome,
      movimentaEstoque: produto,
    );
  }
}
