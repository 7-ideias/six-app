import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/components/mobile/agenda_recorrencia_mobile_fields.dart';
import 'package:sixpos/presentation/components/agenda_recorrencia_web_fields.dart';

void main() {
  testWidgets('Mobile dark mantém contraste e permite configurar repetição', (
    tester,
  ) async {
    final config = AgendaFinanceiraRecorrencia();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder:
                (_, setState) => SingleChildScrollView(
                  child: AgendaRecorrenciaMobileFields(
                    config: config,
                    vencimento: DateTime(2026, 9, 10),
                    onChanged: () => setState(() {}),
                  ),
                ),
          ),
        ),
      ),
    );
    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (widget) =>
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  SixMobileColorScheme.dark.surface,
        );
    expect(container.decoration, isNotNull);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(config.ativa, isTrue);
    expect(find.text('Frequência: Mensal'), findsOneWidget);
    await tester.tap(find.text('Frequência: Mensal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semanal'));
    await tester.pumpAndSettle();
    expect(config.frequencia, 'SEMANAL');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Web preserva série até selecionar este e próximos', (
    tester,
  ) async {
    final config = AgendaFinanceiraRecorrencia.fromJson({
      'serieRecorrenciaId': 'serie',
      'recorrente': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaRecorrenciaWebFields(
            config: config,
            vencimento: DateTime(2026, 9, 10),
            onChanged: () {},
          ),
        ),
      ),
    );
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.onChanged, isNull);
    expect(find.textContaining('Somente este lançamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
