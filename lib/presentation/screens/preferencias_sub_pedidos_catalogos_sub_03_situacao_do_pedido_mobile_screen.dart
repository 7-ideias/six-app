import 'package:flutter/material.dart';

class SituacaoDoPedidoMobileScreen extends StatefulWidget {
  const SituacaoDoPedidoMobileScreen({Key? key}) : super(key: key);

  @override
  State<SituacaoDoPedidoMobileScreen> createState() =>
      _SituacaoDoPedidoMobileScreenState();
}

class _SituacaoDoPedidoMobileScreenState
    extends State<SituacaoDoPedidoMobileScreen> {
  final Map<String, bool> status = {
    'Pendente': true,
    'Aguardando aprovação': true,
    'Aprovado': true,
    'Em andamento': true,
    'Aguardando pagamento': true,
    'Enviado': true,
    'Contrato de manutenção': false, // desabilitado
    'Concluído': true,
    'Garantia': true,
    'Cancelado': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Situação do pedido'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Isto é crucial pra organizar seu negócio.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ...status.entries.map((entry) {
            final isDisabled = entry.key == 'Contrato de manutenção';
            return CheckboxListTile(
              value: entry.value,
              onChanged:
                  isDisabled
                      ? null
                      : (val) {
                        setState(() {
                          status[entry.key] = val ?? false;
                        });
                      },
              title: Text(
                entry.key,
                style:
                    isDisabled
                        ? const TextStyle(color: Colors.grey)
                        : const TextStyle(),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.deepPurple,
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ajuda ou tooltip
        },
        backgroundColor: const Color(0xFFDAE529),
        child: const Icon(Icons.lightbulb_outline, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // salvar status
            },
            child: const Text("salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
