import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';

import 'design_system/themes/zebra_list_item.dart';
import 'top_navigation_bar.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebState();
}

class _PDVWebState extends State<PDVWeb> {
  bool _mostrarDashboardLateral = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationBar(
        items: [
          TopNavItemData(
            title: 'Início',
            subItems: const [
              'Preferências do Sistema',
              'Painel Administrativo',
            ],
            onSelect: (value) {
              if (value == 'Painel Administrativo') {
                showSubPainelConfiguracoes(context, 'Configurações');
              }
            },
          ),
          const TopNavItemData(
            title: 'Permitir',
            subItems: [
              'Gerenciar Permissões',
              'Alterar Configurações',
            ],
          ),
          TopNavItemData(
            title: 'Cadastros',
            subItems: const [
              'Clientes',
              'Produtos',
              'Fornecedores',
              'Produtos List',
            ],
            onSelect: (value) {
              if (value == 'Produtos') {
                showSubPainelCadastroProduto(
                  context,
                  'Cadastro de Produtos',
                );
              }

              if (value == 'Produtos List') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: SubPainelWebProdutoLista(),
                      ),
                    );
                  },
                );
              }
            },
          ),
          const TopNavItemData(
            title: 'Relatórios',
            subItems: [
              'Vendas',
              'Estoque',
              'Financeiro',
            ],
          ),
          const TopNavItemData(
            title: 'Executar',
            subItems: [
              'Processar Pagamentos',
              'Fechar Caixa',
            ],
          ),
          const TopNavItemData(
            title: 'Configurações',
            subItems: [
              'Sistema',
              'Usuários',
            ],
          ),
          const TopNavItemData(
            title: 'Automações',
            subItems: [
              'Tarefas Agendadas',
            ],
          ),
          const TopNavItemData(
            title: 'Ajuda',
            subItems: [
              'Suporte',
              'Sobre',
            ],
          ),
        ],
        onNotificationPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mostrarDashboardLateral) ...[
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Resumo',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ocultar painel',
                          onPressed: () {
                            setState(() {
                              _mostrarDashboardLateral = false;
                            });
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildDashboardCard(
                            data[index]['title']!,
                            data[index]['count']!,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, right: 12),
                child: Tooltip(
                  message: 'Mostrar painel',
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _mostrarDashboardLateral = true;
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Resumo'),
                  ),
                ),
              ),
            ],
            Expanded(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 12,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person_search),
                                  label: const Text("Buscar Cliente"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Buscar Cliente'),
                                          content: const Text(
                                            'Aqui você pode implementar uma busca por nome, CPF, telefone etc.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Fechar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person_search),
                                  label: const Text("Vendedor"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                          const Text('Atribuir vendedor'),
                                          content: const Text(
                                            'Aqui você pode implementar uma busca por nome, CPF, telefone etc.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Fechar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.point_of_sale),
                                  label: const Text("VENDA"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Venda'),
                                          content: const Text(
                                            'Aqui você pode implementar as ações da venda.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Fechar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.construction),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "F R E N T E   D E   C A I X A",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: "Código de Barras",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {},
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: 'Buscar produto',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: SizedBox(
                                      width:
                                      MediaQuery.of(context).size.width *
                                          0.8,
                                      height:
                                      MediaQuery.of(context).size.height *
                                          0.8,
                                      child: SubPainelWebProdutoLista(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: "Itens Total",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Cliente Identificado",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 20,
                          itemBuilder: (context, index) {
                            return ZebraListItem(
                              index: index,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    size: 24,
                                  ),
                                ),
                                title:
                                Text("#$index - Produto Exemplo $index"),
                                subtitle: const Text("Qtd: 2 • R\$ 50,00"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double screenWidth = constraints.maxWidth;
                          final double fontSize = screenWidth > 600 ? 40 : 20;
                          final double buttonFontSize =
                          screenWidth > 600 ? 24 : 16;
                          final EdgeInsets buttonPadding = screenWidth > 600
                              ? const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          )
                              : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "Total: R\$ 250,00",
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    icon: Icon(
                                      Icons.check,
                                      size: buttonFontSize,
                                    ),
                                    label: Text(
                                      "Pausar",
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: buttonPadding,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Pausar'),
                                            content: const Text(
                                              'A ideia é receber depois e deixar a venda aberta.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Fechar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  OutlinedButton.icon(
                                    icon: Icon(
                                      Icons.check,
                                      size: buttonFontSize,
                                    ),
                                    label: Text(
                                      "Finalizar",
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: buttonPadding,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Finalizar'),
                                            content: const Text(
                                              'A ideia é confirmar o tipo de venda e propor alguma coisa.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Fechar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  OutlinedButton.icon(
                                    icon: Icon(
                                      Icons.cancel,
                                      size: buttonFontSize,
                                    ),
                                    label: Text(
                                      "Cancelar",
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: buttonPadding,
                                      side: const BorderSide(width: 2),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Cancelar'),
                                            content:
                                            const Text('Não implementado'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Fechar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, String>> data = [
    {'title': 'Vendas Abertas', 'count': '2'},
    {'title': 'Ordens Abertas', 'count': '2'},
    {'title': 'OTs em revisão', 'count': '33'},
    {'title': 'OTs em processo', 'count': '27'},
    {'title': 'OTs finalizadas', 'count': '94'},
    {'title': 'OTs atrasadas', 'count': '10'},
  ];
}