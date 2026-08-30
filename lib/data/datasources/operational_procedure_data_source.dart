import 'package:sixpos/data/models/operational_procedure_models.dart';

abstract class OperationalProcedureDataSource {
  Future<OperationalProcedureSummary> fetchProcedures({
    String idioma = 'pt-BR',
    bool somenteAtivos = false,
  });

  Future<OperationalProcedure> saveProcedure({
    required OperationalProcedure procedure,
    required String idioma,
    required bool isCreating,
  });
}
