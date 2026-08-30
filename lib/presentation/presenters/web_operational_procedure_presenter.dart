import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_presenter.dart';
import 'package:sixpos/presentation/screens/operational_procedure_execution_web_dialog.dart';

class WebOperationalProcedurePresenter
    implements OperationalProcedurePresenter {
  const WebOperationalProcedurePresenter({required this.context});

  final BuildContext context;

  @override
  Future<ProcedurePresentationResult> present({
    required OperationalProcedure procedure,
    required ProcedureExecutionConfiguration configuration,
    required int currentIndex,
    required int total,
  }) async {
    if (!context.mounted) {
      return const ProcedurePresentationResult.cancelled();
    }
    final ProcedureFlowResult result =
        await showDialog<ProcedureFlowResult>(
          context: context,
          barrierDismissible: false,
          builder: (_) => OperationalProcedureExecutionWebDialog(
            procedure: procedure,
            configuration: configuration.copyWith(
              procedureIndex: currentIndex,
              totalProcedures: total,
            ),
          ),
        ) ??
        const ProcedureFlowResult.cancelled();
    final String? executionId = result.executionIds.isEmpty
        ? null
        : result.executionIds.first;
    return switch (result.outcome) {
      ProcedureFlowOutcome.continueOperation =>
        ProcedurePresentationResult.completed(
          procedure.id,
          executionId: executionId,
        ),
      ProcedureFlowOutcome.skipped => ProcedurePresentationResult.skipped(
        procedure.id,
        executionId: executionId,
      ),
      ProcedureFlowOutcome.cancelled =>
        const ProcedurePresentationResult.cancelled(),
      ProcedureFlowOutcome.error => ProcedurePresentationResult.failed(
        result.errorMessage ?? 'Procedure execution failed',
      ),
    };
  }
}
