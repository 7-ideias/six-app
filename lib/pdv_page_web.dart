import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';

import '../../data/models/produto_model.dart';
import 'design_system/themes/zebra_list_item.dart';
import 'top_navigation_bar.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebState();
}

class _PDVWebState extends State<PDVWeb> {
  bool _mostrarDashboardLateral = true;

  final List<Map<String, dynamic>> _produtosSelecionados = [];
  final Set<String> _formasSelecionadas = {};

  final TextEditingController _codigoBarrasController =
  TextEditingController();
  final TextEditingController _itensTotalController =
  TextEditingController(text: '0');
  final TextEditingController _clienteIdentificadoController =
  TextEditingController();

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _itensTotalController.dispose();
    _clienteIdentificadoController.dispose();
    super.dispose();
  }

  Future<void> _abrirSelecaoProdutoWeb() async {
    final result = await showDialog<ProdutoModel>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: SubPainelWebProdutoLista(isSelecao: true),
          ),
        );
      },
    );

    if (result != null) {
      _adicionarProdutoSelecionado(result);
    }
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    setState(() {
      final indexExistente = _produtosSelecionados.indexWhere(
            (item) => _mesmoProduto(item, produto),
      );

      if (indexExistente >= 0) {
        _produtosSelecionados[indexExistente]['quantidade'] =
            (_produtosSelecionados[indexExistente]['quantidade'] ?? 1) + 1;
      } else {
        _produtosSelecionados.add({
          'id': _extrairIdProduto(produto),
          'codigo': produto.codigoDeBarras,
          'nome': produto.nomeProduto,
          'preco': (produto.precoVenda as num).toDouble(),
          'quantidade': 1,
          'produtoOriginal': produto,
        });
      }

      _atualizarCamposDerivados();
    });
  }

  bool _mesmoProduto(Map<String, dynamic> item, ProdutoModel produto) {
    final idItem = item['id'];
    final idProduto = _extrairIdProduto(produto);

    if (idItem != null && idProduto != null) {
      return idItem == idProduto;
    }

    final codigoItem = item['codigo']?.toString();
    final codigoProduto = produto.codigoDeBarras?.toString();

    if (codigoItem != null &&
        codigoItem.isNotEmpty &&
        codigoProduto != null &&
        codigoProduto.isNotEmpty) {
      return codigoItem == codigoProduto;
    }

    return item['nome'] == produto.nomeProduto;
  }

  dynamic _extrairIdProduto(ProdutoModel produto) {
    try {
      final dynamic p = produto;
      return p.id ?? p.uuid ?? p.idUnico ?? p.codigo;
    } catch (_) {
      return null;
    }
  }

  void _alterarQuantidade(Map<String, dynamic> produto, int delta) {
    setState(() {
      final quantidadeAtual = (produto['quantidade'] ?? 1) as int;
      final novaQuantidade = quantidadeAtual + delta;

      if (novaQuantidade <= 0) {
        _produtosSelecionados.remove(produto);
      } else {
        produto['quantidade'] = novaQuantidade;
      }

      _atualizarCamposDerivados();
    });
  }

  void _removerProduto(Map<String, dynamic> produto) {
    setState(() {
      _produtosSelecionados.remove(produto);
      _atualizarCamposDerivados();
    });
  }

  void _atualizarCamposDerivados() {
    _itensTotalController.text = _calcularQuantidadeItens().toString();
  }

  double _calcularTotal() {
    return _produtosSelecionados.fold<double>(
      0.0,
          (soma, item) =>
      soma +
          (((item['preco'] ?? 0.0) as num).toDouble() *
              ((item['quantidade'] ?? 1) as int)),
    );
  }

  int _calcularQuantidadeItens() {
    return _produtosSelecionados.fold<int>(
      0,
          (soma, item) => soma + ((item['quantidade'] ?? 1) as int),
    );
  }

  Widget _buildResumoCupomFiscalWeb() {
    final total = _calcularTotal();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE89A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6D89A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'RESUMO DA VENDA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF5C4B00),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFD8C67A), thickness: 1),
          const SizedBox(height: 8),
          if (_produtosSelecionados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum item adicionado.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B5B1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ..._produtosSelecionados.map((produto) {
              final nome = produto['nome'] ?? '';
              final preco = (produto['preco'] ?? 0.0).toDouble();
              final quantidade = (produto['quantidade'] ?? 1) as int;
              final subtotal = preco * quantidade;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3E3300),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$quantidade x R\$ ${preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B5B1E),
                          ),
                        ),
                        Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3E3300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: Color(0xFFD8C67A), thickness: 1),
          const SizedBox(height: 8),
          _buildLinhaResumoWeb(
            'Itens',
            _calcularQuantidadeItens().toDouble(),
            mostrarComoMoeda: false,
          ),
          _buildLinhaResumoWeb('Subtotal', total),
          _buildLinhaResumoWeb('Desconto', 0.0),
          const SizedBox(height: 6),
          _buildLinhaResumoWeb('TOTAL', total, destaque: true),
          const SizedBox(height: 10),
          Text(
            'Pagamento: ${_formasSelecionadas.isEmpty ? 'Não definido' : _formasSelecionadas.join(', ')}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C4B00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumoWeb(
      String label,
      double valor, {
        bool destaque = false,
        bool mostrarComoMoeda = true,
      }) {
    final textoValor = mostrarComoMoeda
        ? 'R\$ ${valor.toStringAsFixed(2)}'
        : valor.toInt().toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF3E3300),
          ),
        ),
        Text(
          textoValor,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF3E3300),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 220,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(
            width: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor: Colors.transparent,
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

  void _mostrarDialogMensagem(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();

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
                _abrirSelecaoProdutoWeb();
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
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildTopActionButton(
                                  context: context,
                                  icon: Icons.person_search,
                                  label: 'Buscar Cliente',
                                  onPressed: () {
                                    _mostrarDialogMensagem(
                                      'Buscar Cliente',
                                      'Aqui você pode implementar uma busca por nome, CPF, telefone etc.',
                                    );
                                  },
                                ),
                                _buildTopActionButton(
                                  context: context,
                                  icon: Icons.person_search,
                                  label: 'Vendedor',
                                  onPressed: () {
                                    _mostrarDialogMensagem(
                                      'Atribuir vendedor',
                                      'Aqui você pode implementar uma busca por nome, CPF, telefone etc.',
                                    );
                                  },
                                ),
                                _buildTopActionButton(
                                  context: context,
                                  icon: Icons.point_of_sale,
                                  label: 'VENDA',
                                  onPressed: () {
                                    _mostrarDialogMensagem(
                                      'Venda',
                                      'Aqui você pode implementar as ações da venda.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.construction),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      "F R E N T E   D E   C A I X A",
                                      style:
                                      Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _codigoBarrasController,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            labelText: "Código de Barras",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search),
                                        tooltip: 'Buscar produto',
                                        onPressed: _abrirSelecaoProdutoWeb,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _itensTotalController,
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            labelText: "Itens Total",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller:
                                    _clienteIdentificadoController,
                                    decoration: const InputDecoration(
                                      labelText: "Cliente Identificado",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _produtosSelecionados.isEmpty
                                        ? Center(
                                      child: Text(
                                        'Nenhum item selecionado.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    )
                                        : ListView.builder(
                                      itemCount:
                                      _produtosSelecionados.length,
                                      itemBuilder: (context, index) {
                                        final produto =
                                        _produtosSelecionados[index];
                                        final quantidade =
                                        (produto['quantidade'] ?? 1)
                                        as int;
                                        final preco =
                                        ((produto['preco'] ?? 0.0)
                                        as num)
                                            .toDouble();

                                        return ZebraListItem(
                                          index: index,
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                              Theme.of(context)
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
                                            title: Text(
                                              produto['nome'] ?? '',
                                            ),
                                            subtitle: Text(
                                              'Qtd: $quantidade • R\$ ${preco.toStringAsFixed(2)}',
                                            ),
                                            trailing: Row(
                                              mainAxisSize:
                                              MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .remove_circle_outline,
                                                  ),
                                                  onPressed: () =>
                                                      _alterarQuantidade(
                                                        produto,
                                                        -1,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .add_circle_outline,
                                                  ),
                                                  onPressed: () =>
                                                      _alterarQuantidade(
                                                        produto,
                                                        1,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _removerProduto(
                                                        produto,
                                                      ),
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
                                      final double screenWidth =
                                          constraints.maxWidth;
                                      final double fontSize =
                                      screenWidth > 600 ? 40 : 20;
                                      final double buttonFontSize =
                                      screenWidth > 600 ? 24 : 16;
                                      final EdgeInsets buttonPadding =
                                      screenWidth > 600
                                          ? const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      )
                                          : const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      );

                                      return Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Total: R\$ ${total.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
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
                                                style:
                                                OutlinedButton.styleFrom(
                                                  padding: buttonPadding,
                                                ),
                                                onPressed: () {
                                                  _mostrarDialogMensagem(
                                                    'Pausar',
                                                    'A ideia é receber depois e deixar a venda aberta.',
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
                                                style:
                                                OutlinedButton.styleFrom(
                                                  padding: buttonPadding,
                                                ),
                                                onPressed: () {
                                                  _mostrarDialogMensagem(
                                                    'Finalizar',
                                                    'A ideia é confirmar o tipo de venda e propor alguma coisa.',
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
                                                style:
                                                OutlinedButton.styleFrom(
                                                  padding: buttonPadding,
                                                  side: const BorderSide(
                                                    width: 2,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _mostrarDialogMensagem(
                                                    'Cancelar',
                                                    'Não implementado',
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
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 340,
                              child: SingleChildScrollView(
                                child: _buildResumoCupomFiscalWeb(),
                              ),
                            ),
                          ],
                        ),
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
}