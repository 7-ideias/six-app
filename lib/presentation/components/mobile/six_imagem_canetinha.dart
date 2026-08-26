import 'dart:ui';

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
    this.reforcoContorno = 0,
    this.reforcoAcento = 0,
    this.opacidadeReforco = 0.42,
    this.opacidadeBrilho = 0,
    this.desfoqueBrilho = 4,
  }) : assert(opacidadeContorno >= 0 && opacidadeContorno <= 1),
       assert(opacidadeAcento >= 0 && opacidadeAcento <= 1),
       assert(reforcoContorno >= 0),
       assert(reforcoAcento >= 0),
       assert(opacidadeReforco >= 0 && opacidadeReforco <= 1),
       assert(opacidadeBrilho >= 0 && opacidadeBrilho <= 1),
       assert(desfoqueBrilho >= 0);

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
  final double reforcoContorno;
  final double reforcoAcento;
  final double opacidadeReforco;
  final double opacidadeBrilho;
  final double desfoqueBrilho;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget imagem = SizedBox(
      width: largura,
      height: altura,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            if (opacidadeBrilho > 0)
              ImageFiltered(
                key: const ValueKey<String>('six-canetinha-brilho'),
                imageFilter: ImageFilter.blur(
                  sigmaX: desfoqueBrilho,
                  sigmaY: desfoqueBrilho,
                ),
                child: Opacity(
                  opacity: opacidadeBrilho,
                  child: _CamadaImagemCanetinha(
                    asset: assetContorno,
                    cor: corContorno ?? colorScheme.onSurface,
                    gradiente: gradienteContorno,
                    opacidade: opacidadeContorno,
                    chaveGradiente: null,
                    fit: fit,
                  ),
                ),
              ),
            if (reforcoContorno > 0)
              _CamadaImagemReforcada(
                key: const ValueKey<String>(
                  'six-canetinha-contorno-reforco',
                ),
                asset: assetContorno,
                cor: corContorno ?? colorScheme.onSurface,
                gradiente: gradienteContorno,
                opacidadeCamada: opacidadeContorno,
                opacidadeReforco: opacidadeReforco,
                deslocamento: reforcoContorno,
                fit: fit,
              ),
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
            if (reforcoAcento > 0)
              _CamadaImagemReforcada(
                key: const ValueKey<String>(
                  'six-canetinha-acento-reforco',
                ),
                asset: assetAcento,
                cor: corAcento ?? colorScheme.primary,
                gradiente: gradienteAcento,
                opacidadeCamada: opacidadeAcento,
                opacidadeReforco: opacidadeReforco,
                deslocamento: reforcoAcento,
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
  final Key? chaveGradiente;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
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

class _CamadaImagemReforcada extends StatelessWidget {
  const _CamadaImagemReforcada({
    super.key,
    required this.asset,
    required this.cor,
    required this.gradiente,
    required this.opacidadeCamada,
    required this.opacidadeReforco,
    required this.deslocamento,
    required this.fit,
  });

  final String asset;
  final Color cor;
  final Gradient? gradiente;
  final double opacidadeCamada;
  final double opacidadeReforco;
  final double deslocamento;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final List<Offset> deslocamentos = <Offset>[
      Offset(-deslocamento, 0),
      Offset(deslocamento, 0),
      Offset(0, -deslocamento),
      Offset(0, deslocamento),
    ];

    return Opacity(
      opacity: opacidadeReforco,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final Offset offset in deslocamentos)
            Transform.translate(
              offset: offset,
              child: _CamadaImagemCanetinha(
                asset: asset,
                cor: cor,
                gradiente: gradiente,
                opacidade: opacidadeCamada,
                chaveGradiente: null,
                fit: fit,
              ),
            ),
        ],
      ),
    );
  }
}
