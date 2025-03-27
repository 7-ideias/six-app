import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../custom_nav_bar.dart';

class OperacaoMobileScreen extends StatefulWidget {
  @override
  State<OperacaoMobileScreen> createState() => _OperacaoMobileScreenState();
}

class _OperacaoMobileScreenState extends State<OperacaoMobileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Operação')),
      body: Center(child: Text('Conteúdo da tela de Operação')),
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 2),
    );
  }
}
