import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/produto_model.dart';
import 'produto_list_mobile_screen.dart';

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({super.key});

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _produtosSelecionados = [];
  final List<String> _formasPagamento = [
    'Dinheiro',
    'Cartão Crédito',
    'Cartão Débito',
    'Pix',
    'Fiado',
  ];
  final Map<String, TextEditingController> _valorPorForma = {};
  final Set<String> _formasSelecionadas = {};
  String? _clienteSelecionado;
  final bool _oferecerGarantia = false;

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _valorPorForma.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _buscarProduto(String query) {
    setState(() {
      _produtosSelecionados.add({
        'nome': query,
        'preco': 0.0,
        'quantidade': 1,
      });
    });
  }

  Future<void> _abrirSelecaoProduto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutolistMobileScreen(isSelecao: true),
      ),
    );

    if (result != null && result is ProdutoModel) {
      setState(() {
        _produtosSelecionados.add({
          'nome': result.nomeProduto,
          'preco': result.precoVenda,
          'quantidade': 1,
        });
      });
    }
  }

  void _finalizarVenda() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Venda finalizada!'),
            content: const Text('Obrigado pela compra!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto) {
    final String nome = produto['nome'] ?? '';
    final double preco = (produto['preco'] ?? 0).toDouble();
    final int quantidade = produto['quantidade'] ?? 1;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${preco.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        if (quantidade > 1) {
                          produto['quantidade'] = quantidade - 1;
                        } else {
                          _produtosSelecionados.remove(produto);
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.remove,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$quantidade',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        produto['quantidade'] = quantidade + 1;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            IconButton(
              tooltip: 'Remover item',
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  _produtosSelecionados.remove(produto);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCupomFiscal() {
    final total = _produtosSelecionados.fold<double>(
      0,
          (soma, item) =>
      soma + ((item['preco'] ?? 0.0) * (item['quantidade'] ?? 1)),
    );

    return Container(
      width: double.infinity,
      // margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      margin: const EdgeInsets.fromLTRB(4, 16, 4, 24),
      // margin: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      // margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

          _buildLinhaResumo('Subtotal', total),
          _buildLinhaResumo('Desconto', 0.0),
          const SizedBox(height: 6),
          _buildLinhaResumo('TOTAL', total, destaque: true),

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

  Widget _buildLinhaResumo(String label, double valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPagamentoField(String forma) {
    _valorPorForma.putIfAbsent(forma, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _valorPorForma[forma],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Valor em $forma',
          prefixIcon: const Icon(Icons.attach_money),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();
    final quantidade = _produtosSelecionados.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDV - Ponto de Venda'),
            Text(
              'Itens: $quantidade    Total: R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TextField(
              //   controller: _searchController,
              //   onSubmitted: _buscarProduto,
              //   decoration: InputDecoration(
              //     hintText: 'Buscar produto ou serviço',
              //     prefixIcon: const Icon(Icons.search),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              _produtosSelecionados.isEmpty? Container() : const Text(
                'Itens selecionados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._produtosSelecionados.map(_buildProdutoCard),
              // const SizedBox(height: 24),
              // CheckboxListTile(
              //   value: _oferecerGarantia,
              //   onChanged:
              //       (v) => setState(() => _oferecerGarantia = v ?? false),
              //   title: const Text('Oferecer garantia estendida'),
              // ),
              const SizedBox(height: 24),
              _produtosSelecionados.isEmpty? Container() : const Text(
                'Formas de pagamento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _produtosSelecionados.isEmpty? Container() : Wrap(
                spacing: 8,
                children:
                    _formasPagamento.map((forma) {
                      final selecionado = _formasSelecionadas.contains(forma);
                      return FilterChip(
                        label: Text(forma),
                        selected: selecionado,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _formasSelecionadas.add(forma);
                            } else {
                              _formasSelecionadas.remove(forma);
                            }
                          });
                        },
                        selectedColor: Colors.green.shade200,
                      );
                    }).toList(),
              ),
              ..._formasSelecionadas.map(_buildPagamentoField),
              const SizedBox(height: 36),
              _produtosSelecionados.isEmpty? Container() : ElevatedButton.icon(
                    onPressed: _finalizarVenda,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Finalizar Venda',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                  .animate()
                  .fade(duration: 600.ms)
                  .slideY(begin: 1, curve: Curves.easeOut),
              const SizedBox(height: 10),
              _produtosSelecionados.isEmpty? Container() : ElevatedButton.icon(
                    onPressed: _finalizarVenda,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                  .animate()
                  .fade(duration: 600.ms)
                  .slideY(begin: 1, curve: Curves.easeOut),
              const SizedBox(height: 10),
              _produtosSelecionados.isEmpty? Container() : ElevatedButton.icon(
                    onPressed: _finalizarVenda,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.schedule_send_outlined),
                    label: const Text(
                      'Receber depois',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                  .animate()
                  .fade(duration: 600.ms)
                  .slideY(begin: 1, curve: Curves.easeOut),

              const SizedBox(height: 16),
              _produtosSelecionados.isEmpty? Container() : _buildResumoCupomFiscal(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirSelecaoProduto,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}
