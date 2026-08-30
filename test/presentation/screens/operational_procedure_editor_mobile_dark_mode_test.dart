import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/operational_procedure_editor_mobile_screen.dart';
import 'package:sixpos/providers/operational_procedure_provider.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('editor screen keeps dark surfaces and readable fields', (
    WidgetTester tester,
  ) async {
    await _pumpEditor(tester);

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Informações gerais'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Contexto operacional'),
        SixMobileColorScheme.dark.surfaceElevated,
      ),
      isTrue,
    );
    final TextField nameField = _fieldByLabel(tester, 'Nome');
    expect(
      nameField.decoration?.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );
    expect(nameField.style?.color, SixMobileColorScheme.dark.titleText);

    await tester.dragUntilVisible(
      find.text('Quando executar'),
      find.byType(Scrollable).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Adicionar item'),
      find.byType(Scrollable).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    final List<OutlinedButton> addButtons = <OutlinedButton>[
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Adicionar gatilho'),
      ),
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Adicionar etapa'),
      ),
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Adicionar item'),
      ),
    ];

    for (final OutlinedButton button in addButtons) {
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        SixMobileColorScheme.dark.softAccentSurface,
      );
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        SixMobileColorScheme.dark.accent,
      );
    }
  });

  testWidgets('editor confirmation sheet keeps CTA contrast in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpEditorInNavigation(tester);

    final Finder nameField = find.byWidgetPredicate(
      (Widget widget) =>
          widget is TextField && widget.decoration?.labelText == 'Nome',
    );
    await tester.enterText(nameField, 'Atendimento atualizado');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);

    final OutlinedButton keepEditingButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Continuar editando'),
    );
    final OutlinedButton discardButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Descartar'),
    );

    expect(
      keepEditingButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      SixMobileColorScheme.dark.softAccentSurface,
    );
    expect(
      keepEditingButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      SixMobileColorScheme.dark.accent,
    );
    expect(
      discardButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      SixMobileColorScheme.dark.softSurface,
    );
    expect(
      discardButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      SixMobileColorScheme.dark.error,
    );
  });
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpEditor(
  WidgetTester tester, {
  Brightness brightness = Brightness.dark,
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
    ChangeNotifierProvider<OperationalProcedureProvider>(
      create:
          (_) => OperationalProcedureProvider(
            dataSource: const OperationalProcedureMockDataSource(
              delay: Duration.zero,
            ),
          ),
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
            size: Size(390, 900),
            devicePixelRatio: 1,
          ),
          child: OperationalProcedureEditorMobileScreen(
            initialProcedure: _procedure(),
            isCreating: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _pumpEditorInNavigation(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  SixThemeResolver().atualizarTema(TemaSistema.escuro);

  await tester.pumpWidget(
    ChangeNotifierProvider<OperationalProcedureProvider>(
      create:
          (_) => OperationalProcedureProvider(
            dataSource: const OperationalProcedureMockDataSource(
              delay: Duration.zero,
            ),
          ),
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => MediaQuery(
                              data: const MediaQueryData(
                                disableAnimations: true,
                                accessibleNavigation: true,
                                size: Size(390, 900),
                                devicePixelRatio: 1,
                              ),
                              child: OperationalProcedureEditorMobileScreen(
                                initialProcedure: _procedure(),
                                isCreating: false,
                              ),
                            ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

OperationalProcedure _procedure() {
  final DateTime now = DateTime(2026, 8, 30, 9);
  return OperationalProcedure(
    id: 'procedure-1',
    name: 'Atendimento antes da venda',
    description: 'Confirma a experiência do cliente antes de abrir a venda.',
    operationType: ProcedureOperationType.sale,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: false,
    stages: <ProcedureStage>[
      ProcedureStage(
        id: 'stage-1',
        title: 'Conferência inicial',
        description: 'Validar o primeiro contato antes de seguir.',
        order: 1,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'item-1',
            title: 'Cliente foi recebido?',
            guidance: '',
            responseType: ProcedureResponseType.confirmation,
            required: true,
            order: 1,
          ),
        ],
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasDecoratedAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expectedColor,
) {
  final Finder ancestors = find.ancestor(
    of: child,
    matching: find.byWidgetPredicate((Widget widget) {
      if (widget is Material) {
        return widget.color == expectedColor;
      }
      if (widget is! Container) return false;
      final Decoration? decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      return decoration.color == expectedColor;
    }),
  );

  return ancestors.evaluate().isNotEmpty;
}

TextField _fieldByLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<TextField>(find.byType(TextField))
      .firstWhere((TextField field) => field.decoration?.labelText == label);
}
