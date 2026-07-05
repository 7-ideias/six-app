import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/dominio_models.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
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

  final TextEditingController _buscaClienteController = TextEditingController();
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

  late Future<_AtendimentoTecnicoViewState> _future;
  DateTime _validadeOrcamentoEm = _defaultValidadeOrcamento();
  String? _clienteSelecionadoId;
  bool _salvando = false;

  static DateTime _defaultValidadeOrcamento() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
  }

  @override
  void initState() {
    super.initState();
    _future = _carregar();
    _buscaClienteController.addListener(_onBuscaClienteChanged);
  }

  @override
  void dispose() {
    _buscaClienteController.removeListener(_onBuscaClienteChanged);
    _buscaClienteController.dispose();
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
      _service.listar(),
      _clienteApiClient.listarClientesUsuario(),
    ]);

    return _AtendimentoTecnicoViewState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      atendimentos: results[1] as List<AtendimentoTecnicoModel>,
      clientes: (results[2] as ClienteUsuarioListResponse).clientes,
    );
  }

  void _onBuscaClienteChanged() {
    if (mounted) setState(() {});
  }

  void _recarregar() {
    setState(() => _future = _carregar());
  }

  void _limparFormulario() {
    _clienteSelecionadoId = null;
    _buscaClienteController.clear();
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
    _itens.clear();
  }

  ClienteUsuario? _clienteSelecionado(List<ClienteUsuario> clientes) {
    final id = _clienteSelecionadoId;
    if (id == null || id.isEmpty) return null;
    for (final cliente in clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  List<ClienteUsuario> _clientesFiltrados(List<ClienteUsuario> clientes) {
    final termo = _buscaClienteController.text.trim().toLowerCase();
    final ativos = clientes.where((cliente) => cliente.ativo).toList();
    if (termo.isEmpty) return ativos.take(12).toList(growable: false);
    return ativos.where((cliente) {
      final base = <String>[
        cliente.nome,
        cliente.documento,
        cliente.telefone,
        cliente.email,
      ].join(' ').toLowerCase();
      return base.contains(termo);
    }).take(12).toList(growable: false);
  }

  void _selecionarCliente(ClienteUsuario cliente) {
    setState(() {
      _clienteSelecionadoId = cliente.id;
      _buscaClienteController.text = cliente.nome;
    });
  }

  Future<void> _selecionarValidadeOrcamento() async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final data = await showDatePicker(
      context: context,
      initialDate: _validadeOrcamentoEm.isBefore(inicio)
          ? inicio
          : _validadeOrcamentoEm,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 365)),
      helpText: 'Validade do orçamento',
    );
    if (data == null) return;
    setState(
      () => _validadeOrcamentoEm = DateTime(data.year, data.month, data.day),
    );
  }

  Future<void> _abrirSelecaoItens(String tipoInicial) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.88,
            height: MediaQuery.of(dialogContext).size.height * 0.86,
            child: SubPainelWebProdutoLista(
              isSelecao: true,
              permitirSelecaoMultipla: true,
              tipoInicial: tipoInicial,
            ),
          ),
        );
      },
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
      final index = _itens.indexWhere((elemento) => elemento.chave == item.chave);
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
    setState(() => _itens.removeWhere((elemento) => elemento.chave == item.chave));
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

    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    if (_validadeOrcamentoEm.isBefore(inicioHoje)) {
      _mostrarMensagem('A validade do orçamento não pode ser anterior à data atual.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await _service.criar(
        AtendimentoTecnicoCreateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: cliente.id,
          nomeClienteSnapshot: cliente.nome,
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
          itens: _itens.map((item) => item.toInput()).toList(growable: false),
        ),
      );

      if (!mounted) return;
      setState(_limparFormulario);
      _recarregar();
      _mostrarMensagem('Atendimento técnico criado com validade de orçamento definida.');
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

  String _formatarMoeda(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final dia = value.day.toString().padLeft(2, '0');
    final mes = value.month.toString().padLeft(2, '0');
    final ano = value.year.toString();
    return '$dia/$mes/$ano';
  }

  String _statusLabel(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final nomeBackend = atendimento.statusNomePtBr?.trim() ?? '';
    if (nomeBackend.isNotEmpty) return nomeBackend;
    for (final opcao in status) {
      if (opcao.id == atendimento.statusId &&
          opcao.nomePadraoPtBr.trim().isNotEmpty) {
        return opcao.nomePadraoPtBr;
      }
    }
    return atendimento.statusCodigo;
  }

  int _totalClientesAtivos(List<ClienteUsuario> clientes) =>
      clientes.where((cliente) => cliente.ativo).length;

  int _totalAbertos(List<AtendimentoTecnicoModel> atendimentos) => atendimentos
      .where((atendimento) => !atendimento.operacaoLiquidada)
      .length;

  double _valorAberto(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos.fold<double>(
        0,
        (total, atendimento) => total + atendimento.valorEmAberto,
      );

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
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
                      child: _buildConteudoPrincipal(theme, state, isCompact),
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
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Text('Carregando atendimentos técnicos...'),
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
    final colorScheme = theme.colorScheme;
    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.build_circle_outlined,
            color: colorScheme.primary,
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
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Fluxo com cliente, equipamento, diagnóstico, itens e validade obrigatória do orçamento.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.66)),
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
        _headerBadge(
          theme,
          '${state.atendimentos.length} atendimentos',
          Icons.assignment_outlined,
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
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.14)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              label: 'Atendimentos',
              value: '${state.atendimentos.length}',
              helper: 'Criados no endpoint',
              icon: Icons.assignment_turned_in_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Abertos',
              value: '${_totalAbertos(state.atendimentos)}',
              helper: 'Pendentes de recebimento',
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

  Widget _buildConteudoPrincipal(
    ThemeData theme,
    _AtendimentoTecnicoViewState state,
    bool isCompact,
  ) {
    if (isCompact) {
      return ListView(
        children: <Widget>[
          _buildFluxoAtendimento(theme, state, isCompact: true),
          const SizedBox(height: 14),
          _buildClientesCadastrados(theme, state.clientes, isCompact: true),
          const SizedBox(height: 14),
          _buildAtendimentosCriados(theme, state, isCompact: true),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 7,
          child: _buildFluxoAtendimento(theme, state, isCompact: false),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 460,
          child: Column(
            children: <Widget>[
              Expanded(
                child: _buildClientesCadastrados(
                  theme,
                  state.clientes,
                  isCompact: false,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildAtendimentosCriados(
                  theme,
                  state,
                  isCompact: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFluxoAtendimento(
    ThemeData theme,
    _AtendimentoTecnicoViewState state, {
    required bool isCompact,
  }) {
    final cliente = _clienteSelecionado(state.clientes);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _sectionHeader(
          theme,
          title: 'Novo atendimento técnico',
          subtitle: 'Preencha os dados principais para abrir o fluxo.',
          icon: Icons.assignment_add,
        ),
        const SizedBox(height: 18),
        _buildClienteSelecionadoCard(theme, cliente),
        const SizedBox(height: 18),
        _buildFormGrid(
          children: <Widget>[
            TextField(
              controller: _descricaoController,
              decoration: _inputDecoration(
                theme,
                label: 'Descrição interna',
                hint: 'Ex.: Troca de tela iPhone 11',
                icon: Icons.notes_outlined,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _selecionarValidadeOrcamento,
              child: InputDecorator(
                decoration: _inputDecoration(
                  theme,
                  label: 'Validade do orçamento',
                  helper: 'Obrigatório. O orçamento não pode ficar indeterminado.',
                  icon: Icons.event_outlined,
                ),
                child: Text(
                  _formatarData(_validadeOrcamentoEm),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            TextField(
              controller: _tipoEquipamentoController,
              decoration: _inputDecoration(
                theme,
                label: 'Tipo de equipamento',
                icon: Icons.devices_other_outlined,
              ),
            ),
            TextField(
              controller: _marcaController,
              decoration: _inputDecoration(
                theme,
                label: 'Marca',
                icon: Icons.business_outlined,
              ),
            ),
            TextField(
              controller: _modeloController,
              decoration: _inputDecoration(
                theme,
                label: 'Modelo',
                icon: Icons.category_outlined,
              ),
            ),
            TextField(
              controller: _numeroSerieController,
              decoration: _inputDecoration(
                theme,
                label: 'Número de série',
                icon: Icons.confirmation_number_outlined,
              ),
            ),
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
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
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
        const SizedBox(height: 22),
        _buildItensSection(theme, isCompact: isCompact),
        const SizedBox(height: 22),
        _buildResumoSalvar(theme, state.clientes, isCompact: isCompact),
      ],
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.13)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isCompact ? content : SingleChildScrollView(child: content),
      ),
    );
  }

  Widget _buildClienteSelecionadoCard(ThemeData theme, ClienteUsuario? cliente) {
    final selected = cliente != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withOpacity(0.07)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.24)
              : theme.colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withOpacity(0.10)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              selected
                  ? Icons.check_circle_outline_rounded
                  : Icons.person_pin_circle_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  cliente?.nome.isNotEmpty == true
                      ? cliente!.nome
                      : 'Nenhum cliente selecionado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cliente == null
                      ? 'Escolha um cliente cadastrado no painel ao lado.'
                      : '${cliente.telefone.isEmpty ? 'sem telefone' : cliente.telefone} • ${cliente.email.isEmpty ? 'sem e-mail' : cliente.email}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientesCadastrados(
    ThemeData theme,
    List<ClienteUsuario> clientes, {
    required bool isCompact,
  }) {
    final filtrados = _clientesFiltrados(clientes);
    final list = filtrados.isEmpty
        ? _emptyInline(theme, 'Nenhum cliente encontrado.')
        : ListView.separated(
            primary: false,
            shrinkWrap: isCompact,
            itemCount: filtrados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cliente = filtrados[index];
              final selected = cliente.id == _clienteSelecionadoId;
              return Material(
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.08)
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _selecionarCliente(cliente),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 18,
                          child: Text(
                            cliente.nome.trim().isEmpty
                                ? '?'
                                : cliente.nome.trim()[0].toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                cliente.nome.isEmpty
                                    ? 'Cliente sem nome'
                                    : cliente.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cliente.telefone.isNotEmpty
                                    ? cliente.telefone
                                    : cliente.email.isNotEmpty
                                        ? cliente.email
                                        : cliente.documento,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.13)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sectionHeader(
              theme,
              title: 'Clientes cadastrados',
              subtitle: '${clientes.length} cliente(s) encontrados no cadastro.',
              icon: Icons.people_alt_outlined,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _buscaClienteController,
              decoration: _inputDecoration(
                theme,
                label: 'Buscar cliente',
                hint: 'Nome, telefone, e-mail ou documento',
                icon: Icons.search_rounded,
              ),
            ),
            const SizedBox(height: 12),
            if (isCompact)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: list,
              )
            else
              Expanded(child: list),
          ],
        ),
      ),
    );
  }

  Widget _buildItensSection(ThemeData theme, {required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.13)),
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
                subtitle: 'Adicione peças/produtos e mão de obra no mesmo atendimento.',
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
                  children: <Widget>[title, const SizedBox(height: 12), actions],
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
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nenhum item adicionado. Você pode abrir o atendimento só com o diagnóstico e incluir os itens depois.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            Column(
              children: _itens
                  .map((item) => _buildItemRow(theme, item, isCompact: isCompact))
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
    final icon = Icon(
      isServico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
      color: theme.colorScheme.primary,
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
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
        borderRadius: BorderRadius.circular(16),
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
    final metrics = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _metricChip(
          theme,
          _formatarData(_validadeOrcamentoEm),
          'validade',
          Icons.event_available_outlined,
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
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.16)),
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

  Widget _buildAtendimentosCriados(
    ThemeData theme,
    _AtendimentoTecnicoViewState state, {
    required bool isCompact,
  }) {
    final list = state.atendimentos.isEmpty
        ? _emptyInline(theme, 'Nenhum atendimento técnico ainda.')
        : ListView.separated(
            primary: false,
            shrinkWrap: isCompact,
            itemCount: state.atendimentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildAtendimentoCard(
              theme,
              state.atendimentos[index],
              state.dominios.statusAtendimentoTecnico,
            ),
          );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.13)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sectionHeader(
              theme,
              title: 'Atendimentos criados',
              subtitle: 'Lista gravada no novo endpoint de atendimento técnico.',
              icon: Icons.fact_check_outlined,
            ),
            const SizedBox(height: 14),
            if (isCompact)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: list,
              )
            else
              Expanded(child: list),
          ],
        ),
      ),
    );
  }

  Widget _buildAtendimentoCard(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final equipamento = atendimento.equipamento;
    final titulo = equipamento == null
        ? atendimento.numero
        : '${equipamento.tipo ?? ''} ${equipamento.marca ?? ''} ${equipamento.modelo ?? ''}'
            .trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.devices_other_outlined,
                  color: theme.colorScheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo.isEmpty ? atendimento.numero : titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${atendimento.numero} • ${atendimento.nomeClienteSnapshot ?? 'Cliente não informado'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _smallChip(theme, _statusLabel(atendimento, status), Icons.flag_outlined),
              _smallChip(
                theme,
                'Validade ${_formatarData(atendimento.validadeOrcamentoEm)}',
                Icons.event_available_outlined,
              ),
              _smallChip(
                theme,
                _formatarMoeda(atendimento.valorTotalAtendimento),
                Icons.payments_outlined,
              ),
            ],
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
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
                  color: theme.colorScheme.onSurfaceVariant,
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
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null ? null : Icon(icon, color: theme.colorScheme.primary),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
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
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.12),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highlight
                    ? Colors.white.withOpacity(0.15)
                    : colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: highlight ? Colors.white : colorScheme.primary,
                size: 21,
              ),
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
                      color: highlight
                          ? Colors.white.withOpacity(0.86)
                          : colorScheme.onSurface.withOpacity(0.62),
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
                      color: highlight ? Colors.white : colorScheme.onSurface,
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
                      color: highlight
                          ? Colors.white.withOpacity(0.78)
                          : colorScheme.onSurface.withOpacity(0.56),
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
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return Material(
      color: const Color(0xFFE53935),
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
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _headerBadge(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(ThemeData theme, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _smallChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyInline(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.30)),
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

class _AtendimentoTecnicoViewState {
  const _AtendimentoTecnicoViewState({
    required this.dominios,
    required this.atendimentos,
    required this.clientes,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
  final List<ClienteUsuario> clientes;
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

  AtendimentoTecnicoItemInput toInput() {
    final produto = tipoCodigo == 'PRODUCT';
    return AtendimentoTecnicoItemInput(
      tipoItemId: produto ? 10 : 20,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      movimentaEstoque: produto,
    );
  }
}
