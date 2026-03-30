import 'package:appplanilha/core/utils/produto_helper.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/foundation.dart';
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
  final TextEditingController _controllerBusca = TextEditingController();

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';

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
    super.dispose();
  }

  Future<void> _recarregar() async {
    try {
      _logInfo(
        'Recarregando produtos. tipoSelecionado=$tipoSelecionado ordenacao=$ordenacao termoBusca="$termoBusca"',
      );

      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: tipoSelecionado,
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
      if (items.isNotEmpty) {
        final primeiro = items.first;
        _logInfo(
          'Primeiro produto: nome=${primeiro.nomeProduto}, codigo=${primeiro.codigoDeBarras}, preco=${primeiro.precoVenda}',
        );
      }

      if (!mounted) return;

      setState(() {
        todosProdutos = items;
        _aplicarFiltroOrdenacaoSemSetState();
      });

      _logInfo(
        'Após atualizarListaComProvider: todosProdutos=${todosProdutos.length}, produtosFiltrados=${produtosFiltrados.length}',
      );
    } catch (error, stackTrace) {
      _logError('Erro em atualizarListaComProvider', error, stackTrace);
    }
  }

  void aplicarFiltroOrdenacao() {
    try {
      setState(_aplicarFiltroOrdenacaoSemSetState);
      _logInfo(
        'Filtro aplicado: termo="$termoBusca", ordenacao=$ordenacao, tipo=$tipoSelecionado, resultado=${produtosFiltrados.length}',
      );
    } catch (error, stackTrace) {
      _logError('Erro ao aplicar filtro e ordenação', error, stackTrace);
    }
  }

  void _aplicarFiltroOrdenacaoSemSetState() {
    final listaBase = ProdutoHelper.filtrarEOrdenarProdutos(
      produtos: todosProdutos,
      termoBusca: termoBusca,
      ordenacao: ordenacao,
    );

    produtosFiltrados = listaBase
        .where((produto) => _matchesTipoSelecionado(produto, tipoSelecionado))
        .toList();
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    try {
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
      return tipo == 'PRODUTO';
    }
  }

  void _selecionarProduto(ProdutoModel produto) {
    try {
      _logInfo(
        'Produto clicado. isSelecao=${widget.isSelecao} nome=${produto.nomeProduto} codigo=${produto.codigoDeBarras} preco=${produto.precoVenda}',
      );

      if (widget.isSelecao) {
        _logInfo('Fechando subpainel e retornando produto via Navigator.pop');
        Navigator.pop(context, produto);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clicou em ${produto.nomeProduto}')),
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

      final itensDaLista =
      produtosFiltrados.isNotEmpty ||
          termoBusca.isNotEmpty ||
          todosProdutos.isNotEmpty
          ? produtosFiltrados
          : provider.listaDeProdutos;

      _logInfo(
        'Build: provider.isLoading=${provider.isLoading}, provider.listaDeProdutos=${provider.listaDeProdutos.length}, todosProdutos=${todosProdutos.length}, produtosFiltrados=${produtosFiltrados.length}, itensDaLista=${itensDaLista.length}',
      );

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllerBusca,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: termoBusca.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          try {
                            _controllerBusca.clear();
                            termoBusca = '';
                            aplicarFiltroOrdenacao();
                          } catch (error, stackTrace) {
                            _logError(
                              'Erro ao limpar busca',
                              error,
                              stackTrace,
                            );
                          }
                        },
                      )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      try {
                        termoBusca = value;
                        aplicarFiltroOrdenacao();
                      } catch (error, stackTrace) {
                        _logError(
                          'Erro no onChanged da busca',
                          error,
                          stackTrace,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: ordenacao,
                  items: const [
                    DropdownMenuItem(
                      value: 'nome',
                      child: Text('Ordenar por nome'),
                    ),
                    DropdownMenuItem(
                      value: 'preco',
                      child: Text('Ordenar por preço'),
                    ),
                  ],
                  onChanged: (value) {
                    try {
                      if (value != null) {
                        ordenacao = value;
                        aplicarFiltroOrdenacao();
                      }
                    } catch (error, stackTrace) {
                      _logError(
                        'Erro ao trocar ordenação',
                        error,
                        stackTrace,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : itensDaLista.isEmpty
                ? const Center(
              child: Text('Nenhum produto encontrado.'),
            )
                : Scrollbar(
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(8),
              scrollbarOrientation: ScrollbarOrientation.right,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: itensDaLista.length,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_list_numbered,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${itensDaLista.length} itens encontrados',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: _recarregar,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (error, stackTrace) {
      _logError('Erro geral no build do subpainel', error, stackTrace);
      return const Center(
        child: Text('Erro ao montar a lista de produtos. Veja os logs.'),
      );
    }
  }

  Widget _buildProdutoCard(ProdutoModel produto) {
    try {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selecionarProduto(produto),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.shopping_cart, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nomeProduto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Preço: R\$ ${produto.precoVenda.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (widget.isSelecao)
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: () => _selecionarProduto(produto),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Adicionar'),
                    ),
                  )
                else
                  Text(
                    'R\$ ${produto.precoVenda.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
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
}