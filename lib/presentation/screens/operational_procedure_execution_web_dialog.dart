import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_service.dart';
import 'package:sixpos/presentation/components/web/six_web_operational_procedure_execution_dialog.dart';

Future<ProcedureFlowResult?> showOperationalProcedureExecutionWebDialog({
  required BuildContext context,
  required OperationalProcedure procedure,
  required ProcedureExecutionConfiguration configuration,
  OperationalProcedureService? service,
}) {
  return showSixWebOperationalProcedureExecutionDialog(
    context: context,
    procedure: procedure,
    configuration: configuration,
    onSubmit: (OperationalProcedureExecutionSubmission submission) async {
      final OperationalProcedureService effectiveService =
          service ??
          OperationalProcedureService(
            localeTag: Localizations.localeOf(context).toLanguageTag(),
          );
      final result = await effectiveService.persistExecution(
        procedure: procedure,
        execution: submission.execution,
        configuration: configuration,
        status: submission.status,
        platform: ProcedurePlatform.web,
      );
      return switch (submission.status) {
        'CONCLUIDO' => ProcedureFlowResult.continueOperation(
          completedProcedureIds: <String>[procedure.id],
          executionIds: <String>[result.id],
        ),
        'IGNORADO' => ProcedureFlowResult.skipped(
          skippedProcedureIds: <String>[procedure.id],
          executionIds: <String>[result.id],
        ),
        'CANCELADO' => const ProcedureFlowResult.cancelled(),
        _ => ProcedureFlowResult.error('Unsupported procedure status'),
      };
    },
  );
}
