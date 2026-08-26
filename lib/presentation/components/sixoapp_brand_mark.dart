import 'package:flutter/material.dart';

/// Símbolo oficial do SixoApp para superfícies internas do Flutter.
///
/// Mantém uma única referência de asset e semântica para navegação, cabeçalhos
/// e contextos administrativos, sem acoplar o componente ao layout Web.
class SixoAppBrandMark extends StatelessWidget {
  const SixoAppBrandMark({
    super.key,
    this.size = 32,
    this.semanticLabel = 'SixoApp',
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Image.asset(
          'assets/images/sixoapp_splash_symbol.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: 128,
        ),
      ),
    );
  }
}
