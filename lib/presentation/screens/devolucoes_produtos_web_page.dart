import 'package:flutter/material.dart';

import 'devolucoes_produtos_jornada.dart';

class DevolucoesProdutosWebPage extends StatelessWidget {
  const DevolucoesProdutosWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevolucoesProdutosJornada(web: true);
  }
}
