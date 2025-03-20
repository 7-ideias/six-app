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
                  _buildMenuItem(context, 'Banco de Dados/Backup', [
                    'Backup Manual',
                    'Restaurar Backup'
                  ]),
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
        child: Text(
          'Tela Principal do Sistema',
          style: TextStyle(fontSize: 20),
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
            child: Text(choice),
          );
        }).toList();
      },
      child: TextButton(
        onPressed: subItems.isEmpty ? () {} : null,
        child: Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }
}