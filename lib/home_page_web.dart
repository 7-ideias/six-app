import 'package:appplanilha/presentation/pages/sub_painel_web_produto_lista.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';

import 'design_system/themes/zebra_list_item.dart';

class HomePageWeb extends StatefulWidget {
  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMenuItem(context, 'Início', [
                        'Preferências do Sistema',
                        'Painel Administrativo'
                      ], onSelect: (value) {
                        if (value == 'Painel Administrativo') {
                          showSubPainelConfiguracoes(context, 'Configurações');
                        }
                      }),
                      _buildMenuItem(context, 'Permitir', [
                        'Gerenciar Permissões',
                        'Alterar Configurações'
                      ]),
                      _buildMenuItem(context, 'Cadastros', [
                        'Clientes',
                        'Produtos',
                        'Fornecedores',
                        'Produtos List'
                      ], onSelect: (value) {
                        if (value == 'Produtos') {
                          showSubPainelCadastroProduto(
                              context, 'Cadastro de Produtos');
                        }
                        if (value == 'Produtos List') {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Container(
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.8,
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.8,
                                  child: SubPainelWebProdutoLista(),
                                ),
                              );
                            },
                          );
                        }
                      }),
                      _buildMenuItem(context, 'Relatórios', [
                        'Vendas',
                        'Estoque',
                        'Financeiro'
                      ]),
                      _buildMenuItem(context, 'Executar', [
                        'Processar Pagamentos',
                        'Fechar Caixa'
                      ]),
                      _buildMenuItem(context, 'Configurações', [
                        'Sistema',
                        'Usuários'
                      ]),
                      _buildMenuItem(context, 'Automações', [
                        'Tarefas Agendadas'
                      ]),
                      _buildMenuItem(context, 'Ajuda', [
                        'Suporte',
                        'Sobre'
                      ]),
                    ],
                  ),
                ],
              ),
              Row(children: [
                Icon(Icons.add_alert)
              ],)
            ],
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard à esquerda
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return _buildDashboardCard(
                            data[index]['title']!, data[index]['count']!);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Frente de Caixa à direita
            Expanded(
              flex: 3,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // BUSCAO CLIENTE
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_search),
                            label: const Text("Buscar Cliente"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Buscar Cliente'),
                                    content: const Text(
                                        'Aqui você pode implementar uma busca por nome, CPF, telefone etc.'),
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
                          const SizedBox(width: 20),

                          // TIPO DE OPERACAO
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_search),
                            label: const Text("VENDA"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Buscar Cliente'),
                                    content: const Text(
                                        'Aqui você pode implementar uma busca por nome, CPF, telefone etc.'),
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
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.construction),),

                        ],
                      ),

                      const SizedBox(height: 20),

                      Text("Frente de Caixa", style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge),
                      const SizedBox(height: 20),

                      // Código de Barras
                      // Código de Barras + Botão de Busca
                      Row(
                        children: [
                          // Campo de código de barras
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: "Código de Barras",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {
                                // TODO: buscar produto e adicionar à lista

                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search),
                            tooltip: 'Buscar produto',
                            onPressed: () {
                              // TODO: abrir modal ou painel de busca de produtos
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10)),
                                    child: Container(
                                      width: MediaQuery
                                          .of(context)
                                          .size
                                          .width * 0.8,
                                      height: MediaQuery
                                          .of(context)
                                          .size
                                          .height * 0.8,
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
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: "Itens Total",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {
                                // TODO: buscar produto e adicionar à lista
                              },
                            ),
                          ),
                          // Botão de busca por produto

                        ],
                      ),

                      const SizedBox(height: 10),

                      // Quantidade
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Cliente Identificado",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Lista de itens adicionados
                      Expanded(
                        child: Expanded(
                          child: ListView.builder(
                            itemCount: 20, // TODO: produtos adicionados
                            itemBuilder: (context, index) {
                              return ZebraListItem(
                                index: index,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.grey[200],
                                    child: Icon(
                                      Icons.inventory_2,
                                      // ícone de produto / caixa
                                      color: Colors.grey[800],
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                      "#$index - Produto Exemplo $index"),
                                  subtitle: Text("Qtd: 2 • R\$ 50,00"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          // TODO: diminuir quantidade
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          // TODO: aumentar quantidade
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          // TODO: remover produto da venda
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const Divider(),

                      // Total e ações
                      // Total e ações
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double screenWidth = constraints.maxWidth;
                          double fontSize = screenWidth > 600 ? 40 : 20;
                          double buttonFontSize = screenWidth > 600 ? 24 : 16;
                          EdgeInsets buttonPadding = screenWidth > 600
                              ? EdgeInsets.symmetric(
                              horizontal: 32, vertical: 20)
                              : EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "Total: R\$ 250,00",
                                  style: TextStyle(fontSize: fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(
                                        Icons.check, size: buttonFontSize),
                                    label: Text("Finalizar", style: TextStyle(
                                        fontSize: buttonFontSize)),
                                    style: ElevatedButton.styleFrom(
                                        padding: buttonPadding),
                                    onPressed: () {
                                      // TODO: finalizar venda
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Finalizar'),
                                            content: Text(
                                                'a ideia é confirmar o \ntipo de venda\npropor alguma coisa'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: Text('Fechar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    icon: Icon(
                                        Icons.cancel, size: buttonFontSize),
                                    label: Text("Cancelar", style: TextStyle(
                                        fontSize: buttonFontSize)),
                                    style: OutlinedButton.styleFrom(
                                      padding: buttonPadding,
                                      side: BorderSide(width: 2),
                                    ),
                                    onPressed: () {
                                      // TODO: cancelar venda
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Cancelar'),
                                            content: Text('Nao Implementado'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: Text('Fechar'),
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

  Center buildAnterior() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return _buildDashboardCard(
                      data[index]['title']!, data[index]['count']!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, List<String> subItems, {Function(String)? onSelect}) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (onSelect != null) {
          onSelect(value);
        }
      },
      itemBuilder: (BuildContext context) {
        return subItems.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(
              choice,
              style: TextStyle(
                fontSize: 18, // Aumenta apenas "Preferências do Sistema"
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList();
      },
      child: TextButton(
        onPressed: subItems.isEmpty ? () {} : null,
        child: Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
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
    // {'title': 'OTs pendentes', 'count': '15'},
    // {'title': 'OTs canceladas', 'count': '7'},
    // {'title': 'OTs em auditoria', 'count': '12'},
    // {'title': 'OTs para reabertura', 'count': '5'},
    // {'title': 'OTs em verificação', 'count': '9'},
    // {'title': 'OTs com erro', 'count': '4'},
    // {'title': 'OTs urgentes', 'count': '20'},
    // {'title': 'OTs concluídas hoje', 'count': '30'},
    // {'title': 'OTs em análise', 'count': '8'},
    // {'title': 'OTs em espera', 'count': '11'},
];
}
