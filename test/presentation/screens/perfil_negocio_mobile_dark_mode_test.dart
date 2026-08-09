import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/empresa_configuracao_mobile.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets(
    'business profile loading keeps save action disabled in dark mode',
    (WidgetTester tester) async {
      final Completer<EmpresaModel> completer = Completer<EmpresaModel>();

      await _pumpProfile(
        tester,
        carregarEmpresa: () => completer.future,
        settleInitialLoad: false,
      );
      await tester.pump();

      expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
      expect(find.text('Dados do comércio'), findsOneWidget);
      final FilledButton saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Salvar alterações'),
      );
      expect(saveButton.onPressed, isNull);

      completer.complete(_empresa);
      await tester.pump(const Duration(milliseconds: 80));
    },
  );

  testWidgets('business profile form uses dark surfaces and validation', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester);

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Identidade da empresa'), findsOneWidget);

    final TextFormField firstTextField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(firstTextField.enabled, isNot(false));

    final InputDecorator firstField = tester.widget<InputDecorator>(
      find
          .descendant(
            of: find.byType(TextFormField).first,
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(
      firstField.decoration.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pump();

    expect(find.text('Informe este campo.'), findsOneWidget);
  });

  testWidgets('business profile saves edited values in light mode', (
    WidgetTester tester,
  ) async {
    EmpresaModel? saved;

    await _pumpProfile(
      tester,
      brightness: Brightness.light,
      salvarEmpresa: (EmpresaModel empresa) async {
        saved = empresa;
        return empresa;
      },
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    final FilledButton saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
    );
    expect(saveButton.onPressed, isNotNull);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Identidade da empresa'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField).first, 'Six Comércio');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(saved?.nomeEmpresa, 'Six Comércio');
    expect(
      find.text('Dados da empresa atualizados com sucesso.'),
      findsOneWidget,
    );
  });

  testWidgets('business profile error state uses themed error card', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      brightness: Brightness.light,
      carregarEmpresa: () async => throw StateError('offline'),
    );

    expect(
      find.text('Não foi possível carregar os dados da empresa.'),
      findsOneWidget,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Não foi possível carregar os dados da empresa.'),
        SixMobileColorScheme.light.errorBorder.withValues(alpha: 0.20),
      ),
      isTrue,
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

Future<void> _pumpProfile(
  WidgetTester tester, {
  Brightness brightness = Brightness.dark,
  Future<EmpresaModel> Function()? carregarEmpresa,
  Future<EmpresaModel> Function(EmpresaModel empresa)? salvarEmpresa,
  bool settleInitialLoad = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 860);
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
      locale: const Locale('pt'),
      supportedLocales: _testSupportedLocales,
      localizationsDelegates: _testLocalizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: EmpresaConfiguracaoMobile(
        carregarEmpresa: carregarEmpresa ?? () async => _empresa,
        salvarEmpresa: salvarEmpresa ?? (EmpresaModel empresa) async => empresa,
      ),
    ),
  );
  await tester.pump();
  if (settleInitialLoad) {
    await tester.pump(const Duration(milliseconds: 520));
  }
}

final EmpresaModel _empresa = EmpresaModel(
  nomeEmpresa: 'Six Tecnologia',
  nomeFantasia: 'Six App',
  documentoNoBrasilCNPJ: '12.345.678/0001-90',
);

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
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
