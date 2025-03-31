import 'package:flutter/material.dart';

class CatalogoDisponivelMobileScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CatalogoDisponivelMobileScreenState();
}

class _CatalogoDisponivelMobileScreenState
    extends State<CatalogoDisponivelMobileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'colocar um resumo dos produtos que estao disponiveis, baixo estoque, etc',
            ),
          ),
        ),
      ),
    );
  }
}
