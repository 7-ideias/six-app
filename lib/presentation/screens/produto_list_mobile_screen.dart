import 'package:appplanilha/core/enums/tipo_cadastro_enum.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../design_system/components/mobile/mobile_gereneral.dart';
import '../../providers/produtos_list_provider.dart';

class ProdutolistMobileScreen extends MobileGeneralScreen {
  ProdutolistMobileScreen({super.key})
      : super(body: ProdutoListaBody(),
      textoDaAppBar: 'Lista de Produtos',
      tipoCadastroEnum: TipoCadastroEnum.PRODUTOS_E_OU_SERVICOS);
}

class ProdutoListaBody extends StatefulWidget {
  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];
  String termoBusca = '';
  String _tipoProdutoOuServico = 'SERVICO';
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
    final provider = Provider.of<ProdutosListProvider<ProdutoModel>>(
      context,
      listen: false,
    );
    provider
        .carregar(
          headers: {
            'Content-Type': 'application/json',
            'idUsuario': '2ea5e611cab0439a917229e44e9301a8',
            'idColaborador': '2ea5e611cab0439a917229e44e9301a8',
            'produtosAtivos': 'true',
            'tipo': _tipoProdutoOuServico
          },
        )
        .then((_) {
      atualizarListaComProvider(provider.listaDeProdutos);
        });
  }

  void atualizarListaComProvider(List<ProdutoModel> listaDeProdutos) {
    setState(() {
      todosProdutos = listaDeProdutos;
      aplicarFiltroOrdenacao();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        retornarProdutosList(context);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: todosProdutos.length,
        itemBuilder: (context, index) {
          final produto = todosProdutos[index];
          final ativo = produto.ativo == true;
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
                produto.codigoDeBarras + produto.nomeProduto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Preço: R\$ ${produto.precoVenda.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black54),
              ),
              trailing: ativo
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
              onTap: () {
                // ação ao clicar no item
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Clicou em $produto')));
              },
            ),
          );
        },
      ),
    );
  }
}
