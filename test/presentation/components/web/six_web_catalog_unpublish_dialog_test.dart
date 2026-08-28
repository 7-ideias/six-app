import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_catalog_unpublish_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  testWidgets('confirma uma única vez e conclui com sucesso', (
    WidgetTester tester,
  ) async {
    final Completer<void> confirmation = Completer<void>();
    int calls = 0;
    bool? result;

    await _pumpHarness(
      tester,
      onConfirm: () {
        calls += 1;
        return confirmation.future;
      },
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir diálogo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-unpublish-backdrop')), findsOneWidget);
    expect(find.text('Loja Horizonte'), findsOneWidget);

    await tester.tap(find.byKey(const Key('catalog-unpublish-confirm')));
    await tester.pump();
    expect(calls, 1);
    expect(
      find.byKey(const Key('catalog-unpublish-processing')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('catalog-unpublish-confirm')));
    await tester.pump();
    expect(calls, 1);

    confirmation.complete();
    await tester.pump();
    expect(find.byKey(const Key('catalog-unpublish-success')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('mantém o diálogo aberto e permite tentar novamente após erro', (
    WidgetTester tester,
  ) async {
    int calls = 0;

    await _pumpHarness(
      tester,
      onConfirm: () async {
        calls += 1;
        throw Exception('Falha simulada');
      },
    );

    await tester.tap(find.text('Abrir diálogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('catalog-unpublish-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('catalog-unpublish-error')), findsOneWidget);
    expect(find.text('Falha simulada'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.byKey(const Key('catalog-unpublish-confirm')));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function() onConfirm,
  ValueChanged<bool>? onResult,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      theme: WebThemeTokens.applyTo(ThemeData.light(useMaterial3: true)),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: FilledButton(
              onPressed: () async {
                final bool result = await showSixWebCatalogUnpublishDialog(
                  context: context,
                  commerceName: 'Loja Horizonte',
                  publicUrl: 'https://six.app/catalogo/abc123',
                  onConfirm: onConfirm,
                );
                onResult?.call(result);
              },
              child: const Text('Abrir diálogo'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
