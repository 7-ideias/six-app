import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_logout_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows focused content with blurred navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: () async {});

    await tester.tap(find.text('Abrir logout'));
    await tester.pumpAndSettle();

    expect(find.text('Encerrar sessão agora?'), findsOneWidget);
    expect(
      find.text('A sessão atual será encerrada somente neste navegador.'),
      findsOneWidget,
    );
    expect(find.text('Sair agora'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps dialog busy during processing and transitions to success',
    (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      bool? result;
      await _pumpHarness(
        tester,
        onConfirm: () => completer.future,
        onResult: (bool value) => result = value,
      );

      await tester.tap(find.text('Abrir logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair agora'));
      await tester.pump();

      expect(find.text('Encerrando sessão...'), findsOneWidget);
      expect(find.text('Encerrar sessão agora?'), findsOneWidget);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Sessão encerrada com sucesso'), findsOneWidget);
      expect(
        find.text('Preparando o retorno para a tela pública de login.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 850));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Encerrar sessão agora?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows recoverable error and allows cancel after failure', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async => throw StateError('session error'),
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair agora'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível encerrar a sessão agora. Tente novamente em alguns instantes.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sair agora'), findsOneWidget);

    await tester.tap(find.text('Continuar conectado'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Encerrar sessão agora?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes on escape while in review state', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async {},
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir logout'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Encerrar sessão agora?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores escape while processing', (WidgetTester tester) async {
    final Completer<void> completer = Completer<void>();
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () => completer.future,
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair agora'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.text('Encerrando sessão...'), findsOneWidget);
    expect(result, isNull);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(tester.takeException(), isNull);
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
                    final bool result = await showSixWebLogoutDialog(
                      context: context,
                      onConfirm: onConfirm,
                    );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir logout'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
