import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';

void main() {
  test('copy uses original value and an allowlist, preserving its source', () {
    final source = <String, dynamic>{
      'idLancamento': 'old', 'uuidOperacaoApp': 'old-command',
      'descricao': 'Condomínio', 'tipo': 'PAGAR', 'status': 'PAGO',
      'valorOriginal': 1200, 'valorPagoRecebido': 1252.81, 'valorAberto': 0,
      'dataLiquidacao': '2026-11-13', 'dataVencimento': '2026-11-10',
      'recorrente': true, 'serieRecorrenciaId': 'series', 'quantidadeParcelas': 12,
      'contato': {'id': 'supplier', 'nome': 'Condomínio'},
      'categoria': {'nome': 'Moradia'},
      'dadosEdicao': {'centroCustoId': 'center', 'contaFinanceiraId': 'bank'},
      'agendaFinanceiraLiquidacoes': [{'valorLiquidado': 1252.81}],
    };
    final copy = AgendaFinanceiraLancamentoDetalhe.fromJson(source).paraDuplicacao(
      {'valorOriginal': 5, 'valorEvento': 100, 'idEvento': 'old:baixa-0'},
      descricaoModelo: 'Cópia de {description}', hoje: DateTime(2026, 11, 13),
    );
    expect(copy['descricao'], 'Cópia de Condomínio');
    expect(copy['valorOriginal'], 1200);
    expect(copy['valorRestante'], 1200);
    expect(copy['valorConfirmado'], 0);
    expect(copy['status'], 'PENDENTE');
    expect(copy['recorrente'], false);
    expect(copy['idContato'], 'supplier');
    expect(copy['categoria'], 'Moradia');
    expect(copy['centroCustoId'], 'center');
    expect(copy['contaFinanceiraId'], 'bank');
    expect(copy['vencimento'], DateTime(2026, 11, 13).toIso8601String());
    for (final key in ['id', 'uuidOperacaoApp', 'serieRecorrenciaId', 'quantidadeParcelas',
      'dataLiquidacao', 'dataPrevisaoPagamento', 'agendaFinanceiraLiquidacoes',
      'valorEvento', 'idEvento', 'descontoTotal', 'acrescimoTotal']) {
      expect(copy.containsKey(key), false, reason: key);
    }
    expect(source['status'], 'PAGO');
    expect(source['serieRecorrenciaId'], 'series');
  });
  test('invoice cannot become a duplicated manual entry', () {
    final model = AgendaFinanceiraLancamentoDetalhe.fromJson({'faturaCartaoId': 'invoice', 'valorOriginal': 100});
    expect(() => model.paraDuplicacao({}, descricaoModelo: '{description}', hoje: DateTime(2026)), throwsFormatException);
  });
}
