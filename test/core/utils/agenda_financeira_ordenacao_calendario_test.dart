import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/agenda_financeira_ordenacao_calendario.dart';

void main() {
  final lancamentos = <Map<String, dynamic>>[
    {'id': 'outubro', 'vencimento': '07/10/2026'},
    {'id': 'dezembro', 'vencimento': '01/12/2025'},
    {'id': 'janeiro', 'vencimento': '03/01/2027'},
    {'id': 'fevereiro', 'vencimento': '15/02/2026'},
  ];

  test('ordena por data real decrescente por padrao', () {
    final ordenados =
        AgendaFinanceiraOrdenacaoCalendario.ordenarPorVencimento(lancamentos);
    expect(
      ordenados.map((item) => item['id']).toList(),
      ['janeiro', 'outubro', 'fevereiro', 'dezembro'],
    );
    // A lista original nao pode ser modificada ao alternar a ordenacao.
    expect(lancamentos.first['id'], 'outubro');
  });

  test('permite alternar para ordem crescente', () {
    final ordenados = AgendaFinanceiraOrdenacaoCalendario.ordenarPorVencimento(
      lancamentos,
      decrescente: false,
    );
    expect(
      ordenados.map((item) => item['id']).toList(),
      ['dezembro', 'fevereiro', 'outubro', 'janeiro'],
    );
  });

  test('usa data ISO e preserva a ordem em datas iguais', () {
    final itens = <Map<String, dynamic>>[
      {'id': 'primeiro', 'vencimento': '07/10/2026'},
      {
        'id': 'segundo',
        'vencimento': '01/01/2025',
        'dataVencimento': '2026-10-07',
      },
      {'id': 'terceiro', 'vencimento': '08/10/2026'},
    ];
    final ordenados =
        AgendaFinanceiraOrdenacaoCalendario.ordenarPorVencimento(itens);
    expect(
      ordenados.map((item) => item['id']).toList(),
      ['terceiro', 'primeiro', 'segundo'],
    );
  });

  test('coloca datas ausentes ou invalidas ao final em ambos sentidos', () {
    final itens = <Map<String, dynamic>>[
      {'id': 'invalida', 'vencimento': '31/02/2026'},
      {'id': 'sem-data', 'vencimento': '-'},
      {'id': 'valida', 'vencimento': '07/10/2026'},
    ];
    for (final decrescente in [true, false]) {
      final ordenados =
          AgendaFinanceiraOrdenacaoCalendario.ordenarPorVencimento(
        itens,
        decrescente: decrescente,
      );
      expect(
        ordenados.map((item) => item['id']).toList(),
        ['valida', 'invalida', 'sem-data'],
      );
    }
  });
}
