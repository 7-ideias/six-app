import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/six_mobile_animated_gradient_background.dart';

void main() {
  testWidgets(
    'renderiza fundo animado no tema claro preservando rodape claro',
    (WidgetTester tester) async {
      final Color bottomColor = await _renderAndSampleBottomColor(
        tester,
        theme: ThemeData.light(),
        baseColor: SixMobilePalette.backgroundLight,
      );

      expect(bottomColor.computeLuminance(), greaterThan(0.90));
    },
  );

  testWidgets(
    'renderiza fundo animado no tema escuro sem faixa clara no rodape',
    (WidgetTester tester) async {
      final Color bottomColor = await _renderAndSampleBottomColor(
        tester,
        theme: ThemeData.dark(),
        baseColor: SixMobilePalette.backgroundLight,
      );

      expect(bottomColor.computeLuminance(), lessThan(0.20));
    },
  );
}

Future<Color> _renderAndSampleBottomColor(
  WidgetTester tester, {
  required ThemeData theme,
  required Color baseColor,
}) async {
  final GlobalKey repaintKey = GlobalKey();

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: RepaintBoundary(
        key: repaintKey,
        child: SizedBox(
          width: 120,
          height: 240,
          child: SixMobileAnimatedGradientBackground(
            enabled: false,
            intensity: 1,
            baseColor: baseColor,
            primaryColor: SixMobilePalette.primaryLight,
            secondaryColor: SixMobilePalette.secondaryLight,
            accentColor: SixMobilePalette.accentLight,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final RenderRepaintBoundary boundary =
      repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image =
      (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
  final ByteData bytes =
      (await tester.runAsync<ByteData?>(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;

  final int x = image.width ~/ 2;
  final int y = image.height - 2;
  final int offset = ((y * image.width) + x) * 4;
  final Color color = Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
  image.dispose();

  return color;
}
