import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_presenter.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_resolver.dart';

abstract interface class OperationalProcedureRuntimeRepository {
  Future<List<OperationalProcedure>> fetchProcedures();
}

class OperationalProcedureFlowController {
  const OperationalProcedureFlowController({
    required OperationalProcedureRuntimeRepository repository,
    required OperationalProcedurePresenter presenter,
    OperationalProcedureResolver resolver =
        const OperationalProcedureResolver(),
  }) : _repository = repository,
       _presenter = presenter,
       _resolver = resolver;

  final OperationalProcedureRuntimeRepository _repository;
  final OperationalProcedurePresenter _presenter;
  final OperationalProcedureResolver _resolver;

  Future<ProcedureFlowResult> execute({
    required ProcedureOperationPoint operationPoint,
  }) async {
    try {
      final List<OperationalProcedure> procedures = await _repository
          .fetchProcedures();
      final ProcedureResolution resolution = _resolver.resolve(
        operationPoint: operationPoint,
        procedures: procedures,
      );

      if (!resolution.hasProcedures) {
        return const ProcedureFlowResult.continueOperation();
      }

      final List<String> completed = <String>[];
      final List<String> skipped = <String>[];
      final List<String> executionIds = <String>[];
      final int total = resolution.matchingProcedures.length;

      for (int index = 0; index < total; index++) {
        final OperationalProcedure procedure =
            resolution.matchingProcedures[index];
        final ProcedureTrigger trigger =
            resolution.triggerByProcedureId[procedure.id]!;
        final ProcedureExecutionConfiguration configuration =
            ProcedureExecutionConfiguration(
              mode: ProcedureExecutionMode.operational,
              operationPoint: operationPoint,
              enforcementMode: trigger.enforcementMode,
              procedureIndex: index + 1,
              totalProcedures: total,
            );

        final ProcedurePresentationResult presentation = await _presenter
            .present(
              procedure: procedure,
              configuration: configuration,
              currentIndex: index + 1,
              total: total,
            );

        switch (presentation.outcome) {
          case ProcedurePresentationOutcome.completed:
            final String? id = presentation.completedProcedureId;
            if (id != null) completed.add(id);
            final String? completedExecutionId = presentation.executionId;
            if (completedExecutionId != null) {
              executionIds.add(completedExecutionId);
            }
          case ProcedurePresentationOutcome.skipped:
            final String? id = presentation.skippedProcedureId;
            if (id != null) skipped.add(id);
            final String? skippedExecutionId = presentation.executionId;
            if (skippedExecutionId != null) {
              executionIds.add(skippedExecutionId);
            }
          case ProcedurePresentationOutcome.cancelled:
            return const ProcedureFlowResult.cancelled();
          case ProcedurePresentationOutcome.failed:
            return ProcedureFlowResult.error(
              presentation.error?.toString() ?? 'Procedure presentation failed',
            );
        }
      }

      if (skipped.isNotEmpty) {
        return ProcedureFlowResult.skipped(
          completedProcedureIds: completed,
          skippedProcedureIds: skipped,
          executionIds: executionIds,
        );
      }

      return ProcedureFlowResult.continueOperation(
        completedProcedureIds: completed,
        executionIds: executionIds,
      );
    } catch (error) {
      return ProcedureFlowResult.error(error.toString());
    }
  }
}
