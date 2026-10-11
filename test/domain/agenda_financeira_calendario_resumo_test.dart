import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_calendario_resumo.dart';

void main() {
  Map<String, dynamic> operacao(
    String tipo, String status, double total, double confirmado, double aberto,
  ) => {
    'tipo': tipo,
    'status': status,
    'valorOriginal': total,
    'valorConfirmado': confirmado,
    'valorRestante': aberto,
    // O backend pode devolver `valor` como saldo quando parcial.
    'valor': aberto > 0 ? aberto : total,
  };

  test('pendente destaca saldo aberto, nunca confirmado zero', () {
    final item = operacao('receber', 'Vencido', 150, 0, 150);
    expect(AgendaFinanceiraCalendarioResumo.valorPrincipal(item), 150);
    expect(AgendaFinanceiraCalendarioResumo.rotuloValor(item), 'Em aberto');
  });

  test('recebido destaca confirmacao e nao saldo zerado', () {
    final item = operacao('receber', 'Recebido', 100, 100, 0);
    expect(AgendaFinanceiraCalendarioResumo.valorPrincipal(item), 100);
    expect(AgendaFinanceiraCalendarioResumo.rotuloValor(item), 'Recebido');
  });

  test('parcial de 150 com dois pagamentos conserva 95 e 55', () {
    final item = operacao('receber', 'Parcial', 150, 95, 55);
    expect(AgendaFinanceiraCalendarioResumo.confirmado(item), 95);
    expect(AgendaFinanceiraCalendarioResumo.aberto(item), 55);
    expect(AgendaFinanceiraCalendarioResumo.valorPrincipal(item), 55);
  });

  test('soma valores de entrada e saida separadamente por dia', () {
    final resumo = AgendaFinanceiraCalendarioResumo.calcular([
      operacao('receber', 'Vencido', 150, 0, 150),
      operacao('receber', 'Recebido', 100, 100, 0),
      operacao('receber', 'Parcial', 50, 10, 40),
      operacao('pagar', 'Pendente', 70, 0, 70),
      operacao('pagar', 'Pago', 30, 30, 0),
      operacao('receber', 'Cancelado', 999, 0, 999),
    ]);
    expect(resumo.recebido, 110);
    expect(resumo.aReceber, 190);
    expect(resumo.pago, 30);
    expect(resumo.aPagar, 70);
  });

  test('pagamento quitado legado preserva valor sem confirmado explicito', () {
    final item = {
      'tipo': 'pagar',
      'status': 'Pago',
      'valorOriginal': 80,
      'valorRestante': 0,
    };
    expect(AgendaFinanceiraCalendarioResumo.valorPrincipal(item), 80);
    expect(AgendaFinanceiraCalendarioResumo.rotuloValor(item), 'Pago');
  });

  test('saldo pode vir com representacao monetaria do backend', () {
    final item = {
      'tipo': 'receber', 'status': 'Parcial',
      'valorOriginal': '150.00',
      'valorConfirmado': '95.00',
      'valorRestante': '55.00',
    };
    expect(AgendaFinanceiraCalendarioResumo.aberto(item), 55);
    expect(AgendaFinanceiraCalendarioResumo.confirmado(item), 95);
  });
}
