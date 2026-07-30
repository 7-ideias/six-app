import 'package:sixpos/data/models/operational_procedure_models.dart';

class ProcedureResolution {
  const ProcedureResolution({
    required this.operationPoint,
    required this.matchingProcedures,
    required this.triggerByProcedureId,
  });

  final ProcedureOperationPoint operationPoint;
  final List<OperationalProcedure> matchingProcedures;
  final Map<String, ProcedureTrigger> triggerByProcedureId;

  bool get hasProcedures => matchingProcedures.isNotEmpty;
  bool get hasInformativeProcedures => matchingProcedures.any(
    (OperationalProcedure procedure) =>
        triggerByProcedureId[procedure.id]?.enforcementMode ==
        ProcedureEnforcementMode.informative,
  );
  bool get hasRecommendedProcedures => matchingProcedures.any(
    (OperationalProcedure procedure) =>
        triggerByProcedureId[procedure.id]?.enforcementMode ==
        ProcedureEnforcementMode.recommended,
  );
  bool get hasRequiredProcedures => matchingProcedures.any(
    (OperationalProcedure procedure) =>
        triggerByProcedureId[procedure.id]?.enforcementMode ==
        ProcedureEnforcementMode.required,
  );
}

class OperationalProcedureResolver {
  const OperationalProcedureResolver();

  ProcedureResolution resolve({
    required ProcedureOperationPoint operationPoint,
    required List<OperationalProcedure> procedures,
  }) {
    final Map<String, _ResolvedProcedure> byProcedureId =
        <String, _ResolvedProcedure>{};

    for (final OperationalProcedure procedure in procedures) {
      if (!procedure.isActive) continue;

      for (final ProcedureTrigger trigger in procedure.triggers) {
        if (!_matches(operationPoint, trigger)) continue;
        final _ResolvedProcedure resolved = _ResolvedProcedure(
          procedure: procedure,
          trigger: trigger,
        );
        final _ResolvedProcedure? current = byProcedureId[procedure.id];
        if (current == null || _compareResolved(resolved, current) < 0) {
          byProcedureId[procedure.id] = resolved;
        }
      }
    }

    final List<_ResolvedProcedure> resolved =
        byProcedureId.values.toList()..sort(_compareResolved);

    return ProcedureResolution(
      operationPoint: operationPoint,
      matchingProcedures: resolved
          .map((_ResolvedProcedure item) => item.procedure)
          .toList(growable: false),
      triggerByProcedureId: <String, ProcedureTrigger>{
        for (final _ResolvedProcedure item in resolved)
          item.procedure.id: item.trigger,
      },
    );
  }

  bool _matches(
    ProcedureOperationPoint operationPoint,
    ProcedureTrigger trigger,
  ) {
    return trigger.enabled &&
        trigger.activationMode == ProcedureTriggerActivationMode.automatic &&
        trigger.effectiveOperationPoint == operationPoint;
  }

  int _compareResolved(_ResolvedProcedure left, _ResolvedProcedure right) {
    final int enforcement = _enforcementRank(
      left.trigger.enforcementMode,
    ).compareTo(_enforcementRank(right.trigger.enforcementMode));
    if (enforcement != 0) return enforcement;

    final int order = left.trigger.order.compareTo(right.trigger.order);
    if (order != 0) return order;

    return left.procedure.id.compareTo(right.procedure.id);
  }

  int _enforcementRank(ProcedureEnforcementMode mode) {
    return switch (mode) {
      ProcedureEnforcementMode.required => 0,
      ProcedureEnforcementMode.recommended => 1,
      ProcedureEnforcementMode.informative => 2,
    };
  }
}

class _ResolvedProcedure {
  const _ResolvedProcedure({required this.procedure, required this.trigger});

  final OperationalProcedure procedure;
  final ProcedureTrigger trigger;
}
