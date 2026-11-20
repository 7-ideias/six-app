import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/main.dart';
import 'package:sixpos/presentation/screens/colaborador_convite_mobile_page.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:sixpos/splash_screen.dart';

void main() {
  final mobile = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });
  const code = '0123456789abcdef';
  const invite = 'com.sixoapp.app://colaborador/convites/$code';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> start(WidgetTester tester, String route) async {
    tester.platformDispatcher.defaultRouteNameTestValue = route;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create:
                (_) => LocaleSettingsProvider(
                  regionalizacaoService: RegionalizacaoService(
                    apiClient: HttpRegionalizacaoApiClient(),
                  ),
                ),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }

  testWidgets('Inicialização normal monta o aplicativo e abre o splash', (
    tester,
  ) async {
    await start(tester, '/');
    expect(tester.takeException(), isNull);
    expect(find.byType(SplashScreen), findsOneWidget);
  }, variant: mobile);

  testWidgets('Convite abre direto e a rota nomeada / continua disponível', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await start(tester, invite);
      expect(tester.takeException(), isNull);
      final page = tester.widget<ColaboradorConviteMobilePage>(
        find.byType(ColaboradorConviteMobilePage),
      );
      expect(page.codigo, code);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
      navigator.pushNamed('/');
      await tester.pump();
      final splash = find.byType(SplashScreen, skipOffstage: false);
      expect(ModalRoute.of(tester.element(splash))?.settings.name, '/');
    }, () => MockClient((_) async => http.Response('{}', 404)));
  }, variant: mobile);
}
