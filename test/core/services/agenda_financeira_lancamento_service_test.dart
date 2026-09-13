import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';

void main() {
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
