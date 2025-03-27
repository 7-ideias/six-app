import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../components/custom_nav_bar.dart';

class OperacaoMobileScreen extends StatefulWidget {
  @override
  State<OperacaoMobileScreen> createState() => _OperacaoMobileScreenState();
}

class _OperacaoMobileScreenState extends State<OperacaoMobileScreen> {
  final List<_OperacaoItem> operacoes = [
    _OperacaoItem(Icons.point_of_sale, 'Nova venda', Colors.green, () {
      // TODO: ação venda
    }),
    _OperacaoItem(Icons.person_add, 'Novo cadastro', Colors.blue, () {
      // TODO: ação cadastro
    }),
    _OperacaoItem(
      Icons.request_page,
      'Contas a receber',
      Colors.deepPurple,
      () {
        // TODO: ação contas a receber
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O que deseja fazer?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child:
                  GridView.count(
                    crossAxisCount: 1,
                    childAspectRatio: 2.8,
                    mainAxisSpacing: 20,
                    children:
                        operacoes
                            .map((item) => _buildOperacaoCard(item))
                            .toList(),
                  ).animate().fade(duration: 500.ms).slideY(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 2),
    );
  }

  Widget _buildOperacaoCard(_OperacaoItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: item.color,
              child: Icon(item.icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
    );
  }
}

class _OperacaoItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _OperacaoItem(this.icon, this.label, this.color, this.onTap);
}
