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

    test('migra a agenda web legada e preserva o intervalo personalizado', () {
      final preferenciasLegadas =
          PreferenciasIndividuaisDoUsuarioModel.fromJson(
            const <String, dynamic>{
              'agendaFinanceiraPeriodoWeb': 'ESTE_MES',
              'agendaFinanceiraTipoWeb': 'PAGAR',
            },
          );
      expect(
        preferenciasLegadas.agendaFinanceiraFiltrosWeb.periodo,
        AgendaFinanceiraPeriodoWebPreferencia.esteMes,
      );
      expect(
        preferenciasLegadas.agendaFinanceiraFiltrosWeb.tipo,
        AgendaFinanceiraTipoWebPreferencia.pagar,
      );

      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'agendaFinanceiraPeriodoWeb': 'HOJE',
          'agendaFinanceiraFiltrosWeb': <String, dynamic>{
            'periodo': 'PERSONALIZADO',
            'dataInicio': '2026-08-05',
            'dataFim': '2026-08-23',
            'tipo': 'RECEBER',
            'status': 'PARCIAL',
            'tiposDePagamento': <String>['tipo2', 'tipo3'],
          },
        },
      );

      final filtros = preferencias.agendaFinanceiraFiltrosWeb;
      expect(
        filtros.periodo,
        AgendaFinanceiraPeriodoWebPreferencia.personalizado,
      );
      expect(filtros.dataInicio, DateTime(2026, 8, 5));
      expect(filtros.dataFim, DateTime(2026, 8, 23));
      expect(filtros.tipo, AgendaFinanceiraTipoWebPreferencia.receber);
      expect(filtros.status, AgendaFinanceiraStatusWebPreferencia.parcial);
      expect(filtros.tiposDePagamento, <String>['tipo2', 'tipo3']);
      expect(
        preferencias.agendaFinanceiraPeriodoWeb,
        AgendaFinanceiraPeriodoWebPreferencia.personalizado,
      );
      expect(
        preferencias.toJson()['agendaFinanceiraFiltrosWeb'],
        <String, dynamic>{
          'periodo': 'PERSONALIZADO',
          'dataInicio': '2026-08-05',
          'dataFim': '2026-08-23',
          'tipo': 'RECEBER',
          'status': 'PARCIAL',
          'tiposDePagamento': <String>['tipo2', 'tipo3'],
        },
      );
    });

    test('mantem filtros web e mobile da agenda independentes', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'agendaFinanceiraFiltrosWeb': <String, dynamic>{
            'periodo': 'ESTE_MES',
            'tipo': 'RECEBER',
          },
          'agendaFinanceiraFiltrosMobile': <String, dynamic>{
            'periodo': 'PROXIMO_MES',
            'tipo': 'PAGAR',
            'status': 'VENCIDO',
            'tiposDePagamento': <String>['tipo2'],
          },
        },
      );

      expect(
        preferencias.agendaFinanceiraFiltrosWeb.periodo,
        AgendaFinanceiraPeriodoWebPreferencia.esteMes,
      );
      expect(
        preferencias.agendaFinanceiraFiltrosMobile.periodo,
        AgendaFinanceiraPeriodoWebPreferencia.proximoMes,
      );
      expect(
        preferencias.agendaFinanceiraFiltrosMobile.tipo,
        AgendaFinanceiraTipoWebPreferencia.pagar,
      );
      expect(
        preferencias.agendaFinanceiraFiltrosMobile.status,
        AgendaFinanceiraStatusWebPreferencia.vencido,
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
            'idsVendedores': <String>[
              'vendedor-1',
              ' vendedor-2 ',
              'vendedor-1',
            ],
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
      expect(filtros.idsVendedores, <String>['vendedor-1', 'vendedor-2']);
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
        'idsVendedores': <String>['vendedor-1', 'vendedor-2'],
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

    test('serializa filtros mobile de vendas sem alterar os filtros web', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'consultaVendasFiltrosWeb': <String, dynamic>{
            'busca': 'web',
            'periodo': 'ULTIMOS_30_DIAS',
          },
          'consultaVendasFiltrosMobile': <String, dynamic>{
            'busca': 'mobile',
            'periodo': 'HOJE',
            'statusFinanceiro': 'EM_ABERTO',
            'idsVendedores': <String>['vendedor-3', 'vendedor-4'],
          },
        },
      );

      expect(preferencias.consultaVendasFiltrosWeb.busca, 'web');
      expect(preferencias.consultaVendasFiltrosMobile.busca, 'mobile');
      expect(
        preferencias.consultaVendasFiltrosMobile.periodo,
        ConsultaVendasPeriodoWebPreferencia.hoje,
      );
      expect(
        preferencias.consultaVendasFiltrosMobile.statusFinanceiro,
        'EM_ABERTO',
      );
      expect(preferencias.consultaVendasFiltrosMobile.idsVendedores, <String>[
        'vendedor-3',
        'vendedor-4',
      ]);
      expect(
        preferencias.toJson()['consultaVendasFiltrosMobile'],
        <String, dynamic>{
          'busca': 'mobile',
          'periodo': 'HOJE',
          'statusFinanceiro': 'EM_ABERTO',
          'idsVendedores': <String>['vendedor-3', 'vendedor-4'],
        },
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
            'tecnicoKeys': <String>['tecnico-2', 'tecnico-3'],
            'statusKeys': <String>['codigo:REPAIRING', 'codigo:WAITING_PART'],
            'statusPagamento': 'LIQUIDADO',
          },
        },
      );

      final filtros = preferencias.atendimentosCriadosFiltrosMobile;

      expect(filtros.busca, 'equipamento teste');
      expect(filtros.dataInicio, DateTime(2026, 8, 2));
      expect(filtros.dataFim, DateTime(2026, 8, 8));
      expect(filtros.tecnicoKeysSelecionadas, <String>[
        'tecnico-2',
        'tecnico-3',
      ]);
      expect(filtros.statusKeysSelecionadas, <String>[
        'codigo:REPAIRING',
        'codigo:WAITING_PART',
      ]);
      expect(
        filtros.statusPagamento,
        AtendimentosCriadosStatusPagamentoFiltro.liquidado,
      );
      expect(filtros.toJson(), <String, dynamic>{
        'busca': 'equipamento teste',
        'dataInicio': '2026-08-02',
        'dataFim': '2026-08-08',
        'tecnicoKeys': <String>['tecnico-2', 'tecnico-3'],
        'statusKeys': <String>['codigo:REPAIRING', 'codigo:WAITING_PART'],
        'statusPagamento': 'LIQUIDADO',
      });
      expect(
        PreferenciasIndividuaisDoUsuarioModel.fromJson(
          const <String, dynamic>{},
        ).atendimentosCriadosFiltrosMobile.toJson(),
        isEmpty,
      );
    });

    test('mantem compatibilidade com filtros mobile antigos', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'atendimentosCriadosFiltrosMobile': <String, dynamic>{
            'tecnicoKey': 'tecnico-legado',
            'statusKey': 'codigo:LEGACY_STATUS',
          },
        },
      );

      final filtros = preferencias.atendimentosCriadosFiltrosMobile;

      expect(filtros.tecnicoKeysSelecionadas, <String>['tecnico-legado']);
      expect(filtros.statusKeysSelecionadas, <String>['codigo:LEGACY_STATUS']);
      expect(filtros.toJson(), <String, dynamic>{
        'tecnicoKeys': <String>['tecnico-legado'],
        'statusKeys': <String>['codigo:LEGACY_STATUS'],
      });
    });

    test('separa preferencias da lista mobile de servicos em andamento', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'atendimentosCriadosFiltrosMobile': <String, dynamic>{
            'busca': 'todos os atendimentos',
          },
          'servicosEmAndamentoFiltrosMobile': <String, dynamic>{
            'busca': 'somente ativos',
            'statusKeys': <String>['codigo:REPAIRING'],
          },
        },
      );

      expect(
        preferencias.atendimentosCriadosFiltrosMobile.busca,
        'todos os atendimentos',
      );
      expect(
        preferencias.servicosEmAndamentoFiltrosMobile.busca,
        'somente ativos',
      );
      expect(
        preferencias.servicosEmAndamentoFiltrosMobile.statusKeysSelecionadas,
        <String>['codigo:REPAIRING'],
      );
    });

    test('serializa e desserializa a ordem dos cards da Gestão Mobile', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'ordemCardsGestaoMobile': <String>[
            'FINANCEIRO',
            'CATALOGO',
            'CONFIGURACOES',
            'PESSOAS',
          ],
        },
      );

      expect(preferencias.ordemCardsGestaoMobile, <GestaoMobileCardPreferencia>[
        GestaoMobileCardPreferencia.financeiro,
        GestaoMobileCardPreferencia.catalogo,
        GestaoMobileCardPreferencia.configuracoes,
        GestaoMobileCardPreferencia.pessoas,
      ]);
      expect(preferencias.toJson()['ordemCardsGestaoMobile'], <String>[
        'FINANCEIRO',
        'CATALOGO',
        'CONFIGURACOES',
        'PESSOAS',
      ]);
    });

    test('usa a ordem padrão quando a preferência Mobile é inválida', () {
      for (final dynamic ordemInvalida in <dynamic>[
        <String>['CATALOGO', 'PESSOAS'],
        <String>['CATALOGO', 'CATALOGO', 'FINANCEIRO', 'CONFIGURACOES'],
        <String>['CATALOGO', 'PESSOAS', 'FINANCEIRO', 'DESCONHECIDO'],
      ]) {
        final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
          <String, dynamic>{'ordemCardsGestaoMobile': ordemInvalida},
        );

        expect(
          preferencias.ordemCardsGestaoMobile,
          GestaoMobileCardPreferencia.values,
        );
      }
    });

    test('serializa as ordens independentes dos menus operacionais Mobile', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'ordemCardsAtendimentoMobile': <String>[
            'RECEBER',
            'NOVA_VENDA',
            'DEVOLUCAO',
            'NOVO_SERVICO',
            'OPERACOES_CAIXA',
          ],
          'ordemCardsVendasMobile': <String>[
            'CONSULTAR_VENDAS',
            'NOVA_VENDA',
            'VENDAS_A_RECEBER',
          ],
          'ordemCardsServicosMobile': <String>[
            'SERVICOS_EM_ANDAMENTO',
            'ORCAMENTOS_AGUARDANDO_APROVACAO',
            'SERVICOS_JA_ENCERRADOS',
            'NOVO_SERVICO',
          ],
          'ordemCardsReceberMobile': <String>[
            'SERVICOS_A_RECEBER',
            'VENDAS_A_RECEBER',
          ],
        },
      );

      expect(preferencias.toJson()['ordemCardsAtendimentoMobile'], <String>[
        'RECEBER',
        'NOVA_VENDA',
        'DEVOLUCAO',
        'NOVO_SERVICO',
        'OPERACOES_CAIXA',
      ]);
      expect(preferencias.toJson()['ordemCardsVendasMobile'], <String>[
        'CONSULTAR_VENDAS',
        'NOVA_VENDA',
        'VENDAS_A_RECEBER',
      ]);
      expect(preferencias.toJson()['ordemCardsServicosMobile'], <String>[
        'SERVICOS_EM_ANDAMENTO',
        'ORCAMENTOS_AGUARDANDO_APROVACAO',
        'SERVICOS_JA_ENCERRADOS',
        'NOVO_SERVICO',
      ]);
      expect(preferencias.toJson()['ordemCardsReceberMobile'], <String>[
        'SERVICOS_A_RECEBER',
        'VENDAS_A_RECEBER',
      ]);
    });

    test('rejeita ordem incompleta em cada novo menu Mobile', () {
      final preferencias = PreferenciasIndividuaisDoUsuarioModel.fromJson(
        const <String, dynamic>{
          'ordemCardsAtendimentoMobile': <String>['NOVA_VENDA'],
          'ordemCardsVendasMobile': <String>['NOVA_VENDA'],
          'ordemCardsServicosMobile': <String>['NOVO_SERVICO'],
          'ordemCardsReceberMobile': <String>['VENDAS_A_RECEBER'],
        },
      );

      expect(
        preferencias.ordemCardsAtendimentoMobile,
        AtendimentoMobileCardPreferencia.values,
      );
      expect(
        preferencias.ordemCardsVendasMobile,
        VendasMobileCardPreferencia.values,
      );
      expect(
        preferencias.ordemCardsServicosMobile,
        ServicosMobileCardPreferencia.values,
      );
      expect(
        preferencias.ordemCardsReceberMobile,
        ReceberMobileCardPreferencia.values,
      );
    });
  });
}
