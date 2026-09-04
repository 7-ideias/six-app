import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_selection_sheet.dart';
import 'package:sixpos/presentation/components/web/six_web_multi_select_field.dart';

void main() {
  testWidgets('multisseletor mobile aplica um ou mais vendedores', (
    WidgetTester tester,
  ) async {
    Set<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const <Locale>[Locale('pt')],
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showSixMobileMultiSelectionSheet<String>(
                  context: context,
                  title: 'Vendedores',
                  options: const <SixMobileSelectionOption<String>>[
                    SixMobileSelectionOption<String>(
                      value: 'ana',
                      title: 'Ana',
                    ),
                    SixMobileSelectionOption<String>(
                      value: 'bruno',
                      title: 'Bruno',
                    ),
                  ],
                  selectedValues: const <String>{},
                  allLabel: 'Todos os vendedores',
                  emptyTitle: 'Nenhum vendedor',
                );
              },
              child: const Text('Abrir mobile'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir mobile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await tester.tap(find.text('Bruno'));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(result, <String>{'ana', 'bruno'});
  });

  testWidgets('multisseletor web representa todos com selecao vazia', (
    WidgetTester tester,
  ) async {
    Set<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const <Locale>[Locale('pt')],
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SixWebMultiSelectField(
              label: 'Vendedores',
              value: 'Ana',
              width: 240,
              options: const <SixWebMultiSelectOption>[
                SixWebMultiSelectOption(value: 'ana', label: 'Ana'),
                SixWebMultiSelectOption(value: 'bruno', label: 'Bruno'),
              ],
              selectedValues: const <String>{'ana'},
              allLabel: 'Todos os vendedores',
              searchHint: 'Buscar vendedor',
              emptyLabel: 'Nenhum vendedor',
              onChanged: (Set<String> values) => result = values,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SixWebMultiSelectField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos os vendedores'));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(result, isEmpty);
  });
}
