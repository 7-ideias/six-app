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
  final ClienteUsuarioApiClient _clienteApiClient = HttpClienteUsuarioApiClient();

  final TextEditingController _buscaClienteController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _tipoEquipamentoController = TextEditingController(
    text: 'SMARTPHONE',
  );
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _acessoriosController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();

  final List<_AtendimentoItemDraft> _itens = <_AtendimentoItemDraft>[];

  late Future<_AtendimentoTecnicoViewState> _future;
  String? _clienteSelecionadoId;
  bool _salvando = false;

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

    final dominios = results[0] as AtendimentoTecnicoDominiosBaseModel;
    final atendimentos = results[1] as List<AtendimentoTecnicoModel>;
    final clientesResponse = results[2] as ClienteUsuarioListResponse;

    return _AtendimentoTecnicoViewState(
      dominios: dominios,
      atendimentos: atendimentos,
      clientes: clientesResponse.clientes,
    );
  }

  void _onBuscaClienteChanged() {
    if (mounted) setState(() {});
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  void _limparFormulario() {
    _clienteSelecionadoId = null;
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
  }

  String _statusLabel(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    for (final opcao in status) {
      if (opcao.id == atendimento.statusId &&
          opcao.nomePadraoPtBr.trim().isNotEmpty) {
        return opcao.nomePadraoPtBr;
      }
    }
    return atendimento.statusCodigo;
  }

  ClienteUsuario? _clienteSelecionado(List<ClienteUsuario> clientes) {
    final String? id = _clienteSelecionadoId;
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

  Future<void> _abrirSelecaoItens(String tipoInicial) async {
    final dynamic result = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext dialogContext) {
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
      _adicionarProduto(result);
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

  void _adicionarProduto(ProdutoModel produto) {
    setState(() => _adicionarProdutoSemSetState(produto));
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

    final tipoCodigo = _ehServico(produto) ? 'SERVICE' : 'PRODUCT';
    _itens.add(
      _AtendimentoItemDraft(
        chave: chave,
        idSku: produto.id ?? produto.codigoDeBarras,
        descricao: produto.nomeProduto,
        tipoCodigo: tipoCodigo,
        quantidade: 1,
        valorUnitario: produto.precoVenda,
      ),
    );
  }

  void _alterarQuantidade(_AtendimentoItemDraft item, int delta) {
    setState(() {
      final index = _itens.indexWhere((elemento) => elemento.chave == item.chave);
      if (index < 0) return;
      final novaQuantidade = _itens[index].quantidade + delta;
      if (novaQuantidade <= 0) {
        _itens.removeAt(index);
        return;
      }
      _itens[index] = _itens[index].copyWith(quantidade: novaQuantidade);
    });
  }

  void _removerItem(_AtendimentoItemDraft item) {
    setState(() {
      _itens.removeWhere((elemento) => elemento.chave == item.chave);
    });
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
    return tipo == 'SERVICO' || tipo == 'SERVIÇO';
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

    setState(() => _salvando = true);
    try {
      await _service.criar(
        AtendimentoTecnicoCreateInput(
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
      _mostrarMensagem('Atendimento técnico criado com sucesso.');
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

  String _formatarMoeda(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AtendimentoTecnicoErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }

        final state = snapshot.data!;
        return Column(
          children: <Widget>[
            _buildHeader(theme, state),
            const SizedBox(height: 18),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 980;
                  final form = _buildFluxoAtendimento(theme, state);
                  final side = _buildPainelLateral(theme, state);

                  if (compact) {
                    return ListView(
                      children: <Widget>[form, const SizedBox(height: 16), side],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 6, child: form),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: side),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Padding(padding: const EdgeInsets.all(20), child: content);
    }

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
      body: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }

  Widget _buildHeader(ThemeData theme, _AtendimentoTecnicoViewState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final intro = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atendimentos técnicos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fluxo de teste com cliente cadastrado, equipamento, diagnóstico, peças, serviços e abertura do atendimento.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: <Widget>[
              _metricChip(
                theme,
                '${state.clientes.length}',
                'clientes',
                Icons.people_alt_outlined,
              ),
              _metricChip(
                theme,
                '${state.atendimentos.length}',
                'atendimentos',
                Icons.assignment_outlined,
              ),
              OutlinedButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[intro, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: intro),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFluxoAtendimento(
    ThemeData theme,
    _AtendimentoTecnicoViewState state,
  ) {
    final cliente = _clienteSelecionado(state.clientes);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          primary: false,
          shrinkWrap: true,
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
                  decoration: const InputDecoration(
                    labelText: 'Descrição interna',
                    hintText: 'Ex.: Troca de tela iPhone 11',
                  ),
                ),
                TextField(
                  controller: _tipoEquipamentoController,
                  decoration: const InputDecoration(labelText: 'Tipo de equipamento'),
                ),
                TextField(
                  controller: _marcaController,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                TextField(
                  controller: _modeloController,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                TextField(
                  controller: _numeroSerieController,
                  decoration: const InputDecoration(labelText: 'Número de série'),
                ),
                TextField(
                  controller: _imeiController,
                  decoration: const InputDecoration(labelText: 'IMEI'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _acessoriosController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Acessórios / observações de entrada',
                hintText: 'Ex.: capa, película quebrada, sem carregador...',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _defeitoController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Defeito relatado pelo cliente',
                hintText: 'Descreva o problema informado no balcão.',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _diagnosticoController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Diagnóstico técnico inicial',
                hintText: 'Opcional neste primeiro teste.',
              ),
            ),
            const SizedBox(height: 22),
            _buildItensSection(theme),
            const SizedBox(height: 22),
            _buildResumoSalvar(theme, state.clientes),
          ],
        ),
      ),
    );
  }

  Widget _buildPainelLateral(
    ThemeData theme,
    _AtendimentoTecnicoViewState state,
  ) {
    return ListView(
      primary: false,
      shrinkWrap: true,
      children: <Widget>[
        _buildClientesCadastrados(theme, state.clientes),
        const SizedBox(height: 16),
        _buildAtendimentosCriados(theme, state),
      ],
    );
  }

  Widget _buildClienteSelecionadoCard(ThemeData theme, ClienteUsuario? cliente) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.person_pin_circle_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  cliente?.nome.isNotEmpty == true
                      ? cliente!.nome
                      : 'Nenhum cliente selecionado',
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
    List<ClienteUsuario> clientes,
  ) {
    final filtrados = _clientesFiltrados(clientes);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: 'Buscar cliente',
                hintText: 'Nome, telefone, e-mail ou documento',
              ),
            ),
            const SizedBox(height: 12),
            if (filtrados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'Nenhum cliente encontrado.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cliente = filtrados[index];
                    final selected = cliente.id == _clienteSelecionadoId;
                    return Material(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.42),
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItensSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionHeader(
                  theme,
                  title: 'Itens do orçamento/serviço',
                  subtitle: 'Adicione peças/produtos e mão de obra no mesmo atendimento.',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
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
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_itens.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nenhum item adicionado. Você pode abrir o atendimento só com o diagnóstico e incluir os itens depois.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            Column(
              children: _itens.map((item) => _buildItemRow(theme, item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, _AtendimentoItemDraft item) {
    final isServico = item.tipoCodigo == 'SERVICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isServico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
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
          ),
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
          SizedBox(
            width: 94,
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

  Widget _buildResumoSalvar(ThemeData theme, List<ClienteUsuario> clientes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _metricChip(theme, _formatarMoeda(_totalProdutos), 'produtos', Icons.inventory_2_outlined),
                _metricChip(theme, _formatarMoeda(_totalServicos), 'serviços', Icons.handyman_outlined),
                _metricChip(theme, _formatarMoeda(_totalAtendimento), 'total', Icons.payments_outlined),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _salvando ? null : () => _salvarAtendimento(clientes),
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_salvando ? 'Salvando...' : 'Criar atendimento'),
          ),
        ],
      ),
    );
  }

  Widget _buildAtendimentosCriados(
    ThemeData theme,
    _AtendimentoTecnicoViewState state,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
            if (state.atendimentos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Text(
                    'Nenhum atendimento técnico ainda.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.atendimentos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildAtendimentoCard(
                      theme,
                      state.atendimentos[index],
                      state.dominios.statusAtendimentoTecnico,
                    );
                  },
                ),
              ),
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
        : '${equipamento.marca ?? ''} ${equipamento.modelo ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.devices_other_outlined, color: theme.colorScheme.primary),
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
              _smallChip(theme, _formatarMoeda(atendimento.valorTotalAtendimento), Icons.payments_outlined),
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
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
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
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ))
                .toList(),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: child,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _metricChip(ThemeData theme, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
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
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
