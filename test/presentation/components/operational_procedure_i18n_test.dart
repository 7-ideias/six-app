import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';

void main() {
  testWidgets('formats stage progress in pt-BR, en-US and es', (tester) async {
    expect(
      await _readWithLocale(
        tester,
        const Locale('pt', 'BR'),
        (BuildContext context) =>
            OperationalProcedureI18n.stageProgress(context, 1, 3),
      ),
      'Etapa 1 de 3',
    );
    expect(
      await _readWithLocale(
        tester,
        const Locale('en', 'US'),
        (BuildContext context) =>
            OperationalProcedureI18n.stageProgress(context, 1, 3),
      ),
      'Stage 1 of 3',
    );
    expect(
      await _readWithLocale(
        tester,
        const Locale('es'),
        (BuildContext context) =>
            OperationalProcedureI18n.stageProgress(context, 1, 3),
      ),
      'Etapa 1 de 3',
    );
  });

  testWidgets('formats item, stage and action plurals', (tester) async {
    final _LocalizedValues values = await _readWithLocale(
      tester,
      const Locale('pt', 'BR'),
      (BuildContext context) => _LocalizedValues(
        zeroItems: OperationalProcedureI18n.itemCount(context, 0),
        oneItem: OperationalProcedureI18n.itemCount(context, 1),
        twoItems: OperationalProcedureI18n.itemCount(context, 2),
        oneStage: OperationalProcedureI18n.stageCount(context, 1),
        twoStages: OperationalProcedureI18n.stageCount(context, 2),
        oneAction: OperationalProcedureI18n.actionsCompleted(context, 1, 3),
        twoActions: OperationalProcedureI18n.actionsCompleted(context, 2, 3),
      ),
    );

    expect(values.zeroItems, '0 itens');
    expect(values.oneItem, '1 item');
    expect(values.twoItems, '2 itens');
    expect(values.oneStage, '1 etapa');
    expect(values.twoStages, '2 etapas');
    expect(values.oneAction, '1 de 3 ação concluída');
    expect(values.twoActions, '2 de 3 ações concluídas');
  });

  testWidgets('renders localized semantics and keeps admin content unchanged', (
    tester,
  ) async {
    final String label = await _readWithLocale(
      tester,
      const Locale('en', 'US'),
      (BuildContext context) => OperationalProcedureI18n.stageSemantics(
        context,
        order: 1,
        title: 'Conferência do aparelho',
        itemCount: 2,
      ),
    );

    expect(label, 'Stage 1: Conferência do aparelho. 2 items.');
  });

  testWidgets('formats dates and parses decimals according to locale', (
    tester,
  ) async {
    final _FormatValues pt = await _readWithLocale(
      tester,
      const Locale('pt', 'BR'),
      (BuildContext context) => _FormatValues(
        date: OperationalProcedureI18n.formatDate(
          context,
          DateTime(2026, 7, 29),
        ),
        number: OperationalProcedureI18n.parseNumber(context, '1.250,50'),
        emptyNumber: OperationalProcedureI18n.parseNumber(context, ''),
      ),
    );
    final _FormatValues en = await _readWithLocale(
      tester,
      const Locale('en', 'US'),
      (BuildContext context) => _FormatValues(
        date: OperationalProcedureI18n.formatDate(
          context,
          DateTime(2026, 7, 29),
        ),
        number: OperationalProcedureI18n.parseNumber(context, '1,250.50'),
        emptyNumber: OperationalProcedureI18n.parseNumber(context, ''),
      ),
    );

    expect(pt.date, '29/07/2026');
    expect(en.date, '7/29/2026');
    expect(pt.number, 1250.5);
    expect(en.number, 1250.5);
    expect(pt.emptyNumber, isNull);
    expect(en.emptyNumber, isNull);
  });

  test('keeps operation point id stable across locales', () {
    expect(ProcedureOperationPoint.saleStartBefore.id, 'sale.start.before');
  });
}

Future<T> _readWithLocale<T>(
  WidgetTester tester,
  Locale locale,
  T Function(BuildContext context) read,
) async {
  late T value;
  await _pumpLocalizedWidget(
    tester,
    locale,
    Builder(
      builder: (BuildContext context) {
        value = read(context);
        return Text(value.toString());
      },
    ),
  );
  return value;
}

Future<void> _pumpLocalizedWidget(
  WidgetTester tester,
  Locale locale,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

class _LocalizedValues {
  const _LocalizedValues({
    required this.zeroItems,
    required this.oneItem,
    required this.twoItems,
    required this.oneStage,
    required this.twoStages,
    required this.oneAction,
    required this.twoActions,
  });

  final String zeroItems;
  final String oneItem;
  final String twoItems;
  final String oneStage;
  final String twoStages;
  final String oneAction;
  final String twoActions;
}

class _FormatValues {
  const _FormatValues({
    required this.date,
    required this.number,
    required this.emptyNumber,
  });

  final String date;
  final num? number;
  final num? emptyNumber;
}
