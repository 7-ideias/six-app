import 'package:appplanilha/core/enums/tipo_cadastro_enum.dart';
import 'package:appplanilha/data/models/desconto_model.dart';
import 'package:appplanilha/design_system/components/mobile/mobile_gereneral.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/produtos_list_provider.dart';

class TabelaDePrecosMobileScreen extends MobileGeneralScreen {
  TabelaDePrecosMobileScreen({super.key})
    : super(
        body: CadastroListaBody(),
        textoDaAppBar: 'Tabela de Preços',
        tipoCadastroEnum: TipoCadastroEnum.TABELA_DE_PRECOS,
      );
}

class CadastroListaBody extends StatefulWidget {
  @override
  State<CadastroListaBody> createState() => _CadastroListaBodyState();
}

class _CadastroListaBodyState extends State<CadastroListaBody> {
  List<DescontoModel> todosOsDescontos = [];
  List<DescontoModel> descontosFiltrados = [];
  String termoBusca = '';
  String ordenacao = 'nome';
  TextEditingController _controllerBusca = TextEditingController();
  final List<String> descontos = List.generate(
    20,
    (index) => 'Produto ${index + 1}',
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      retornarDescontosList(context);
    });
  }

  void aplicarFiltroOrdenacao() {
    List<DescontoModel> resultado = [...todosOsDescontos];

    // Filtro por nome a partir da 3ª letra
    if (termoBusca.length >= 1) {
      resultado =
          resultado
              .where(
                (p) => p.nomeDoDesconto.toLowerCase().contains(
                  termoBusca.toLowerCase(),
                ),
              )
              .toList();
    }

    // Ordenação
    if (ordenacao == 'nomeDoDesconto') {
      resultado.sort((a, b) => a.nomeDoDesconto.compareTo(b.nomeDoDesconto));
    } else if (ordenacao == 'valor') {
      resultado.sort((a, b) => a.valor.compareTo(b.valor));
    }

    setState(() {
      descontosFiltrados = resultado;
    });
  }

  void retornarDescontosList(BuildContext context) {
    final provider = Provider.of<ProdutosListProvider<DescontoModel>>(
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
          atualizarListaComProvider(provider.listaDeProdutos);
        });
  }

  void atualizarListaComProvider(List<DescontoModel> items) {
    setState(() {
      todosOsDescontos = items;
      aplicarFiltroOrdenacao();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: todosOsDescontos.length,
      itemBuilder: (context, index) {
        final produto = todosOsDescontos[index];
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
