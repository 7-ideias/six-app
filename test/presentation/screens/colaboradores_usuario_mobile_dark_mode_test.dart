import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_mobile_screen.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('collaborators list keeps dark mobile surfaces', (
    WidgetTester tester,
  ) async {
    await _pumpCollaborators(
      tester,
      apiClient: _FakeColaboradorUsuarioApiClient(
        colaboradores: <ColaboradorUsuarioResumo>[
          _colaborador(
            id: 'colab-1',
            nome: 'Equipe Alfa',
            nomeDeGuerra: 'Alfa',
            email: 'alfa@six.test',
            celular: '+55 11 99999-0001',
          ),
          _colaborador(
            id: 'colab-2',
            nome: 'Equipe Beta',
            nomeDeGuerra: '',
            email: '',
            celular: '+55 11 99999-0002',
          ),
        ],
      ),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Colaboradores encontrados'), findsOneWidget);
    expect(find.text('Equipe Alfa'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Equipe'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Equipe Alfa'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Buscar colaborador...'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('collaborators empty state keeps dark mobile surface', (
    WidgetTester tester,
  ) async {
    await _pumpCollaborators(
      tester,
      apiClient: _FakeColaboradorUsuarioApiClient(),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Nenhum colaborador encontrado'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhum colaborador encontrado'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('admin sees performance shortcut below the summary cards', (
    WidgetTester tester,
  ) async {
    await _pumpCollaborators(
      tester,
      apiClient: _FakeColaboradorUsuarioApiClient(
        colaboradores: <ColaboradorUsuarioResumo>[
          _colaborador(
            id: 'colab-1',
            nome: 'Equipe Alfa',
            nomeDeGuerra: 'Alfa',
            email: 'alfa@six.test',
            celular: '+55 11 99999-0001',
          ),
        ],
      ),
      colaboradorProvider: _AdminAutorizacoesProvider(),
    );

    expect(
      find.byKey(const ValueKey<String>('colaboradores-performance-card')),
      findsOneWidget,
    );
    expect(find.text('Desempenho do colaborador'), findsOneWidget);
    expect(
      tester
              .getTopLeft(
                find.byKey(
                  const ValueKey<String>('colaboradores-performance-card'),
                ),
              )
              .dy >
          tester.getTopLeft(find.text('Buscar colaborador...')).dy,
      isFalse,
    );
  });

  testWidgets('collaborator does not see performance shortcut', (
    WidgetTester tester,
  ) async {
    await _pumpCollaborators(
      tester,
      apiClient: _FakeColaboradorUsuarioApiClient(
        colaboradores: <ColaboradorUsuarioResumo>[
          _colaborador(
            id: 'colab-1',
            nome: 'Equipe Alfa',
            nomeDeGuerra: 'Alfa',
            email: 'alfa@six.test',
            celular: '+55 11 99999-0001',
          ),
        ],
      ),
      colaboradorProvider: _CollaboratorAutorizacoesProvider(),
    );

    expect(
      find.byKey(const ValueKey<String>('colaboradores-performance-card')),
      findsNothing,
    );
    expect(find.text('Desempenho do colaborador'), findsNothing);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpCollaborators(
  WidgetTester tester, {
  required ColaboradorUsuarioApiClient apiClient,
  Brightness brightness = Brightness.dark,
  ColaboradorAutorizacoesProvider? colaboradorProvider,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final bool isDark = brightness == Brightness.dark;
  SixThemeResolver().atualizarTema(
    isDark ? TemaSistema.escuro : TemaSistema.claro,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleSettingsProvider>(
          create:
              (_) => LocaleSettingsProvider(
                regionalizacaoService: RegionalizacaoService(
                  apiClient: _FakeRegionalizacaoApiClient(),
                ),
              ),
        ),
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>.value(
          value: colaboradorProvider ?? _AdminAutorizacoesProvider(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
            size: Size(390, 900),
            devicePixelRatio: 1,
          ),
          child: ColaboradoresUsuarioMobileScreen(apiClient: apiClient),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

ColaboradorUsuarioResumo _colaborador({
  required String id,
  required String nome,
  required String nomeDeGuerra,
  required String email,
  required String celular,
}) {
  return ColaboradorUsuarioResumo(
    idUnicoPessoal: id,
    nome: nome,
    nomeDeGuerra: nomeDeGuerra,
    celularDeAcesso: celular,
    email: email,
    foto: '',
    dataCadastro: DateTime(2026, 8, 16),
  );
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasDecoratedAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Container>(
        find.ancestor(of: child, matching: find.byType(Container)),
      )
      .any((Container container) {
        final Decoration? decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == expected;
      });
}

class _FakeColaboradorUsuarioApiClient implements ColaboradorUsuarioApiClient {
  const _FakeColaboradorUsuarioApiClient({
    this.colaboradores = const <ColaboradorUsuarioResumo>[],
  });

  final List<ColaboradorUsuarioResumo> colaboradores;

  @override
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(String idUnicoDoUsuario) {
    throw UnimplementedError();
  }

  @override
  Future<void> editarColaborador(Map<String, dynamic> payload) {
    throw UnimplementedError();
  }

  @override
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores() async {
    return colaboradores;
  }

  @override
  Future<List<ColaboradorUsuarioResumo>>
  listarTecnicosAssistenciaTecnica() async {
    return colaboradores;
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

class _AdminAutorizacoesProvider extends ColaboradorAutorizacoesProvider {
  @override
  bool get ehColaborador => false;
}

class _CollaboratorAutorizacoesProvider
    extends ColaboradorAutorizacoesProvider {
  @override
  bool get ehColaborador => true;
}
