import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({super.key});

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _produtosSelecionados = [];
  final List<String> _formasPagamento = [
    'Dinheiro',
    'Cartão Crédito',
    'Cartão Débito',
    'Pix',
    'Fiado',
  ];
  String? _clienteSelecionado;
  String? _formaPagamentoSelecionada;
  bool _oferecerGarantia = false;

  void _buscarProduto(String query) {
    setState(() {
      _produtosSelecionados.add('Produto: \$query');
    });
  }

  void _finalizarVenda() {
    // lógica de finalização
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

  Widget _buildProdutoCard(String nome) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(child: Text(nome, style: const TextStyle(fontSize: 16))),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() => _produtosSelecionados.remove(nome));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDV - Ponto de Venda')),
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
              if (_produtosSelecionados.isNotEmpty)
                ..._produtosSelecionados.map(_buildProdutoCard),

              const SizedBox(height: 24),
              const Text(
                'Cliente',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _clienteSelecionado,
                items:
                    ['Ana', 'Carlos', 'Bruno', 'Fernanda']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => setState(() => _clienteSelecionado = v),
                decoration: InputDecoration(
                  hintText: 'Selecionar cliente',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              CheckboxListTile(
                value: _oferecerGarantia,
                onChanged:
                    (v) => setState(() => _oferecerGarantia = v ?? false),
                title: const Text('Oferecer garantia estendida'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Forma de pagamento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _formasPagamento.map((forma) {
                      final selecionado = _formaPagamentoSelecionada == forma;
                      return ChoiceChip(
                        label: Text(forma),
                        selected: selecionado,
                        onSelected:
                            (_) => setState(
                              () => _formaPagamentoSelecionada = forma,
                            ),
                        selectedColor: Colors.green.shade200,
                      );
                    }).toList(),
              ),

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
                    icon: const Icon(Icons.check_circle_outline),
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
                    icon: const Icon(Icons.check_circle_outline),
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
