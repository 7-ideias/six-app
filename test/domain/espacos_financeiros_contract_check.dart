import '../../lib/data/models/agenda_financeira_lancamento_model.dart';

void main() {
  void check(bool value, String message) {
    if (!value) throw StateError(message);
  }

  final total = AgendaFinanceiraLiquidacaoRequest(
    tipoLiquidacao: 'TOTAL',
    dataLiquidacao: DateTime(2026, 10, 6),
    valorLiquidado: 100,
    formaPagamentoRealizada: 'tipo2',
    contaFinanceiraId: 'conta-efetiva',
  );
  check(
    total.toJson()['contaFinanceiraId'] == 'conta-efetiva',
    'Conta da liquidação não foi serializada',
  );
  final parcial = AgendaFinanceiraParcialRequest(
    tipoLiquidacao: 'PARCIAL',
    dataLiquidacao: DateTime(2026, 10, 6),
    valorLiquidado: 20,
    formaPagamentoRealizada: 'tipo1',
    contaFinanceiraId: 'carteira',
  );
  check(
    parcial.toJson()['contaFinanceiraId'] == 'carteira',
    'Conta parcial perdida',
  );
  final detalhe = AgendaFinanceiraLancamentoDetalhe.fromJson({
    'idLancamento': 'lancamento',
    'dadosEdicao': {
      'contaFinanceiraId': 'conta-prevista',
      'centroCustoId': 'centro-pessoal',
    },
  }).paraEdicao({'contaFinanceiraId': 'desatualizada'});
  check(
    detalhe['contaFinanceiraId'] == 'conta-prevista',
    'Edição não usa conta persistida',
  );
  check(
    detalhe['centroCustoId'] == 'centro-pessoal',
    'Centro de custo perdido na edição',
  );
  print('4 verificações de contrato financeiro passaram.');
}
