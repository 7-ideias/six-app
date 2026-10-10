import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';
import 'package:sixpos/presentation/components/agenda_recorrencia_confirmacao.dart';

void main() {
  AgendaFinanceiraRecorrencia criarRecorrencia() {
    return AgendaFinanceiraRecorrencia.fromJson({
      'recorrente': true,
      'serieRecorrenciaId': 'serie-teste',
      'frequenciaRecorrencia': 'MENSAL',
      'quantidadeParcelas': 10,
      'numeroOcorrencia': 3,
    });
  }

  testWidgets('Web: edicao individual tem escopo seguro por padrao', (tester) async {
    AgendaRecorrenciaConfirmacao? resultado;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () async {
          resultado = await confirmarImpactoRecorrencia(
            context,
            mobile: false,
            recorrencia: criarRecorrencia(),
            descricao: 'Aluguel',
            valorFormatado: 'R\\$ 1300',
            vencimentoFormatado: '15/03/2027',
            cancelar: false,
          );
        },
        child: const Text('Abrir'),
      ))),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Somente este lançamento'), findsOneWidget);
    expect(find.textContaining('somente a 3ª ocorrência'), findsOneWidget);
    await tester.tap(find.text('Confirmar alterações'));
    await tester.pumpAndSettle();
    expect(resultado?.escopo, 'ESTE');
  });

  testWidgets('Mobile: cancelar seguintes exibe alcance da serie', (tester) async {
    AgendaRecorrenciaConfirmacao? resultado;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () async {
          resultado = await confirmarImpactoRecorrencia(
            context,
            mobile: true,
            recorrencia: criarRecorrencia(),
            descricao: 'Aluguel',
            valorFormatado: 'R\\$ 1000',
            vencimentoFormatado: '10/03/2027',
            cancelar: true,
            permitirTrocarEscopo: true,
          );
        },
        child: const Text('Abrir'),
      ))),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Este e os próximos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('8 ocorrências'), findsOneWidget);
    await tester.tap(find.text('Cancelar lançamento'));
    await tester.pumpAndSettle();
    expect(resultado?.escopo, 'ESTE_E_PROXIMOS');
  });
}
