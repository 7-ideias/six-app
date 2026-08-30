import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/etiqueta_models.dart';
import 'package:sixpos/domain/services/etiqueta/etiqueta_service.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_dialog.dart';
import 'package:sixpos/presentation/screens/etiqueta_impressao_web_page.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  testWidgets('opens inside animated shell and closes on escape', (
    WidgetTester tester,
  ) async {
    bool closed = false;

    tester.view.physicalSize = const Size(1440, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        theme: WebThemeTokens.applyTo(
          ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.dark,
            ),
          ),
        ),
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
                      await showSixWebAnimatedDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            insetPadding: const EdgeInsets.all(18),
                            clipBehavior: Clip.antiAlias,
                            backgroundColor:
                                WebThemeTokens.of(dialogContext).cardBackground,
                            surfaceTintColor: Colors.transparent,
                            child: SizedBox(
                              width: 1240,
                              height: 860,
                              child: EtiquetaImpressaoWebPage(
                                modelos: <EtiquetaModelo>[_model()],
                                service: EtiquetaService(),
                                onClose: () {
                                  closed = true;
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Abrir impressão'),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir impressão'));
    await tester.pumpAndSettle();

    expect(find.text('Imprimir etiquetas'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(find.text('Imprimir etiquetas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

EtiquetaModelo _model() {
  return const EtiquetaModelo(
    id: 'modelo-1',
    nome: 'Modelo 60x30',
    papel: EtiquetaPapel(preset: 'A4', larguraMm: 210, alturaMm: 297),
    grade: EtiquetaGrade(colunas: 3, linhas: 8),
    etiqueta: EtiquetaTamanho(larguraMm: 60, alturaMm: 30),
  );
}
