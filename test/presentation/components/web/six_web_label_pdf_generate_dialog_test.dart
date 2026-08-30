import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_label_pdf_generate_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows summary with focused navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: () async {});

    await tester.tap(find.text('Abrir geração'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('labels-generate-backdrop')), findsOneWidget);
    expect(find.text('Gerar PDF de etiquetas?'), findsOneWidget);
    expect(find.text('modelo 60x30'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Gerar PDF'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps dialog busy during processing and transitions to success',
    (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      bool? result;
      int calls = 0;

      await _pumpHarness(
        tester,
        onConfirm: () {
          calls += 1;
          return completer.future;
        },
        onResult: (bool value) => result = value,
      );

      await tester.tap(find.text('Abrir geração'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('labels-generate-confirm')));
      await tester.pump();

      expect(calls, 1);
      expect(find.text('Gerando PDF...'), findsOneWidget);

      await tester.tap(find.byKey(const Key('labels-generate-confirm')));
      await tester.pump();
      expect(calls, 1);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('PDF pronto para download'), findsOneWidget);
      expect(
        find.text(
          'A geração foi concluída e o arquivo foi enviado para o navegador.',
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Gerar PDF de etiquetas?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows recoverable error and allows retry or back', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    bool? result;

    await _pumpHarness(
      tester,
      onConfirm: () async {
        calls += 1;
        throw Exception('Falha ao gerar o PDF.');
      },
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir geração'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('labels-generate-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('labels-generate-error')), findsOneWidget);
    expect(find.text('Falha ao gerar o PDF.'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.byKey(const Key('labels-generate-confirm')));
    await tester.pumpAndSettle();
    expect(calls, 2);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.text('Gerar PDF de etiquetas?'), findsNothing);
  });

  testWidgets('closes on escape while interactive', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async {},
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir geração'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Gerar PDF de etiquetas?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores escape while processing', (WidgetTester tester) async {
    final Completer<void> completer = Completer<void>();
    bool? result;

    await _pumpHarness(
      tester,
      onConfirm: () => completer.future,
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir geração'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('labels-generate-confirm')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.text('Gerando PDF...'), findsOneWidget);
    expect(result, isNull);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function() onConfirm,
  ValueChanged<bool>? onResult,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      theme: WebThemeTokens.applyTo(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.light,
          ),
        ),
      ),
      darkTheme: WebThemeTokens.applyTo(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
          ),
        ),
      ),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder:
              (BuildContext context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    final bool result = await showSixWebLabelPdfGenerateDialog(
                      context: context,
                      templateName: 'modelo 60x30',
                      productCount: 4,
                      totalLabels: 12,
                      estimatedPages: 2,
                      onConfirm: onConfirm,
                    );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir geração'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
