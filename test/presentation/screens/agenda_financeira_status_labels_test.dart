import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/agenda_financeira_status_labels.dart';

void main() {
  testWidgets('Web e Mobile compartilham Status, Pendente e Previsto em PT', (tester) async {
    late String titulo;
    late String pendente;
    late String previsto;
    late String codigo;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: const [Locale('pt'), Locale('en')],
      home: Builder(builder: (context) {
        titulo = context.t('agenda.form.situation');
        pendente = AgendaFinanceiraStatusLabels.rotulo(context, 'Pendente');
        previsto = AgendaFinanceiraStatusLabels.rotulo(context, 'Previsto');
        codigo = AgendaFinanceiraStatusLabels.codigoDaEscolha(context, pendente);
        return const Scaffold(body: SizedBox());
      }),
    ));
    expect(titulo, 'Status');
    expect(pendente, 'Pendente');
    expect(previsto, 'Previsto');
    expect(codigo, 'Pendente');
  });
}
