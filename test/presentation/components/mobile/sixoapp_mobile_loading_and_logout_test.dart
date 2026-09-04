import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_logout_sheet.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_mobile_loading_scene.dart';

void main() {
  testWidgets('themed mobile loading follows light and dark backgrounds', (
    WidgetTester tester,
  ) async {
    for (final Brightness brightness in <Brightness>[
      Brightness.light,
      Brightness.dark,
    ]) {
      final SixMobileColorScheme colors =
          brightness == Brightness.dark
              ? SixMobileColorScheme.dark
              : SixMobileColorScheme.light;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (BuildContext context) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: true, accessibleNavigation: true),
                child: const SixoAppMobileLoadingOverlay(
                  isLoading: true,
                  message: 'Finalizando sua venda...',
                  child: ColoredBox(color: Colors.pink),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final ColoredBox background = tester.widget<ColoredBox>(
        find.byKey(const ValueKey<String>('sixoapp-mobile-loading-background')),
      );
      expect(background.color, colors.background);
      expect(find.text('SixoApp'), findsOneWidget);
      expect(find.text('Finalizando sua venda...'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('SixoApp'),
          matching: find.byType(Material),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sixoapp-mobile-loading-visible')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('logout uses Cupertino presentation and requires full swipe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const _LogoutHarness()),
    );

    await tester.tap(find.text('Abrir saída'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byIcon(CupertinoIcons.power), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('six-mobile-logout-slider')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('six-mobile-logout-slider')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resultado: null'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey<String>('six-mobile-logout-slider')),
      const Offset(380, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resultado: true'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logout cancel keeps the current session flow untouched', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.light(), home: const _LogoutHarness()),
    );

    await tester.tap(find.text('Abrir saída'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('six-mobile-logout-cancel')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resultado: false'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LogoutHarness extends StatefulWidget {
  const _LogoutHarness();

  @override
  State<_LogoutHarness> createState() => _LogoutHarnessState();
}

class _LogoutHarnessState extends State<_LogoutHarness> {
  bool? _result;

  Future<void> _open() async {
    final bool result = await showSixMobileLogoutSheet(context);
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FilledButton(onPressed: _open, child: const Text('Abrir saída')),
            Text('Resultado: $_result'),
          ],
        ),
      ),
    );
  }
}
