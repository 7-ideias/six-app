import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';

void main() {
  group('SixWebDashboardHeader', () {
    testWidgets('nao renderiza acao de fechar quando onBack nao existe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SixWebDashboardHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Produtos',
              subtitle: 'Resumo do catalogo.',
              actions: const <Widget>[],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byTooltip('Fechar'), findsNothing);
    });

    testWidgets('mantem acao de fechar quando onBack existe', (
      WidgetTester tester,
    ) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SixWebDashboardHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Produtos',
              subtitle: 'Resumo do catalogo.',
              actions: const <Widget>[],
              onBack: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.byTooltip('Fechar'), findsOneWidget);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();

      expect(closed, isTrue);
    });
  });
}
