import 'package:appplanilha/core/utils/produto_helper.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class SubPainelWebProdutoLista extends SubPainelWebGeneral {
  SubPainelWebProdutoLista({
    super.key,
    this.isSelecao = false,
  }) : super(
          body: ProdutoListaBody(isSelecao: isSelecao),
          textoDaAppBar: 'Lista de Produtos',
        );

  final bool isSelecao;
}

class ProdutoListaBody extends StatefulWidget {
  const ProdutoListaBody({
    super.key,
    this.isSelecao = false,
  });

  final bool isSelecao;

  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  static const Color _pageBackground = Color(0xfff4f7fb);
  static const Color _cardBorder = Color(0xffdde6f0);
  static const Color _mutedText = Color(0xff5b6475);
  static const Color _strongText = Color(0xff14213d);
  static const Color _primaryBlue = Color(0xff1d4ed8);
  static const Color _softBlue = Color(0xffe8f0fe);

  final TextEditingController _controllerBusca = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProdutoModel> todosProdutos = <ProdutoModel>[];
  List<ProdutoModel> produtosFiltrados = <ProdutoModel>[];

  String termoBusca = '';
  String tipoSelecionado = 'TODOS';
  String ordenacao = 'nomeAsc';
  bool somenteAtivos = true;

  void _logInfo(String message) {
    debugPrint('[SubPainelWebProdutoLista][INFO] $message');
  }

  void _logError(
    String errorContext,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[SubPainelWebProdutoLista][ERROR] $errorContext');
    debugPrint('[SubPainelWebProdutoLista][ERROR] $error');
    debugPrint('[SubPainelWebProdutoLista][STACK] $stackTrace');

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'produto_lista_sub_painel_web',
        context: ErrorDescription(errorContext),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _logInfo('Widget iniciado. isSelecao=${widget.isSelecao}');
    Future.microtask(_recarregar);
  }

