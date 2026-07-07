import 'package:flutter/material.dart';

import 'atendimentos_tecnicos_web_page.dart';

class AtendimentoTecnicoMobileScreen extends StatelessWidget {
  const AtendimentoTecnicoMobileScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Novo atendimento técnico',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: const SafeArea(
        child: AtendimentosTecnicosWebPage(embedded: true),
      ),
    );
  }
}
