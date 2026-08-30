import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_pdv_clear_sale_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  testWidgets('shows operational summary with focused backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: () async {});

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pdv-clear-sale-backdrop')), findsOneWidget);
    expect(find.text('Limpar venda atual?'), findsOneWidget);
    expect(find.text('Marina Oliveira'), findsOneWidget);
    expect(find.text('R\$ 189,90'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Limpar venda'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes with escape while interactive', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async {},
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Limpar venda atual?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps dialog open while processing and ignores escape', (
    WidgetTester tester,
  ) async {
    final Completer<void> confirmation = Completer<void>();
    bool? result;

    await _pumpHarness(
      tester,
      onConfirm: () => confirmation.future,
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pdv-clear-sale-confirm')));
    await tester.pump();

    expect(find.byKey(const Key('pdv-clear-sale-processing')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key('pdv-clear-sale-processing')), findsOneWidget);
    expect(result, isNull);

    confirmation.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows recoverable error and allows retrying', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    final Completer<void> retryConfirmation = Completer<void>();
    bool? result;

    await _pumpHarness(
      tester,
      onConfirm: () {
        calls += 1;
        if (calls == 1) {
          throw StateError('simulated');
        }
        return retryConfirmation.future;
      },
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pdv-clear-sale-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pdv-clear-sale-error')), findsOneWidget);
    expect(
      find.text(
        'Não foi possível limpar a venda agora. Tente novamente em instantes.',
      ),
      findsOneWidget,
    );
    expect(calls, 1);

    await tester.tap(find.byKey(const Key('pdv-clear-sale-confirm')));
    await tester.pump();
    expect(find.byKey(const Key('pdv-clear-sale-processing')), findsOneWidget);
    expect(calls, 2);

    retryConfirmation.complete();
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
      theme: WebThemeTokens.applyTo(ThemeData.light(useMaterial3: true)),
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
                    final bool result = await showSixWebPdvClearSaleDialog(
                      context: context,
                      itemCount: 3,
                      totalLabel: 'R\$ 189,90',
                      customerLabel: 'Marina Oliveira',
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