  @override
  void dispose() {
    _controllerBusca.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    try {
      _logInfo(
        'Recarregando produtos. tipoSelecionado=$tipoSelecionado ordenacao=$ordenacao termoBusca="$termoBusca"',
      );

      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: tipoSelecionado == 'TODOS' ? 'PRODUTO' : tipoSelecionado,
        onSucesso: atualizarListaComProvider,
      );
    } catch (error, stackTrace) {
      _logError('Erro ao recarregar produtos', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao recarregar produtos. Veja os logs.'),
          ),
        );
      }
    }
  }

  void atualizarListaComProvider(List<ProdutoModel> items) {
    try {
      _logInfo('Produtos recebidos do helper/provider: ${items.length}');

      if (!mounted) return;

      setState(() {
        todosProdutos = items;
        _aplicarFiltroOrdenacaoSemSetState();
      });
    } catch (error, stackTrace) {
      _logError('Erro em atualizarListaComProvider', error, stackTrace);
    }
  }

  void aplicarFiltroOrdenacao() {
    try {
      setState(_aplicarFiltroOrdenacaoSemSetState);
      _logInfo(
        'Filtro aplicado: termo="$termoBusca", ordenacao=$ordenacao, tipo=$tipoSelecionado, somenteAtivos=$somenteAtivos, resultado=${produtosFiltrados.length}',
      );
    } catch (error, stackTrace) {
      _logError('Erro ao aplicar filtro e ordenação', error, stackTrace);
    }
  }

  void _aplicarFiltroOrdenacaoSemSetState() {
    final termo = termoBusca.trim().toLowerCase();

    produtosFiltrados = todosProdutos.where((produto) {
      final nome = produto.nomeProduto.toLowerCase();
      final codigo = produto.codigoDeBarras.toLowerCase();
      final tipoOk = _matchesTipoSelecionado(produto, tipoSelecionado);
      final buscaOk =
          termo.isEmpty || nome.contains(termo) || codigo.contains(termo);
      final ativoOk = !somenteAtivos || produto.ativo;

      return tipoOk && buscaOk && ativoOk;
    }).toList();

    switch (ordenacao) {
      case 'precoAsc':
        produtosFiltrados.sort((a, b) => a.precoVenda.compareTo(b.precoVenda));
        break;
      case 'precoDesc':
        produtosFiltrados.sort((a, b) => b.precoVenda.compareTo(a.precoVenda));
        break;
      case 'nomeDesc':
        produtosFiltrados.sort(
          (a, b) => b.nomeProduto.toLowerCase().compareTo(
                a.nomeProduto.toLowerCase(),
              ),
        );
        break;
      case 'nomeAsc':
      default:
        produtosFiltrados.sort(
          (a, b) => a.nomeProduto.toLowerCase().compareTo(
                b.nomeProduto.toLowerCase(),
              ),
        );
        break;
    }
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    try {
      if (tipo == 'TODOS') return true;

      final dynamic p = produto;

      final dynamic valor =
          p.tipoProduto ??
          p.tipoPoduto ??
          p.tipoCadastro ??
          p.tipo ??
          p.categoria;

      if (valor == null) {
        return tipo == 'PRODUTO';
      }

      return valor.toString().toUpperCase() == tipo.toUpperCase();
    } catch (error, stackTrace) {
      _logError('Erro ao validar tipo selecionado', error, stackTrace);
      return tipo == 'TODOS' || tipo == 'PRODUTO';
    }
  }

  void _selecionarProduto(ProdutoModel produto) {
    try {
      _logInfo(
        'Produto clicado. isSelecao=${widget.isSelecao} nome=${produto.nomeProduto} codigo=${produto.codigoDeBarras} preco=${produto.precoVenda}',
      );

      if (widget.isSelecao) {
        Navigator.pop(context, produto);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produto selecionado: ${produto.nomeProduto}')),
        );
      }
    } catch (error, stackTrace) {
      _logError('Erro ao selecionar produto', error, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar produto. Veja os logs.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final provider = context.watch<ProdutosListProvider<ProdutoModel>>();

      final itensDaLista = todosProdutos.isNotEmpty
          ? produtosFiltrados
          : provider.listaDeProdutos;

      final totalEncontrado = itensDaLista.length;

      return Container(
        color: _pageBackground,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, totalEncontrado),
              const SizedBox(height: 18),
              _buildPainelFiltros(context, totalEncontrado),
              const SizedBox(height: 18),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : itensDaLista.isEmpty
                        ? _buildEmptyState(context)
                        : _buildListaProdutos(context, itensDaLista),
              ),
            ],
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logError('Erro geral no build do subpainel', error, stackTrace);
      return const Center(
        child: Text('Erro ao montar a lista de produtos. Veja os logs.'),
      );
    }
  }

  Widget _buildHeader(BuildContext context, int totalEncontrado) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xff1d4ed8), Color(0xff2563eb)],
              ),
            ),
            child: Icon(
              widget.isSelecao
                  ? Icons.playlist_add_circle_rounded
                  : Icons.inventory_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isSelecao
                      ? 'Selecionar produto para a venda'
                      : 'Catálogo de produtos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _strongText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isSelecao
                      ? 'Busque rapidamente, filtre por tipo e adicione o item certo ao atendimento.'
                      : 'Visualize o catálogo com busca inteligente, filtros e ordenação no mesmo padrão visual das demais telas.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _buildTopInfoChip(
            icon: Icons.inventory_2_outlined,
            label: 'Itens exibidos',
            value: '$totalEncontrado',
          ),
          _buildTopInfoChip(
            icon: Icons.tune_rounded,
            label: 'Ordenação',
            value: _labelOrdenacao(ordenacao),
          ),
          _buildTopInfoChip(
            icon: Icons.category_outlined,
            label: 'Tipo',
            value: _labelTipoSelecionado(tipoSelecionado),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelFiltros(BuildContext context, int totalEncontrado) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Busca e filtros',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: _strongText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Refine a lista por nome, código, tipo e ordenação para localizar o produto com mais rapidez.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              SizedBox(
                width: 420,
                child: _buildFieldBox(
                  label: 'Buscar por nome ou código',
                  child: TextField(
                    controller: _controllerBusca,
                    decoration: _inputDecoration(
                      hint: 'Ex.: bateria, película, 789...',
                      prefixIcon: Icons.search_rounded,
                      suffix: termoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controllerBusca.clear();
                                termoBusca = '';
                                aplicarFiltroOrdenacao();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      termoBusca = value;
                      aplicarFiltroOrdenacao();
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: _buildFieldBox(
                  label: 'Tipo',
                  child: DropdownButtonFormField<String>(
                    value: tipoSelecionado,
                    decoration: _inputDecoration(
                      hint: 'Selecione',
                      prefixIcon: Icons.widgets_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'TODOS',
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: 'PRODUTO',
                        child: Text('Produtos'),
                      ),
                      DropdownMenuItem(
                        value: 'SERVICO',
                        child: Text('Serviços'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      tipoSelecionado = value;
                      aplicarFiltroOrdenacao();
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildFieldBox(
                  label: 'Ordenar por',
                  child: DropdownButtonFormField<String>(
                    value: ordenacao,
                    decoration: _inputDecoration(
                      hint: 'Selecione',
                      prefixIcon: Icons.sort_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'nomeAsc',
                        child: Text('Nome A → Z'),
                      ),
                      DropdownMenuItem(
                        value: 'nomeDesc',
                        child: Text('Nome Z → A'),
                      ),
                      DropdownMenuItem(
                        value: 'precoAsc',
                        child: Text('Menor preço'),
                      ),
                      DropdownMenuItem(
                        value: 'precoDesc',
                        child: Text('Maior preço'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      ordenacao = value;
                      aplicarFiltroOrdenacao();
                    },
                  ),
                ),
              ),
              Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fbff),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffdbe4ef)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contexto adicional',
                      style: TextStyle(
                        color: _strongText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: somenteAtivos,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mostrar somente ativos',
                        style: TextStyle(fontSize: 13.5),
                      ),
                      onChanged: (value) {
                        somenteAtivos = value ?? true;
                        aplicarFiltroOrdenacao();
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isSelecao
                          ? 'Ideal para exibir somente itens disponíveis para atendimento.'
                          : 'Use para reduzir ruído visual e focar nos itens válidos para operação.',
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12.8,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xffeef5ff),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalEncontrado item(ns) encontrados',
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar lista'),
                style: _secondaryButtonStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaProdutos(
    BuildContext context,
    List<ProdutoModel> itensDaLista,
  ) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildCabecalhoLista(),
          const Divider(height: 1, color: _cardBorder),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(8),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(18),
                itemCount: itensDaLista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  try {
                    final produto = itensDaLista[index];
                    return _buildProdutoCard(produto);
                  } catch (error, stackTrace) {
                    _logError(
                      'Erro ao renderizar item da lista no subpainel',
                      error,
                      stackTrace,
                    );
                    return const Card(
                      child: ListTile(
                        title: Text('Erro ao renderizar produto'),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoLista() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Row(
        children: const [
          Expanded(
            flex: 6,
            child: Text(
              'Produto',
              style: TextStyle(
                color: Color(0xff475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Tipo',
              style: TextStyle(
                color: Color(0xff475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Preço',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Color(0xff475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 132),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Nenhum produto encontrado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _strongText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar a busca, limpar filtros ou atualizar a lista para carregar novamente os itens.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _mutedText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _controllerBusca.clear();
                      termoBusca = '';
                      tipoSelecionado = 'TODOS';
                      ordenacao = 'nomeAsc';
                      somenteAtivos = true;
                      aplicarFiltroOrdenacao();
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded),
                    label: const Text('Limpar filtros'),
                    style: _secondaryButtonStyle(),
                  ),
                  ElevatedButton.icon(
                    onPressed: _recarregar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Atualizar lista'),
                    style: _primaryButtonStyle(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoCard(ProdutoModel produto) {
    try {
      final tipo = _resolverTipoDoProduto(produto);
      final ativo = produto.ativo;

      return InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _selecionarProduto(produto),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffdce5f0)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xffe8f0fe),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  tipo == 'SERVICO'
                      ? Icons.build_circle_outlined
                      : Icons.inventory_2_outlined,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          produto.nomeProduto,
                          style: const TextStyle(
                            color: _strongText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _buildStatusPill(
                          ativo ? 'Ativo' : 'Inativo',
                          ativo
                              ? const Color(0xff15803d)
                              : const Color(0xffb91c1c),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _buildInlineInfo(
                          Icons.qr_code_rounded,
                          produto.codigoDeBarras.isEmpty
                              ? 'Sem código'
                              : produto.codigoDeBarras,
                        ),
                        _buildInlineInfo(
                          Icons.category_outlined,
                          _labelTipoSelecionado(tipo),
                        ),
                        _buildInlineInfo(
                          Icons.sell_outlined,
                          produto.modeloProduto,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusPill(
                    _labelTipoSelecionado(tipo),
                    tipo == 'SERVICO'
                        ? const Color(0xff7c3aed)
                        : _primaryBlue,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatCurrency(produto.precoVenda),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xff0f172a),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 114,
                child: widget.isSelecao
                    ? ElevatedButton.icon(
                        onPressed: () => _selecionarProduto(produto),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Adicionar'),
                        style: _primaryButtonStyle().copyWith(
                          padding: const MaterialStatePropertyAll<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => _selecionarProduto(produto),
                        style: _secondaryButtonStyle(),
                        child: const Text('Detalhes'),
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao montar card de produto', error, stackTrace);
      return const Card(
        child: ListTile(
          title: Text('Erro ao montar card do produto'),
        ),
      );
    }
  }

  Widget _buildTopInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd9e4f2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _primaryBlue),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff7a8394),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff18243d),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldBox({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff4b5563),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String? hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffdbe4ef)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInlineInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xff64748b)),
        const SizedBox(width: 6),
        Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff64748b),
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.04),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      elevation: 0,
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xff1e293b),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      side: const BorderSide(color: Color(0xffd3deea)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  String _resolverTipoDoProduto(ProdutoModel produto) {
    try {
      final dynamic p = produto;
      final dynamic valor =
          p.tipoProduto ??
          p.tipoPoduto ??
          p.tipoCadastro ??
          p.tipo ??
          p.categoria;

      return valor?.toString().toUpperCase() ?? 'PRODUTO';
    } catch (_) {
      return 'PRODUTO';
    }
  }

  String _labelTipoSelecionado(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'SERVICO':
        return 'Serviço';
      case 'PRODUTO':
        return 'Produto';
      case 'TODOS':
      default:
        return 'Todos';
    }
  }

  String _labelOrdenacao(String valor) {
    switch (valor) {
      case 'precoAsc':
        return 'Menor preço';
      case 'precoDesc':
        return 'Maior preço';
      case 'nomeDesc':
        return 'Nome Z → A';
      case 'nomeAsc':
      default:
        return 'Nome A → Z';
    }
  }

  String _formatCurrency(double value) {
    final negative = value < 0;
    final absolute = value.abs();
    final fixed = absolute.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      final position = integer.length - i;
      buffer.write(integer[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${negative ? '-' : ''}R\$ ${buffer.toString()},$decimal';
  }
}
