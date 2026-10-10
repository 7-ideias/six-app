import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/agenda_itens_venda_resumo.dart';

void main() {
  final itens = <Map<String, dynamic>>[
    {
      'tipo': 'PRODUTO',
      'idSKU': 'SKU-123',
      'descricao': 'Bateria',
      'quantidade': 2,
      'valorUnitario': 25.50,
      'valorTotal': 51,
    },
    {
      'tipo': 'SERVICO',
      'descricao': 'Troca de bateria',
      'quantidade': 1,
      'valorUnitario': 40,
      'valorTotal': 40,
      'responsavel': 'Técnico',
    },
  ];

  test('snapshot de venda com origem operacional e nao conta avulsa', () {
    expect(AgendaItensVendaResumo.ehVenda({
      'origem': {'tipo': 'VENDA'},
    }), true);
    expect(AgendaItensVendaResumo.ehVenda({
      'origem': 'DESPESA_MANUAL',
    }), false);
    expect(AgendaItensVendaResumo.lerItens({
      'itensVenda': itens,
    }).length, 2);
  });

  testWidgets('exibe produto, servico, quantidade, unitario e total',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AgendaItensVendaResumo(
            itens: itens,
            formatarMoeda: (n) => 'R\\$ ${n.toStringAsFixed(2)}',
          ),
        ),
      ),
    ));
    expect(find.text('Bateria'), findsOneWidget);
    expect(find.text('Troca de bateria'), findsOneWidget);
    expect(find.textContaining('Qtd. 2'), findsOneWidget);
    expect(find.text('R\\$ 51.00'), findsOneWidget);
    expect(find.text('R\\$ 40.00'), findsWidgets);
    expect(find.text('Técnico'), findsOneWidget);
  });

  testWidgets('venda antiga sem itens nao inventa produtos', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AgendaItensVendaResumo(
          itens: const [],
          mostrarVazio: true,
          formatarMoeda: (n) => '$n',
        ),
      ),
    ));
    expect(find.textContaining('não estão disponíveis'), findsOneWidget);
  });
}
