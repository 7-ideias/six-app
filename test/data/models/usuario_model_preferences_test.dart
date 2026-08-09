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

    test('serializa e desserializa filtros web de atendimentos criados', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'atendimentosCriadosFiltrosWeb': <String, dynamic>{
            'busca': 'cliente teste',
            'dataInicio': '2026-08-01',
            'dataFim': '2026-08-09',
            'tecnicoKey': 'tecnico-1',
            'statusKey': 'id:3',
            'statusPagamento': 'EM_ABERTO',
          },
        },
      );

      final filtros = preferencias.atendimentosCriadosFiltrosWeb;

      expect(filtros.busca, 'cliente teste');
      expect(filtros.dataInicio, DateTime(2026, 8, 1));
      expect(filtros.dataFim, DateTime(2026, 8, 9));
      expect(filtros.tecnicoKey, 'tecnico-1');
      expect(filtros.statusKey, 'id:3');
      expect(
        filtros.statusPagamento,
        AtendimentosCriadosStatusPagamentoFiltro.emAberto,
      );
      expect(filtros.toJson(), <String, dynamic>{
        'busca': 'cliente teste',
        'dataInicio': '2026-08-01',
        'dataFim': '2026-08-09',
        'tecnicoKey': 'tecnico-1',
        'statusKey': 'id:3',
        'statusPagamento': 'EM_ABERTO',
      });
      expect(
        PreferenciasIndividuaisDoUsuarioModel.fromJson(
          const <String, dynamic>{},
        ).atendimentosCriadosFiltrosWeb.toJson(),
        isEmpty,
      );
    });

    test('serializa e desserializa filtros mobile de atendimentos criados', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'atendimentosCriadosFiltrosMobile': <String, dynamic>{
            'busca': 'equipamento teste',
            'dataInicio': '2026-08-02',
            'dataFim': '2026-08-08',
            'tecnicoKey': 'tecnico-2',
            'statusKey': 'codigo:REPAIRING',
            'statusPagamento': 'LIQUIDADO',
          },
        },
      );

      final filtros = preferencias.atendimentosCriadosFiltrosMobile;

      expect(filtros.busca, 'equipamento teste');
      expect(filtros.dataInicio, DateTime(2026, 8, 2));
      expect(filtros.dataFim, DateTime(2026, 8, 8));
      expect(filtros.tecnicoKey, 'tecnico-2');
      expect(filtros.statusKey, 'codigo:REPAIRING');
      expect(
        filtros.statusPagamento,
        AtendimentosCriadosStatusPagamentoFiltro.liquidado,
      );
      expect(filtros.toJson(), <String, dynamic>{
        'busca': 'equipamento teste',
        'dataInicio': '2026-08-02',
        'dataFim': '2026-08-08',
        'tecnicoKey': 'tecnico-2',
        'statusKey': 'codigo:REPAIRING',
        'statusPagamento': 'LIQUIDADO',
      });
      expect(
        PreferenciasIndividuaisDoUsuarioModel.fromJson(
          const <String, dynamic>{},
        ).atendimentosCriadosFiltrosMobile.toJson(),
        isEmpty,
      );
    });
  });
}
