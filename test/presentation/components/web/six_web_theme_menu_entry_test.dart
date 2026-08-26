import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/components/web/six_web_theme_menu_entry.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/theme_provider.dart';

void main() {
  testWidgets('alterna o tema e fecha o menu apos a animacao', (
    WidgetTester tester,
  ) async {
    final ThemeProvider themeProvider = ThemeProvider(
      enableLocalPersistence: false,
      initialTheme: TemaSistema.claro,
    );
    addTearDown(() {
      themeProvider.dispose();
      SixThemeResolver().atualizarTema(TemaSistema.claro);
    });

    await tester.pumpWidget(_ThemeMenuHarness(themeProvider: themeProvider));

    await tester.tap(find.byKey(const Key('open-theme-menu')));
    await tester.pumpAndSettle();

    final double profileTop = tester.getTopLeft(find.text('Meu perfil')).dy;
    final double themeTop = tester.getTopLeft(find.text('Tema escuro')).dy;
    final double logoutTop = tester.getTopLeft(find.text('Sair')).dy;

    expect(profileTop, lessThan(themeTop));
    expect(themeTop, lessThan(logoutTop));
    expect(
      find.byKey(const ValueKey<String>('six-web-theme-toggle-sun')),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Ativar tema escuro'));
    await tester.pump();

    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(
      find.byKey(const ValueKey<String>('six-web-theme-toggle-moon')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();

    expect(find.text('Tema escuro'), findsNothing);
    expect(find.text('Sair'), findsNothing);
  });
}

class _ThemeMenuHarness extends StatelessWidget {
  const _ThemeMenuHarness({required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider provider, Widget? child) {
          return MaterialApp(
            theme: WebThemeTokens.applyTo(
              ThemeData.light(useMaterial3: true),
            ),
            darkTheme: WebThemeTokens.applyTo(
              ThemeData.dark(useMaterial3: true),
            ),
            themeMode: provider.themeMode,
            locale: const Locale('pt'),
            supportedLocales: const <Locale>[
              Locale('pt'),
              Locale('en'),
              Locale('es'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(
              body: Center(
                child: PopupMenuButton<String>(
                  key: const Key('open-theme-menu'),
                  constraints: const BoxConstraints(
                    minWidth: 228,
                    maxWidth: 248,
                  ),
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'profile',
                          child: Text('Meu perfil'),
                        ),
                        const SixWebThemeMenuEntry<String>(),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Sair'),
                        ),
                      ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
