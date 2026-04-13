import 'package:flutter/material.dart';

class UnidadesMedidaMobileScreen extends StatefulWidget {
  const UnidadesMedidaMobileScreen({Key? key}) : super(key: key);

  @override
  State<UnidadesMedidaMobileScreen> createState() =>
      _UnidadesMedidaMobileScreenState();
}

class _UnidadesMedidaMobileScreenState
    extends State<UnidadesMedidaMobileScreen> {
  final Map<String, List<_UnidadeItem>> grupos = {
    'Unidades': [_UnidadeItem(sigla: 'un.', descricao: 'unidades')],
    'Área': [
      _UnidadeItem(sigla: 'm²', descricao: 'metros quadrados'),
      _UnidadeItem(sigla: 'km²', descricao: 'quilômetros quadrados'),
      _UnidadeItem(sigla: 'ha', descricao: 'hectares'),
    ],
    'Distância': [
      _UnidadeItem(sigla: 'mm', descricao: 'milímetros'),
      _UnidadeItem(sigla: 'cm', descricao: 'centímetros'),
      _UnidadeItem(sigla: 'm', descricao: 'metros'),
      _UnidadeItem(sigla: 'km', descricao: 'quilômetros'),
    ],
    'Volume': [
      _UnidadeItem(sigla: 'mL', descricao: 'mililitros'),
      _UnidadeItem(sigla: 'L', descricao: 'litros'),
      _UnidadeItem(sigla: 'm³', descricao: 'metros cúbicos'),
    ],
    'Tempo': [
      _UnidadeItem(sigla: 'min', descricao: 'minutos'),
      _UnidadeItem(sigla: 'h', descricao: 'horas'),
      _UnidadeItem(sigla: 'dias', descricao: 'dias'),
      _UnidadeItem(sigla: 'semanas', descricao: 'semanas'),
      _UnidadeItem(sigla: 'meses', descricao: 'meses'),
    ],
    'Peso': [
      _UnidadeItem(sigla: 'g', descricao: 'gramas'),
      _UnidadeItem(sigla: 'kg', descricao: 'quilogramas'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unidade de medida"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Como você mede serviços e peças pra definir preços?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...grupos.entries.map((grupo) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grupo.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...grupo.value.map((item) {
                  return CheckboxListTile(
                    value: item.selecionado,
                    onChanged: (val) {
                      setState(() {
                        item.selecionado = val ?? false;
                      });
                    },
                    title: Text(item.sigla),
                    subtitle: Text(item.descricao),
                    activeColor: Colors.deepPurple,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
                const Divider(),
              ],
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ajuda, dica ou tooltip
        },
        backgroundColor: const Color(0xFFDAE529),
        child: const Icon(Icons.lightbulb_outline, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
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
              // salvar unidades selecionadas
            },
            child: const Text("salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _UnidadeItem {
  final String sigla;
  final String descricao;
  bool selecionado;

  _UnidadeItem({
    required this.sigla,
    required this.descricao,
    this.selecionado = true,
  });
}
