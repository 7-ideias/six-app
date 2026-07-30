import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_flow_controller.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns continue when there is no procedure', () async {
    final _FakePresenter presenter = _FakePresenter();
    final OperationalProcedureFlowController controller =
        OperationalProcedureFlowController(
          repository: const _FakeRepository(<OperationalProcedure>[]),
          presenter: presenter,
        );

    final ProcedureFlowResult result = await controller.execute(
      operationPoint: ProcedureOperationPoint.saleStartBefore,
    );

    expect(result.outcome, ProcedureFlowOutcome.continueOperation);
    expect(presenter.presentedIds, isEmpty);
  });

  test('completed informative procedure continues', () async {
    final ProcedureFlowResult result = await _execute(
      procedures: <OperationalProcedure>[
        _procedure(
          'info',
          enforcementMode: ProcedureEnforcementMode.informative,
        ),
      ],
      outcomes: <String, ProcedurePresentationResult>{
        'info': const ProcedurePresentationResult.completed('info'),
      },
    );

    expect(result.outcome, ProcedureFlowOutcome.continueOperation);
    expect(result.completedProcedureIds, <String>['info']);
  });

  test('completed recommended procedure continues', () async {
    final ProcedureFlowResult result = await _execute(
      procedures: <OperationalProcedure>[
        _procedure(
          'recommended',
          enforcementMode: ProcedureEnforcementMode.recommended,
        ),
      ],
      outcomes: <String, ProcedurePresentationResult>{
        'recommended': const ProcedurePresentationResult.completed(
          'recommended',
        ),
      },
    );

    expect(result.outcome, ProcedureFlowOutcome.continueOperation);
    expect(result.completedProcedureIds, <String>['recommended']);
  });

  test('skipped recommended procedure still allows operation', () async {
    final ProcedureFlowResult result = await _execute(
      procedures: <OperationalProcedure>[
        _procedure(
          'recommended',
          enforcementMode: ProcedureEnforcementMode.recommended,
        ),
      ],
      outcomes: <String, ProcedurePresentationResult>{
        'recommended': const ProcedurePresentationResult.skipped('recommended'),
      },
    );

    expect(result.outcome, ProcedureFlowOutcome.skipped);
    expect(result.shouldContinue, true);
    expect(result.skippedProcedureIds, <String>['recommended']);
  });

  test('completed required procedure allows operation', () async {
    final ProcedureFlowResult result = await _execute(
      procedures: <OperationalProcedure>[_procedure('required')],
      outcomes: <String, ProcedurePresentationResult>{
        'required': const ProcedurePresentationResult.completed('required'),
      },
    );

    expect(result.outcome, ProcedureFlowOutcome.continueOperation);
    expect(result.completedProcedureIds, <String>['required']);
  });

  test('cancelled required procedure cancels operation', () async {
    final ProcedureFlowResult result = await _execute(
      procedures: <OperationalProcedure>[_procedure('required')],
      outcomes: <String, ProcedurePresentationResult>{
        'required': const ProcedurePresentationResult.cancelled(),
      },
    );

    expect(result.outcome, ProcedureFlowOutcome.cancelled);
    expect(result.shouldContinue, false);
  });

  test('multiple procedures execute in resolver order', () async {
    final _FakePresenter presenter = _FakePresenter(
      outcomes: <String, ProcedurePresentationResult>{
        'required': const ProcedurePresentationResult.completed('required'),
        'recommended': const ProcedurePresentationResult.skipped('recommended'),
        'info': const ProcedurePresentationResult.completed('info'),
      },
    );
    final OperationalProcedureFlowController controller =
        OperationalProcedureFlowController(
          repository: _FakeRepository(<OperationalProcedure>[
            _procedure(
              'info',
              enforcementMode: ProcedureEnforcementMode.informative,
            ),
            _procedure(
              'recommended',
              enforcementMode: ProcedureEnforcementMode.recommended,
            ),
            _procedure('required'),
          ]),
          presenter: presenter,
        );

    final ProcedureFlowResult result = await controller.execute(
      operationPoint: ProcedureOperationPoint.saleStartBefore,
    );

    expect(presenter.presentedIds, <String>['required', 'recommended', 'info']);
    expect(result.outcome, ProcedureFlowOutcome.skipped);
    expect(result.completedProcedureIds, <String>['required', 'info']);
    expect(result.skippedProcedureIds, <String>['recommended']);
  });

  test('cancellation interrupts the sequence', () async {
    final _FakePresenter presenter = _FakePresenter(
      outcomes: <String, ProcedurePresentationResult>{
        'required': const ProcedurePresentationResult.completed('required'),
        'recommended': const ProcedurePresentationResult.cancelled(),
        'info': const ProcedurePresentationResult.completed('info'),
      },
    );
    final OperationalProcedureFlowController controller =
        OperationalProcedureFlowController(
          repository: _FakeRepository(<OperationalProcedure>[
            _procedure('required'),
            _procedure(
              'recommended',
              enforcementMode: ProcedureEnforcementMode.recommended,
            ),
            _procedure(
              'info',
              enforcementMode: ProcedureEnforcementMode.informative,
            ),
          ]),
          presenter: presenter,
        );

    final ProcedureFlowResult result = await controller.execute(
      operationPoint: ProcedureOperationPoint.saleStartBefore,
    );

    expect(result.outcome, ProcedureFlowOutcome.cancelled);
    expect(presenter.presentedIds, <String>['required', 'recommended']);
  });

  test('presenter failure returns error', () async {
    final ProcedureFlowResult result = await _execute(
      procedures: <OperationalProcedure>[_procedure('required')],
      outcomes: <String, ProcedurePresentationResult>{
        'required': const ProcedurePresentationResult.failed('erro'),
      },
    );

    expect(result.outcome, ProcedureFlowOutcome.error);
    expect(result.errorMessage, 'erro');
  });
}

