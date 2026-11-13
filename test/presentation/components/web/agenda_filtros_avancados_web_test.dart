import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/agenda_filtros_avancados_web.dart';
import 'package:sixpos/presentation/components/web/agenda_resumo_periodo_web.dart';

Future<void> _open(
  WidgetTester tester, {
  required ValueChanged<AgendaFiltrosAvancados?> onResult,
  String language = 'pt',
  double width = 1100,
  bool canceled = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      locale: Locale(language),
      supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onResult(
              await showAgendaFiltrosAvancadosWeb(
                context: context,
                initial: AgendaFiltrosAvancados(pagamentos: {'Pix'}),
                pagamentos: const ['Pix', 'Cartão'],
                centros: const ['Oficina', 'Administração'],
                espaco: 'Empresa',
                statusCancelado: canceled,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'fechar descarta o rascunho e reabrir restaura filtros aplicados',
    (tester) async {
      AgendaFiltrosAvancados? result;
      var closed = false;
      await _open(
        tester,
        onResult: (value) {
          result = value;
          closed = true;
        },
      );
      await _tap(tester, find.text('Cartão'));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(closed, true);
      expect(result, null);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final selected = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(selected.where((tile) => tile.value == true).length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('aplicar retorna todas as dimensões em uma única confirmação', (
    tester,
  ) async {
    AgendaFiltrosAvancados? result;
    var calls = 0;
    await _open(
      tester,
      onResult: (value) {
        result = value;
        calls++;
      },
    );
    await _tap(tester, find.text('Cartão'));
    await _tap(tester, find.text('Oficina'));
    await _tap(tester, find.byKey(const ValueKey('ir-filter')));
    await _tap(tester, find.text('Mostrar cancelados'));
    expect(calls, 0);
    await _tap(tester, find.byKey(const ValueKey('agenda-apply-filters')));
    expect(calls, 1);
    expect(result!.pagamentos, {'Pix', 'Cartão'});
    expect(result!.centros, {'Oficina'});
    expect(result!.somenteImpostoRenda, true);
    expect(result!.mostrarCancelados, true);
  });

  testWidgets(
    'limpar só é efetivado ao aplicar; status cancelado continua explícito',
    (tester) async {
      AgendaFiltrosAvancados? result;
      await _open(tester, canceled: true, onResult: (value) => result = value);
      await _tap(tester, find.text('Limpar'));
      expect(result, null);
      final showCanceled = find.widgetWithText(
        SwitchListTile,
        'Mostrar cancelados',
      );
      await tester.ensureVisible(showCanceled);
      final tile = tester.widget<SwitchListTile>(showCanceled);
      expect(tile.value, true);
      expect(tile.onChanged, null);
      await _tap(tester, find.byKey(const ValueKey('agenda-apply-filters')));
      expect(result!.pagamentos, isEmpty);
      expect(result!.centros, isEmpty);
    },
  );

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('painel compacto sem overflow em $language', (tester) async {
      await _open(tester, language: language, width: 390, onResult: (_) {});
      await _tap(tester, find.text('Cartão'));
      await _tap(tester, find.byKey(const ValueKey('ir-filter')));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byKey(const ValueKey('agenda-apply-filters')));
      expect(find.byType(AgendaFiltrosAvancadosWeb), findsNothing);
    });
  }

  testWidgets('recolher resumo preserva valores ao expandir novamente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgendaResumoPeriodoWeb(
              receberAberto: 0,
              pagarAberto: 0,
              saldoARealizar: 0,
              recebido: 4800,
              pago: 1352.81,
              realizado: 3447.19,
              projetado: 3447.19,
              formatarMoeda: (value) => value.toStringAsFixed(2),
              onRecebido: () {},
              onPago: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('agenda-summary-toggle')));
    expect(
      find.byKey(const ValueKey('period-summary-panel-open')),
      findsNothing,
    );
    await _tap(tester, find.byKey(const ValueKey('agenda-summary-toggle')));
    expect(find.text('4800.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
