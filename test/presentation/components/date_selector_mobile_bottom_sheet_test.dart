import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/components/date_selector_mobile_bottom_sheet.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  for (final _ThemeCase themeCase in <_ThemeCase>[
    _ThemeCase(
      description: 'light',
      brightness: Brightness.light,
      expectedBackground: SixMobileColorScheme.light.background,
    ),
    _ThemeCase(
      description: 'dark',
      brightness: Brightness.dark,
      expectedBackground: SixMobileColorScheme.dark.background,
    ),
  ]) {
    testWidgets(
      'date selector opens, selects and confirms in ${themeCase.description} mode',
      (WidgetTester tester) async {
        DateTime? selectedDate;

        await _pumpHost(
          tester,
          brightness: themeCase.brightness,
          onResult: (DateTime? value) => selectedDate = value,
        );

        await tester.tap(find.text('Abrir seletor'));
        await tester.pumpAndSettle();

        expect(find.text('Selecionar data'), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Selecionar data'),
            themeCase.expectedBackground,
          ),
          isTrue,
        );

        await tester.tap(find.text('5').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar data'));
        await tester.pumpAndSettle();

        expect(selectedDate, DateTime(2026, 8, 5));
      },
    );
  }

  testWidgets('date selector cancel closes without returning a date', (
    WidgetTester tester,
  ) async {
    DateTime? selectedDate;
    bool closed = false;

    await _pumpHost(
      tester,
      brightness: Brightness.dark,
      onResult: (DateTime? value) {
        selectedDate = value;
        closed = true;
      },
    );

    await tester.tap(find.text('Abrir seletor'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(selectedDate, isNull);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required Brightness brightness,
  required ValueChanged<DateTime?> onResult,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final bool isDark = brightness == Brightness.dark;
  SixThemeResolver().atualizarTema(
    isDark ? TemaSistema.escuro : TemaSistema.claro,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: _DateSelectorHost(onResult: onResult),
    ),
  );
}

class _DateSelectorHost extends StatelessWidget {
  const _DateSelectorHost({required this.onResult});

  final ValueChanged<DateTime?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final DateTime? result = await showModalBottomSheet<DateTime>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) {
                return DateSelectorMobileBottomSheet(
                  title: 'Selecionar data',
                  initialDate: DateTime(2026, 8, 8),
                  firstDate: DateTime(2026, 8),
                  lastDate: DateTime(2026, 8, 31),
                );
              },
            );
            onResult(result);
          },
          child: const Text('Abrir seletor'),
        ),
      ),
    );
  }
}

class _ThemeCase {
  const _ThemeCase({
    required this.description,
    required this.brightness,
    required this.expectedBackground,
  });

  final String description;
  final Brightness brightness;
  final Color expectedBackground;
}

bool _hasDecoratedAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Container>(
        find.ancestor(of: child, matching: find.byType(Container)),
      )
      .any((Container container) {
        final Decoration? decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == expected;
      });
}
