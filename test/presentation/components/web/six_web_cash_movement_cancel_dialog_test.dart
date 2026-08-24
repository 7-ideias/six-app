import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_cash_movement_cancel_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows summary with blurred navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: () async {});

    await tester.tap(find.text('Abrir cancelamento'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar movimentação?'), findsOneWidget);
    expect(find.text('Suprimento'), findsOneWidget);
    expect(find.text('Pix'), findsOneWidget);
    expect(find.text('R\$ 250,50'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks escape during processing and transitions to success', (
    WidgetTester tester,
  ) async {
    final Completer<void> completer = Completer<void>();
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () => completer.future,
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir cancelamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar operação'));
    await tester.pump();

    expect(find.text('Cancelando...'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(result, isNull);
    expect(find.text('Cancelar movimentação?'), findsOneWidget);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Movimentação cancelada'), findsOneWidget);
    expect(
      find.text(
        'O histórico do caixa foi atualizado e a operação não seguirá ativa na sessão atual.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Cancelar movimentação?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows recoverable error and allows retry', (
    WidgetTester tester,
  ) async {
    int attempts = 0;
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async {
        attempts += 1;
        if (attempts == 1) {
          throw StateError('linked future receipt');
        }
      },
      errorMessageBuilder:
          (_) =>
              'Esta movimentação possui vínculo com recebimentos ou lançamentos futuros e precisa permanecer registrada no histórico financeiro.',
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir cancelamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar operação'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Esta movimentação possui vínculo com recebimentos ou lançamentos futuros e precisa permanecer registrada no histórico financeiro.',
      ),
      findsOneWidget,
    );
    expect(result, isNull);

    await tester.tap(find.text('Cancelar operação'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes on escape while in review state', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async {},
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir cancelamento'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Cancelar movimentação?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function() onConfirm,
  String Function(Object error)? errorMessageBuilder,
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
          builder:
              (BuildContext context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    final bool result =
                        await showSixWebCashMovementCancelDialog(
                          context: context,
                          operationLabel: 'Suprimento',
                          paymentMethodLabel: 'Pix',
                          amountLabel: 'R\$ 250,50',
                          onConfirm: onConfirm,
                          errorMessageBuilder:
                              errorMessageBuilder ??
                              (_) => 'Falha ao cancelar movimentação.',
                        );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir cancelamento'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
