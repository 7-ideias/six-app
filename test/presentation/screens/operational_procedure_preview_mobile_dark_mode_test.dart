import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/operational_procedure_preview_mobile_screen.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('preview discard sheet keeps CTA contrast in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester);

    await tester.tap(find.byIcon(Icons.thumb_down_alt_outlined));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Descartar respostas?'), findsOneWidget);

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

Future<void> _pumpPreview(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  SixThemeResolver().atualizarTema(TemaSistema.escuro);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: _testSupportedLocales,
      localizationsDelegates: _testLocalizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
          size: Size(390, 900),
          devicePixelRatio: 1,
        ),
        child: OperationalProcedurePreviewMobileScreen(procedure: _procedure()),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

OperationalProcedure _procedure() {
  final DateTime now = DateTime(2026, 8, 30, 9);

  return OperationalProcedure(
    id: 'preview-dark-test',
    name: 'Preview dark',
    description: 'Procedimento para validar sheet em dark mode.',
    operationType: ProcedureOperationType.technicalService,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: true,
    stages: <ProcedureStage>[
      ProcedureStage(
        id: 'stage-1',
        title: 'Etapa',
        description: '',
        order: 1,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'item-1',
            title: 'O aparelho possui chip?',
            guidance: '',
            responseType: ProcedureResponseType.yesNo,
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