Future<ProcedureFlowResult> _execute({
  required List<OperationalProcedure> procedures,
  required Map<String, ProcedurePresentationResult> outcomes,
}) {
  final OperationalProcedureFlowController controller =
      OperationalProcedureFlowController(
        repository: _FakeRepository(procedures),
        presenter: _FakePresenter(outcomes: outcomes),
      );
  return controller.execute(
    operationPoint: ProcedureOperationPoint.saleStartBefore,
  );
}

class _FakeRepository implements OperationalProcedureRuntimeRepository {
  const _FakeRepository(this.procedures);

  final List<OperationalProcedure> procedures;

  @override
  Future<List<OperationalProcedure>> fetchProcedures() async => procedures;
}

class _FakePresenter implements OperationalProcedurePresenter {
  _FakePresenter({
    this.outcomes = const <String, ProcedurePresentationResult>{},
  });

  final Map<String, ProcedurePresentationResult> outcomes;
  final List<String> presentedIds = <String>[];

  @override
  Future<ProcedurePresentationResult> present({
    required OperationalProcedure procedure,
    required ProcedureExecutionConfiguration configuration,
    required int currentIndex,
    required int total,
  }) async {
    presentedIds.add(procedure.id);
    expect(configuration.procedureIndex, currentIndex);
    expect(configuration.totalProcedures, total);
    return outcomes[procedure.id] ??
        ProcedurePresentationResult.completed(procedure.id);
  }
}

OperationalProcedure _procedure(
  String id, {
  ProcedureEnforcementMode enforcementMode = ProcedureEnforcementMode.required,
}) {
  return OperationalProcedure(
    id: id,
    name: id,
    description: '',
    operationType: ProcedureOperationType.sale,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: enforcementMode == ProcedureEnforcementMode.required,
    triggers: <ProcedureTrigger>[
      ProcedureTrigger(
        id: '$id-trigger',
        operationPoint: ProcedureOperationPoint.saleStartBefore,
        operationType: ProcedureOperationType.sale,
        triggerMoment: ProcedureTriggerMoment.beforeStart,
        activationMode: ProcedureTriggerActivationMode.automatic,
        enforcementMode: enforcementMode,
        enabled: true,
        order: 1,
        createdAt: DateTime(2026, 7, 29),
        updatedAt: DateTime(2026, 7, 29),
      ),
    ],
    stages: const <ProcedureStage>[],
    createdAt: DateTime(2026, 7, 29),
    updatedAt: DateTime(2026, 7, 29),
  );
}
