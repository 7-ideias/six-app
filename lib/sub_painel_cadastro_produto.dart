import 'package:appplanilha/sub_painel_geral.dart';
import 'package:flutter/material.dart';

class SubPainelCadastroProduto extends SubPainelGeral {
  const SubPainelCadastroProduto({super.key, required super.body, required super.textoDaAppBar});
}

void showSubPainelCadastroProduto(BuildContext context, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      var widget = Column(children: [
        Text('data'),
        Text('data'),
        Text('data'),
      ],);
      return SubPainelCadastroProduto(body: widget, textoDaAppBar: textoDaAppBar,);
    },
  );
}