import 'package:flutter/material.dart';

class EstoqueMobileScreen extends StatefulWidget {
  const EstoqueMobileScreen({Key? key}) : super(key: key);

  @override
  State<EstoqueMobileScreen> createState() => _EstoqueMobileScreenState();
}

class _EstoqueMobileScreenState extends State<EstoqueMobileScreen> {
  bool controleEstoque = true;
  String? statusSelecionado = 'Pendente';

  final Map<String, Color> statusColors = {
    'Pendente': Colors.orange,
    'Aguardando aprovação': Colors.orange,
    'Aprovado': Colors.blue,
    'Em andamento': Colors.blue,
    'Aguardando pagamento': Colors.blue,
    'Enviado': Colors.blue,
    'Concluído': Colors.green,
    'Garantia': Colors.green,
    'Cancelado': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estoque de Peças"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Controle de estoque"),
            value: controleEstoque,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                controleEstoque = value;
              });
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Escolha qual status do pedido vai indicar que suas peças não estão mais no estoque.",
                style: TextStyle(fontSize: 14),
              ),
              Icon(Icons.info_outline, color: Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 16),
          ...statusColors.entries.map((entry) {
            return RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: entry.value),
                  const SizedBox(width: 8),
                  Text(entry.key),
                ],
              ),
              value: entry.key,
              groupValue: statusSelecionado,
              activeColor: Colors.deepPurple,
              onChanged: (value) {
                setState(() {
                  statusSelecionado = value;
                });
              },
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
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
              // salvar configuração de estoque
            },
            child: const Text("salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
