import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';

class HomePageWeb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
                    'Fornecedores'
                  ], onSelect: (value) {
                    if (value == 'Produtos') {
                      showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
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
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
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
                    return _buildDashboardCard(data[index]['title']!, data[index]['count']!);
                  },
                ),
              ),
            ],
          ),
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


final List<Map<String, String>> data = [
  {'title': 'OTs em revisão', 'count': '33'},
  {'title': 'OTs em processo', 'count': '27'},
  {'title': 'OTs finalizadas', 'count': '94'},
  {'title': 'OTs atrasadas', 'count': '10'},
  {'title': 'OTs pendentes', 'count': '15'},
  {'title': 'OTs canceladas', 'count': '7'},
  {'title': 'OTs em auditoria', 'count': '12'},
  {'title': 'OTs para reabertura', 'count': '5'},
  {'title': 'OTs em verificação', 'count': '9'},
  {'title': 'OTs com erro', 'count': '4'},
  {'title': 'OTs urgentes', 'count': '20'},
  {'title': 'OTs concluídas hoje', 'count': '30'},
  {'title': 'OTs em análise', 'count': '8'},
  {'title': 'OTs em espera', 'count': '11'},
];
}
