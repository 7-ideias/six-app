import 'package:flutter/material.dart';

/// Ilustração em duas camadas que acompanha as cores do tema ativo.
class SixImagemCanetinha extends StatelessWidget {
  const SixImagemCanetinha({
    super.key,
    required this.assetContorno,
    required this.assetAcento,
    required this.largura,
    required this.altura,
    this.fit = BoxFit.contain,
    this.rotuloSemantico,
    this.corContorno,
    this.corAcento,
    this.gradienteContorno,
    this.gradienteAcento,
    this.opacidadeContorno = 1,
    this.opacidadeAcento = 1,
  });

  final String assetContorno;
  final String assetAcento;
  final double largura;
  final double altura;
  final BoxFit fit;
  final String? rotuloSemantico;
  final Color? corContorno;
  final Color? corAcento;
  final Gradient? gradienteContorno;
  final Gradient? gradienteAcento;
  final double opacidadeContorno;
  final double opacidadeAcento;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget imagem = SizedBox(
      width: largura,
      height: altura,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          _CamadaImagemCanetinha(
            asset: assetContorno,
            cor: corContorno ?? colorScheme.onSurface,
            gradiente: gradienteContorno,
            opacidade: opacidadeContorno,
            chaveGradiente: const ValueKey<String>(
              'six-canetinha-contorno-gradiente',
            ),
            fit: fit,
          ),
          _CamadaImagemCanetinha(
            asset: assetAcento,
            cor: corAcento ?? colorScheme.primary,
            gradiente: gradienteAcento,
            opacidade: opacidadeAcento,
            chaveGradiente: const ValueKey<String>(
              'six-canetinha-acento-gradiente',
            ),
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
    required this.gradiente,
    required this.opacidade,
    required this.chaveGradiente,
    required this.fit,
  });

  final String asset;
  final Color cor;
  final Gradient? gradiente;
  final double opacidade;
  final Key chaveGradiente;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    assert(opacidade >= 0 && opacidade <= 1);

    final Widget imagem = Image.asset(
      asset,
      fit: fit,
      color: gradiente == null ? cor : null,
      colorBlendMode: gradiente == null ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      excludeFromSemantics: true,
    );
    final Widget camada =
        gradiente == null
            ? imagem
            : ShaderMask(
              key: chaveGradiente,
              shaderCallback: (Rect bounds) => gradiente!.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: imagem,
            );

    if (opacidade == 1) return camada;
    return Opacity(opacity: opacidade, child: camada);
  }
}
