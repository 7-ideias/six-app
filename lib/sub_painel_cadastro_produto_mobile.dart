import 'package:flutter/material.dart';
import 'package:appplanilha/data/models/produto_model.dart';

class SubPainelCadastroProduto extends StatelessWidget {
  const SubPainelCadastroProduto({
    super.key,
    required this.textoDaAppBar,
    this.body,
  });

  final String textoDaAppBar;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void showSubPainelCadastroProduto(
  BuildContext context,
  String textoDaAppBar, {
  ProdutoModel? produtoParaEdicao,
  bool modoEdicao = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Cadastro de produto disponível apenas na versão web.'),
    ),
  );
}
