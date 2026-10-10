/// Competência é um período contábil (mês/ano), sem dia significativo.
/// O contrato legado permanece DateTime com o primeiro dia do mês.
abstract final class CompetenciaFinanceira {
  static DateTime normalizar(DateTime data) => DateTime(data.year, data.month);

  static String formatar(DateTime data) =>
      '${data.month.toString().padLeft(2, '0')}/${data.year.toString().padLeft(4, '0')}';
}
