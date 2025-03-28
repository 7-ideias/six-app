import 'package:flutter/material.dart';

class CamposEspecificosSegmentoScreen extends StatefulWidget {
  const CamposEspecificosSegmentoScreen({Key? key}) : super(key: key);

  @override
  State<CamposEspecificosSegmentoScreen> createState() =>
      _CamposEspecificosSegmentoScreenState();
}

class _CamposEspecificosSegmentoScreenState
    extends State<CamposEspecificosSegmentoScreen> {
  final Map<String, String> campos = {
    'Validade do orçamento (data)': 'data',
    'Validade do orçamento (texto)': 'texto',
    'Horário de início': 'hora',
    'Tipo de evento': 'texto',
    'Tema do evento': 'texto',
    'Local do evento': 'texto',
    'Número esperado de pessoas': 'texto',
    'Duração do serviço': 'texto',
    'Observações': 'texto',
  };

  final Map<String, bool> selecionados = {};

  @override
  void initState() {
    super.initState();
    for (var campo in campos.keys) {
      selecionados[campo] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campos específicos"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Você pode escolher campos específicos pro seu negócio.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ...campos.entries.map((entry) {
            return CheckboxListTile(
              value: selecionados[entry.key],
              onChanged: (val) {
                setState(() {
                  selecionados[entry.key] = val ?? false;
                });
              },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key.replaceAll(RegExp(r'\s\(\w+\)$'), '')),
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
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
          // Aqui poderia abrir um modal de ajuda, por exemplo
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
              // salvar campos
            },
            child: const Text("salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
