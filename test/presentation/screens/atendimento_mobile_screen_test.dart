import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/atendimento_tecnico_models.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/models/regionalizacao_models.dart';
import 'package:sixpos/domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/components/nav_bar_mobile.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/atendimento_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_pendentes_pagamento_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_venda_mobile_screen.dart';
import 'package:sixpos/presentation/screens/receber_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_servicos_atendimento_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    UsuarioProvider().clear();
  });

  testWidgets('navbar mobile mantém apenas os três destinos principais', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(bottomNavigationBar: NavBarMobile())),
    );

    expect(find.text('dash'), findsOneWidget);
    expect(find.text('Gestão'), findsOneWidget);
    expect(find.text('Atendimento'), findsOneWidget);
    expect(find.text('Devoluções'), findsNothing);
  });

  testWidgets('exibe ações principais sem seção acompanhe hoje', (
    WidgetTester tester,
  ) async {
    await _pumpAtendimento(tester);

    expect(find.text('O que você deseja fazer?'), findsOneWidget);
    expect(find.text('Nova venda'), findsOneWidget);
    expect(find.text('Serviços'), findsOneWidget);
    expect(find.text('Receber'), findsOneWidget);
    expect(find.text('Acompanhe hoje'), findsNothing);
    expect(find.text('Mais opções'), findsNothing);
    expect(find.text('Operações de caixa'), findsOneWidget);
    expect(find.text('Devoluções'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantém layout sem overflow entre 320 e 430 px', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[320, 360, 390, 430]) {
      await _pumpAtendimento(tester, size: Size(width, 900));
      _expectActionCardHierarchy(tester);
      expect(tester.takeException(), isNull, reason: 'largura $width');
    }
  });

  testWidgets('mantém layout sem overflow com texto ampliado', (
    WidgetTester tester,
  ) async {
    await _pumpAtendimento(tester, size: const Size(320, 940), textScale: 1.35);

    expect(find.text('Nova venda'), findsOneWidget);
    _expectActionCardHierarchy(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aplica ilustrações duotone e superfícies de marca nos temas', (
    WidgetTester tester,
  ) async {
    for (final Brightness brightness in <Brightness>[
      Brightness.light,
      Brightness.dark,
    ]) {
      await _pumpAtendimento(tester, brightness: brightness);

      final Finder hero = find.byKey(
        const ValueKey<String>('atendimento-hero-art'),
      );
      expect(
        tester
            .widgetList<ShaderMask>(
              find.descendant(of: hero, matching: find.byType(ShaderMask)),
            )
            .length,
        greaterThan(1),
      );

      for (final String id in <String>[
        'new-sale',
        'new-service',
        'receive',
        'cash',
        'return',
      ]) {
        final Finder action = find.byKey(
          ValueKey<String>('atendimento-action-$id'),
        );
        final Finder surface = find.byKey(
          ValueKey<String>('atendimento-action-surface-$id'),
        );
        final Finder halo = find.byKey(
          ValueKey<String>('atendimento-action-halo-$id'),
        );

        expect(
          tester
              .widgetList<ShaderMask>(
                find.descendant(of: action, matching: find.byType(ShaderMask)),
              )
              .length,
          greaterThan(2),
          reason: '$id em $brightness',
        );
        expect(
          find.descendant(
            of: action,
            matching: find.byKey(
              const ValueKey<String>('six-canetinha-brilho'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: action,
            matching: find.byKey(
              const ValueKey<String>('six-canetinha-contorno-reforco'),
            ),
          ),
          findsOneWidget,
        );

        final Ink surfaceWidget = tester.widget<Ink>(surface);
        final BoxDecoration surfaceDecoration =
            surfaceWidget.decoration! as BoxDecoration;
        expect(surfaceDecoration.gradient, isA<LinearGradient>());

        final Container haloWidget = tester.widget<Container>(halo);
        final BoxDecoration haloDecoration =
            haloWidget.decoration! as BoxDecoration;
        expect(haloDecoration.gradient, isA<LinearGradient>());
      }

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('preserva as navegações e abre devoluções pelo atendimento', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = await _pumpAtendimento(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-new-sale')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-new-service')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-receive')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-cash')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-return')),
    );
    await tester.pump();

    expect(navigations, <String>[
      'NovaVendaMobileScreen',
      'ServicosAtendimentoMobileScreen',
      'ReceberMobileScreen',
      'OperacoesCaixaMobileScreen',
      'DevolucoesProdutosMobileScreen',
    ]);
    expect(find.text('Em breve'), findsNothing);
  });

  testWidgets('menu receber abre vendas e serviços a receber', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = await _pumpReceber(tester);

    expect(find.text('Vendas a receber'), findsOneWidget);
    expect(find.text('Serviços a receber'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('receber-action-sales')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('receber-action-services')),
    );
    await tester.pump();

    expect(navigations, <String>[
      'VendasNaoLiquidadasMobileScreen',
      'AtendimentosTecnicosPendentesPagamentoMobileScreen',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restaura a ordem independente dos quatro menus Mobile', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sixapp.preferenciasIndividuaisDoUsuario': jsonEncode(<String, dynamic>{
        'ordemCardsAtendimentoMobile': <String>[
          'RECEBER',
          'NOVA_VENDA',
          'DEVOLUCAO',
          'NOVO_SERVICO',
          'OPERACOES_CAIXA',
        ],
        'ordemCardsVendasMobile': <String>[
          'CONSULTAR_VENDAS',
          'NOVA_VENDA',
          'VENDAS_A_RECEBER',
        ],
        'ordemCardsServicosMobile': <String>[
          'SERVICOS_EM_ANDAMENTO',
          'ORCAMENTOS_AGUARDANDO_APROVACAO',
          'SERVICOS_JA_ENCERRADOS',
          'NOVO_SERVICO',
        ],
        'ordemCardsReceberMobile': <String>[
          'SERVICOS_A_RECEBER',
          'VENDAS_A_RECEBER',
        ],
      }),
    });

    await _pumpAtendimento(tester);
    final Finder primaryRow = find.byKey(
      const ValueKey<String>('atendimento-actions-row-primary'),
    );
    final Finder compactRow = find.byKey(
      const ValueKey<String>('atendimento-actions-row-compact'),
    );
    final Finder returnAction = find.byKey(
      const ValueKey<String>('atendimento-action-return'),
    );
    final Finder cashAction = find.byKey(
      const ValueKey<String>('atendimento-action-cash'),
    );
    final Finder receiveAction = find.byKey(
      const ValueKey<String>('atendimento-action-receive'),
    );
    final Finder saleAction = find.byKey(
      const ValueKey<String>('atendimento-action-new-sale'),
    );
    final Finder serviceAction = find.byKey(
      const ValueKey<String>('atendimento-action-new-service'),
    );

    final double primaryCardWidth = (tester.getSize(primaryRow).width - 12) / 2;
    final double compactCardWidth = (tester.getSize(compactRow).width - 16) / 3;

    expect(tester.getSize(returnAction).width, closeTo(primaryCardWidth, 0.01));
    expect(tester.getSize(cashAction).width, closeTo(primaryCardWidth, 0.01));
    expect(
      tester.getSize(receiveAction).width,
      closeTo(compactCardWidth, 0.01),
    );
    expect(tester.getSize(saleAction).width, closeTo(compactCardWidth, 0.01));
    expect(
      tester.getSize(serviceAction).width,
      closeTo(compactCardWidth, 0.01),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('atendimento-action-receive')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('atendimento-action-new-sale')),
            )
            .dx,
      ),
    );

    await _pumpNovaVenda(tester);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('nova-venda-action-history')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('nova-venda-action-new-sale')),
            )
            .dy,
      ),
    );

    await _pumpServicos(tester);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('servicos-action-in-progress')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('servicos-action-new-service')),
            )
            .dy,
      ),
    );

    await _pumpReceber(tester);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('receber-action-services')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('receber-action-sales')),
            )
            .dy,
      ),
    );
  });

  testWidgets('reordena o menu Receber e salva a preferência no cache', (
    WidgetTester tester,
  ) async {
    await _pumpReceber(tester);

    final Finder sales = find.byKey(
      const ValueKey<String>('receber-action-sales'),
    );
    final Finder services = find.byKey(
      const ValueKey<String>('receber-action-services'),
    );
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(sales),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(services));
    await tester.pump(const Duration(milliseconds: 160));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 240));

    expect(
      tester.getTopLeft(services).dy,
      lessThan(tester.getTopLeft(sales).dy),
    );

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Map<String, dynamic> cached =
        jsonDecode(
              preferences.getString('sixapp.preferenciasIndividuaisDoUsuario')!,
            )
            as Map<String, dynamic>;
    expect(cached['ordemCardsReceberMobile'], <String>[
      'SERVICOS_A_RECEBER',
      'VENDAS_A_RECEBER',
    ]);
  });

  testWidgets('usa ilustrações canetinha temáticas nos novos menus', (
    WidgetTester tester,
  ) async {
    await _pumpNovaVenda(tester);
    expect(find.byType(ShaderMask), findsWidgets);

    await _pumpServicos(tester);
    expect(find.byType(ShaderMask), findsWidgets);

    await _pumpReceber(tester);
    expect(find.byType(ShaderMask), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu de nova venda abre PDV, recebimentos e histórico', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = await _pumpNovaVenda(tester);

    expect(find.text('Nova venda'), findsWidgets);
    expect(find.text('Vendas a receber'), findsOneWidget);
    expect(find.text('Consultar vendas'), findsOneWidget);
    expect(find.text('Consultar histórico de vendas'), findsOneWidget);
    expect(find.text('Em breve'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('nova-venda-action-new-sale')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('nova-venda-action-receive')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('nova-venda-action-history')),
    );
    await tester.pump();

    expect(navigations, <String>[
      'PdvMobileScreen',
      'VendasNaoLiquidadasMobileScreen',
      'ConsultaVendasMobileScreen',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu de nova venda mantém três cards sem overflow mobile', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[320, 360, 390, 430]) {
      await _pumpNovaVenda(tester, size: Size(width, 760));

      expect(find.text('Nova venda'), findsWidgets);
      expect(find.text('Vendas a receber'), findsOneWidget);
      expect(find.text('Consultar vendas'), findsOneWidget);
      expect(find.text('Em breve'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'largura $width');
    }
  });

  testWidgets('menu de serviços abre listagens filtradas e orçamentos', (
    WidgetTester tester,
  ) async {
    final List<Widget> navigations = await _pumpServicos(tester);

    expect(find.text('Novo serviço'), findsOneWidget);
    expect(find.text('Consultar serviços em andamento'), findsOneWidget);
    expect(find.text('Orçamentos aguardando aprovação'), findsOneWidget);
    expect(find.text('Serviços já encerrados'), findsOneWidget);
    expect(
      find.text('Consulte serviços que ainda precisam da aprovação do cliente'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('servicos-action-in-progress')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('servicos-action-waiting-approval')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('servicos-action-closed-services')),
    );
    await tester.pump();

    expect(
      navigations.map((Widget page) => page.runtimeType.toString()),
      <String>[
        'AtendimentosTecnicosMobileScreen',
        'AtendimentosTecnicosMobileScreen',
        'AtendimentosTecnicosMobileScreen',
      ],
    );
    final AtendimentosTecnicosMobileScreen approvalPage =
        navigations[1] as AtendimentosTecnicosMobileScreen;
    final AtendimentosTecnicosMobileScreen closedPage =
        navigations[2] as AtendimentosTecnicosMobileScreen;
    final AtendimentosTecnicosMobileScreen inProgressPage =
        navigations.first as AtendimentosTecnicosMobileScreen;
    expect(inProgressPage.listContext.statusFilter, 'ACTIVE_GROUP');
    expect(approvalPage.listContext.statusFilter, 'WAITING_CUSTOMER_APROVAL');
    expect(
      approvalPage.listContext.titleFallback,
      'Orçamentos aguardando aprovação',
    );
    expect(closedPage.listContext.statusFilter, 'FINALIZED_GROUP');
    expect(closedPage.listContext.titleFallback, 'Serviços já encerrados');
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha nos contadores não bloqueia ações principais', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = await _pumpAtendimento(tester);

    expect(find.text('Não foi possível atualizar agora'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-receive')),
    );
    await tester.pump();

    expect(navigations, <String>['ReceberMobileScreen']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pendentes de pagamento lista apenas financeiro aberto', (
    WidgetTester tester,
  ) async {
    await _pumpPendentesPagamento(
      tester,
      service: _FakeAtendimentoTecnicoService(<AtendimentoTecnicoModel>[
        _atendimento(
          numero: 'OS-001',
          cliente: 'Cliente aberto',
          valorAberto: 120,
          liquidada: false,
        ),
        _atendimento(
          numero: 'OS-002',
          cliente: 'Cliente liquidado',
          valorAberto: 0,
          liquidada: true,
        ),
        _atendimento(
          numero: 'OS-003',
          cliente: 'Cliente sem saldo',
          valorAberto: 0,
          liquidada: false,
        ),
      ]),
    );

    expect(find.text('Atendimento OS-001'), findsOneWidget);
    expect(find.text('Cliente aberto'), findsOneWidget);
    expect(find.text('Atendimento OS-002'), findsNothing);
    expect(find.text('Atendimento OS-003'), findsNothing);
    expect(find.text('R\$ 120,00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

void _expectActionCardHierarchy(WidgetTester tester) {
  final double saleHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-new-sale'),
              skipOffstage: false,
            ),
          )
          .height;
  final double saleWidth =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-new-sale'),
              skipOffstage: false,
            ),
          )
          .width;
  final double serviceHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-new-service'),
              skipOffstage: false,
            ),
          )
          .height;
  final double serviceWidth =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-new-service'),
              skipOffstage: false,
            ),
          )
          .width;
  final double receiveHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-receive'),
              skipOffstage: false,
            ),
          )
          .height;
  final double receiveWidth =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-receive'),
              skipOffstage: false,
            ),
          )
          .width;
  final double cashHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-cash'),
              skipOffstage: false,
            ),
          )
          .height;
  final double cashWidth =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-cash'),
              skipOffstage: false,
            ),
          )
          .width;
  final double returnHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-return'),
              skipOffstage: false,
            ),
          )
          .height;
  final double returnWidth =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-return'),
              skipOffstage: false,
            ),
          )
          .width;

  expect(serviceHeight, saleHeight, reason: 'novo serviço');
  expect(serviceWidth, saleWidth, reason: 'largura novo serviço');
  expect(cashHeight, receiveHeight, reason: 'altura operações de caixa');
  expect(returnHeight, receiveHeight, reason: 'altura devoluções');
  expect(cashWidth, receiveWidth, reason: 'largura operações de caixa');
  expect(returnWidth, receiveWidth, reason: 'largura devoluções');
  expect(saleHeight, greaterThan(receiveHeight), reason: 'hierarquia visual');
}

