import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({super.key});

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _produtosSelecionados = [
    {'nome': 'Corte de cabelo', 'preco': 30.0},
    {'nome': 'Shampoo', 'preco': 15.0},
    {'nome': 'Barba', 'preco': 25.0},
    {'nome': 'Escova', 'preco': 40.0},
    {'nome': 'Máscara capilar', 'preco': 20.0},
  ];
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
  bool _oferecerGarantia = false;

  void _buscarProduto(String query) {
    setState(() {
      _produtosSelecionados.add({'nome': query, 'preco': 0.0});
    });
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${produto['nome']} - R\$ ${produto['preco'].toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() => _produtosSelecionados.remove(produto));
              },
            ),
          ],
        ),
      ),
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
    return _produtosSelecionados.fold(
      0.0,
      (soma, item) => soma + (item['preco'] as double),
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
              TextField(
                controller: _searchController,
                onSubmitted: _buscarProduto,
                decoration: InputDecoration(
                  hintText: 'Buscar produto ou serviço',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Itens selecionados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._produtosSelecionados.map(_buildProdutoCard),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _oferecerGarantia,
                onChanged:
                    (v) => setState(() => _oferecerGarantia = v ?? false),
                title: const Text('Oferecer garantia estendida'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Formas de pagamento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
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
              ..._formasSelecionadas.map(_buildPagamentoField).toList(),
              const SizedBox(height: 36),
              ElevatedButton.icon(
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
              ElevatedButton.icon(
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
              ElevatedButton.icon(
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
            ],
          ),
        ),
      ),
    );
  }
}
