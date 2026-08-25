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
