import 'package:appplanilha/presentation/screens/seguimento_selecionar_mobile_screen.dart';
import 'package:flutter/material.dart';

class SeguimentoMobileScreen extends StatefulWidget {
  const SeguimentoMobileScreen({super.key});

  @override
  State<SeguimentoMobileScreen> createState() => _SeguimentoMobileScreenState();
}

class _SeguimentoMobileScreenState extends State<SeguimentoMobileScreen> {
  List<String> segmentosSelecionados = [
    'Design gráfico',
    'Celular',
    'Maquiagem',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Segmentos selecionados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  segmentosSelecionados
                      .map(
                        (item) => Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const SeguimentoSelecionarMobileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar segmentos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
