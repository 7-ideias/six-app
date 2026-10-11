import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_detalhe_valores.dart';

void main() {
  test('dois parciais de 10 e 85 preservam total original 150', () {
    final resumo = <String, dynamic>{
      'id': 'venda-1',
      'descricao': 'Venda',
      'valor': 55,
      'valorOriginal': 55, // resumo legado tratava saldo como original
      'valorConfirmado': 95,
      'valorRestante': 55,
      'formaPagamento': 'BUFUNFA',
      'status': 'Parcial',
    };
    final detalhe = <String, dynamic>{
      'valorOriginal': 150,
      'valorPagoRecebido': 95,
      'valorAberto': 55,
      'itensVenda': [
        {'descricao': 'Produto 1', 'valorTotal': 150},
      ],
      'liquidacoes': [
        {'valorLiquidado': 10},
        {'valorLiquidado': 85},
      ],
    };
    final resultado = AgendaFinanceiraDetalheValores.combinar(resumo, detalhe);
    expect(resultado['valorOriginal'], 150);
    expect(resultado['valorConfirmado'], 95);
    expect(resultado['valorRestante'], 55);
    expect(resultado['liquidacoes'], hasLength(2));
    expect(resultado['itensVenda'], hasLength(1));
    expect(resultado['status'], 'Parcial');
  });

  test('fallback mantém resumo quando detalhamento não responde', () {
    final resumo = {'valorOriginal': 150, 'valorConfirmado': 10, 'valorRestante': 140};
    final resultado = AgendaFinanceiraDetalheValores.combinar(resumo, {});
    expect(resultado, resumo);
  });

  test('campos de valores detalhados ausentes preservam resumo', () {
    final resumo = {'valorOriginal': 150, 'valorConfirmado': 95, 'valorRestante': 55};
    final resultado = AgendaFinanceiraDetalheValores.combinar(resumo, {
      'descricao': 'Venda',
    });
    expect(resultado['valorOriginal'], 150);
    expect(resultado['valorConfirmado'], 95);
    expect(resultado['valorRestante'], 55);
  });
}
