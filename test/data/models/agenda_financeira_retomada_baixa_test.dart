import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_baixa_model.dart';

void main() {
  test('baixa integral já registrada impede nova confirmação', () {
    expect(AgendaBaixaDados.encerrada({'status': 'PAGO'}), isTrue);
    expect(AgendaBaixaDados.encerrada({'valorAberto': '0.00'}), isTrue);
    expect(AgendaBaixaDados.encerrada({'status': 'CANCELADO'}), isTrue);
  });

  test('retomada permite liquidar o saldo ainda em aberto', () {
    expect(AgendaBaixaDados.encerrada({
      'status': 'PARCIAL',
      'valorAberto': 14.09,
    }), isFalse);
  });
}
