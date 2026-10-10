import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_origem.dart';

void main() {
  test('recebimento manual não deve se passar por venda', () {
    expect(AgendaFinanceiraOrigem.manual('Receber'), 'RECEITA_MANUAL');
    expect(AgendaFinanceiraOrigem.manual('RECEBER'), 'RECEITA_MANUAL');
  });

  test('pagamento manual não deve se passar por compra', () {
    expect(AgendaFinanceiraOrigem.manual('Pagar'), 'DESPESA_MANUAL');
  });

  test('edição preserva origem operacional real mesmo com tipo diferente', () {
    expect(AgendaFinanceiraOrigem.preservada('VENDA', 'Pagar'), 'VENDA');
    expect(AgendaFinanceiraOrigem.preservada('COMPRA', 'Receber'), 'COMPRA');
    expect(
      AgendaFinanceiraOrigem.preservada({'tipo': 'VENDA_NAO_LIQUIDADA'}, 'Receber'),
      'VENDA_NAO_LIQUIDADA',
    );
    expect(
      AgendaFinanceiraOrigem.preservada({'tipo': 'ATENDIMENTO_TECNICO'}, 'Pagar'),
      'ATENDIMENTO_TECNICO',
    );
  });

  test('origem ausente recebe fallback manual, nunca venda', () {
    expect(AgendaFinanceiraOrigem.preservada(null, 'Receber'), 'RECEITA_MANUAL');
    expect(AgendaFinanceiraOrigem.preservada('', 'Pagar'), 'DESPESA_MANUAL');
  });
}
