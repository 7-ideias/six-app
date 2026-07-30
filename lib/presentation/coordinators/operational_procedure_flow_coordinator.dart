import 'package:flutter/material.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_flow_controller.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_presenter.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_resolver.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/presenters/mobile_operational_procedure_presenter.dart';

typedef OperationalProcedureRunner =
    Future<ProcedureFlowResult> Function(
      BuildContext context,
      OperationalProcedure procedure,
      ProcedureExecutionConfiguration configuration,
    );

const OperationalProcedureRuntimeMockScenario
defaultSaleStartRuntimeMockScenario =
    OperationalProcedureRuntimeMockScenario.required;

class OperationalProcedureFlowCoordinator {
  OperationalProcedureFlowCoordinator({
    OperationalProcedureResolver resolver =
        const OperationalProcedureResolver(),
    OperationalProcedureMockDataSource dataSource =
        const OperationalProcedureMockDataSource(
          delay: Duration.zero,
          runtimeScenario: defaultSaleStartRuntimeMockScenario,
        ),
    OperationalProcedureRunner? runner,
  }) : _resolver = resolver,
       _dataSource = dataSource,
       _runner = runner;

  final OperationalProcedureResolver _resolver;
  final OperationalProcedureMockDataSource _dataSource;
  final OperationalProcedureRunner? _runner;

  Future<ProcedureFlowResult> execute({
    required BuildContext context,
    required ProcedureOperationPoint operationPoint,
  }) async {
    final OperationalProcedurePresenter presenter =
        _runner == null
            ? MobileOperationalProcedurePresenter(context: context)
            : _RunnerOperationalProcedurePresenter(
              context: context,
              runner: _runner,
            );
    final OperationalProcedureFlowController controller =
        OperationalProcedureFlowController(
          repository: _MockRuntimeRepository(_dataSource),
          presenter: presenter,
          resolver: _resolver,
        );

    final ProcedureFlowResult result = await controller.execute(
      operationPoint: operationPoint,
    );

    if (result.outcome == ProcedureFlowOutcome.error && context.mounted) {
      debugPrint(
        '[OperationalProcedureFlowCoordinator] ${result.errorMessage}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'procedimentos.operationalLoadError',
              fallback: 'Não foi possível carregar os procedimentos.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return result;
  }
}

class _MockRuntimeRepository implements OperationalProcedureRuntimeRepository {
  const _MockRuntimeRepository(this._dataSource);

  final OperationalProcedureMockDataSource _dataSource;

  @override
  Future<List<OperationalProcedure>> fetchProcedures() async {
    final OperationalProcedureSummary summary =
        await _dataSource.fetchProcedures();
    return summary.procedures;
  }
}

class _RunnerOperationalProcedurePresenter
    implements OperationalProcedurePresenter {
  const _RunnerOperationalProcedurePresenter({
    required this.context,
    required this.runner,
  });

  final BuildContext context;
  final OperationalProcedureRunner runner;

  @override
  Future<ProcedurePresentationResult> present({
    required OperationalProcedure procedure,
    required ProcedureExecutionConfiguration configuration,
    required int currentIndex,
    required int total,
  }) async {
    final ProcedureFlowResult result = await runner(
      context,
      procedure,
      configuration.copyWith(
        procedureIndex: currentIndex,
        totalProcedures: total,
      ),
    );
    return switch (result.outcome) {
      ProcedureFlowOutcome.continueOperation =>
        ProcedurePresentationResult.completed(procedure.id),
      ProcedureFlowOutcome.skipped => ProcedurePresentationResult.skipped(
        procedure.id,
      ),
      ProcedureFlowOutcome.cancelled =>
        const ProcedurePresentationResult.cancelled(),
      ProcedureFlowOutcome.error => ProcedurePresentationResult.failed(
        result.errorMessage ?? 'Procedure execution failed',
      ),
    };
  }
}
