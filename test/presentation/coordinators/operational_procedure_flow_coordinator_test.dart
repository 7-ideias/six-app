import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';

void main() {
  testWidgets('returns continue immediately when there is no procedure', (
    tester,
  ) async {
    ProcedureFlowResult? result;
    await _pumpCoordinator(
      tester,
      runtimeScenario: OperationalProcedureRuntimeMockScenario.none,
      onResult: (ProcedureFlowResult value) => result = value,
    );

    await tester.tap(find.text('Executar'));
    await tester.pumpAndSettle();

    expect(result?.outcome, ProcedureFlowOutcome.continueOperation);
    expect(find.text('Antes de iniciar a venda'), findsNothing);
  });

  testWidgets('recommended procedure can be skipped and allows sale', (
    tester,
  ) async {
    ProcedureFlowResult? result;
    ProcedureExecutionConfiguration? receivedConfiguration;
    await _pumpCoordinator(
      tester,
      runtimeScenario: OperationalProcedureRuntimeMockScenario.recommended,
      runner: (
        BuildContext context,
        OperationalProcedure procedure,
        ProcedureExecutionConfiguration configuration,
      ) async {
        receivedConfiguration = configuration;
        return ProcedureFlowResult.skipped(
          skippedProcedureIds: <String>[procedure.id],
        );
      },
      onResult: (ProcedureFlowResult value) => result = value,
    );

    await tester.tap(find.text('Executar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(result?.outcome, ProcedureFlowOutcome.skipped);
    expect(result?.shouldContinue, true);
    expect(result?.skippedProcedureIds, contains('sale-start-recommended'));
    expect(
      receivedConfiguration?.enforcementMode,
      ProcedureEnforcementMode.recommended,
    );
  });

  testWidgets('required procedure accepts no as valid answer and continues', (
    tester,
  ) async {
    ProcedureFlowResult? result;
    await _pumpCoordinator(
      tester,
      runtimeScenario: OperationalProcedureRuntimeMockScenario.required,
      runner: (
        BuildContext context,
        OperationalProcedure procedure,
        ProcedureExecutionConfiguration configuration,
      ) async {
        return ProcedureFlowResult.continueOperation(
          completedProcedureIds: <String>[procedure.id],
        );
      },
      onResult: (ProcedureFlowResult value) => result = value,
    );

    await tester.tap(find.text('Executar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(result?.outcome, ProcedureFlowOutcome.continueOperation);
    expect(
      result?.completedProcedureIds,
      contains('sale-start-required-parking'),
    );
  });

  testWidgets('required procedure cancellation does not allow sale', (
    tester,
  ) async {
    ProcedureFlowResult? result;
    await _pumpCoordinator(
      tester,
      runtimeScenario: OperationalProcedureRuntimeMockScenario.required,
      runner: (
        BuildContext context,
        OperationalProcedure procedure,
        ProcedureExecutionConfiguration configuration,
      ) async {
        return const ProcedureFlowResult.cancelled();
      },
      onResult: (ProcedureFlowResult value) => result = value,
    );

    await tester.tap(find.text('Executar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(result?.outcome, ProcedureFlowOutcome.cancelled);
    expect(result?.shouldContinue, false);
  });

  testWidgets('multiple procedures run sequentially and stop on cancellation', (
    tester,
  ) async {
    ProcedureFlowResult? result;
    final List<String> executed = <String>[];
    await _pumpCoordinator(
      tester,
      runtimeScenario: OperationalProcedureRuntimeMockScenario.multiple,
      runner: (
        BuildContext context,
        OperationalProcedure procedure,
        ProcedureExecutionConfiguration configuration,
      ) async {
        executed.add(procedure.id);
        if (procedure.id == 'sale-start-recommended') {
          return const ProcedureFlowResult.cancelled();
        }
        return ProcedureFlowResult.continueOperation(
          completedProcedureIds: <String>[procedure.id],
        );
      },
      onResult: (ProcedureFlowResult value) => result = value,
    );

    await tester.tap(find.text('Executar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(executed, <String>[
      'sale-start-required-parking',
      'sale-start-recommended',
    ]);
    expect(result?.outcome, ProcedureFlowOutcome.cancelled);
  });

  test(
    'mobile sale entries dispatch sale.start.before before opening sale',
    () {
      final String operationSource =
          File(
            'lib/presentation/screens/operacao_mobile_screen.dart',
          ).readAsStringSync();
      final String homeSource =
          File(
            'lib/presentation/screens/home_page_mobile_screen.dart',
          ).readAsStringSync();

      expect(
        operationSource,
        contains('ProcedureOperationPoint.saleStartBefore'),
      );
      expect(operationSource, contains('_openNewSale()'));
      expect(homeSource, contains('ProcedureOperationPoint.saleStartBefore'));
      expect(homeSource, contains('_openNewSale()'));
    },
  );
}

Future<void> _pumpCoordinator(
  WidgetTester tester, {
  required OperationalProcedureRuntimeMockScenario runtimeScenario,
  OperationalProcedureRunner? runner,
  required ValueChanged<ProcedureFlowResult> onResult,
}) async {
  final OperationalProcedureFlowCoordinator coordinator =
      OperationalProcedureFlowCoordinator(
        dataSource: OperationalProcedureMockDataSource(
          delay: Duration.zero,
          runtimeScenario: runtimeScenario,
        ),
        runner: runner,
      );

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1100);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final ProcedureFlowResult result = await coordinator
                        .execute(
                          context: context,
                          operationPoint:
                              ProcedureOperationPoint.saleStartBefore,
                        );
                    onResult(result);
                  },
                  child: const Text('Executar'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
