import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_cash_session_close_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows operational summary with focused navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: () async {});

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();

    expect(find.text('Encerrar sessão de caixa?'), findsOneWidget);
    expect(find.text('Caixa 1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('BRL 510,93'), findsOneWidget);
    expect(find.text('Resumo operacional disponível'), findsOneWidget);
    expect(find.text('Encerrar caixa'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps dialog open while processing and morphs into success', (
    WidgetTester tester,
  ) async {
    final Completer<void> closeCompleter = Completer<void>();
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () => closeCompleter.future,
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar caixa'));
    await tester.pump();

    expect(find.text('Encerrando...'), findsOneWidget);
    expect(find.text('Encerrar sessão de caixa?'), findsOneWidget);

    closeCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Caixa encerrado com sucesso'), findsOneWidget);
    expect(
      find.text('A sessão foi finalizada e permanece disponível no histórico.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Encerrar sessão de caixa?'), findsNothing);
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows recoverable error and allows returning safely', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async => throw StateError('backend unavailable'),
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar caixa'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível encerrar o caixa. Verifique sua conexão e tente novamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Encerrar caixa'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Encerrar sessão de caixa?'), findsNothing);
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
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: FilledButton(
              onPressed: () async {
                final bool result = await showSixWebCashSessionCloseDialog(
                  context: context,
                  cashDeskName: 'Caixa 1',
                  movementCount: 4,
                  expectedBalance: 'BRL 510,93',
                  onConfirm: onConfirm,
                );
                onResult?.call(result);
              },
              child: const Text('Abrir confirmação'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
