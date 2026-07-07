import 'package:flutter/material.dart';
import 'package:sixpos/design_system/components/web/sub_painel_web_general.dart';

import 'presentation/screens/colaborador_convite_web_body.dart';

class SubPainelCadastroColaborador extends SubPainelWebGeneral {
  const SubPainelCadastroColaborador({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroColaborador(
  BuildContext context,
  String textoDaAppBar,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return SubPainelCadastroColaborador(
        textoDaAppBar: textoDaAppBar,
        body: const ColaboradorConviteWebBody(),
      );
    },
  );
}
