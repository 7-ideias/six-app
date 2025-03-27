import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../design_system/components/mobile/mobile_gereneral.dart';
import '../../providers/BaseProviderParaListas.dart';

class ProdutolistMobileScreen extends MobileGeneralScreen {
  ProdutolistMobileScreen({super.key})
    : super(body: ProdutoListaBody(), textoDaAppBar: 'Lista de Produtos x');
}

class ProdutoListaBody extends StatefulWidget {
  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];
  String termoBusca = '';
  String ordenacao = 'nome';
  TextEditingController _controllerBusca = TextEditingController();
  final List<String> produtos = List.generate(
    20,
    (index) => 'Produto ${index + 1}',
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      retornarProdutosList(context);
    });
  }

  void aplicarFiltroOrdenacao() {
    List<ProdutoModel> resultado = [...todosProdutos];

    // Filtro por nome a partir da 3ª letra
    if (termoBusca.length >= 1) {
      resultado =
          resultado
              .where(
                (p) => p.nomeProduto.toLowerCase().contains(
                  termoBusca.toLowerCase(),
                ),
              )
              .toList();
    }

    // Ordenação
    if (ordenacao == 'nome') {
      resultado.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
    } else if (ordenacao == 'preco') {
      resultado.sort((a, b) => a.precoVenda.compareTo(b.precoVenda));
    }

    setState(() {
      produtosFiltrados = resultado;
    });
  }

  void retornarProdutosList(BuildContext context) {
    final provider = Provider.of<BaseProviderParaListas<ProdutoModel>>(
      context,
      listen: false,
    );
    provider
        .carregar(
          headers: {
            'Content-Type': 'application/json',
            'idUsuario': '2ea5e611cab0439a917229e44e9301a8',
            'idColaborador': '2ea5e611cab0439a917229e44e9301a8',
          },
        )
        .then((_) {
          atualizarListaComProvider(provider.items);
        });
  }

  void atualizarListaComProvider(List<ProdutoModel> items) {
    setState(() {
      todosProdutos = items;
      aplicarFiltroOrdenacao();
    });
  }

  @override
  Widget build(BuildContext context) {
    final temaDaAplicacao = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: todosProdutos.length,
      itemBuilder: (context, index) {
        final produto = todosProdutos[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
              backgroundColor: Colors.blue.shade200,
              foregroundColor: Colors.white,
            ),
            title: Text(
              'produto',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Descrição do produto'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // ação ao clicar no item
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Clicou em $produto')));
            },
          ),
        );
      },
    );
  }
}