Future<List<String>> _pumpAtendimento(
  WidgetTester tester, {
  Size size = const Size(390, 900),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  final List<String> navigations = <String>[];

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final OperationalProcedureFlowCoordinator procedureCoordinator =
      OperationalProcedureFlowCoordinator(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
          runtimeScenario: OperationalProcedureRuntimeMockScenario.none,
        ),
      );

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
          size: size,
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(textScale),
        ),
        child: AtendimentoMobileScreen(
          procedureCoordinator: procedureCoordinator,
          showBottomNavigationBar: false,
          onNavigate:
              (_, Widget page) => navigations.add(page.runtimeType.toString()),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  return navigations;
}

Future<List<Widget>> _pumpServicos(
  WidgetTester tester, {
  Size size = const Size(390, 900),
}) async {
  final List<Widget> navigations = <Widget>[];

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
          size: size,
          devicePixelRatio: 1,
        ),
        child: OpcoesServicosAtendimentoMobileScreen(
          onNavigate: (_, Widget page) => navigations.add(page),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  return navigations;
}

Future<List<String>> _pumpNovaVenda(
  WidgetTester tester, {
  Size size = const Size(390, 900),
}) async {
  final List<String> navigations = <String>[];

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final OperationalProcedureFlowCoordinator procedureCoordinator =
      OperationalProcedureFlowCoordinator(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
          runtimeScenario: OperationalProcedureRuntimeMockScenario.none,
        ),
      );

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
          size: size,
          devicePixelRatio: 1,
        ),
        child: OpcoesVendaMobileScreen(
          procedureCoordinator: procedureCoordinator,
          onNavigate:
              (_, Widget page) => navigations.add(page.runtimeType.toString()),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  return navigations;
}

