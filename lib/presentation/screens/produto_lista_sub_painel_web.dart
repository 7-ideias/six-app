import 'dart:async';

import 'package:appplanilha/core/utils/produto_helper.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class SubPainelWebProdutoLista extends SubPainelWebGeneral {
  SubPainelWebProdutoLista({super.key})
    : super(body: ProdutoListaBody(), textoDaAppBar: 'Lista de Produtos');
}

class ProdutoListaBody extends StatefulWidget {
  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];
  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';
  TextEditingController _controllerBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _recarregar();
    });
  }

  void _recarregar() {
    ProdutoHelper.retornarProdutosList(
      context,
      tipo: tipoSelecionado,
      onSucesso: atualizarListaComProvider,
    );
  }

  void atualizarListaComProvider(List<ProdutoModel> items) {
    todosProdutos = items;
    aplicarFiltroOrdenacao();
  }

  void aplicarFiltroOrdenacao() {
    setState(() {
      produtosFiltrados = ProdutoHelper.filtrarEOrdenarProdutos(
        produtos: todosProdutos,
        termoBusca: termoBusca,
        ordenacao: ordenacao,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
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
                        suffixIcon:
                            termoBusca.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _controllerBusca.clear();
                                    setState(() {
                                      termoBusca = '';
                                      aplicarFiltroOrdenacao();
                                    });
                                  },
                                )
                                : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          termoBusca = value;
                          aplicarFiltroOrdenacao();
                        });
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
                      if (value != null) {
                        ordenacao = value;
                        aplicarFiltroOrdenacao();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ProdutosListProvider<ProdutoModel>>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (provider.listaDeProdutos.isEmpty) {
                    return const Center(
                      child: Text('Nenhum produto encontrado.'),
                    );
                  }

                  if (todosProdutos.isEmpty) {
                    todosProdutos = provider.listaDeProdutos;
                    aplicarFiltroOrdenacao();
                  }

                  return Scrollbar(
                    thumbVisibility: true,
                    thickness: 8,
                    radius: const Radius.circular(8),
                    scrollbarOrientation: ScrollbarOrientation.right,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: produtosFiltrados.length,
                      itemBuilder: (context, index) {
                        final produto = produtosFiltrados[index];
                        return _buildProdutoCard(produto);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _recarregar,
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.refresh),
          ),
        ),
        Positioned(
          bottom: 90,
          right: 20,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(30),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                      Icons.format_list_numbered, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    '${produtosFiltrados.length} itens encontrados',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      ],
    );
  }
}

Widget _buildProdutoCard(ProdutoModel produto) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.shopping_cart, color: Colors.white),
      ),
      title: Text(
        produto.nomeProduto,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Preço: R\$ ${produto.precoVenda.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
      ),
      trailing: Text(
        'R\$ ${produto.precoVenda.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    ),
  );
}
