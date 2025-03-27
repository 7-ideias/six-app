import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../components/custom_nav_bar.dart';

class GestaoMobileScreen extends StatefulWidget {
  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestao')),
      body: Center(child: Text('Conteúdo da tela de Gestao')),
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 0),
    );
  }
}
