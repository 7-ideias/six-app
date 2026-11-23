import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/consulta_vendas_models.dart';
import 'package:sixpos/data/services/vendas/consulta_vendas_api_client.dart';
import 'package:sixpos/presentation/screens/consulta_vendas_web_page.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class _Vendas implements ConsultaVendasApiClient {
  final consultas = <ConsultaVendasFiltro>[];

  @override
  Future<ConsultaVendasResponse> consultar(ConsultaVendasFiltro filtro) async {
    consultas.add(filtro);
    return ConsultaVendasResponse.fromJson({});
  }

  @override
  Future<VendaDetalheResponse> detalhar(String identificador) =>
      throw UnimplementedError();
}

Finder _campo(String nome) => find.byKey(ValueKey('sales-filter-$nome'));

void main() {
  for (final (width, columns, dark, locale, scale) in [
    (1600.0, 4, false, 'pt', 1.0),
    (1280.0, 4, true, 'en', 1.0),
    (960.0, 2, false, 'es', 1.25),
    (420.0, 1, true, 'pt', 1.0),
  ]) {
    testWidgets('Filtros de vendas em $columns colunas • $width • $locale', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final api = _Vendas();
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LocaleSettingsProvider(),
          child: MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            locale: Locale(locale),
            supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
            home: Scaffold(
              body: ConsultaVendasWebPage(
                apiClient: api,
                vendedoresLoader: () async => [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cells = [
        'search',
        'period',
        'sellers',
        'order',
        'finances',
        'returns',
        'min',
        'max',
      ];
      final first = tester.getRect(_campo('search'));
      for (final (i, name) in cells.indexed) {
        final rect = tester.getRect(_campo(name));
        expect(rect.width, closeTo(first.width, 0.01));
        expect(rect.height, closeTo(first.height, 0.01));
        expect(
          rect.left,
          closeTo(first.left + (i % columns) * (first.width + 12), 0.01),
        );
        expect(
          rect.top,
          closeTo(first.top + (i ~/ columns) * (first.height + 12), 0.01),
        );
      }
      for (final name in ['search', 'min', 'max']) {
        final editable = find.descendant(
          of: _campo(name),
          matching: find.byType(EditableText),
        );
        final border = InputDecorator.containerOf(tester.element(editable))!;
        expect(border.size, first.size, reason: 'Borda visível do campo $name');
      }
      if (width == 1600) {
        await tester.enterText(_campo('search'), 'Cabo USB');
        await tester.enterText(_campo('min'), '10');
        await tester.enterText(_campo('max'), '25');
        await tester.ensureVisible(_campo('period'));
        await tester.tap(_campo('period'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Intervalo personalizado').last);
        await tester.pumpAndSettle();
        expect(tester.getSize(_campo('from')), first.size);
        expect(tester.getSize(_campo('to')), first.size);
        final aplicar = find.text('Aplicar filtros');
        await tester.ensureVisible(aplicar);
        await tester.tap(aplicar);
        await tester.pumpAndSettle();
        expect(api.consultas.last.busca, 'Cabo USB');
        expect(api.consultas.last.valorMinimo, 10);
        expect(api.consultas.last.valorMaximo, 25);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
