import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/agenda_financeira_lancamento_card_web.dart';

void main() {
  Map<String, dynamic> lancamento({
    String tipo = 'receber',
    String status = 'Vencido',
    double original = 150,
    double confirmado = 0,
    double restante = 150,
    String origem = 'VENDA',
    List<String> acoes = const [
      'Editar', 'Liquidar', 'Registrar parcial', 'Detalhes',
    ],
  }) => {
    'id': 'exemplo-1',
    'tipo': tipo,
    'descricao': tipo == 'receber' ? 'Venda' : 'Aluguel',
    'codigoOperacao': '1791391599398',
    'contato': 'Não informado',
    'vencimento': '07/10/2026',
    'dataCompetencia': '2026-10-01',
    'formaPagamento': 'Bufunfa',
    'origem': origem,
    'status': status,
    'valorOriginal': original,
    'valorConfirmado': confirmado,
    'valorRestante': restante,
    'acoes': acoes,
  };

  Future<void> montar(
    WidgetTester tester, {
    required Map<String, dynamic> item,
    double width = 1350,
    void Function(String acao)? onAcao,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AgendaFinanceiraLancamentoCardWeb(
            item: item,
            formatarMoeda: (n) => 'R\$ ${n.toStringAsFixed(2)}',
            onDetalhes: () => onAcao?.call('detalhes'),
            onEditar: () => onAcao?.call('editar'),
            onLiquidar: () => onAcao?.call('liquidar'),
            onRegistrarParcial: () => onAcao?.call('parcial'),
            onCancelar: () => onAcao?.call('cancelar'),
            onComprovante: () => onAcao?.call('comprovante'),
          ),
        ),
      ),
    ));
  }

  testWidgets('Web vencido mostra valor e CTAs na mesma faixa horizontal', (tester) async {
    final eventos = <String>[];
    await montar(tester, item: lancamento(), onAcao: eventos.add);
    expect(find.text('Venda'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
    expect(find.text('Original: R\$ 150.00'), findsOneWidget);
    expect(find.byKey(const Key('agenda-card-editar')), findsOneWidget);
    expect(find.byKey(const Key('agenda-card-liquidar')), findsOneWidget);
    expect(find.text('Receber'), findsOneWidget);
    expect(find.text('Não informado'), findsNothing);

    await tester.tap(find.text('Receber'));
    expect(eventos, ['liquidar']);
    await tester.tap(find.text('Editar'));
    expect(eventos, ['liquidar', 'editar']);

    final liquidarY = tester.getTopLeft(find.byKey(const Key('agenda-card-liquidar'))).dy;
    final originalY = tester.getTopLeft(find.text('Original: R\$ 150.00')).dy;
    expect((liquidarY - originalY).abs(), lessThan(48));
  });

  testWidgets('Despesa exibe Pagar e seta de saida', (tester) async {
    final eventos = <String>[];
    await montar(tester,
      item: lancamento(tipo: 'pagar', status: 'Pendente', original: 1000,
          restante: 1000, origem: 'DESPESA_MANUAL'),
      onAcao: eventos.add,
    );
    expect(find.text('Pagar'), findsOneWidget);
    expect(find.text('Receber'), findsNothing);
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
    await tester.tap(find.text('Pagar'));
    expect(eventos, ['liquidar']);
  });

  testWidgets('Parcial prioriza saldo restante e parcial permanece no menu', (tester) async {
    final eventos = <String>[];
    await montar(tester,
      item: lancamento(status: 'Parcial', original: 300, confirmado: 100, restante: 200),
      onAcao: eventos.add,
    );
    expect(find.text('Receber restante'), findsOneWidget);
    expect(find.text('R\$ 200.00'), findsOneWidget);
    expect(find.byKey(const Key('agenda-card-editar')), findsNothing);
    await tester.tap(find.byKey(const Key('agenda-card-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar parcial'));
    expect(eventos, ['parcial']);
  });

  testWidgets('Venda recebida exibe somente comprovante e detalhes', (tester) async {
    final eventos = <String>[];
    await montar(tester,
      item: lancamento(status: 'Recebido', original: 100, confirmado: 100,
        restante: 0, acoes: ['Detalhes']),
      onAcao: eventos.add,
    );
    expect(find.text('Recebido'), findsOneWidget);
    expect(find.byKey(const Key('agenda-card-liquidar')), findsNothing);
    expect(find.byKey(const Key('agenda-card-editar')), findsNothing);
    expect(find.byKey(const Key('agenda-card-comprovante')), findsOneWidget);
    await tester.tap(find.text('Comprovante'));
    expect(eventos, ['comprovante']);
  });

  testWidgets('Acoes respeitam a permissoes da API e cancelamento no menu', (tester) async {
    final eventos = <String>[];
    await montar(tester,
      item: lancamento(acoes: ['Detalhes', 'Cancelar']),
      onAcao: eventos.add,
    );
    expect(find.byKey(const Key('agenda-card-editar')), findsNothing);
    expect(find.byKey(const Key('agenda-card-liquidar')), findsNothing);
    await tester.tap(find.byKey(const Key('agenda-card-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar ocorrência'));
    expect(eventos, ['cancelar']);
  });

  testWidgets('Largura intermediaria reorganiza acoes sem overflow', (tester) async {
    await montar(tester, item: lancamento(), width: 830);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('agenda-card-liquidar')), findsOneWidget);
  });

  testWidgets('Largura estreita preserva botoes e descricao legivel', (tester) async {
    await montar(tester, item: lancamento(), width: 520);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('agenda-card-liquidar')), findsOneWidget);
    expect(find.text('Venda'), findsOneWidget);
  });
}
