import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/tela_inicial_models.dart';
import 'package:sixpos/data/services/telainicial_web/tela_inicial_api_client.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/atendimento_mobile_screen.dart';

void main() {
  testWidgets('exibe ações principais e contadores carregados', (
    WidgetTester tester,
  ) async {
    await _pumpAtendimento(tester);

    expect(find.text('O que você deseja fazer?'), findsOneWidget);
    expect(find.text('Nova venda'), findsOneWidget);
    expect(find.text('Novo serviço'), findsOneWidget);
    expect(find.text('Receber'), findsOneWidget);
    expect(find.text('Acompanhe hoje'), findsOneWidget);
    expect(find.text('Mais opções'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantém layout sem overflow entre 320 e 430 px', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[320, 360, 390, 430]) {
      await _pumpAtendimento(tester, size: Size(width, 900));
      _expectPrimaryActionCardsSameHeight(tester);
      expect(tester.takeException(), isNull, reason: 'largura $width');
    }
  });

  testWidgets('mantém layout sem overflow com texto ampliado', (
    WidgetTester tester,
  ) async {
    await _pumpAtendimento(tester, size: const Size(320, 940), textScale: 1.35);

    expect(find.text('Nova venda'), findsOneWidget);
    _expectPrimaryActionCardsSameHeight(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserva as cinco navegações e mantém devolução bloqueada', (
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
      find.byKey(const ValueKey<String>('atendimento-row-services')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-row-cash')),
    );
    await tester.pump();
    await tester.tap(find.text('Devolução'));
    await tester.pump();

    expect(navigations, <String>[
      'PdvMobileScreen',
      'AtendimentoTecnicoMobileScreen',
      'VendasNaoLiquidadasMobileScreen',
      'AtendimentosTecnicosMobileScreen',
      'OperacoesCaixaMobileScreen',
    ]);
    expect(find.text('Em breve'), findsWidgets);
  });

  testWidgets('falha nos contadores não bloqueia ações principais', (
    WidgetTester tester,
  ) async {
    final List<String> navigations = await _pumpAtendimento(
      tester,
      apiClient: _FakeResumoClient(error: StateError('offline')),
    );

    expect(find.text('Não foi possível atualizar agora'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('atendimento-action-receive')),
    );
    await tester.pump();

    expect(navigations, <String>['VendasNaoLiquidadasMobileScreen']);
    expect(tester.takeException(), isNull);
  });
}

void _expectPrimaryActionCardsSameHeight(WidgetTester tester) {
  final double saleHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-new-sale'),
              skipOffstage: false,
            ),
          )
          .height;
  final double serviceHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-new-service'),
              skipOffstage: false,
            ),
          )
          .height;
  final double receiveHeight =
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('atendimento-action-receive'),
              skipOffstage: false,
            ),
          )
          .height;

  expect(serviceHeight, saleHeight, reason: 'novo serviço');
  expect(receiveHeight, saleHeight, reason: 'receber');
}

Future<List<String>> _pumpAtendimento(
  WidgetTester tester, {
  Size size = const Size(390, 900),
  double textScale = 1,
  TelaInicialWebApiClient? apiClient,
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
          textScaler: TextScaler.linear(textScale),
        ),
        child: AtendimentoMobileScreen(
          apiClient: apiClient ?? _FakeResumoClient(),
          procedureCoordinator: procedureCoordinator,
          showBottomNavigationBar: false,
          enableWebSocket: false,
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

class _FakeResumoClient implements TelaInicialWebApiClient {
  _FakeResumoClient({this.error});

  final Object? error;

  @override
  Future<TelaInicialModel> getResumo() async {
    final Object? currentError = error;
    if (currentError != null) throw currentError;

    return TelaInicialModel(
      totalVendasAbertas: 7,
      totalAtendimentoTecnicosNaoEntregues: 5,
      totalAtendimentoTecnicoEmAndamento: 3,
      totalAtendimentoTecnicoAguardandoAssinatura: 1,
      totalOrdensDeServicoAbertas: 4,
    );
  }
}
