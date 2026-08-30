import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_card.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('trigger card keeps compact CTA contrast in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpTriggerCard(tester);

    expect(
      _hasMaterialAncestorColor(
        find.text('Venda'),
        SixMobileColorScheme.dark.softSurface,
      ),
      isTrue,
    );

    final OutlinedButton editButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Editar'),
    );
    final OutlinedButton deleteButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Excluir gatilho'),
    );

    expect(
      editButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      SixMobileColorScheme.dark.softAccentSurface,
    );
    expect(
      editButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      SixMobileColorScheme.dark.accent,
    );
    expect(
      deleteButton.style?.foregroundColor?.resolve(<WidgetState>{}),
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

Future<void> _pumpTriggerCard(WidgetTester tester) async {
  SixThemeResolver().atualizarTema(TemaSistema.escuro);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: _testSupportedLocales,
      localizationsDelegates: _testLocalizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: OperationalProcedureTriggerCard(
              trigger: _trigger(),
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onEnabledChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProcedureTrigger _trigger() {
  final DateTime now = DateTime(2026, 8, 30, 9);
  return ProcedureTrigger(
    id: 'trigger-1',
    operationPoint: ProcedureOperationPoint.saleStartBefore,
    operationType: ProcedureOperationType.sale,
    triggerMoment: ProcedureTriggerMoment.beforeStart,
    activationMode: ProcedureTriggerActivationMode.automatic,
    enforcementMode: ProcedureEnforcementMode.recommended,
    enabled: true,
    order: 1,
    createdAt: now,
    updatedAt: now,
  );
}

bool _hasMaterialAncestorColor(Finder child, Color expectedColor) {
  final Finder ancestors = find.ancestor(
    of: child,
    matching: find.byWidgetPredicate((Widget widget) {
      return widget is Material && widget.color == expectedColor;
    }),
  );

  return ancestors.evaluate().isNotEmpty;
}
