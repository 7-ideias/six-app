import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_presenter.dart';
import 'package:sixpos/presentation/screens/operational_procedure_preview_mobile_screen.dart';

class MobileOperationalProcedurePresenter
    implements OperationalProcedurePresenter {
  const MobileOperationalProcedurePresenter({required this.context});

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
        await Navigator.of(context).push<ProcedureFlowResult>(
          MaterialPageRoute<ProcedureFlowResult>(
            builder:
                (_) => OperationalProcedurePreviewMobileScreen(
                  procedure: procedure,
                  configuration: configuration.copyWith(
                    procedureIndex: currentIndex,
                    totalProcedures: total,
                  ),
                ),
          ),
        ) ??
        const ProcedureFlowResult.cancelled();

    return _mapResult(procedure.id, result);
  }

  ProcedurePresentationResult _mapResult(
    String procedureId,
    ProcedureFlowResult result,
  ) {
    return switch (result.outcome) {
      ProcedureFlowOutcome.continueOperation =>
        ProcedurePresentationResult.completed(procedureId),
      ProcedureFlowOutcome.skipped => ProcedurePresentationResult.skipped(
        procedureId,
      ),
      ProcedureFlowOutcome.cancelled =>
        const ProcedurePresentationResult.cancelled(),
      ProcedureFlowOutcome.error => ProcedurePresentationResult.failed(
        result.errorMessage ?? 'Procedure execution failed',
      ),
    };
  }
}
