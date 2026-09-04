import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_logout_sheet.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_mobile_loading_scene.dart';

void main() {
  testWidgets('mobile overlay preserves context with adaptive iOS-like blur', (
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

      final DecoratedBox tint = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey<String>('sixoapp-mobile-loading-tint')),
      );
      final BoxDecoration decoration = tint.decoration as BoxDecoration;
      expect(
        decoration.color,
        colors.background.withValues(
          alpha: brightness == Brightness.dark ? 0.76 : 0.72,
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('sixoapp-mobile-loading-blur')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('sixoapp-mobile-loading-logo')),
        findsOneWidget,
      );
      expect(find.text('SixoApp'), findsNothing);
      expect(find.text('Finalizando sua venda...'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Finalizando sua venda...'),
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

  testWidgets('mobile overlay morphs into success only when requested', (
    WidgetTester tester,
  ) async {
    Widget buildOverlay({required bool isLoading, required bool isSuccess}) {
      return MaterialApp(
        theme: ThemeData.light(),
        home: SixoAppMobileLoadingOverlay(
          isLoading: isLoading,
          isSuccess: isSuccess,
          message: 'Finalizando sua venda...',
          successMessage: 'Venda concluída',
          child: const ColoredBox(color: Colors.pink),
        ),
      );
    }

    await tester.pumpWidget(buildOverlay(isLoading: true, isSuccess: false));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('sixoapp-mobile-loading-logo')),
      findsOneWidget,
    );

    await tester.pumpWidget(buildOverlay(isLoading: false, isSuccess: true));
    await tester.pump(const Duration(milliseconds: 240));

    expect(
      find.byKey(const ValueKey<String>('sixoapp-mobile-loading-success')),
      findsOneWidget,
    );
    expect(find.text('Venda concluída'), findsOneWidget);

    await tester.pumpWidget(buildOverlay(isLoading: false, isSuccess: false));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey<String>('sixoapp-mobile-loading-visible')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
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
