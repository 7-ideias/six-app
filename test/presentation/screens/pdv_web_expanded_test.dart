import 'package:flutter/material.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/domain/services/caixa/caixa_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/models/streak_models.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/data/services/streak/streak_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/domain/services/streak/streak_service.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/pagina_principal_web.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/streak_provider.dart';

void main() {
  testWidgets('mantem conteudo da frente de caixa ao expandir', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_PdvExpandedTestApp());
    await tester.pump();

    final Element pageElement = tester.element(find.byType(PaginaPrincipalWeb));
    expect(acionarPdvFrenteCaixaPeloElemento(pageElement), isTrue);
    await tester.pump();

    expect(find.text('Frente de caixa'), findsOneWidget);

    await tester.tap(find.byTooltip('Expandir frente de caixa'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('pdv-expanded-front-desk-overlay')),
      findsOneWidget,
    );
    expect(find.text('Frente de caixa'), findsOneWidget);
    expect(find.text('Itens da venda'), findsOneWidget);
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'caixa fechado exibe apenas o aviso e a abertura ($brightness)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1366, 768));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _PdvExpandedTestApp(open: false, brightness: brightness),
        );
        await tester.pump();
        final page = tester.element(find.byType(PaginaPrincipalWeb));
        expect(acionarPdvFrenteCaixaPeloElemento(page), isTrue);
        await tester.pump();
        await tester.pump();
        expect(
          find.text('Abra o caixa para iniciar uma venda.'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilledButton, 'Abrir caixa'),
          findsOneWidget,
        );
        expect(find.text('Vendas a receber'), findsNothing);
        expect(find.byTooltip('Operações de caixa'), findsNothing);
        expect(find.text('Itens da venda'), findsNothing);
      },
    );
  }
}

class _FakeCaixaService extends Fake implements CaixaService {
  _FakeCaixaService(this.open);
  final bool open;

  @override
  Future<CaixaSessao?> buscarSessaoAtual() async =>
      open ? CaixaSessao.fromJson({'status': 'aberta'}) : null;
}

class _PdvExpandedTestApp extends StatelessWidget {
  const _PdvExpandedTestApp({
    this.open = true,
    this.brightness = Brightness.light,
  });
  final bool open;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<EmpresaProvider>.value(value: EmpresaProvider()),
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>(
          create: (_) => ColaboradorAutorizacoesProvider(),
        ),
        ChangeNotifierProvider<StreakProvider>(
          create:
              (_) => StreakProvider(
                service: StreakService(apiClient: _FakeStreakApiClient()),
              ),
        ),
        ChangeNotifierProvider<LocaleSettingsProvider>(
          create:
              (_) => LocaleSettingsProvider(
                regionalizacaoService: RegionalizacaoService(
                  apiClient: _FakeRegionalizacaoApiClient(),
                ),
              ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        locale: const Locale('pt'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaginaPrincipalWeb(caixaService: _FakeCaixaService(open)),
      ),
    );
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

class _FakeStreakApiClient implements StreakApiClient {
  @override
  Future<UserStreaksModel> getStreaks({String? timezone}) {
    return Future<UserStreaksModel>.value(_loadedStreaks);
  }

  @override
  Future<UserStreaksModel> registerActivity(StreakActivityRequest request) {
    return Future<UserStreaksModel>.value(_loadedStreaks);
  }
}

const UserStreaksModel _loadedStreaks = UserStreaksModel(
  mobile: UserStreakScopeModel(
    currentDays: 0,
    longestDays: 0,
    activeToday: false,
  ),
  web: UserStreakScopeModel(currentDays: 0, longestDays: 0, activeToday: true),
  shared: UserStreakScopeModel(
    currentDays: 0,
    longestDays: 0,
    activeToday: false,
  ),
);
