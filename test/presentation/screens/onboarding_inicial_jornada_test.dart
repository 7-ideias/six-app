import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/onboarding_inicial_service.dart';
import 'package:sixpos/core/services/perfil_negocio_service.dart';
import 'package:sixpos/data/models/onboarding_inicial_model.dart';
import 'package:sixpos/data/models/perfil_negocio_model.dart';
import 'package:sixpos/data/services/i18n/web_i18n_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/onboarding_inicial_mobile_screen.dart';
import 'package:sixpos/presentation/screens/onboarding_inicial_web_page.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/onboarding_inicial_provider.dart';

class _Jornada extends Fake implements OnboardingInicialService {
  _Jornada({required this.admin});
  final bool admin;

  @override
  Future<OnboardingInicialModel> buscar() async => OnboardingInicialModel(
    fezOnboardingInicial: false,
    podeConfigurarEmpresa: admin,
    idiomaPreferencial: 'pt-BR',
    nomeUsuario: 'Ana',
    nomeEmpresa: 'Loja',
    realizaVendas: true,
    prestaServicosTecnicos: false,
  );
}

class _Perfil extends Fake implements PerfilNegocioService {
  @override
  Future<String> empresaAtual() async => 'loja';

  @override
  Future<PerfilNegocioEmpresaModel> buscar(String empresaId) async =>
      PerfilNegocioEmpresaModel.fromJson({'perfil': {}, 'podeEditar': true});

  @override
  Future<CatalogoPerfilNegocioModel> catalogo(String empresaId) async =>
      CatalogoPerfilNegocioModel.fallbackV1();

  @override
  void dispose() {}
}

class _Regionalizacao extends Fake implements RegionalizacaoService {}

class _SemPacoteRemoto extends Fake implements SixI18nApiClient {
  @override
  Future<Map<String, dynamic>?> fetchMessages(
    String languageTag, {
    bool force = false,
  }) async => null;
}

Future<void> _abrir(
  WidgetTester tester, {
  required Size viewport,
  required bool mobile,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final onboarding = OnboardingInicialProvider(
    service: _Jornada(admin: !mobile),
  );
  await onboarding.carregar();
  final settings = LocaleSettingsProvider(
    regionalizacaoService: _Regionalizacao(),
    i18nApiClient: _SemPacoteRemoto(),
  );
  await settings.setUserLocale(const Locale('en', 'US'));
  await settings.applyAuthenticatedLocale(
    idiomaDePreferencia: 'en-US',
    idiomaDaJornada: onboarding.idiomaDaJornadaPendente,
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: onboarding),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          theme: ThemeData(brightness: brightness),
          locale: context.watch<LocaleSettingsProvider>().currentLocale,
          supportedLocales: LocaleSettingsProvider.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: mobile
              ? OnboardingInicialMobileScreen(onCompleted: (_) {})
              : OnboardingInicialWebPage(
                  onCompleted: () {},
                  createPerfilService: _Perfil.new,
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('web troca o idioma mantendo os dados', (tester) async {
    await _abrir(tester, viewport: const Size(1280, 800), mobile: false);
    expect(find.text('Vamos começar pelo essencial'), findsOneWidget);
    final portugues = find.widgetWithText(ChoiceChip, 'Português');
    expect(tester.widget<ChoiceChip>(portugues).selected, isTrue);
    await tester.enterText(find.byType(TextField).first, 'Michelli');
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Michelli'), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Empecemos por lo esencial'), findsOneWidget);
    expect(find.text('Paso 1 de 4'), findsOneWidget);
  });

  for (final size in [const Size(1179, 550), const Size(375, 620)]) {
    testWidgets('ramo e especialidade com rodapé visível em $size', (
      tester,
    ) async {
      await _abrir(
        tester,
        viewport: size,
        mobile: false,
        brightness: Brightness.dark,
      );
      final continuar = find.widgetWithText(FilledButton, 'Continuar');
      await tester.tap(continuar.hitTestable());
      await tester.pumpAndSettle();
      final ramo = find.text('Eletrônicos e acessórios');
      await tester.ensureVisible(ramo);
      await tester.tap(ramo.hitTestable());
      await tester.pumpAndSettle();
      final especialidade = find.text('Celulares');
      await tester.ensureVisible(especialidade);
      await tester.tap(especialidade.hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(continuar.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('O que sua empresa faz?'), findsOneWidget);
      await tester.tap(find.text('Voltar').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Etapa 2 de 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile mantém o idioma na etapa seguinte', (tester) async {
    await _abrir(tester, viewport: const Size(390, 844), mobile: true);
    expect(find.text('Em qual idioma deseja continuar?'), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué idioma deseas continuar?'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo podemos llamarte?'), findsOneWidget);
    expect(find.text('Comenzar a usar SixoApp'), findsOneWidget);
  });
}
