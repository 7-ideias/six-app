import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'edição cadastral envia PATCH no espaço correto sem campos financeiros',
    () async {
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'exp':
                    DateTime.now()
                        .add(const Duration(hours: 1))
                        .millisecondsSinceEpoch ~/
                    1000,
              }),
            ),
          )
          .replaceAll('=', '');
      final token = 'eyJhbGciOiJub25lIn0.$payload.assinatura';
      SharedPreferences.setMockInitialValues({
        'accessToken': token,
        'idUnicoDaEmpresa': 'empresa',
      });
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.path,
          '/private/api/agenda-financeira/lancamentos/entry/cadastro',
        );
        expect(request.headers['espacoFinanceiro'], 'PESSOAL');
        expect(request.headers['idUnicoDaEmpresa'], 'empresa');
        expect(request.headers['Authorization'], 'Bearer $token');
        final data = jsonDecode(request.body) as Map;
        expect(data['categoria'], '');
        expect(data['alterarCentroCusto'], true);
        expect(data.containsKey('centroCustoId'), true);
        expect(data['centroCustoId'], isNull);
        expect(data.containsKey('nomeContato'), false);
        expect(
          data.keys,
          unorderedEquals([
            'descricao',
            'categoria',
            'alterarCentroCusto',
            'centroCustoId',
            'nomeColaborador',
            'referenciaExterna',
            'documentoFiscal',
            'observacoes',
            'impostoRenda',
          ]),
        );
        return http.Response('', 204);
      });
      final service = AgendaFinanceiraLancamentoService(
        httpClient: client,
      ).paraEspaco('PESSOAL');
      await service.editarCadastroLancamento(
        'entry',
        const AgendaFinanceiraEdicaoCadastroRequest(
          descricao: 'Escola',
          categoria: '',
          alterarCentroCusto: true,
          nomeColaborador: '',
          referenciaExterna: '',
          documentoFiscal: '',
          observacoes: '',
          impostoRenda: {
            'separarImpostoRenda': false,
            'comprovantesImpostoRenda': [],
          },
        ),
      );
    },
  );

  test('detalhe atual substitui status antigo e preserva IDs de edição', () {
    final detalhe = AgendaFinanceiraLancamentoDetalhe.fromJson({
      'status': 'PAGO',
      'tipo': 'PAGAR',
      'valorOriginal': 1680,
      'valorPagoRecebido': 1380,
      'valorAberto': 0,
      'contato': null,
      'dadosEdicao': {'somenteCadastro': true, 'centroCustoId': 'centro'},
    });
    final item = detalhe.paraEdicao({
      'status': 'Pendente',
      'idContato': 'antigo',
      'contato': 'Antigo',
    });
    expect(item['status'], 'PAGO');
    expect(item['somenteCadastro'], true);
    expect(item['valorOriginal'], 1680);
    expect(item['valorConfirmado'], 1380);
    expect(item['centroCustoId'], 'centro');
    expect(item['idContato'], isNull);
    expect(item['contato'], '');
  });

  test('conflito e falta de permissão de edição têm códigos localizáveis', () {
    expect(
      AgendaFinanceiraLancamentoApiException(
        statusCode: 409,
        body: '{"reason":"AGF_EDICAO_SOMENTE_CADASTRO"}',
      ).codigoEdicao,
      'AGF_EDICAO_SOMENTE_CADASTRO',
    );
    expect(
      AgendaFinanceiraLancamentoApiException(
        statusCode: 403,
        body: '',
      ).codigoEdicao,
      'AGF_EDICAO_SEM_PERMISSAO',
    );
  });

  test('consulta agenda e valores confirmados em paralelo', () async {
    final service = _AgendaServiceControlado();

    final consulta = service.consultarAgendaEmParalelo(_request());
    await Future.wait(<Future<void>>[
      service.agendaIniciada.future,
      service.confirmadosIniciados.future,
    ]);

    service.agendaResultado.complete(<String, dynamic>{'agenda': true});
    service.confirmadosResultado.complete(<String, dynamic>{
      'confirmados': true,
    });

    final resultado = await consulta;
    expect(resultado.agenda, <String, dynamic>{'agenda': true});
    expect(resultado.valoresConfirmados, <String, dynamic>{
      'confirmados': true,
    });
    expect(resultado.valoresConfirmadosDisponiveis, isTrue);
  });

  test('mantem a agenda quando valores confirmados falham', () async {
    final service = _AgendaServiceControlado();

    final consulta = service.consultarAgendaEmParalelo(_request());
    await Future.wait(<Future<void>>[
      service.agendaIniciada.future,
      service.confirmadosIniciados.future,
    ]);
    service.agendaResultado.complete(<String, dynamic>{'agenda': true});
    service.confirmadosResultado.completeError(StateError('indisponivel'));

    final resultado = await consulta;
    expect(resultado.agenda, <String, dynamic>{'agenda': true});
    expect(resultado.valoresConfirmados, isEmpty);
    expect(resultado.valoresConfirmadosDisponiveis, isFalse);
    expect(resultado.erroValoresConfirmados, isA<StateError>());
  });

  test('propaga a falha da consulta principal', () async {
    final service = _AgendaServiceControlado();

    final consulta = service.consultarAgendaEmParalelo(_request());
    await Future.wait(<Future<void>>[
      service.agendaIniciada.future,
      service.confirmadosIniciados.future,
    ]);
    service.agendaResultado.completeError(StateError('agenda indisponivel'));
    service.confirmadosResultado.complete(<String, dynamic>{});

    await expectLater(consulta, throwsA(isA<StateError>()));
  });
}

AgendaFinanceiraConsultaRequest _request() {
  final data = DateTime(2026, 9, 1);
  return AgendaFinanceiraConsultaRequest(
    periodo: AgendaFinanceiraPeriodoRequest(
      modo: 'ESTE_MES',
      dataInicio: data,
      dataFim: DateTime(2026, 9, 30),
    ),
    filtros: AgendaFinanceiraFiltrosRequest(
      tipo: 'TODOS',
      status: <String>[],
      origens: <String>[],
      categorias: <String>[],
      formasPagamento: <String>[],
      codigosTipoRecebimento: <String>[],
      centrosCusto: <String>[],
      somenteCriticos: false,
    ),
    visaoSelecionada: 'AGENDA',
  );
}

class _AgendaServiceControlado extends AgendaFinanceiraLancamentoService {
  final Completer<void> agendaIniciada = Completer<void>();
  final Completer<void> confirmadosIniciados = Completer<void>();
  final Completer<Map<String, dynamic>> agendaResultado =
      Completer<Map<String, dynamic>>();
  final Completer<Map<String, dynamic>> confirmadosResultado =
      Completer<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> consultarLancamentos(
    AgendaFinanceiraConsultaRequest request,
  ) {
    agendaIniciada.complete();
    return agendaResultado.future;
  }

  @override
  Future<Map<String, dynamic>> consultarValoresConfirmados(
    AgendaFinanceiraConsultaRequest request,
  ) {
    confirmadosIniciados.complete();
    return confirmadosResultado.future;
  }
}
