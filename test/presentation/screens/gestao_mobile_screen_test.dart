import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/management_overview_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';
import 'package:sixpos/presentation/components/nav_bar_mobile.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    UsuarioProvider().clear();
  });

  testWidgets('exibe hub com quatro áreas e direciona sem seletor ou loading', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = <String>[];
    await _pumpGestao(tester, navigations: navigations, area: null);

    expect(
      find.byKey(const ValueKey<String>('gestao-hub-card-catalog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('gestao-hub-card-people')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('gestao-hub-card-finance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('gestao-hub-card-settings')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('management-section-selector-surface')),
      findsNothing,
    );
    expect(find.text('Visão geral'), findsNothing);

    for (final String title in <String>[
      'Catálogo',
      'Pessoas',
      'Financeiro',
      'Configurações',
    ]) {
      await tester.tap(find.text(title));
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(navigations, <String>[
      'GestaoMobileScreen:catalogo',
      'GestaoMobileScreen:pessoas',
      'GestaoMobileScreen:financeiro',
      'GestaoMobileScreen:configuracoes',
    ]);
  });

  testWidgets('mantém os cards próximos ao resumo e acima da navegação', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester, area: null);

    final Rect introRect = tester.getRect(
      find.byKey(const ValueKey<String>('gestao-hub-intro')),
    );
    final Rect firstCardRect = tester.getRect(
      find.byKey(const ValueKey<String>('gestao-hub-card-catalog')),
    );
    final Rect lastCardRect = tester.getRect(
      find.byKey(const ValueKey<String>('gestao-hub-card-settings')),
    );
    final Rect navigationRect = tester.getRect(find.byType(NavBarMobile));

    expect(firstCardRect.top - introRect.bottom, closeTo(16, 0.5));
    expect(lastCardRect.bottom, lessThanOrEqualTo(navigationRect.top));
  });

  testWidgets('aciona item disponível e mantém item bloqueado sem navegação', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = <String>[];
    await _pumpGestao(tester, navigations: navigations);

    await tester.tap(find.text('Produtos e Serviços'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(navigations, contains('CatalogHealthMobileScreen'));

    await _pumpGestao(
      tester,
      navigations: navigations,
      area: GestaoMobileArea.pessoas,
    );
    await tester.tap(find.text('Fornecedores').last);
    await tester.pump(const Duration(milliseconds: 120));

    expect(navigations.length, 1);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
    expect(find.text('Em breve'), findsWidgets);
  });

  testWidgets('abre o catálogo virtual na experiência mobile própria', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = <String>[];
    await _pumpGestao(tester, navigations: navigations);

    final Finder virtualCatalog = find.text('Catálogo virtual');
    expect(virtualCatalog, findsOneWidget);
    await tester.ensureVisible(virtualCatalog);
    await tester.tap(virtualCatalog);
    await tester.pump(const Duration(milliseconds: 120));

    expect(navigations, contains('CatalogoVirtualMobileScreen'));
    expect(find.text('WEB'), findsNothing);
  });

  testWidgets('abre desempenho do colaborador na seção de pessoas', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = <String>[];
    await _pumpGestao(
      tester,
      navigations: navigations,
      area: GestaoMobileArea.pessoas,
    );

    final Finder performance = find.text('Desempenho do colaborador');
    expect(performance, findsOneWidget);
    await tester.ensureVisible(performance);
    await tester.tap(performance);
    await tester.pump(const Duration(milliseconds: 120));

    expect(navigations, contains('DesempenhoColaboradorMobileScreen'));
  });

  testWidgets('oculta desempenho da equipe para colaborador', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(
      tester,
      area: GestaoMobileArea.pessoas,
      colaboradorProvider: _CollaboratorProvider(),
    );
    expect(find.text('Fornecedores'), findsOneWidget);
    expect(find.text('Desempenho do colaborador'), findsNothing);
  });

  testWidgets('exibe Usuarios do Sixo apenas para SUPER', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = <String>[];
    await _pumpGestao(
      tester,
      navigations: navigations,
      area: GestaoMobileArea.pessoas,
      colaboradorProvider: _SuperProvider(),
    );

    final Finder sixoUsers = find.text('Usuários do Sixo');
    expect(sixoUsers, findsOneWidget);
    await tester.ensureVisible(sixoUsers);
    await tester.tap(sixoUsers);
    await tester.pump(const Duration(milliseconds: 120));

    expect(navigations, contains('UsuariosSixoMobileScreen'));

    await _pumpGestao(tester, area: GestaoMobileArea.pessoas);
    expect(find.text('Usuários do Sixo'), findsNothing);
  });

  testWidgets('restaura a ordem dos cards salva no cache do usuário', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sixapp.preferenciasIndividuaisDoUsuario': jsonEncode(<String, dynamic>{
        'ordemCardsGestaoMobile': <String>[
          'FINANCEIRO',
          'CATALOGO',
          'CONFIGURACOES',
          'PESSOAS',
        ],
      }),
    });

    await _pumpGestao(tester, area: null);

    final Offset finance = tester.getTopLeft(
      find.byKey(const ValueKey<String>('gestao-hub-card-finance')),
    );
    final Offset catalog = tester.getTopLeft(
      find.byKey(const ValueKey<String>('gestao-hub-card-catalog')),
    );
    final Offset settings = tester.getTopLeft(
      find.byKey(const ValueKey<String>('gestao-hub-card-settings')),
    );
    final Offset people = tester.getTopLeft(
      find.byKey(const ValueKey<String>('gestao-hub-card-people')),
    );

    expect(finance.dy, closeTo(catalog.dy, 0.1));
    expect(finance.dx, lessThan(catalog.dx));
    expect(settings.dy, closeTo(people.dy, 0.1));
    expect(settings.dx, lessThan(people.dx));
    expect(finance.dy, lessThan(settings.dy));
  });

  testWidgets('reordena por pressão longa e salva a preferência no cache', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester, area: null);

    final Finder catalogFinder = find.byKey(
      const ValueKey<String>('gestao-hub-card-catalog'),
    );
    final Finder settingsFinder = find.byKey(
      const ValueKey<String>('gestao-hub-card-settings'),
    );
    final Offset destino = tester.getCenter(settingsFinder);
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(catalogFinder),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(destino);
    await tester.pump(const Duration(milliseconds: 160));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 240));

    final Offset people = tester.getTopLeft(
      find.byKey(const ValueKey<String>('gestao-hub-card-people')),
    );
    final Offset finance = tester.getTopLeft(
      find.byKey(const ValueKey<String>('gestao-hub-card-finance')),
    );
    final Offset settings = tester.getTopLeft(settingsFinder);
    final Offset catalog = tester.getTopLeft(catalogFinder);
    expect(people.dy, closeTo(finance.dy, 0.1));
    expect(people.dx, lessThan(finance.dx));
    expect(settings.dy, closeTo(catalog.dy, 0.1));
    expect(settings.dx, lessThan(catalog.dx));

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(
      'sixapp.preferenciasIndividuaisDoUsuario',
    );
    expect(raw, isNotNull);
    final Map<String, dynamic> json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ordemCardsGestaoMobile'], <String>[
      'PESSOAS',
      'FINANCEIRO',
      'CONFIGURACOES',
      'CATALOGO',
    ]);
  });

  testWidgets('preserva selos Em breve e Experimental em Configurações', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester, area: GestaoMobileArea.configuracoes);

    expect(find.text('Usuários e permissões'), findsOneWidget);
    expect(find.text('Em breve'), findsAtLeastNWidgets(1));
    expect(find.text('Procedimentos'), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
  });

  testWidgets('exibe indicadores carregados e atenção de estoque baixo', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester);

    expect(find.text('24'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'management-summary-catalog-low-stock-attention-dot',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Estoque precisa de atenção'), findsOneWidget);
    expect(find.text('Ver itens'), findsOneWidget);
  });

  testWidgets('não exibe bolinha de atenção quando estoque baixo é zero', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester, snapshot: _zeroLowStockSnapshot);

    expect(find.text('0'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'management-summary-catalog-low-stock-attention-dot',
        ),
      ),
      findsNothing,
    );
    expect(find.text('Estoque precisa de atenção'), findsNothing);
  });

  testWidgets(
    'exibe estado sem dados sem preencher indicadores com zero falso',
    (WidgetTester tester) async {
      final List<String> navigations = <String>[];
      await _pumpGestao(
        tester,
        snapshot: _emptySnapshot,
        navigations: navigations,
      );

      expect(find.text('Catálogo sem dados para exibir'), findsOneWidget);
      expect(find.text('--'), findsWidgets);

      await _pumpGestao(
        tester,
        snapshot: _emptySnapshot,
        navigations: navigations,
        area: GestaoMobileArea.financeiro,
      );
      expect(find.text('Agenda sem lançamentos próximos'), findsOneWidget);

      await tester.tap(find.text('Abrir agenda'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(navigations, contains('AgendaFinanceiraMobileScreen'));
    },
  );

  testWidgets('respeita permissão real do catálogo ao ocultar ação restrita', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(
      tester,
      colaboradorProvider: _NoCatalogPermissionProvider(),
    );

    expect(find.text('Produtos e Serviços'), findsNothing);
    expect(find.text('Categorias'), findsNothing);
    expect(find.text('Estoque'), findsNothing);
    expect(find.text('Catálogo virtual'), findsNothing);
    expect(find.text('Catálogo restrito para este usuário'), findsOneWidget);
  });

  testWidgets('mantém leitura com escala de texto aumentada', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(
      tester,
      mediaQueryData: const MediaQueryData(
        disableAnimations: true,
        accessibleNavigation: true,
        textScaler: TextScaler.linear(1.15),
      ),
      area: GestaoMobileArea.configuracoes,
      showBottomNavigationBar: false,
    );

    expect(find.text('Configurações da empresa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpGestao(
  WidgetTester tester, {
  ManagementOverviewSnapshot snapshot = _loadedSnapshot,
  List<String>? navigations,
  MediaQueryData? mediaQueryData,
  ColaboradorAutorizacoesProvider? colaboradorProvider,
  GestaoMobileArea? area = GestaoMobileArea.catalogo,
  bool showBottomNavigationBar = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final ManagementOverviewProvider overviewProvider =
      ManagementOverviewProvider(initialSnapshot: snapshot);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>.value(
          value: colaboradorProvider ?? ColaboradorAutorizacoesProvider(),
        ),
        ChangeNotifierProvider<EmpresaProvider>.value(value: EmpresaProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: (mediaQueryData ??
                  const MediaQueryData(
                    disableAnimations: true,
                    accessibleNavigation: true,
                  ))
              .copyWith(size: const Size(390, 900), devicePixelRatio: 1),
          child: GestaoMobileScreen(
            overviewProvider: overviewProvider,
            area: area,
            showBottomNavigationBar: showBottomNavigationBar,
            onNavigate:
                navigations == null
                    ? null
                    : (_, Widget page) {
                      if (page case GestaoMobileScreen(:final area)) {
                        navigations.add(
                          'GestaoMobileScreen:${area?.name ?? 'hub'}',
                        );
                        return;
                      }
                      navigations.add(page.runtimeType.toString());
                    },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

class _NoCatalogPermissionProvider extends ColaboradorAutorizacoesProvider {
  @override
  bool get podeAcessarCatalogo => false;

  @override
  bool get podeVerEstoqueDeProduto => false;
}

class _CollaboratorProvider extends ColaboradorAutorizacoesProvider {
  @override
  bool get ehColaborador => true;
}

class _SuperProvider extends ColaboradorAutorizacoesProvider {
  @override
  bool get ehSuperUsuario => true;
}

const ManagementOverviewSnapshot _loadedSnapshot = ManagementOverviewSnapshot(
  catalog: ManagementSectionLoadState<ManagementCatalogOverview>.data(
    ManagementCatalogOverview(
      productCount: 18,
      serviceCount: 6,
      categoryCount: 5,
      lowStockItems: 3,
      attentionItems: 4,
      isDemonstrationData: false,
    ),
  ),
  people: ManagementSectionLoadState<ManagementPeopleOverview>.data(
    ManagementPeopleOverview(
      clientCount: 42,
      collaboratorCount: 7,
      activeCollaboratorCount: 6,
      supplierCount: null,
    ),
  ),
  finance: ManagementSectionLoadState<ManagementFinanceOverview>.data(
    ManagementFinanceOverview(
      totalEvents: 9,
      receivableEvents: 6,
      payableEvents: 3,
      attentionEvents: 2,
    ),
  ),
);

const ManagementOverviewSnapshot _emptySnapshot = ManagementOverviewSnapshot(
  catalog: ManagementSectionLoadState<ManagementCatalogOverview>.empty(),
  people: ManagementSectionLoadState<ManagementPeopleOverview>.empty(),
  finance: ManagementSectionLoadState<ManagementFinanceOverview>.empty(),
);

const ManagementOverviewSnapshot _zeroLowStockSnapshot =
    ManagementOverviewSnapshot(
      catalog: ManagementSectionLoadState<ManagementCatalogOverview>.data(
        ManagementCatalogOverview(
          productCount: 18,
          serviceCount: 6,
          categoryCount: 5,
          lowStockItems: 0,
          attentionItems: 1,
          isDemonstrationData: false,
        ),
      ),
      people: ManagementSectionLoadState<ManagementPeopleOverview>.data(
        ManagementPeopleOverview(
          clientCount: 42,
          collaboratorCount: 7,
          activeCollaboratorCount: 6,
          supplierCount: null,
        ),
      ),
      finance: ManagementSectionLoadState<ManagementFinanceOverview>.data(
        ManagementFinanceOverview(
          totalEvents: 9,
          receivableEvents: 6,
          payableEvents: 3,
          attentionEvents: 2,
        ),
      ),
    );
