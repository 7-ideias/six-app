import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/domain/services/workspace_home/workspace_home_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/screens/workspace_home_web.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

void main() {
  setUp(() {
    UsuarioProvider().setUsuario(
      UsuarioModel(
        nome: 'Ana',
        sobrenome: 'Souza',
        cpf: '',
        registroProfissional: '',
        email: 'ana@six.test',
        nomeDeGuerra: 'Ana',
      ),
    );
    EmpresaProvider().setEmpresa(
      EmpresaModel(
        nomeEmpresa: 'Assistência Cartaxo LTDA',
        nomeFantasia: 'Assistência Cartaxo',
        documentoNoBrasilCNPJ: '',
      ),
    );
  });

  tearDown(() {
    UsuarioProvider().clear();
    EmpresaProvider().clear();
  });

  group('WorkspaceHomeWeb', () {
    testWidgets(
      'renderiza dados reais disponíveis e omite blocos indisponíveis',
      (WidgetTester tester) async {
        final _RecordingActions actions = _RecordingActions();

        await _pumpHome(
          tester,
          service: _FakeWorkspaceHomeService(_home(financialAvailable: false)),
          actions: actions,
          permissions: _FakeAutorizacoesProvider(admin: true),
        );

        expect(find.text('Meu dia no SixApp'), findsOneWidget);
        expect(find.text('Olá, Ana'), findsOneWidget);
        expect(find.text('Assistência Cartaxo'), findsOneWidget);
        expect(find.text('Hoje: 10/08/2026'), findsOneWidget);
        expect(find.text('Caixa'), findsWidgets);
        expect(find.text('Aberto'), findsOneWidget);
        expect(find.text('desde 08:12'), findsOneWidget);
        expect(find.text('Assistências'), findsWidgets);
        expect(find.text('8 em andamento'), findsOneWidget);
        expect(find.text('A receber hoje'), findsNothing);
        expect(find.text('A pagar hoje'), findsNothing);
        expect(find.text('1 produto com estoque negativo'), findsOneWidget);
      },
    );

    testWidgets('caixa aberto em outro dia mostra data e hora local', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        service: _FakeWorkspaceHomeService(
          _home(openedAt: '2026-08-09T14:31:00Z'),
        ),
        permissions: _FakeAutorizacoesProvider(admin: true),
      );

      expect(find.text('desde 09/08/2026 às 11:31'), findsOneWidget);
      expect(find.text('desde 14:31'), findsNothing);
    });

    testWidgets('alertas acionáveis navegam pelo resolver existente', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();

      await _pumpHome(
        tester,
        service: _FakeWorkspaceHomeService(_home()),
        actions: actions,
        permissions: _FakeAutorizacoesProvider(admin: true),
      );

      await tester.ensureVisible(find.text('Abrir assistências').first);
      await tester.tap(find.text('Abrir assistências').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Abrir estoque').first);
      await tester.tap(find.text('Abrir estoque').first);
      await tester.pumpAndSettle();

      expect(actions.calls, <WebNavigationDestination>[
        WebNavigationDestination.operationsTechnicalServices,
        WebNavigationDestination.catalogStock,
      ]);
    });

    testWidgets('ações rápidas respeitam permissões reais adaptadas', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();
      int novosAtendimentos = 0;

      await _pumpHome(
        tester,
        service: _FakeWorkspaceHomeService(_home(financialAvailable: false)),
        actions: actions,
        permissions: _FakeAutorizacoesProvider(
          podeLancarAssistenciaTecnica: true,
        ),
        onNovoAtendimentoTecnico: () => novosAtendimentos += 1,
      );

      await tester.ensureVisible(find.text('Ações rápidas'));
      expect(find.text('Nova venda'), findsNothing);
      expect(find.text('Novo atendimento'), findsOneWidget);
      expect(find.text('Agenda financeira'), findsNothing);

      await tester.tap(find.text('Novo atendimento'));
      await tester.pumpAndSettle();

      expect(novosAtendimentos, 1);
      expect(actions.calls, isEmpty);
    });

    testWidgets('usa estado vazio quando não há alertas positivos', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        service: _FakeWorkspaceHomeService(_homeWithoutAttention()),
        permissions: _FakeAutorizacoesProvider(admin: true),
      );

      await tester.ensureVisible(find.text('Precisa da sua atenção'));
      expect(find.text('Nenhuma pendência importante agora.'), findsOneWidget);
    });

    testWidgets('renderiza sem exceção nas larguras Web de referência', (
      WidgetTester tester,
    ) async {
      for (final Size size in _responsiveValidationSizes) {
        await _pumpHome(
          tester,
          service: _FakeWorkspaceHomeService(_home()),
          permissions: _FakeAutorizacoesProvider(admin: true),
          size: size,
        );

        expect(tester.takeException(), isNull, reason: size.toString());
      }
    });

    testWidgets('renderiza em Light e Dark Mode sem exceção', (
      WidgetTester tester,
    ) async {
      for (final ThemeMode themeMode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        await _pumpHome(
          tester,
          service: _FakeWorkspaceHomeService(_home()),
          permissions: _FakeAutorizacoesProvider(admin: true),
          themeMode: themeMode,
        );

        expect(tester.takeException(), isNull, reason: themeMode.name);
      }
    });

    testWidgets('possui traduções locais da Home em pt, en e es', (
      WidgetTester tester,
    ) async {
      for (final Locale locale in const <Locale>[
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ]) {
        late BuildContext probeContext;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const <Locale>[
              Locale('pt'),
              Locale('en'),
              Locale('es'),
            ],
            home: Builder(
              builder: (BuildContext context) {
                probeContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final String key in _workspaceHomeI18nKeys) {
          expect(
            probeContext.t(key),
            isNot(key),
            reason: '${locale.languageCode}: $key',
          );
        }
      }
    });
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required WorkspaceHomeService service,
  _RecordingActions? actions,
  ColaboradorAutorizacoesProvider? permissions,
  VoidCallback? onNovoAtendimentoTecnico,
  Size size = const Size(1366, 768),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EmpresaProvider>.value(value: EmpresaProvider()),
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>.value(
          value: permissions ?? _FakeAutorizacoesProvider(admin: true),
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
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        locale: const Locale('pt'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          Locale('pt'),
          Locale('en'),
          Locale('es'),
        ],
        home: Scaffold(
          body: WorkspaceHomeWeb(
            compact: false,
            resolver: WebNavigationDestinationResolver(
              actions: actions ?? _RecordingActions(),
            ),
            onNovoAtendimentoTecnico: onNovoAtendimentoTecnico ?? () {},
            service: service,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

const List<Size> _responsiveValidationSizes = <Size>[
  Size(1920, 1080),
  Size(1440, 900),
  Size(1366, 768),
  Size(1280, 720),
  Size(1024, 768),
];

class _FakeWorkspaceHomeService implements WorkspaceHomeService {
  const _FakeWorkspaceHomeService(this._home);

  final WorkspaceHomeModel _home;

  @override
  Future<WorkspaceHomeModel> buscarHome() async => _home;
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async {
    return _regionalizacaoResponse;
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) async {
    return _regionalizacaoResponse;
  }
}

class _FakeAutorizacoesProvider extends ColaboradorAutorizacoesProvider {
  _FakeAutorizacoesProvider({
    this.admin = false,
    this.podeLancarAssistenciaTecnica = false,
  });

  final bool admin;

  @override
  bool get podeFazerVenda => false;

  @override
  final bool podeLancarAssistenciaTecnica;

  @override
  bool get podeEditarCliente => false;

  @override
  bool get podeCadastrarProduto => false;

  @override
  bool get podeEditarProduto => false;

  @override
  bool get podeVerEstoqueDeProduto => false;

  @override
  bool get podeGerarRelatorio => false;

  @override
  bool get podeReceberNoCaixa => false;

  @override
  bool get podeVerQuantoVendeu => false;

  @override
  bool get ehAdministrador => admin;

  @override
  bool get autorizacoesCarregadasComSucesso => true;
}

class _RecordingActions implements WebNavigationDestinationActions {
  final List<WebNavigationDestination> calls = <WebNavigationDestination>[];

  WebNavigationResolutionResult _record(WebNavigationDestination destination) {
    calls.add(destination);
    return WebNavigationResolutionResult.handled(destination);
  }

  @override
  WebNavigationResolutionResult openHome() {
    return _record(WebNavigationDestination.home);
  }

  @override
  WebNavigationResolutionResult openPointOfSale() {
    return _record(WebNavigationDestination.operationsPointOfSale);
  }

  @override
  WebNavigationResolutionResult openTechnicalServices() {
    return _record(WebNavigationDestination.operationsTechnicalServices);
  }

  @override
  WebNavigationResolutionResult openCatalogProducts() {
    return _record(WebNavigationDestination.catalogProducts);
  }

  @override
  WebNavigationResolutionResult openCatalogServices() {
    return _record(WebNavigationDestination.catalogServices);
  }

  @override
  WebNavigationResolutionResult openCatalogStock() {
    return _record(WebNavigationDestination.catalogStock);
  }

  @override
  WebNavigationResolutionResult openCatalogCategories() {
    return _record(WebNavigationDestination.catalogCategories);
  }

  @override
  WebNavigationResolutionResult openPeopleCustomers() {
    return _record(WebNavigationDestination.peopleCustomers);
  }

  @override
  WebNavigationResolutionResult openPeopleCollaborators() {
    return _record(WebNavigationDestination.peopleCollaborators);
  }

  @override
  WebNavigationResolutionResult openPeoplePerformance() {
    return _record(WebNavigationDestination.peoplePerformance);
  }

  @override
  WebNavigationResolutionResult openCash() {
    return _record(WebNavigationDestination.cash);
  }

  @override
  WebNavigationResolutionResult openFinancialAgenda() {
    return _record(WebNavigationDestination.financialAgenda);
  }

  @override
  WebNavigationResolutionResult openSettings() {
    return _record(WebNavigationDestination.settings);
  }
}

final ConfiguracaoRegionalizacaoResponse _regionalizacaoResponse =
    ConfiguracaoRegionalizacaoResponse.fromJson(const <String, dynamic>{
      'languageCode': 'pt',
      'countryCode': 'BR',
      'currencyCode': 'BRL',
      'timeZone': 'America/Sao_Paulo',
      'dateFormat': 'dd/MM/yyyy',
      'timeFormat': '24h',
      'decimalSeparator': ',',
      'thousandSeparator': '.',
      'firstDayOfWeek': 'MONDAY',
      'numberPattern': '#,##0.00',
      'decimalPlaces': 2,
      'allowMultipleCurrencies': false,
      'applyFinancialRounding': true,
    });

WorkspaceHomeModel _home({
  bool financialAvailable = true,
  String openedAt = '2026-08-10T08:12:00',
}) {
  return WorkspaceHomeModel.fromJson(<String, dynamic>{
    'date': '2026-08-10',
    'timeZone': 'America/Sao_Paulo',
    'cash': <String, dynamic>{
      'available': true,
      'open': true,
      'openedAt': openedAt,
      'responsibleName': 'Ana',
    },
    'technicalServices': <String, dynamic>{
      'available': true,
      'active': 8,
      'waitingApproval': 5,
      'late': 3,
      'readyForPickup': 4,
    },
    'financial':
        financialAvailable
            ? <String, dynamic>{
              'available': true,
              'receivableToday': <String, dynamic>{
                'count': 4,
                'amount': 1240.0,
              },
              'payableToday': <String, dynamic>{'count': 2, 'amount': 680.0},
              'overdueReceivable': <String, dynamic>{
                'count': 1,
                'amount': 230.0,
              },
              'overduePayable': <String, dynamic>{'count': 3, 'amount': 540.0},
            }
            : <String, dynamic>{'available': false},
    'stock': <String, dynamic>{
      'available': true,
      'belowMinimum': 6,
      'withoutStock': 2,
      'negative': 1,
    },
  });
}

WorkspaceHomeModel _homeWithoutAttention() {
  return WorkspaceHomeModel.fromJson(const <String, dynamic>{
    'date': '2026-08-10',
    'timeZone': 'America/Sao_Paulo',
    'cash': <String, dynamic>{'available': true, 'open': false},
    'technicalServices': <String, dynamic>{
      'available': true,
      'active': 0,
      'waitingApproval': 0,
      'late': 0,
      'readyForPickup': 0,
    },
    'financial': <String, dynamic>{
      'available': true,
      'receivableToday': <String, dynamic>{'count': 0, 'amount': 0.0},
      'payableToday': <String, dynamic>{'count': 0, 'amount': 0.0},
      'overdueReceivable': <String, dynamic>{'count': 0, 'amount': 0.0},
      'overduePayable': <String, dynamic>{'count': 0, 'amount': 0.0},
    },
    'stock': <String, dynamic>{
      'available': true,
      'belowMinimum': 0,
      'withoutStock': 0,
      'negative': 0,
    },
  });
}

const List<String> _workspaceHomeI18nKeys = <String>[
  'workspaceHome.title',
  'workspaceHome.greeting',
  'workspaceHome.unknownUser',
  'workspaceHome.companyFallback',
  'workspaceHome.operationalDate',
  'workspaceHome.refreshTooltip',
  'workspaceHome.loading.title',
  'workspaceHome.loading.subtitle',
  'workspaceHome.error.title',
  'workspaceHome.section.today',
  'workspaceHome.section.attention',
  'workspaceHome.section.quickActions',
  'workspaceHome.empty.today',
  'workspaceHome.empty.attention',
  'workspaceHome.empty.quickActions',
  'workspaceHome.cash.title',
  'workspaceHome.cash.open',
  'workspaceHome.cash.closed',
  'workspaceHome.cash.openedAt',
  'workspaceHome.cash.openedAtWithDate',
  'workspaceHome.cash.responsible',
  'workspaceHome.technical.title',
  'workspaceHome.technical.active.one',
  'workspaceHome.technical.active.other',
  'workspaceHome.financial.receivableToday',
  'workspaceHome.financial.payableToday',
  'workspaceHome.financial.count.one',
  'workspaceHome.financial.count.other',
  'workspaceHome.stock.title',
  'workspaceHome.stock.noCritical',
  'workspaceHome.stock.belowMinimum.one',
  'workspaceHome.stock.belowMinimum.other',
  'workspaceHome.stock.withoutStock.one',
  'workspaceHome.stock.withoutStock.other',
  'workspaceHome.stock.negative.one',
  'workspaceHome.stock.negative.other',
  'workspaceHome.attention.lateServices.one',
  'workspaceHome.attention.lateServices.other',
  'workspaceHome.attention.waitingApproval.one',
  'workspaceHome.attention.waitingApproval.other',
  'workspaceHome.attention.readyForPickup.one',
  'workspaceHome.attention.readyForPickup.other',
  'workspaceHome.attention.overdueReceivable.one',
  'workspaceHome.attention.overdueReceivable.other',
  'workspaceHome.attention.overduePayable.one',
  'workspaceHome.attention.overduePayable.other',
  'workspaceHome.attention.stockNegative.one',
  'workspaceHome.attention.stockNegative.other',
  'workspaceHome.attention.stockWithout.one',
  'workspaceHome.attention.stockWithout.other',
  'workspaceHome.attention.stockBelow.one',
  'workspaceHome.attention.stockBelow.other',
  'workspaceHome.action.openTechnicalServices',
  'workspaceHome.action.openFinancial',
  'workspaceHome.action.openStock',
  'workspaceHome.quickAction.newSale',
  'workspaceHome.quickAction.newTechnicalService',
  'workspaceHome.quickAction.cash',
  'workspaceHome.quickAction.financialAgenda',
];
