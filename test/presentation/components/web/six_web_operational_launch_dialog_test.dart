import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/presentation/components/web/six_web_operational_launch_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows focused modal and advances to review summary', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: (_) async {});

    await tester.tap(find.text('Abrir lançamento'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar lançamento operacional'), findsOneWidget);
    expect(find.text('Caixa 1'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await _fillRequiredFields(tester);
    await tester.tap(find.text('Revisar lançamento'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar lançamento operacional?'), findsOneWidget);
    expect(find.text('Sangria'), findsWidgets);
    expect(find.text('R\$ 150,00'), findsOneWidget);
    expect(find.text('Resumo pronto para confirmação.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps dialog busy during processing and transitions to success',
    (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      bool? result;
      await _pumpHarness(
        tester,
        onConfirm: (_) => completer.future,
        onResult: (bool value) => result = value,
      );

      await tester.tap(find.text('Abrir lançamento'));
      await tester.pumpAndSettle();
      await _fillRequiredFields(tester);
      await tester.tap(find.text('Revisar lançamento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar movimentação'));
      await tester.pump();

      expect(find.text('Registrando...'), findsOneWidget);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('Movimentação registrada com sucesso'), findsOneWidget);
      expect(
        find.text('O lançamento já aparece no histórico e no resumo do caixa.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Registrar lançamento operacional'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows recoverable error and allows returning to edit mode', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: (_) async => throw StateError('backend unavailable'),
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir lançamento'));
    await tester.pumpAndSettle();
    await _fillRequiredFields(tester);
    await tester.tap(find.text('Revisar lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar movimentação'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível registrar a movimentação. Verifique os dados e tente novamente.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar lançamento operacional'), findsOneWidget);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'closes on escape in interactive state and ignores escape while processing',
    (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      bool? result;
      await _pumpHarness(
        tester,
        onConfirm: (_) => completer.future,
        onResult: (bool value) => result = value,
      );

      await tester.tap(find.text('Abrir lançamento'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(result, isFalse);

      await tester.tap(find.text('Abrir lançamento'));
      await tester.pumpAndSettle();
      await _fillRequiredFields(tester);
      await tester.tap(find.text('Revisar lançamento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar movimentação'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Registrando...'), findsOneWidget);
      expect(result, isFalse);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function(SixWebOperationalLaunchSubmission submission)
  onConfirm,
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
                    final bool result = await showSixWebOperationalLaunchDialog(
                      context: context,
                      cashDeskName: 'Caixa 1',
                      operationTypes: <OperacaoCaixaTipo>[
                        OperacaoCaixaTipo.suprimento,
                        OperacaoCaixaTipo.sangria,
                      ],
                      relatedTypes: <TiposRecebimento>[
                        TiposRecebimento(
                          codigoTipo: 'tipo1',
                          descricaoExibicao: 'Dinheiro',
                          naturezaRecebimento: 'imediato',
                          aceitaParcelamento: false,
                          ativo: true,
                          exigeCliente: false,
                          ordemExibicao: 0,
                          corHex: '#22C55E',
                          icone: 'payments',
                        ),
                      ],
                      operationLabel: (OperacaoCaixaTipo tipo) {
                        switch (tipo) {
                          case OperacaoCaixaTipo.suprimento:
                            return 'Suprimento';
                          case OperacaoCaixaTipo.sangria:
                            return 'Sangria';
                          default:
                            return tipo.name;
                        }
                      },
                      operationIcon: (OperacaoCaixaTipo tipo) {
                        switch (tipo) {
                          case OperacaoCaixaTipo.suprimento:
                            return Icons.add_circle_outline_rounded;
                          case OperacaoCaixaTipo.sangria:
                            return Icons.remove_circle_outline_rounded;
                          default:
                            return Icons.tune_rounded;
                        }
                      },
                      relatedTypeLabel:
                          (TiposRecebimento tipo) => tipo.descricaoExibicao,
                      currencySymbol: 'R\$',
                      formatCurrency:
                          (double value) =>
                              'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
                      onConfirm: onConfirm,
                    );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir lançamento'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('operational-launch-type-field')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sangria').last);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const ValueKey<String>('operational-launch-amount-field')),
    '150,00',
  );
  await tester.pump();
}
