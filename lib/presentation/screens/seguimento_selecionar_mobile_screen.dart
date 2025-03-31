import 'package:flutter/material.dart';

class SeguimentoSelecionarMobileScreen extends StatefulWidget {
  const SeguimentoSelecionarMobileScreen({super.key});

  @override
  State<SeguimentoSelecionarMobileScreen> createState() =>
      _SeguimentoSelecionarMobileScreenState();
}

class _SeguimentoSelecionarMobileScreenState
    extends State<SeguimentoSelecionarMobileScreen> {
  final TextEditingController _searchController = TextEditingController();

  final Map<String, List<String>> segmentos = {
    'Artes digitais & Marketing': [
      'Audiovisual',
      'Comunicação visual',
      'Design gráfico',
      'Marketing digital',
      'Marketing e publicidade',
      'Redes sociais',
    ],
    'Assistência técnica': [
      'Aparelho de som',
      'Aparelho odontológico',
      'Ar condicionado',
      'Cabeamento de rede',
      'Celular',
      'Computador',
      'Cooktop',
      'Câmera',
      'DVD',
      'Eletrônicos',
      'Fogão',
      'Informática',
      'Lava-louças',
      'Microondas',
      'Máquina de costura',
      'Máquina de lavar',
      'Máquinas',
      'Notebook / Laptop',
      'TV',
      'Tablet',
      'Telefone PABX',
      'Telefone fixo',
    ],
    'Beleza & Moda': [
      'Acessórios',
      'Barbeiro',
      'Cabeleireiro',
      'Corte & Costura',
      'Cosméticos',
      'Design de sobrancelhas',
      'Design de unhas',
      'Estamparia',
      'Estofados',
      'Estética',
      'Joias',
      'Manicure',
      'Maquiagem',
      'Massagem',
      'Pedicure',
      'Perfumes',
      'Relojoaria',
      'Roupas',
      'Sapateiro',
      'Tatuagem',
    ],
    'Comércio': ['Comércio em geral'],
    'Construção & Manutenção': [
      'Arquitetura',
      'Automação industrial',
      'Automação residencial',
      'Caixa d\'água',
      'Calha',
      'Chaveiro',
      'Climatização & Refrigeração',
      'Construção & Reforma',
      'Cortinas e persianas',
      'Decoração de interiores',
      'Dedetização',
    ],
    'Eventos & Alimentação': [
      'Bares & Restaurantes',
      'Bolos',
      'Buffet',
      'Caligrafia',
      'Cerimonial',
      'Churrasco',
      'Confeitaria',
      'Convites',
      'Doces',
      'Filmagem',
      'Fotografia',
    ],
    'Saúde & Bem-estar': [
      'Cuidador',
      'Enfermagem',
      'Fisioterapia',
      'Fitness e exercício',
      'Medicina',
      'Odontologia',
      'Psicologia',
      'Terapia',
    ],
  };

  final Map<String, bool> expandedSegments = {};
  final Map<String, bool> selectedSubsegments = {};

  @override
  void initState() {
    super.initState();
    for (var key in segmentos.keys) {
      expandedSegments[key] = false;
    }
  }

  List<String> get _filteredSegmentos {
    final query = _searchController.text.toLowerCase();
    return segmentos.keys
        .where((s) => s.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar segmentos'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFCDDE38),
        child: const Icon(Icons.lightbulb_outline, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: selectedSubsegments.containsValue(true) ? () {} : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor:
                selectedSubsegments.containsValue(true)
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
            disabledForegroundColor: Colors.white.withOpacity(0.5),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('salvar segmento'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              children:
                  _filteredSegmentos.map((segmento) {
                    final isExpanded = expandedSegments[segmento] ?? false;
                    final subSegmentos = segmentos[segmento]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.category),
                          title: Text(
                            segmento,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                            onPressed: () {
                              setState(() {
                                expandedSegments[segmento] = !isExpanded;
                              });
                            },
                          ),
                        ),
                        if (isExpanded)
                          ...subSegmentos.map((sub) {
                            final selected = selectedSubsegments[sub] ?? false;
                            return CheckboxListTile(
                              title: Text(sub),
                              value: selected,
                              onChanged: (value) {
                                setState(() {
                                  selectedSubsegments[sub] = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
