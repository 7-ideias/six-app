import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:appplanilha/core/services/produto_service.dart';
import 'package:appplanilha/core/utils/produto_helper.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class SubPainelWebProdutoLista extends SubPainelWebGeneral {
  SubPainelWebProdutoLista({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
  }) : super(
    body: ProdutoListaBody(
      isSelecao: isSelecao,
      modoEdicao: modoEdicao,
    ),
    textoDaAppBar: 'Lista de Produtos',
  );

  final bool isSelecao;
  final bool modoEdicao;
}

class ProdutoListaBody extends StatefulWidget {
  const ProdutoListaBody({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
  });

  final bool isSelecao;
  final bool modoEdicao;

  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  final TextEditingController _controllerBusca = TextEditingController();
  final ProdutoService _produtoService = ProdutoService();

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';
  bool _isGerandoRelatorio = false;

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
        if (widget.modoEdicao) {
          _abrirCadastroParaEdicao(produto);
          return;
        }

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

  void _abrirCadastroParaEdicao(ProdutoModel produto) {
    showSubPainelCadastroProduto(
      context,
      'Editar Produto',
      produtoParaEdicao: produto,
      modoEdicao: true,
    );
  }

  Future<void> _imprimirRelatorioProdutos() async {
    if (_isGerandoRelatorio) {
      return;
    }

    setState(() {
      _isGerandoRelatorio = true;
    });

    try {
      final RelatorioProdutoPdfResponse response =
          await _produtoService.gerarRelatorioListagemPdf();

      if (response.arquivoBase64.trim().isEmpty) {
        throw Exception('O backend retornou o PDF vazio.');
      }

      final Uint8List bytes = base64Decode(response.arquivoBase64);
      final html.Blob blob = html.Blob(<dynamic>[bytes], response.mimeType);
      final String url = html.Url.createObjectUrlFromBlob(blob);
      final html.AnchorElement anchor = html.AnchorElement(href: url)
        ..download = response.nomeArquivo
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Relatório salvo: ${response.nomeArquivo}')),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao imprimir relatório de produtos', error, stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível gerar o PDF: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGerandoRelatorio = false;
        });
      }
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
          if (widget.modoEdicao && !widget.isSelecao)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo edição ativo: clique em um produto para abrir o cadastro em edição.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
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
                Wrap(
                  spacing: 12,
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: _recarregar,
                      backgroundColor: Colors.blueAccent,
                      child: const Icon(Icons.refresh),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isGerandoRelatorio
                          ? null
                          : _imprimirRelatorioProdutos,
                      icon: _isGerandoRelatorio
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_outlined),
                      label: Text(
                        _isGerandoRelatorio ? 'Gerando PDF...' : 'Imprimir',
                      ),
                    ),
                  ],
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
                else if (widget.modoEdicao)
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirCadastroParaEdicao(produto),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
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
