import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/consulta_vendas_models.dart';

void main() {
  group('ConsultaVendasFiltro', () {
    test('envia um ou mais vendedores como parametro repetido', () {
      final ConsultaVendasFiltro filtro = ConsultaVendasFiltro(
        dataInicial: DateTime(2026, 9, 1),
        dataFinal: DateTime(2026, 9, 4),
        idColaborador: 'legado',
        idsColaboradores: const <String>[
          'vendedor-1',
          ' vendedor-2 ',
          'vendedor-1',
          '',
        ],
      );

      final Uri uri = Uri.parse(
        'https://six.test/vendas',
      ).replace(queryParameters: filtro.toQueryParameters());

      expect(uri.queryParametersAll['idsColaboradores'], <String>[
        'vendedor-1',
        'vendedor-2',
      ]);
      expect(uri.queryParameters.containsKey('idColaborador'), isFalse);
    });

    test('preserva o parametro legado quando nao ha multisselecao', () {
      final ConsultaVendasFiltro filtro = ConsultaVendasFiltro(
        dataInicial: DateTime(2026, 9, 1),
        dataFinal: DateTime(2026, 9, 4),
        idColaborador: 'vendedor-legado',
      );

      expect(filtro.toQueryParameters()['idColaborador'], <String>[
        'vendedor-legado',
      ]);
      expect(
        filtro.toQueryParameters().containsKey('idsColaboradores'),
        isFalse,
      );
    });

    test('permite limpar os vendedores no copyWith', () {
      final ConsultaVendasFiltro filtro = ConsultaVendasFiltro(
        dataInicial: DateTime(2026, 9, 1),
        dataFinal: DateTime(2026, 9, 4),
        idsColaboradores: const <String>['vendedor-1'],
      );

      expect(
        filtro.copyWith(limparIdsColaboradores: true).idsColaboradores,
        isEmpty,
      );
    });
  });
}
