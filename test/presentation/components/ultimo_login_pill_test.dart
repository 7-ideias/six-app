import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/components/ultimo_login_pill.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class _RegionalClient extends Fake implements RegionalizacaoApiClient {}

void main() {
  for (final brightness in Brightness.values) {
    for (final language in ['pt', 'en', 'es']) {
      testWidgets(
        'pill acessível em $language / $brightness / largura estreita',
        (tester) async {
          final provider = LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _RegionalClient(),
            ),
          );
          final dark = brightness == Brightness.dark;
          final color = dark
              ? SixMobilePalette.successDark
              : SixMobilePalette.successLight;
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: provider,
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: const [
                  Locale('pt'),
                  Locale('en'),
                  Locale('es'),
                ],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: ThemeData(brightness: brightness),
                home: Scaffold(
                  body: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(1.8),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 220,
                        child: UltimoLoginPill(
                          ultimoLoginEm: DateTime.now().toUtc(),
                          hojeColor: color,
                          recenteColor: Colors.blue,
                          antigoColor: Colors.amber,
                          semRegistroColor: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          final title = switch (language) {
            'en' => 'Last sign-in',
            'es' => 'Último acceso',
            _ => 'Última entrada',
          };
          final text = tester.widget<Text>(find.textContaining(title).first);
          expect(text.style!.color, color);
          expect(find.byIcon(Icons.login_rounded), findsOneWidget);
          expect(find.byType(Tooltip), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          provider.dispose();
        },
      );
    }
  }
}
