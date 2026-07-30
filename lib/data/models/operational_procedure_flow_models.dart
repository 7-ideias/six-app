import 'package:sixpos/data/models/operational_procedure_models.dart';

enum ProcedureExecutionMode { demonstration, operational }

enum ProcedureFlowOutcome { continueOperation, cancelled, skipped, error }

class ProcedureExecutionConfiguration {
  const ProcedureExecutionConfiguration({
    this.mode = ProcedureExecutionMode.demonstration,
    this.operationPoint,
    this.enforcementMode = ProcedureEnforcementMode.informative,
    this.procedureIndex = 1,
    this.totalProcedures = 1,
  });

  final ProcedureExecutionMode mode;
  final ProcedureOperationPoint? operationPoint;
  final ProcedureEnforcementMode enforcementMode;
  final int procedureIndex;
  final int totalProcedures;

  bool get isOperational => mode == ProcedureExecutionMode.operational;
  bool get isDemonstration => mode == ProcedureExecutionMode.demonstration;
  bool get allowSkip => enforcementMode != ProcedureEnforcementMode.required;

  ProcedureExecutionConfiguration copyWith({
    ProcedureExecutionMode? mode,
    ProcedureOperationPoint? operationPoint,
    ProcedureEnforcementMode? enforcementMode,
    int? procedureIndex,
    int? totalProcedures,
  }) {
    return ProcedureExecutionConfiguration(
      mode: mode ?? this.mode,
      operationPoint: operationPoint ?? this.operationPoint,
      enforcementMode: enforcementMode ?? this.enforcementMode,
      procedureIndex: procedureIndex ?? this.procedureIndex,
      totalProcedures: totalProcedures ?? this.totalProcedures,
    );
  }
}

class ProcedureFlowResult {
  const ProcedureFlowResult({
    required this.outcome,
    this.completedProcedureIds = const <String>[],
    this.skippedProcedureIds = const <String>[],
    this.errorMessage,
  });

  const ProcedureFlowResult.continueOperation({
    List<String> completedProcedureIds = const <String>[],
  }) : this(
         outcome: ProcedureFlowOutcome.continueOperation,
         completedProcedureIds: completedProcedureIds,
       );

  const ProcedureFlowResult.cancelled()
    : this(outcome: ProcedureFlowOutcome.cancelled);

  const ProcedureFlowResult.skipped({
    List<String> completedProcedureIds = const <String>[],
    List<String> skippedProcedureIds = const <String>[],
  }) : this(
         outcome: ProcedureFlowOutcome.skipped,
         completedProcedureIds: completedProcedureIds,
         skippedProcedureIds: skippedProcedureIds,
       );

  const ProcedureFlowResult.error(String message)
    : this(outcome: ProcedureFlowOutcome.error, errorMessage: message);

  final ProcedureFlowOutcome outcome;
  final List<String> completedProcedureIds;
  final List<String> skippedProcedureIds;
  final String? errorMessage;

  bool get shouldContinue =>
      outcome == ProcedureFlowOutcome.continueOperation ||
      outcome == ProcedureFlowOutcome.skipped;
}
