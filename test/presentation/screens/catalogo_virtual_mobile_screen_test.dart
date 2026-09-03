import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/catalogo_publico_service.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/catalogo_virtual_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SixThemeResolver().atualizarTema(TemaSistema.escuro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets(
    'renderiza a jornada própria do catálogo virtual com contraste dark',
    (WidgetTester tester) async {
      final _FakeCatalogoPublicoService service = _FakeCatalogoPublicoService(
        _configuration(),
      );

      await _pumpScreen(tester, service: service);

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        SixMobileColorScheme.dark.background,
      );
      expect(
        find.byKey(
          const ValueKey<String>('catalog-virtual-mobile-publication-card'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('catalog-virtual-mobile-editor-presentation'),
        ),
        findsOneWidget,
      );
      expect(find.text('Catálogo virtual'), findsOneWidget);
      expect(find.text('Publicado'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('catalog-virtual-mobile-editor-presentation'),
        ),
      );
      await tester.pumpAndSettle();

      final Finder sheet = find.byKey(
        const ValueKey<String>('catalog-virtual-mobile-editor-sheet'),
      );
      expect(sheet, findsOneWidget);
      expect(
        tester.widget<Material>(sheet).color,
        SixMobileColorScheme.dark.surface,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edita a apresentação e salva pela barra mobile', (
    WidgetTester tester,
  ) async {
    final _FakeCatalogoPublicoService service = _FakeCatalogoPublicoService(
      _configuration(),
    );
    await _pumpScreen(tester, service: service);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('catalog-virtual-mobile-editor-presentation'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-title-field')),
      'Assistência sem complicação',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-save-bar')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-save')),
    );
    await tester.pumpAndSettle();

    expect(service.updateCount, 1);
    expect(
      service.current.personalizacao.titulo,
      'Assistência sem complicação',
    );
    expect(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-save-bar')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirma a retirada do catálogo antes de salvar', (
    WidgetTester tester,
  ) async {
    final _FakeCatalogoPublicoService service = _FakeCatalogoPublicoService(
      _configuration(),
    );
    await _pumpScreen(tester, service: service);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Despublicar catálogo?'), findsOneWidget);
    await tester.tap(find.text('Despublicar'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-save-bar')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-save')),
    );
    await tester.pumpAndSettle();

    expect(service.updateCount, 1);
    expect(service.current.ativo, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantém os editores navegáveis em uma tela compacta', (
    WidgetTester tester,
  ) async {
    final _FakeCatalogoPublicoService service = _FakeCatalogoPublicoService(
      _configuration(),
    );
    await _pumpScreen(
      tester,
      service: service,
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(1.15),
    );

    final Finder contentEditor = find.byKey(
      const ValueKey<String>('catalog-virtual-mobile-editor-content'),
    );
    await tester.ensureVisible(contentEditor);
    await tester.pumpAndSettle();
    await tester.tap(contentEditor);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('catalog-virtual-mobile-editor-sheet')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required CatalogoPublicoService service,
  Size size = const Size(390, 900),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>(
      create:
          (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _FakeRegionalizacaoApiClient(),
            ),
          ),
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[
          Locale('pt', 'BR'),
          Locale('en', 'US'),
          Locale('es', 'ES'),
        ],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 1,
            disableAnimations: true,
            accessibleNavigation: true,
            textScaler: textScaler,
          ),
          child: CatalogoVirtualMobileScreen(service: service),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

CatalogoPublicoConfiguracaoModel _configuration() {
  return const CatalogoPublicoConfiguracaoModel(
    ativo: true,
    token: 'catalog-token',
    url: 'https://sixapp.com/catalogo/catalog-token',
    locale: 'pt-BR',
    currencyCode: 'BRL',
    personalizacao: CatalogoPublicoPersonalizacaoModel(
      titulo: 'Oficina do bairro',
      descricao: 'Reparos e acessórios em um só lugar.',
      corPrincipal: '#126BFF',
    ),
    empresa: CatalogoPublicoEmpresaPreviewModel(
      nome: 'Oficina do bairro',
      endereco: 'Rua Central, 10',
      whatsapp: '5511999999999',
    ),
    produtos: <CatalogoPublicoProdutoPreviewModel>[
      CatalogoPublicoProdutoPreviewModel(
        id: 'produto-1',
        nome: 'Troca de tela',
        modelo: 'Smartphone',
        preco: 249.9,
      ),
    ],
  );
}

class _FakeCatalogoPublicoService extends CatalogoPublicoService {
  _FakeCatalogoPublicoService(this.current)
    : super(client: MockClient((_) async => http.Response('{}', 500)));

  CatalogoPublicoConfiguracaoModel current;
  int updateCount = 0;

  @override
  Future<CatalogoPublicoConfiguracaoModel> buscarConfiguracao({
    String? baseUrl,
  }) async {
    return current;
  }

  @override
  Future<CatalogoPublicoConfiguracaoModel> atualizarConfiguracao({
    required bool ativo,
    required CatalogoPublicoPersonalizacaoModel personalizacao,
    String? baseUrl,
  }) async {
    updateCount += 1;
    current = current.copyWith(ativo: ativo, personalizacao: personalizacao);
    return current;
  }
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() {
    throw UnimplementedError();
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) {
    throw UnimplementedError();
  }
}
