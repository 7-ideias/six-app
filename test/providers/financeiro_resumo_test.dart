import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/providers/management_overview_provider.dart';

class _Agenda extends AgendaFinanceiraLancamentoService {
  Map<String, dynamic> payload = {};
  AgendaFinanceiraConsultaRequest? request;
  bool fail = false;
  @override
  AgendaFinanceiraLancamentoService paraEspaco(String espaco) {
    espacoFinanceiro = espaco;
    return this;
  }

  @override
  Future<Map<String, dynamic>> consultarLancamentos(
    AgendaFinanceiraConsultaRequest r,
  ) async {
    request = r;
    if (fail) throw StateError('offline');
    return payload;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'counts only open entries and sums outstanding amounts, including partial adjustments',
    () async {
      final api = _Agenda()
        ..payload = {
          'gruposAgenda': [
            {
              'itens': [
                {
                  'idLancamento': '1',
                  'tipo': 'RECEBER',
                  'status': 'PARCIAL',
                  'valorOriginal': 100,
                  'valorRestante': 35,
                  'valorConfirmado': 60,
                },
                {
                  'idLancamento': '2',
                  'tipo': 'PAGAR',
                  'status': 'VENCE_HOJE',
                  'valorOriginal': 200,
                  'valorConfirmado': 50,
                  'descontoTotal': 20,
                  'acrescimoTotal': 5,
                },
                {
                  'idLancamento': '3',
                  'tipo': 'RECEBER',
                  'status': 'RECEBIDO',
                  'valor': 999,
                },
                {
                  'idLancamento': '4',
                  'tipo': 'PAGAR',
                  'status': 'CANCELADO',
                  'valor': 999,
                },
                {
                  'idLancamento': '5',
                  'tipo': 'PAGAR',
                  'status': 'PAGO',
                  'valor': 999,
                },
                {
                  'idLancamento': '1',
                  'tipo': 'RECEBER',
                  'status': 'PARCIAL',
                  'valorRestante': 35,
                },
              ],
            },
          ],
        };
      final provider = ManagementOverviewProvider(agendaFinanceiraService: api);
      final period = AgendaFinanceiraPeriodoRequest(
        modo: 'PERSONALIZADO',
        dataInicio: DateTime(2026, 11, 1),
        dataFim: DateTime(2026, 11, 30),
      );
      final result = await provider.consultarFinanceiro(
        espaco: 'PESSOAL',
        periodo: period,
      );
      expect(api.espacoFinanceiro, 'PESSOAL');
      expect(api.request!.periodo, same(period));
      expect(result.data!.totalEvents, 2);
      expect(result.data!.receivableEvents, 1);
      expect(result.data!.payableEvents, 1);
      expect(result.data!.totalReceber, 35);
      expect(result.data!.totalPagar, 135);
      expect(result.data!.dueTodayEvents, 1);
      provider.dispose();
    },
  );
  test(
    'empty successful response preserves zeros; failure is not empty data',
    () async {
      final api = _Agenda();
      final provider = ManagementOverviewProvider(agendaFinanceiraService: api);
      final empty = await provider.consultarFinanceiro();
      expect(empty.hasError, isFalse);
      expect(empty.data!.totalEvents, 0);
      expect(empty.data!.totalReceber, 0);
      expect(empty.data!.totalPagar, 0);
      api.fail = true;
      final error = await provider.consultarFinanceiro();
      expect(error.hasError, isTrue);
      expect(error.data, isNull);
      api.fail = false;
      expect((await provider.consultarFinanceiro()).data!.totalEvents, 0);
      provider.dispose();
    },
  );
}
