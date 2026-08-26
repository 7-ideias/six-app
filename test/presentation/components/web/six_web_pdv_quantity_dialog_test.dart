import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_pdv_quantity_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows focused backdrop and contextual summary', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: (_) async {});

    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();

    expect(find.text('Editar quantidade'), findsOneWidget);
    expect(find.text('Bone Preto'), findsOneWidget);
    expect(find.text('Código: 1782837527'), findsOneWidget);
    expect(find.text('Quantidade atual'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
    expect(find.text('Aplicar quantidade'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes on escape while in review state', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: (_) async {},
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Editar quantidade'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'blocks duplicate submit, ignores escape while processing and morphs into success',
    (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      int confirmCalls = 0;
      int? appliedQuantity;
      bool? result;
      await _pumpHarness(
        tester,
        onConfirm: (int quantity) {
          confirmCalls += 1;
          appliedQuantity = quantity;
          return completer.future;
        },
        onResult: (bool value) => result = value,
      );

      await tester.tap(find.text('Abrir editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('pdv-quantity-field')),
        '125',
      );
      await tester.tap(find.text('Aplicar quantidade'));
      await tester.pump();
      await tester.tap(find.text('Aplicando quantidade...'));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(confirmCalls, 1);
      expect(appliedQuantity, 125);
      expect(find.text('Aplicando quantidade...'), findsOneWidget);
      expect(result, isNull);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Quantidade atualizada'), findsOneWidget);
      expect(
        find.text(
          'O item foi recalculado e a venda já reflete a nova quantidade.',
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 850));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Editar quantidade'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows recoverable error and allows cancel after failure', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: (_) async => throw StateError('update error'),
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar quantidade'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível atualizar a quantidade agora. Tente novamente em alguns instantes.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Editar quantidade'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies dedicated dark colors to surface and actions', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(
      tester,
      onConfirm: (_) async {},
      themeMode: ThemeMode.dark,
      theme: WebThemeTokens.applyTo(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.light,
          ),
        ),
      ),
      darkTheme: WebThemeTokens.applyTo(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();

    final Finder dialogMaterialFinder = find.ancestor(
      of: find.byKey(const ValueKey<String>('pdv-quantity-review')),
      matching: find.byType(Material),
    );
    final Material dialogMaterial = tester.widget<Material>(
      dialogMaterialFinder.first,
    );
    final Finder dialogScope = find.byKey(
      const ValueKey<String>('pdv-quantity-review'),
    );
    final FilledButton filledButton = tester.widget<FilledButton>(
      find.descendant(of: dialogScope, matching: find.byType(FilledButton)),
    );
    final TextButton textButton = tester.widget<TextButton>(
      find.descendant(of: dialogScope, matching: find.byType(TextButton)),
    );

    expect(dialogMaterial.color, const Color(0xFF17253A));
    expect(
      filledButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF4151D9),
    );
    expect(
      textButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF8DAAFD),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function(int quantity) onConfirm,
  ValueChanged<bool>? onResult,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      theme:
          theme ?? WebThemeTokens.applyTo(ThemeData.light(useMaterial3: true)),
      darkTheme:
          darkTheme ??
          WebThemeTokens.applyTo(ThemeData.dark(useMaterial3: true)),
      themeMode: themeMode ?? ThemeMode.light,
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
                    final bool result = await showSixWebPdvQuantityDialog(
                      context: context,
                      productName: 'Bone Preto',
                      productCode: '1782837527',
                      currentQuantity: 10,
                      onConfirm: onConfirm,
                    );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir editor'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
