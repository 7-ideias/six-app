import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_atendimento_date_filter_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows contextual date filter with blurred navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar por data'), findsOneWidget);
    expect(
      find.text('Defina o intervalo de atualização dos atendimentos.'),
      findsOneWidget,
    );
    expect(find.text('Campo'), findsOneWidget);
    expect(find.text('Atualização'), findsOneWidget);
    expect(find.text('Todas as datas'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('six-web-atendimento-date-filter-dialog'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes on escape while focused', (WidgetTester tester) async {
    bool completed = false;
    SixWebAtendimentoDateFilterResult? result;
    await _pumpHarness(
      tester,
      onResult: (SixWebAtendimentoDateFilterResult? value) {
        completed = true;
        result = value;
      },
    );

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.text('Filtrar por data'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies typed date range', (WidgetTester tester) async {
    SixWebAtendimentoDateFilterResult? result;
    await _pumpHarness(
      tester,
      onResult: (SixWebAtendimentoDateFilterResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('six-date-filter-start-field')),
      '10/08/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('six-date-filter-end-field')),
      '12/08/2026',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(result?.dataInicio, DateTime(2026, 8, 10));
    expect(result?.dataFim, DateTime(2026, 8, 12));
    expect(find.text('Filtrar por data'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses configured month-first date format while parsing', (
    WidgetTester tester,
  ) async {
    SixWebAtendimentoDateFilterResult? result;
    await _pumpHarness(
      tester,
      dateFormatPattern: 'MM/dd/yyyy',
      onResult: (SixWebAtendimentoDateFilterResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('six-date-filter-start-field')),
      '08/10/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('six-date-filter-end-field')),
      '08/12/2026',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(result?.dataInicio, DateTime(2026, 8, 10));
    expect(result?.dataFim, DateTime(2026, 8, 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows recoverable validation error', (
    WidgetTester tester,
  ) async {
    bool completed = false;
    await _pumpHarness(tester, onResult: (_) => completed = true);

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('six-date-filter-start-field')),
      '12/08/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('six-date-filter-end-field')),
      '10/08/2026',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(
      find.text('A data final não pode ser anterior à inicial.'),
      findsOneWidget,
    );
    expect(find.text('Filtrar por data'), findsOneWidget);
    expect(completed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clear returns an empty range', (WidgetTester tester) async {
    SixWebAtendimentoDateFilterResult? result;
    await _pumpHarness(
      tester,
      dataInicio: DateTime(2026, 8, 10),
      dataFim: DateTime(2026, 8, 12),
      onResult: (SixWebAtendimentoDateFilterResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result?.dataInicio, isNull);
    expect(result?.dataFim, isNull);
    expect(find.text('Filtrar por data'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays within compact web viewport without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, size: const Size(1040, 760));

    await tester.tap(find.text('Abrir filtro'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar por data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  Size size = const Size(1400, 900),
  DateTime? dataInicio,
  DateTime? dataFim,
  String dateFormatPattern = 'dd/MM/yyyy',
  ValueChanged<SixWebAtendimentoDateFilterResult?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder:
              (BuildContext context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    final SixWebAtendimentoDateFilterResult? result =
                        await showSixWebAtendimentoDateFilterDialog(
                          context: context,
                          dataInicio: dataInicio,
                          dataFim: dataFim,
                          formatarData: _formatarData,
                          dateFormatPattern: dateFormatPattern,
                        );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir filtro'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _formatarData(DateTime? value) {
  if (value == null) return '';
  return '${_two(value.day)}/${_two(value.month)}/${value.year}';
}

String _two(int value) => value.toString().padLeft(2, '0');
