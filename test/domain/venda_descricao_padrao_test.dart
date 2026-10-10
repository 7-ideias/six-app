import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/venda_descricao_padrao.dart';

void main() {
  test('PDV Web e Mobile compartilham titulo neutro da venda', () {
    expect(VendaDescricaoPadrao.valor, 'Venda');
    expect(VendaDescricaoPadrao.valor.contains('em andamento'), isFalse);
    expect(VendaDescricaoPadrao.valor.contains('mobile'), isFalse);
  });
}
