import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/agenda_financeira_status_labels.dart';

void main() {
  for (final caso in [
    ('RECEBER', 'RECEBIDO', 'Recebido'),
    ('receber', 'PAGO', 'Recebido'),
    ('RECEBER', 'FINALIZADO', 'Recebido'),
    ('PAGAR', 'PAGO', 'Pago'),
    ('PAGAR', 'FINALIZADA', 'Pago'),
    ('', 'RECEBIDO', 'Recebido'),
  ]) {
    testWidgets('quitacao ${caso.$1}/${caso.$2}: ${caso.$3}', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const [Locale('pt'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => Text(
            AgendaFinanceiraStatusLabels.rotuloQuitacao(
              context,
              tipo: caso.$1,
              status: caso.$2,
            ),
          ),
        ),
      ));
      expect(find.text(caso.$3), findsOneWidget);
    });
  }
  testWidgets('Web e Mobile compartilham Status, Pendente e Previsto em PT', (tester) async {
    late String titulo;
    late String pendente;
    late String previsto;
    late String codigo;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: const [Locale('pt'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
