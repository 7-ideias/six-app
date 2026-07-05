import 'package:flutter/material.dart';

import 'atendimentos_tecnicos_web_page.dart';

class OrcamentoWeb extends StatelessWidget {
  const OrcamentoWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AtendimentosTecnicosWebPage(
      embedded: embedded,
      onBack: onBack,
    );
  }
}
