import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_sale_processing.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('bloqueia o PDV durante o registro no tema ${brightness.name}', (
      tester,
    ) async {
      var cliques = 0;
      var processando = false;
      late StateSetter atualizar;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                atualizar = setState;
                return SixWebSaleProcessing(
                  processing: processando,
                  label: 'Registrando...',
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton(
                      onPressed: () => cliques++,
                      child: const Text('Registrar'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final botao = find.text('Registrar');
      await tester.tap(botao);
      atualizar(() => processando = true);
      await tester.pump();
      expect(find.text('Registrando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(botao, warnIfMissed: false);
      expect(cliques, 1);

      atualizar(() => processando = false);
      await tester.pump();
      expect(find.text('Registrando...'), findsNothing);
      await tester.tap(botao);
      expect(cliques, 2);
    });
  }
}