Future<List<String>> _pumpReceber(
  WidgetTester tester, {
  Size size = const Size(390, 900),
}) async {
  final List<String> navigations = <String>[];

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
          size: size,
          devicePixelRatio: 1,
        ),
        child: ReceberMobileScreen(
          onNavigate:
              (_, Widget page) => navigations.add(page.runtimeType.toString()),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  return navigations;
}

Future<void> _pumpPendentesPagamento(
  WidgetTester tester, {
  required AtendimentoTecnicoService service,
  Size size = const Size(390, 900),
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
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
            size: size,
            devicePixelRatio: 1,
          ),
          child: AtendimentosTecnicosPendentesPagamentoMobileScreen(
            service: service,
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

class _FakeAtendimentoTecnicoService extends AtendimentoTecnicoService {
  _FakeAtendimentoTecnicoService(this.atendimentos);

  final List<AtendimentoTecnicoModel> atendimentos;

  @override
  Future<List<AtendimentoTecnicoModel>> listar({String? status}) async {
    return atendimentos;
  }
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async {
    return ConfiguracaoRegionalizacaoResponse.fromJson(
      ConfiguracaoRegionalizacaoSistema.defaultConfiguration().toTestJson(),
    );
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) async {
    return ConfiguracaoRegionalizacaoResponse.fromJson(request.toJson());
  }
}

extension on ConfiguracaoRegionalizacaoSistema {
  Map<String, dynamic> toTestJson() {
    return <String, dynamic>{
      'languageCode': languageCode,
      'countryCode': countryCode,
      'currencyCode': formatting.currencyCode,
      'timeZone': formatting.timeZone,
      'dateFormat': formatting.dateFormat,
      'timeFormat': formatting.timeFormat,
      'decimalSeparator': formatting.decimalSeparator,
      'thousandSeparator': formatting.thousandSeparator,
      'firstDayOfWeek': formatting.firstDayOfWeek,
      'numberPattern': formatting.numberPattern,
      'decimalPlaces': formatting.decimalPlaces,
      'allowMultipleCurrencies': formatting.allowMultipleCurrencies,
      'applyFinancialRounding': formatting.applyFinancialRounding,
    };
  }
}

AtendimentoTecnicoModel _atendimento({
  required String numero,
  required String cliente,
  required double valorAberto,
  required bool liquidada,
}) {
  return AtendimentoTecnicoModel(
    id: numero,
    numero: numero,
    statusId: 1,
    statusCodigo: 'EM_ANDAMENTO',
    statusI18nKey: 'atendimento.status.emAndamento',
    valorTotalProdutos: 0,
    valorTotalServicos: 200,
    valorTotalAtendimento: 200,
    valorRecebido: 200 - valorAberto,
    valorEmAberto: valorAberto,
    operacaoLiquidada: liquidada,
    statusLiquidacaoCodigo: liquidada ? 'LIQUIDADA' : 'NAO_LIQUIDADA',
    itens: const <AtendimentoTecnicoItemModel>[],
    historicoStatus: const <AtendimentoTecnicoHistoricoStatusModel>[],
    historicoAuditoria: const <AtendimentoTecnicoAuditoriaModel>[],
    recebimentos: const <AtendimentoTecnicoRecebimentoModel>[],
    idOperacaoFinanceira: liquidada ? null : 'fin-$numero',
    nomeClienteSnapshot: cliente,
    statusNomePtBr: 'Em andamento',
    dataVencimentoEm: DateTime(2026, 8, 10),
    equipamento: const AtendimentoTecnicoEquipamentoModel(
      tipo: 'Celular',
      marca: 'Six',
      modelo: 'Pro',
    ),
  );
}
