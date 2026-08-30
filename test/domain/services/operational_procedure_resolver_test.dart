import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_resolver.dart';

void main() {
  group('ProcedureOperationPoint catalog', () {
    test('declares stable sale start before point', () {
      expect(ProcedureOperationPoint.saleStartBefore.id, 'sale.start.before');
      expect(
        ProcedureOperationPoint.saleStartBefore.operationType,
        ProcedureOperationType.sale,
      );
      expect(
        ProcedureOperationPoint.saleStartBefore.triggerMoment,
        ProcedureTriggerMoment.beforeStart,
      );
      expect(ProcedureOperationPoint.saleStartBefore.mobileAvailable, true);
      expect(ProcedureOperationPoint.saleStartBefore.webAvailable, true);
      expect(
        procedureOperationPointCatalog.publishedFor(ProcedurePlatform.mobile),
        <ProcedureOperationPoint>[
          ProcedureOperationPoint.saleStartBefore,
          ProcedureOperationPoint.technicalServiceStartBefore,
          ProcedureOperationPoint.cashRegisterStartBefore,
        ],
      );
      expect(
        procedureOperationPointCatalog.publishedFor(ProcedurePlatform.web),
        <ProcedureOperationPoint>[
          ProcedureOperationPoint.saleStartBefore,
          ProcedureOperationPoint.technicalServiceStartBefore,
          ProcedureOperationPoint.cashRegisterStartBefore,
        ],
      );
      expect(
        procedureOperationPointCatalog.isPublishedFor(
          ProcedureOperationPoint.saleStartBefore,
          ProcedurePlatform.mobile,
        ),
        true,
      );
    });
  });

  group('OperationalProcedureResolver', () {
    const OperationalProcedureResolver resolver =
        OperationalProcedureResolver();

    test('returns empty resolution when there are no procedures', () {
      final ProcedureResolution resolution = resolver.resolve(
        operationPoint: ProcedureOperationPoint.saleStartBefore,
        procedures: const <OperationalProcedure>[],
      );

      expect(resolution.hasProcedures, false);
      expect(resolution.matchingProcedures, isEmpty);
    });

    test(
      'ignores inactive procedures inactive triggers and manual triggers',
      () {
        final ProcedureResolution resolution = resolver.resolve(
          operationPoint: ProcedureOperationPoint.saleStartBefore,
          procedures: <OperationalProcedure>[
            _procedure('inactive-procedure', status: ProcedureStatus.inactive),
            _procedure('inactive-trigger', triggerEnabled: false),
            _procedure(
              'manual-trigger',
              activationMode: ProcedureTriggerActivationMode.manual,
            ),
          ],
        );

        expect(resolution.matchingProcedures, isEmpty);
      },
    );

    test('finds active automatic trigger by official operation point', () {
      final ProcedureResolution resolution = resolver.resolve(
        operationPoint: ProcedureOperationPoint.saleStartBefore,
        procedures: <OperationalProcedure>[_procedure('sale-start')],
      );

      expect(resolution.matchingProcedures.single.id, 'sale-start');
      expect(resolution.hasRequiredProcedures, true);
    });

    test(
      'does not duplicate same procedure with multiple matching triggers',
      () {
        final OperationalProcedure procedure = _procedure(
          'duplicated',
          triggers: <ProcedureTrigger>[
            _trigger('trigger-1', order: 2),
            _trigger('trigger-2', order: 1),
          ],
        );

        final ProcedureResolution resolution = resolver.resolve(
          operationPoint: ProcedureOperationPoint.saleStartBefore,
          procedures: <OperationalProcedure>[procedure],
        );

        expect(resolution.matchingProcedures, hasLength(1));
        expect(resolution.triggerByProcedureId['duplicated']?.id, 'trigger-2');
      },
    );

    test('orders required recommended and informative procedures', () {
      final ProcedureResolution resolution = resolver.resolve(
        operationPoint: ProcedureOperationPoint.saleStartBefore,
        procedures: <OperationalProcedure>[
          _procedure(
            'info',
            enforcementMode: ProcedureEnforcementMode.informative,
          ),
          _procedure(
            'recommended',
            enforcementMode: ProcedureEnforcementMode.recommended,
          ),
          _procedure('required'),
        ],
      );

      expect(
        resolution.matchingProcedures.map(
          (OperationalProcedure item) => item.id,
        ),
        <String>['required', 'recommended', 'info'],
      );
      expect(resolution.hasInformativeProcedures, true);
      expect(resolution.hasRecommendedProcedures, true);
      expect(resolution.hasRequiredProcedures, true);
    });
  });
}

OperationalProcedure _procedure(
  String id, {
  ProcedureStatus status = ProcedureStatus.active,
  bool triggerEnabled = true,
  ProcedureTriggerActivationMode activationMode =
      ProcedureTriggerActivationMode.automatic,
  ProcedureEnforcementMode enforcementMode = ProcedureEnforcementMode.required,
  List<ProcedureTrigger>? triggers,
}) {
  return OperationalProcedure(
    id: id,
    name: id,
    description: '',
    operationType: ProcedureOperationType.sale,
    moment: ProcedureMoment.beforeStart,
    status: status,
    required: enforcementMode == ProcedureEnforcementMode.required,
    triggers:
        triggers ??
        <ProcedureTrigger>[
          _trigger(
            '$id-trigger',
            enabled: triggerEnabled,
            activationMode: activationMode,
            enforcementMode: enforcementMode,
          ),
        ],
    stages: const <ProcedureStage>[],
    createdAt: DateTime(2026, 7, 29),
    updatedAt: DateTime(2026, 7, 29),
  );
}

ProcedureTrigger _trigger(
  String id, {
  int order = 1,
  bool enabled = true,
  ProcedureTriggerActivationMode activationMode =
      ProcedureTriggerActivationMode.automatic,
  ProcedureEnforcementMode enforcementMode = ProcedureEnforcementMode.required,
}) {
  return ProcedureTrigger(
    id: id,
    operationPoint: ProcedureOperationPoint.saleStartBefore,
    operationType: ProcedureOperationType.sale,
    triggerMoment: ProcedureTriggerMoment.beforeStart,
    activationMode: activationMode,
    enforcementMode: enforcementMode,
    enabled: enabled,
    order: order,
    createdAt: DateTime(2026, 7, 29),
    updatedAt: DateTime(2026, 7, 29),
  );
}
