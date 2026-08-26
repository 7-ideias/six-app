import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/mobile/six_imagem_canetinha.dart';

const String _assetContorno =
    'assets/images/atendimento mobile/acao-receber.webp';
const String _assetAcento =
    'assets/images/atendimento mobile/acao-receber-acento.webp';

void main() {
  testWidgets('aplica as cores das duas camadas no tema claro', (
    WidgetTester tester,
  ) async {
    const Color corContorno = Color(0xFF172033);
    const Color corPrimaria = Color(0xFF1D63E9);

    await _pumpImagem(
      tester,
      brightness: Brightness.light,
      corContorno: corContorno,
      corPrimaria: corPrimaria,
    );

    _expectCamadas(tester, corContorno: corContorno, corPrimaria: corPrimaria);
    expect(find.bySemanticsLabel('Pagamento recebido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aplica as cores das duas camadas no tema escuro', (
    WidgetTester tester,
  ) async {
    const Color corContorno = Color(0xFFEFF4FA);
    const Color corPrimaria = Color(0xFF60A5FA);

    await _pumpImagem(
      tester,
      brightness: Brightness.dark,
      corContorno: corContorno,
      corPrimaria: corPrimaria,
    );

    _expectCamadas(tester, corContorno: corContorno, corPrimaria: corPrimaria);
    expect(find.bySemanticsLabel('Pagamento recebido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aplica gradientes independentes nas duas camadas', (
    WidgetTester tester,
  ) async {
    const LinearGradient gradienteContorno = LinearGradient(
      colors: <Color>[Color(0xFF10D9F0), Color(0xFF145BFF)],
    );
    const LinearGradient gradienteAcento = LinearGradient(
      colors: <Color>[Color(0xFF145BFF), Color(0xFF5A20FF)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SixImagemCanetinha(
              assetContorno: _assetContorno,
              assetAcento: _assetAcento,
              largura: 120,
              altura: 120,
              gradienteContorno: gradienteContorno,
              gradienteAcento: gradienteAcento,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('six-canetinha-contorno-gradiente'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('six-canetinha-acento-gradiente')),
      findsOneWidget,
    );

    final List<Image> camadas =
        tester
            .widgetList<Image>(
              find.descendant(
                of: find.byType(SixImagemCanetinha),
                matching: find.byType(Image),
              ),
            )
            .toList();
    expect(camadas, hasLength(2));
    expect(camadas[0].color, isNull);
    expect(camadas[1].color, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reforça traços e brilho sem perder o cache de pintura', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SixImagemCanetinha(
              assetContorno: _assetContorno,
              assetAcento: _assetAcento,
              largura: 120,
              altura: 120,
              gradienteContorno: const LinearGradient(
                colors: <Color>[Color(0xFF10D9F0), Color(0xFF145BFF)],
              ),
              gradienteAcento: const LinearGradient(
                colors: <Color>[Color(0xFF145BFF), Color(0xFF5A20FF)],
              ),
              reforcoContorno: 0.7,
              reforcoAcento: 0.8,
              opacidadeBrilho: 0.5,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('six-canetinha-brilho')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('six-canetinha-contorno-reforco'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('six-canetinha-acento-reforco')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SixImagemCanetinha),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<Image>(
            find.descendant(
              of: find.byType(SixImagemCanetinha),
              matching: find.byType(Image),
            ),
          )
          .length,
      greaterThan(2),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpImagem(
  WidgetTester tester, {
  required Brightness brightness,
  required Color corContorno,
  required Color corPrimaria,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corPrimaria,
          brightness: brightness,
        ).copyWith(primary: corPrimaria, onSurface: corContorno),
      ),
      home: const Scaffold(
        body: Center(
          child: SixImagemCanetinha(
            assetContorno: _assetContorno,
            assetAcento: _assetAcento,
            largura: 120,
            altura: 120,
            rotuloSemantico: 'Pagamento recebido',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectCamadas(
  WidgetTester tester, {
  required Color corContorno,
  required Color corPrimaria,
}) {
  final Finder finder = find.descendant(
    of: find.byType(SixImagemCanetinha),
    matching: find.byType(Image),
  );
  final List<Image> camadas = tester.widgetList<Image>(finder).toList();

  expect(camadas, hasLength(2));
  expect(camadas[0].color, corContorno);
  expect(camadas[1].color, corPrimaria);
  expect(camadas[0].colorBlendMode, BlendMode.srcIn);
  expect(camadas[1].colorBlendMode, BlendMode.srcIn);
  expect(camadas[0].excludeFromSemantics, isTrue);
  expect(camadas[1].excludeFromSemantics, isTrue);
  expect(
    find.descendant(
      of: find.byType(SixImagemCanetinha),
      matching: find.byType(Stack),
    ),
    findsOneWidget,
  );
}
