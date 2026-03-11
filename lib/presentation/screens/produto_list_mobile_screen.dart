import 'package:appplanilha/core/enums/tipo_cadastro_enum.dart';
import 'package:appplanilha/core/utils/produto_helper.dart';
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
  String _tipoProdutoOuServico = 'PRODUTO';
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
      ProdutoHelper.retornarProdutosList(context, onSucesso: atualizarListaComProvider);
    });
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

  void atualizarListaComProvider(List<ProdutoModel> listaDeProdutos) {
    todosProdutos = listaDeProdutos;
    aplicarFiltroOrdenacao();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<ProdutosListProvider<ProdutoModel>>(
          builder: (context, provider, _) {
            final response = provider.fullResponse;
            if (response is! ProdutoResponseModel) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Itens TT', response.itensTotaisNoEstoque.toString()),
                  _buildSummaryItem('Sem Estoque', response.qtSemEstoque.toString()),
                  _buildSummaryItem('Valor', 'R\$ ${response.vlEstoqueEmGrana.toStringAsFixed(2)}'),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ProdutoHelper.retornarProdutosList(context, onSucesso: atualizarListaComProvider);
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
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.blue)),
      ],
    );
  }
}
