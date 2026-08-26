import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_theme_toggle.dart';

void main() {
  testWidgets('exibe sol no tema claro e solicita ativacao do tema escuro', (
    WidgetTester tester,
  ) async {
    bool? requestedValue;

    await _pumpToggle(
      tester,
      isDark: false,
      onChanged: (bool value) => requestedValue = value,
    );

    expect(
      find.byKey(
        const ValueKey<String>('six-mobile-theme-toggle-sun'),
      ),
      findsOneWidget,
    );

    expect(find.bySemanticsLabel('Ativar tema escuro'), findsOneWidget);

    await tester.tap(find.byType(SixMobileThemeToggle));

    expect(requestedValue, isTrue);
  });

  testWidgets('exibe lua no tema escuro e solicita ativacao do tema claro', (
    WidgetTester tester,
  ) async {
    bool? requestedValue;

    await _pumpToggle(
      tester,
      isDark: true,
      onChanged: (bool value) => requestedValue = value,
    );

    expect(
      find.byKey(
        const ValueKey<String>('six-mobile-theme-toggle-moon'),
      ),
      findsOneWidget,
    );

    expect(find.bySemanticsLabel('Desativar tema escuro'), findsOneWidget);

    await tester.tap(find.byType(SixMobileThemeToggle));

    expect(requestedValue, isFalse);
  });

  testWidgets('remove movimento quando a acessibilidade pede reducao', (
    WidgetTester tester,
  ) async {
    await _pumpToggle(
      tester,
      isDark: false,
      disableAnimations: true,
      onChanged: (_) {},
    );

    final AnimatedContainer track = tester.widget<AnimatedContainer>(
      find.byKey(
        const ValueKey<String>('six-mobile-theme-toggle-track'),
      ),
    );
    final AnimatedPositioned thumbPosition =
        tester.widget<AnimatedPositioned>(
          find.byKey(
            const ValueKey<String>(
              'six-mobile-theme-toggle-thumb-position',
            ),
          ),
        );

    expect(track.duration, Duration.zero);
    expect(thumbPosition.duration, Duration.zero);
  });
}

Future<void> _pumpToggle(
  WidgetTester tester, {
  required bool isDark,
  required ValueChanged<bool> onChanged,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SixMobileThemeToggle(
              isDark: isDark,
              semanticsLabel:
                  isDark ? 'Desativar tema escuro' : 'Ativar tema escuro',
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}
