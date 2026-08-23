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
      expect(filtros.tecnicoKeysSelecionadas, <String>['tecnico-1']);
      expect(filtros.statusKeysSelecionadas, <String>['id:3']);
      expect(
        filtros.statusPagamento,
        AtendimentosCriadosStatusPagamentoFiltro.emAberto,
      );
      expect(filtros.toJson(), <String, dynamic>{
        'busca': 'cliente teste',
        'dataInicio': '2026-08-01',
        'dataFim': '2026-08-09',
        'tecnicoKeys': <String>['tecnico-1'],
        'statusKeys': <String>['id:3'],
        'statusPagamento': 'EM_ABERTO',
      });
      expect(
        PreferenciasIndividuaisDoUsuarioModel.fromJson(
          const <String, dynamic>{},
        ).atendimentosCriadosFiltrosWeb.toJson(),
        isEmpty,
      );
    });

    test('serializa e desserializa filtros web de reservas do catálogo', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'catalogoReservasFiltrosWeb': <String, dynamic>{
            'status': <String>['CONFIRMADA', 'RECEBIDA', 'CONFIRMADA'],
            'periodo': 'PERSONALIZADO',
            'dataInicio': '2026-08-03',
            'dataFim': '2026-08-12',
          },
        },
      );

      final filtros = preferencias.catalogoReservasFiltrosWeb;

      expect(filtros.status, <String>['CONFIRMADA', 'RECEBIDA']);
      expect(
        filtros.periodo,
        CatalogoReservasPeriodoWebPreferencia.personalizado,
      );
      expect(filtros.dataInicio, DateTime(2026, 8, 3));
      expect(filtros.dataFim, DateTime(2026, 8, 12));
      expect(filtros.toJson(), <String, dynamic>{
        'status': <String>['CONFIRMADA', 'RECEBIDA'],
        'periodo': 'PERSONALIZADO',
        'dataInicio': '2026-08-03',
        'dataFim': '2026-08-12',
      });
      expect(
        PreferenciasIndividuaisDoUsuarioModel.fromJson(
          const <String, dynamic>{},
        ).catalogoReservasFiltrosWeb.toJson(),
        isEmpty,
      );
    });

    test('serializa e desserializa filtros web da consulta de vendas', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'consultaVendasFiltrosWeb': <String, dynamic>{
            'busca': 'joao',
            'periodo': 'PERSONALIZADO',
            'dataInicio': '2026-08-05',
            'dataFim': '2026-08-23',
            'statusFinanceiro': 'QUITADA',
            'statusDevolucao': 'PARCIAL',
            'valorMinimo': '100',
            'valorMaximo': '900',
            'ordenacao': 'MAIOR_VALOR',
            'tamanhoPagina': 50,
          },
        },
      );

      final filtros = preferencias.consultaVendasFiltrosWeb;

      expect(filtros.busca, 'joao');
      expect(
        filtros.periodo,
        ConsultaVendasPeriodoWebPreferencia.personalizado,
      );
      expect(filtros.dataInicio, DateTime(2026, 8, 5));
      expect(filtros.dataFim, DateTime(2026, 8, 23));
      expect(filtros.statusFinanceiro, 'QUITADA');
      expect(filtros.statusDevolucao, 'PARCIAL');
      expect(filtros.valorMinimo, '100');
      expect(filtros.valorMaximo, '900');
      expect(filtros.ordenacao, 'MAIOR_VALOR');
      expect(filtros.tamanhoPagina, 50);
      expect(filtros.toJson(), <String, dynamic>{
        'busca': 'joao',
        'periodo': 'PERSONALIZADO',
        'dataInicio': '2026-08-05',
        'dataFim': '2026-08-23',
        'statusFinanceiro': 'QUITADA',
        'statusDevolucao': 'PARCIAL',
        'valorMinimo': '100',
        'valorMaximo': '900',
        'ordenacao': 'MAIOR_VALOR',
        'tamanhoPagina': 50,
      });
      expect(
        PreferenciasIndividuaisDoUsuarioModel.fromJson(
          const <String, dynamic>{},
        ).consultaVendasFiltrosWeb.toJson(),
        isEmpty,
      );
    });

    test('mantem multiplos filtros web de atendimentos criados', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'atendimentosCriadosFiltrosWeb': <String, dynamic>{
            'tecnicoKeys': <String>['tecnico-1', 'tecnico-2'],
            'statusKeys': <String>['id:3', 'codigo:REPAIRING'],
          },
        },
      );

      final filtros = preferencias.atendimentosCriadosFiltrosWeb;

      expect(filtros.tecnicoKeysSelecionadas, <String>[
        'tecnico-1',
        'tecnico-2',
      ]);
      expect(filtros.statusKeysSelecionadas, <String>[
        'id:3',
        'codigo:REPAIRING',
      ]);
      expect(filtros.toJson(), <String, dynamic>{
        'tecnicoKeys': <String>['tecnico-1', 'tecnico-2'],
        'statusKeys': <String>['id:3', 'codigo:REPAIRING'],
      });
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
