import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_metadata.dart';

void main() {
  group('operational procedure trigger metadata', () {
    test('returns operation types and moments published for mobile', () {
      expect(publishedMobileOperationTypes(), <ProcedureOperationType>[
        ProcedureOperationType.sale,
        ProcedureOperationType.technicalService,
        ProcedureOperationType.cashRegister,
      ]);
      expect(
        publishedMobileMomentsForOperation(ProcedureOperationType.sale),
        <ProcedureTriggerMoment>[ProcedureTriggerMoment.beforeStart],
      );
      expect(ProcedureOperationPoint.saleStartBefore.id, 'sale.start.before');
    });

    test('returns valid moments by operation type', () {
      expect(
        triggerMomentsForOperation(ProcedureOperationType.sale),
        contains(ProcedureTriggerMoment.beforeFinish),
      );
      expect(
        triggerMomentsForOperation(ProcedureOperationType.delivery),
        isNot(contains(ProcedureTriggerMoment.beforeFinish)),
      );
      expect(
        triggerMomentsForOperation(ProcedureOperationType.customerRegistration),
        contains(ProcedureTriggerMoment.afterFinish),
      );
    });

    test('validates moment compatibility', () {
      expect(
        isTriggerMomentValid(
          ProcedureOperationType.cashRegister,
          ProcedureTriggerMoment.beforeFinish,
        ),
        isTrue,
      );
      expect(
        isTriggerMomentValid(
          ProcedureOperationType.delivery,
          ProcedureTriggerMoment.afterStart,
        ),
        isFalse,
      );
    });

    test('detects duplicates by context moment and activation mode', () {
      final ProcedureTrigger existing = _trigger(id: 'existing');
      final ProcedureTrigger duplicate = _trigger(id: 'new');
      final ProcedureTrigger differentMode = _trigger(
        id: 'manual',
        activationMode: ProcedureTriggerActivationMode.manual,
      );

      expect(
        hasDuplicateTrigger(<ProcedureTrigger>[existing], duplicate),
        true,
      );
      expect(
        hasDuplicateTrigger(<ProcedureTrigger>[existing], differentMode),
        false,
      );
      expect(
        hasDuplicateTrigger(
          <ProcedureTrigger>[existing],
          existing,
          ignoringId: existing.id,
        ),
        false,
      );
    });
  });
}

ProcedureTrigger _trigger({
  required String id,
  ProcedureTriggerActivationMode activationMode =
      ProcedureTriggerActivationMode.automatic,
}) {
  return ProcedureTrigger(
    id: id,
    operationType: ProcedureOperationType.sale,
    triggerMoment: ProcedureTriggerMoment.beforeFinish,
    activationMode: activationMode,
    enforcementMode: ProcedureEnforcementMode.required,
    enabled: true,
    order: 1,
    createdAt: DateTime(2026, 7, 29),
    updatedAt: DateTime(2026, 7, 29),
  );
}
