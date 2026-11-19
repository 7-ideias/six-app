import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/web_i18n_store.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_mobile.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_web.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  const email = 'conta@example.test';
  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    for (final web in [true, false]) {
      testWidgets('troca de senha exibe destinatário fixo (web=$web, $tema)', (
        tester,
      ) async {
        final locale = LocaleSettingsProvider(
          regionalizacaoService: RegionalizacaoService(
            apiClient: HttpRegionalizacaoApiClient(),
          ),
        );
        addTearDown(locale.dispose);
        SixI18nStore.instance.setMessages(locale.languageCode, {
          'authBack': 'Back',
        });
        SixI18nStore.instance.setMessages('en', {'authBack': 'Back'});
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: locale),
              ChangeNotifierProvider(
                create:
                    (_) => ThemeProvider(
                      enableLocalPersistence: false,
                      initialTheme:
                          tema == ThemeMode.dark
                              ? TemaSistema.escuro
                              : TemaSistema.claro,
                    ),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: tema,
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: TextButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) =>
                                        web
                                            ? const EsqueceuSenhaWeb.alterarSenha(
                                              emailDaConta: email,
                                            )
                                            : const EsqueceuSenhaMobile.alterarSenha(
                                              emailDaConta: email,
                                            ),
                              ),
                            ),
                        child: const Text('Profile'),
                      ),
                    ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Change password'), findsOneWidget);
        expect(find.text(email), findsOneWidget);
        expect(find.byType(EditableText), findsNothing);
        await tester.tap(
          web ? find.text('Back') : find.byIcon(Icons.arrow_back_ios_rounded),
        );
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);
      });
    }
  }
}
