import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/agenda_financeira_resumo_visual.dart';

void main() {
  test('forma prevista sem recebimento nao e exibida como realizada', () {
    final pendente = <String, dynamic>{
      'status': 'Vencido',
      'valorOriginal': 150,
      'valorConfirmado': 0,
      'valorRestante': 150,
      'formaPagamento': 'BUFUNFA',
    };
    expect(AgendaFinanceiraResumoVisual.possuiRecebimento(pendente), isFalse);
    expect(AgendaFinanceiraResumoVisual.formaRealizada(pendente), isNull);
  });

  test('forma realizada aparece somente apos pagamento parcial ou integral', () {
    final parcial = <String, dynamic>{
      'valorOriginal': 150,
      'valorConfirmado': 50,
      'valorRestante': 100,
      'formaPagamento': 'BUFUNFA',
    };
    expect(AgendaFinanceiraResumoVisual.formaRealizada(parcial), 'BUFUNFA');
    expect(
      AgendaFinanceiraResumoVisual.formaRealizada({
        ...parcial,
        'valorConfirmado': 150,
        'valorRestante': 0,
      }),
      'BUFUNFA',
    );
  });

  test('contatos vazios ou nao informados nao aparecem nos cards', () {
    for (final contato in [
      null, '', ' ', '-', 'Não informado', 'Nao informado',
      'NO INFORMADO', 'Not provided', 'null',
    ]) {
      expect(AgendaFinanceiraResumoVisual.contatoInformado(contato), isNull);
    }
    expect(AgendaFinanceiraResumoVisual.contatoInformado('Maria Silva'),
        'Maria Silva');
  });
}
