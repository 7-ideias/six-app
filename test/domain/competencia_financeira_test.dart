import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/competencia_financeira.dart';

void main() {
  test('exibe competencia em MM/AAAA mesmo para registros antigos', () {
    expect(CompetenciaFinanceira.formatar(DateTime(2026, 10, 26)), '10/2026');
    expect(CompetenciaFinanceira.formatar(DateTime(2027, 1, 31)), '01/2027');
  });

  test('normaliza dia e hora sem alterar o mês ou ano', () {
    final competencia = CompetenciaFinanceira.normalizar(
      DateTime(2024, 2, 29, 23, 59),
    );
    expect(competencia, DateTime(2024, 2, 1));
    expect(CompetenciaFinanceira.formatar(competencia), '02/2024');
  });
}
