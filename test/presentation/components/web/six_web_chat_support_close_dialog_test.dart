import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_chat_support_close_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows requester summary over the focused navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: () async {});

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();

    expect(find.text('Concluir este atendimento?'), findsOneWidget);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Comércio Exemplo'), findsOneWidget);
    expect(find.text('Concluir atendimento'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks duplicate action and morphs into success', (
    WidgetTester tester,
  ) async {
    final Completer<void> completer = Completer<void>();
    int confirmations = 0;
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () {
        confirmations++;
        return completer.future;
      },
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir atendimento'));
    await tester.pump();

    expect(find.text('Concluindo...'), findsOneWidget);
    expect(confirmations, 1);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Atendimento concluído'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Concluir este atendimento?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a recoverable error in the dialog', (
    WidgetTester tester,
  ) async {
    bool? result;
    await _pumpHarness(
      tester,
      onConfirm: () async => throw StateError('backend unavailable'),
      onResult: (bool value) => result = value,
    );

    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir atendimento'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível concluir. Verifique sua conexão e tente novamente.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
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
          builder: (BuildContext context) => Center(
            child: FilledButton(
              onPressed: () async {
                final bool result = await showSixWebChatSupportCloseDialog(
                  context: context,
                  requesterName: 'Maria Silva',
                  companyName: 'Comércio Exemplo',
                  onConfirm: onConfirm,
                );
                onResult?.call(result);
              },
              child: const Text('Abrir confirmação'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
