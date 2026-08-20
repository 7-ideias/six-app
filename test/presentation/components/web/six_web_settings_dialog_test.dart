import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_settings_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows focused settings shell with blurred navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('six-settings-dialog-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('six-settings-dialog-badge')),
      findsOneWidget,
    );
    expect(find.text('Painel de configurações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes on escape while focused', (WidgetTester tester) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Painel de configurações'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes when tapping the blurred backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(find.text('Painel de configurações'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays within compact viewport without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1040, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHarness(tester, resetView: false);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Painel de configurações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(WidgetTester tester, {bool resetView = true}) async {
  if (resetView) {
    tester.view.physicalSize = const Size(1440, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

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
          builder: (BuildContext context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  showSixWebSettingsDialog(
                    context: context,
                    builder: (_) => const _FakeSettingsBody(),
                  );
                },
                child: const Text('Abrir configurações'),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSettingsBody extends StatelessWidget {
  const _FakeSettingsBody();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Container(
          width: 320,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text('Painel de configurações'),
        ),
      ),
    );
  }
}
