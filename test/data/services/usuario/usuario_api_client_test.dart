import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/services/usuario/usuario_api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
  });

  test(
    'atualizarPreferenciasIndividuais envia evento simples parcial',
    () async {
      late http.Request capturedRequest;
      final client = HttpUsuarioApiClient(
        httpClient: MockClient((http.Request request) async {
          capturedRequest = request;
          return http.Response('', 202);
        }),
      );

      await client.atualizarPreferenciasIndividuais(<String, dynamic>{
        'agendaFinanceiraPeriodoWeb': 'ESTE_MES',
        'agendaFinanceiraTipoDePagamentoWeb': <String>['tipo2', 'tipo3'],
        'catalogoReservasFiltrosWeb': <String, dynamic>{
          'status': <String>['CONFIRMADA'],
          'periodo': 'PERSONALIZADO',
          'dataInicio': '2026-08-03',
          'dataFim': '2026-08-12',
        },
        'consultaVendasFiltrosWeb': <String, dynamic>{
          'busca': 'joao',
          'periodo': 'ULTIMOS_30_DIAS',
          'statusFinanceiro': 'QUITADA',
          'ordenacao': 'MAIOR_VALOR',
        },
        'atendimentosCriadosFiltrosWeb': <String, dynamic>{
          'busca': 'cliente teste',
          'statusKey': 'id:3',
          'statusPagamento': 'EM_ABERTO',
        },
        'atendimentosCriadosFiltrosMobile': <String, dynamic>{
          'tecnicoKey': 'tecnico-2',
          'statusPagamento': 'LIQUIDADO',
        },
        'ordemCardsGestaoMobile': <String>[
          'FINANCEIRO',
          'CATALOGO',
          'CONFIGURACOES',
          'PESSOAS',
        ],
      });

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.path,
        '/private/api/eventos/atualizacoes-simples',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer token-test');
      expect(capturedRequest.headers['idUnicoDaEmpresa'], 'empresa-test');

      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['tipo'], 'PREFERENCIAS_INDIVIDUAIS_DO_USUARIO');
      expect(body['recurso'], 'preferenciasIndividuaisDoUsuario');
      expect(body['acao'], 'ATUALIZAR_PARCIAL');
      expect(body['payload'], <String, dynamic>{
        'agendaFinanceiraPeriodoWeb': 'ESTE_MES',
        'agendaFinanceiraTipoDePagamentoWeb': <String>['tipo2', 'tipo3'],
        'catalogoReservasFiltrosWeb': <String, dynamic>{
          'status': <String>['CONFIRMADA'],
          'periodo': 'PERSONALIZADO',
          'dataInicio': '2026-08-03',
          'dataFim': '2026-08-12',
        },
        'consultaVendasFiltrosWeb': <String, dynamic>{
          'busca': 'joao',
          'periodo': 'ULTIMOS_30_DIAS',
          'statusFinanceiro': 'QUITADA',
          'ordenacao': 'MAIOR_VALOR',
        },
        'atendimentosCriadosFiltrosWeb': <String, dynamic>{
          'busca': 'cliente teste',
          'statusKey': 'id:3',
          'statusPagamento': 'EM_ABERTO',
        },
        'atendimentosCriadosFiltrosMobile': <String, dynamic>{
          'tecnicoKey': 'tecnico-2',
          'statusPagamento': 'LIQUIDADO',
        },
        'ordemCardsGestaoMobile': <String>[
          'FINANCEIRO',
          'CATALOGO',
          'CONFIGURACOES',
          'PESSOAS',
        ],
      });
    },
  );
}
