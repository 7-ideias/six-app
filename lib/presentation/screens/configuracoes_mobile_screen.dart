import 'package:flutter/material.dart';

import 'empresa_configuracao_screen.dart';

class ConfiguracoesMobileScreen extends StatelessWidget {
  const ConfiguracoesMobileScreen({super.key});

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
        leading: const BackButton(),
        title: const Text(
          'Empresa',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: const SafeArea(
        child: EmpresaConfiguracaoForm(embedded: false),
      ),
    );
  }
}
