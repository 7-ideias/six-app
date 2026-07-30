import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';

abstract interface class OperationalProcedurePresenter {
  Future<ProcedurePresentationResult> present({
    required OperationalProcedure procedure,
    required ProcedureExecutionConfiguration configuration,
    required int currentIndex,
    required int total,
  });
}

enum ProcedurePresentationOutcome { completed, skipped, cancelled, failed }

class ProcedurePresentationResult {
  const ProcedurePresentationResult({
    required this.outcome,
    this.completedProcedureId,
    this.skippedProcedureId,
    this.error,
  });

  const ProcedurePresentationResult.completed(String procedureId)
    : this(
        outcome: ProcedurePresentationOutcome.completed,
        completedProcedureId: procedureId,
      );

  const ProcedurePresentationResult.skipped(String procedureId)
    : this(
        outcome: ProcedurePresentationOutcome.skipped,
        skippedProcedureId: procedureId,
      );

  const ProcedurePresentationResult.cancelled()
    : this(outcome: ProcedurePresentationOutcome.cancelled);

  const ProcedurePresentationResult.failed(Object error)
    : this(outcome: ProcedurePresentationOutcome.failed, error: error);

  final ProcedurePresentationOutcome outcome;
  final String? completedProcedureId;
  final String? skippedProcedureId;
  final Object? error;
}
