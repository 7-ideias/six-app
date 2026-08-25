import 'package:flutter/material.dart';

/// Ilustração do atendimento com suporte a arte pronta ou duas camadas.
class SixImagemCanetinha extends StatelessWidget {
  const SixImagemCanetinha({
    super.key,
    required this.assetContorno,
    required this.largura,
    required this.altura,
    this.assetAcento,
    this.fit = BoxFit.contain,
    this.rotuloSemantico,
    this.corContorno,
    this.corAcento,
    this.preservarCoresOriginais = false,
  });

  final String assetContorno;
  final String? assetAcento;
  final double largura;
  final double altura;
  final BoxFit fit;
  final String? rotuloSemantico;
  final Color? corContorno;
  final Color? corAcento;
  final bool preservarCoresOriginais;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget imagem = SizedBox(
      width: largura,
      height: altura,
      child:
          preservarCoresOriginais || (assetAcento?.trim().isEmpty ?? true)
              ? Image.asset(
                assetContorno,
                fit: fit,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                excludeFromSemantics: true,
              )
              : Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: <Widget>[
                  _CamadaImagemCanetinha(
                    asset: assetContorno,
                    cor: corContorno ?? colorScheme.onSurface,
                    fit: fit,
                  ),
                  _CamadaImagemCanetinha(
                    asset: assetAcento!,
                    cor: corAcento ?? colorScheme.primary,
                    fit: fit,
                  ),
                ],
              ),
    );
    final String? rotulo = rotuloSemantico?.trim();

    if (rotulo == null || rotulo.isEmpty) {
      return ExcludeSemantics(child: imagem);
    }

    return Semantics(
      image: true,
      label: rotulo,
      child: ExcludeSemantics(child: imagem),
    );
  }
}

class _CamadaImagemCanetinha extends StatelessWidget {
  const _CamadaImagemCanetinha({
    required this.asset,
    required this.cor,
    required this.fit,
  });

  final String asset;
  final Color cor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      color: cor,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      excludeFromSemantics: true,
    );
  }
}
