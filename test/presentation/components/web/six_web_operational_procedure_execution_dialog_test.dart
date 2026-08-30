import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/components/web/six_web_operational_procedure_execution_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
    'shows focused backdrop and operational context without overflow',
    (WidgetTester tester) async {
      await _pumpHarness(tester, onSubmit: (_) async => _continueResult());

      await tester.tap(find.text('Abrir procedimento'));
      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Atendimento antes da venda'), findsOneWidget);
      expect(
        find.text('As respostas e o horário serão salvos ao concluir.'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Etapa 1 de 1'), findsAtLeastNWidgets(1));
      expect(
        find.text('O cliente encontrou tudo o que procurava?'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('closes on escape while interactive', (
    WidgetTester tester,
  ) async {
    ProcedureFlowResult? result;
    await _pumpHarness(
      tester,
      onSubmit: (_) async => _continueResult(),
      onResult: (ProcedureFlowResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir procedimento'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Atendimento antes da venda'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'blocks escape during processing and transitions to success once',
    (WidgetTester tester) async {
      final Completer<ProcedureFlowResult> completer =
          Completer<ProcedureFlowResult>();
      int submitCount = 0;
      ProcedureFlowResult? result;
      await _pumpHarness(
        tester,
        onSubmit: (_) {
          submitCount++;
          return completer.future;
        },
        onResult: (ProcedureFlowResult? value) => result = value,
      );

      await tester.tap(find.text('Abrir procedimento'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sim'));
      await tester.tap(find.text('Sim'));
      await tester.pump();
      await tester.tap(find.text('Concluir'));
      await tester.pump();

      expect(submitCount, 1);
      expect(find.text('Salvando...'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Atendimento antes da venda'), findsOneWidget);

      completer.complete(_continueResult());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Procedimento concluído'), findsOneWidget);
      expect(
        find.text(
          'As respostas foram registradas e a operação pode continuar.',
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(result?.outcome, ProcedureFlowOutcome.continueOperation);
      expect(find.text('Atendimento antes da venda'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows recoverable error and allows retry', (
    WidgetTester tester,
  ) async {
    int attempts = 0;
    ProcedureFlowResult? result;
    await _pumpHarness(
      tester,
      onSubmit: (_) async {
        attempts++;
        if (attempts == 1) {
          throw StateError('backend unavailable');
        }
        return _continueResult();
      },
      onResult: (ProcedureFlowResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir procedimento'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sim'));
    await tester.tap(find.text('Sim'));
    await tester.pump();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível salvar as respostas. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Concluir'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Procedimento concluído'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(result?.outcome, ProcedureFlowOutcome.continueOperation);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required SixWebOperationalProcedureSubmit onSubmit,
  ValueChanged<ProcedureFlowResult?>? onResult,
}) async {
  tester.view.physicalSize = const Size(1180, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final OperationalProcedure procedure = _procedure();

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      theme: WebThemeTokens.applyTo(
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
                    final ProcedureFlowResult? dialogResult =
                        await showSixWebOperationalProcedureExecutionDialog(
                          context: context,
                          procedure: procedure,
                          configuration: const ProcedureExecutionConfiguration(
                            mode: ProcedureExecutionMode.operational,
                            operationPoint:
                                ProcedureOperationPoint.saleStartBefore,
                            enforcementMode:
                                ProcedureEnforcementMode.recommended,
                            procedureIndex: 1,
                            totalProcedures: 1,
                          ),
                          onSubmit: onSubmit,
                        );
                    onResult?.call(dialogResult);
                  },
                  child: const Text('Abrir procedimento'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

OperationalProcedure _procedure() {
  return OperationalProcedure(
    id: 'procedure-1',
    name: 'Atendimento antes da venda',
    description: '',
    operationType: ProcedureOperationType.sale,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: false,
    stages: const <ProcedureStage>[
      ProcedureStage(
        id: 'stage-1',
        title: 'Experiência do cliente',
        description:
            'Confirma a experiência do cliente antes de abrir a venda.',
        order: 1,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'item-1',
            title: 'O cliente encontrou tudo o que procurava?',
            guidance: 'Se a resposta for não, registre o que faltou.',
            responseType: ProcedureResponseType.yesNo,
            required: true,
            order: 1,
            configuration: ProcedureItemConfiguration(requireTextWhenNo: true),
          ),
        ],
      ),
    ],
    createdAt: DateTime(2026, 8, 30),
    updatedAt: DateTime(2026, 8, 30),
  );
}

ProcedureFlowResult _continueResult() {
  return const ProcedureFlowResult.continueOperation(
    completedProcedureIds: <String>['procedure-1'],
    executionIds: <String>['execution-1'],
  );
}
