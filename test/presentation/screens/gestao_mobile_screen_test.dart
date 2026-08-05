import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/management_overview_provider.dart';
import 'package:sixpos/presentation/components/mobile/management/management_section_selector.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';

void main() {
  testWidgets('troca entre as quatro opções e atualiza o estado selecionado', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester);

    expect(
      find.byKey(const ValueKey<String>('management-area-catalog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('management-section-selector-surface')),
      findsOneWidget,
    );
    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Resumo do catálogo'), findsOneWidget);
    expect(find.text('Produtos e Serviços'), findsOneWidget);

    await _selectSection(tester, 'Pessoas');
    expect(
      find.byKey(const ValueKey<String>('management-area-people')),
      findsOneWidget,
    );
    expect(find.text('Clientes'), findsWidgets);
    expect(find.text('Fornecedores'), findsWidgets);

    await _selectSection(tester, 'Financeiro');
    expect(
      find.byKey(const ValueKey<String>('management-area-finance')),
      findsOneWidget,
    );
    expect(find.text('Agenda financeira'), findsOneWidget);
    expect(find.text('Contas a receber'), findsOneWidget);

    await _selectSection(tester, 'Configurações');
    expect(
      find.byKey(const ValueKey<String>('management-area-settings')),
      findsOneWidget,
    );
    expect(find.text('Usuários e permissões'), findsOneWidget);
    expect(find.text('Procedimentos'), findsOneWidget);
  });

  testWidgets('aciona item disponível e mantém item bloqueado sem navegação', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = <String>[];
    await _pumpGestao(tester, navigations: navigations);

    await tester.tap(find.text('Produtos e Serviços'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(navigations, contains('CatalogHealthMobileScreen'));

    await _selectSection(tester, 'Pessoas');
    await tester.tap(find.text('Fornecedores').last);
    await tester.pump(const Duration(milliseconds: 120));

    expect(navigations.length, 1);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
    expect(find.text('Em breve'), findsWidgets);
  });

  testWidgets('preserva selos Em breve e Experimental em Configurações', (
    WidgetTester tester,
  ) async {
    await _pumpGestao(tester);

    await _selectSection(tester, 'Configurações');

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

      await _selectSection(tester, 'Financeiro');
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
    expect(find.text('Categorias'), findsWidgets);
    expect(find.text('Estoque'), findsWidgets);
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
      showBottomNavigationBar: false,
    );

    await _selectSection(tester, 'Pessoas');
    await _selectSection(tester, 'Financeiro');
    await _selectSection(tester, 'Configurações');

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
            showBottomNavigationBar: showBottomNavigationBar,
            onNavigate:
                navigations == null
                    ? null
                    : (_, Widget page) =>
                        navigations.add(page.runtimeType.toString()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _selectSection(WidgetTester tester, String title) async {
  final int index = switch (title) {
    'Catálogo' => 0,
    'Pessoas' => 1,
    'Financeiro' => 2,
    'Configurações' => 3,
    _ => throw ArgumentError.value(title, 'title', 'Área inválida'),
  };
  final Finder option = find.byKey(
    ValueKey<String>('management-section-tab-$index'),
    skipOffstage: false,
  );
  final Finder selector = find.byType(ManagementSectionSelector);

  for (int attempt = 0; attempt < index; attempt += 1) {
    await tester.drag(selector, const Offset(-180, 0));
    await tester.pump(const Duration(milliseconds: 80));
  }

  await tester.tap(option, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 450));
}

class _NoCatalogPermissionProvider extends ColaboradorAutorizacoesProvider {
  @override
  bool get podeAcessarCatalogo => false;
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
