import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/usuario_model.dart';

void main() {
  group('PreferenciasIndividuaisDoUsuarioModel', () {
    test('usa fallbacks compativeis para agenda financeira web ausente', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{},
      );

      expect(
        preferencias.agendaFinanceiraPeriodoWeb,
        AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
      );
      expect(
        preferencias.agendaFinanceiraTipoWeb,
        AgendaFinanceiraTipoWebPreferencia.todos,
      );
      expect(
        preferencias.agendaFinanceiraStatusWeb,
        AgendaFinanceiraStatusWebPreferencia.todos,
      );
      expect(preferencias.agendaFinanceiraTipoDePagamentoWeb, isEmpty);
    });

    test('serializa e desserializa preferencias da agenda financeira web', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'agendaFinanceiraPeriodoWeb': 'ESTE_MES',
          'agendaFinanceiraTipoWeb': 'RECEBER',
          'agendaFinanceiraStatusWeb': 'PAGO',
          'agendaFinanceiraTipoDePagamentoWeb': <String>[
            'tipo2',
            'tipo3',
            'tipo2',
          ],
        },
      );

      expect(
        preferencias.agendaFinanceiraPeriodoWeb,
        AgendaFinanceiraPeriodoWebPreferencia.esteMes,
      );
      expect(
        preferencias.agendaFinanceiraTipoWeb,
        AgendaFinanceiraTipoWebPreferencia.receber,
      );
      expect(
        preferencias.agendaFinanceiraStatusWeb,
        AgendaFinanceiraStatusWebPreferencia.pago,
      );
      expect(preferencias.agendaFinanceiraTipoDePagamentoWeb, <String>[
        'tipo2',
        'tipo3',
      ]);

      expect(
        preferencias.toJson(),
        containsPair('agendaFinanceiraPeriodoWeb', 'ESTE_MES'),
      );
      expect(
        preferencias.toJson(),
        containsPair('agendaFinanceiraTipoWeb', 'RECEBER'),
      );
      expect(
        preferencias.toJson(),
        containsPair('agendaFinanceiraStatusWeb', 'PAGO'),
      );
      expect(
        preferencias.toJson(),
        containsPair('agendaFinanceiraTipoDePagamentoWeb', <String>[
          'tipo2',
          'tipo3',
        ]),
      );
    });
  });
}
