import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/competencia_mes_ano_picker.dart';

void main() {
  for (final mobile in [false, true]) {
    testWidgets(
      mobile ? 'Mobile seleciona mês e ano sem dia' : 'Web seleciona mês e ano sem dia',
      (tester) async {
        DateTime? selecionada;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('Abrir competência'),
                onPressed: () async {
                  selecionada = await selecionarCompetenciaMesAno(
                    context,
                    competencia: DateTime(2026, 10, 29),
                    mobile: mobile,
                  );
                },
              ),
            ),
          ),
        ));
        await tester.tap(find.text('Abrir competência'));
        await tester.pumpAndSettle();
        expect(find.text('2026'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsNothing);
        await tester.tap(find.byTooltip('Próximo ano'));
        await tester.pumpAndSettle();
        expect(find.text('2027'), findsOneWidget);
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();
        expect(selecionada, DateTime(2027, 10, 1));
      },
    );
  }
}
