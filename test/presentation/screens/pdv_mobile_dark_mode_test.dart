import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/documento_models.dart';
import 'package:sixpos/data/models/operacao_models.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/models/venda_nao_liquidada_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/models/regionalizacao_models.dart';
import 'package:sixpos/domain/services/caixa/caixa_service.dart';
import 'package:sixpos/domain/services/operacao/operacao_service.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/opcoes_venda_mobile_screen.dart';
import 'package:sixpos/presentation/screens/pdv_mobile.dart' as pdv_base;
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart' as pdv_host;
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('PDV entry runs sale-start procedure before opening the route', (
    WidgetTester tester,
  ) async {
    final List<Widget> destinations = <Widget>[];
    final List<ProcedureExecutionConfiguration> configurations =
        <ProcedureExecutionConfiguration>[];
    final OperationalProcedureFlowCoordinator coordinator =
        OperationalProcedureFlowCoordinator(
          dataSource: const OperationalProcedureMockDataSource(
            delay: Duration.zero,
            runtimeScenario: OperationalProcedureRuntimeMockScenario.required,
          ),
          runner: (
            _,
            OperationalProcedure procedure,
            ProcedureExecutionConfiguration configuration,
          ) async {
            configurations.add(configuration);
            expect(procedure.id, 'sale-start-required-parking');
            return const ProcedureFlowResult.continueOperation(
              completedProcedureIds: <String>['sale-start-required-parking'],
            );
          },
        );

    await _pumpMobile(
      tester,
      brightness: Brightness.dark,
      child: OpcoesVendaMobileScreen(
        procedureCoordinator: coordinator,
        onNavigate: (_, Widget page) => destinations.add(page),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('nova-venda-action-new-sale')),
    );
    await tester.pumpAndSettle();

    expect(configurations, hasLength(1));
    expect(
      configurations.single.operationPoint,
      ProcedureOperationPoint.saleStartBefore,
    );
    expect(
      configurations.single.enforcementMode,
      ProcedureEnforcementMode.required,
    );
    expect(destinations, hasLength(1));
    expect(destinations.single, isA<pdv_host.PdvMobileScreen>());

    final OperationalProcedureFlowCoordinator cancellingCoordinator =
        OperationalProcedureFlowCoordinator(
          dataSource: const OperationalProcedureMockDataSource(
            delay: Duration.zero,
            runtimeScenario: OperationalProcedureRuntimeMockScenario.required,
          ),
          runner: (_, __, ___) async => const ProcedureFlowResult.cancelled(),
        );
    destinations.clear();

    await _pumpMobile(
      tester,
      brightness: Brightness.light,
      child: OpcoesVendaMobileScreen(
        procedureCoordinator: cancellingCoordinator,
        onNavigate: (_, Widget page) => destinations.add(page),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('nova-venda-action-new-sale')),
    );
    await tester.pumpAndSettle();

    expect(destinations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDV initial loading error and cash gate stay themed', (
    WidgetTester tester,
  ) async {
    for (final _ThemeCase themeCase in _themeCases) {
      final Completer<CaixaSessao?> sessionCompleter =
          Completer<CaixaSessao?>();
      final _FakeCaixaApiClient caixaApiClient = _FakeCaixaApiClient(
        sessionCompleter: sessionCompleter,
      );
      int cashNavigationCalls = 0;
      int productSelectionCalls = 0;

      await _pumpPdv(
        tester,
        themeCase: themeCase,
        caixaApiClient: caixaApiClient,
        cashOperationsLauncher: () async {
          cashNavigationCalls += 1;
        },
        productSelectionLauncher: () async {
          productSelectionCalls += 1;
          return null;
        },
        settle: false,
      );
      await tester.pump();

      expect(_scaffoldBackground(tester), themeCase.colors.background);
      expect(find.text('Verificando sessão do caixa'), findsWidgets);
      expect(caixaApiClient.sessaoAtualCalls, 1);

      sessionCompleter.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('Abra o caixa para vender'), findsOneWidget);
      expect(find.text('Sem sessão aberta'), findsWidgets);
      expect(
        _hasMaterialAncestorColor(
          tester,
          find.text('Adicionar produto').first,
          themeCase.colors.softSurface,
        ),
        isTrue,
      );

      await tester.tap(find.text('Adicionar produto').first);
      await tester.pumpAndSettle();
      expect(productSelectionCalls, 0);
      expect(
        find.text('Abra uma sessão de caixa antes de lançar vendas no PDV.'),
        findsWidgets,
      );

      await tester.tap(find.text('Operações de caixa').first);
      await tester.pumpAndSettle();
      expect(cashNavigationCalls, 1);
      expect(caixaApiClient.sessaoAtualCalls, 2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('catalog handoff adds product and service to the cart', (
    WidgetTester tester,
  ) async {
    for (final _ThemeCase themeCase in _themeCases) {
      int catalogCalls = 0;
      await _pumpPdv(
        tester,
        themeCase: themeCase,
        productSelectionLauncher: () async {
          catalogCalls += 1;
          return <ProdutoModel>[
            _product(id: 'produto-1', name: _longProductName, price: 45.25),
            _product(id: 'produto-1', name: _longProductName, price: 45.25),
            _service(id: 'servico-1', name: _longServiceName, price: 99.5),
          ];
        },
      );

      await _tapText(tester, 'Adicionar produto');
      await tester.pumpAndSettle();

      expect(catalogCalls, 1);
      expect(find.text(_longProductName), findsOneWidget);
      expect(find.text(_longServiceName), findsOneWidget);
      expect(find.text('Produto'), findsWidgets);
      expect(find.text('Serviço'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('Total'), findsOneWidget);
      expect(find.textContaining('R\$'), findsWidgets);
      expect(
        _hasDecoratedAncestorColor(
          tester,
          find.text('Itens da venda'),
          themeCase.colors.surface,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('scanner uses controlled result and never touches the camera', (
    WidgetTester tester,
  ) async {
    int scannerCalls = 0;
    int productLookupCalls = 0;
    String? scannerResult = '789456';
    List<ProdutoModel> lookupResult = <ProdutoModel>[
      _product(id: 'scan-1', name: _scannerProductName, barcode: '789456'),
    ];

    await _pumpPdv(
      tester,
      themeCase: _darkTheme,
      barcodeScannerLauncher: () async {
        scannerCalls += 1;
        return scannerResult;
      },
      barcodeProductLoader: (_, String tipo) async {
        productLookupCalls += 1;
        expect(tipo, 'PRODUTO');
        return lookupResult;
      },
    );

    await _tapText(tester, 'Ler código de barras');
    await tester.pumpAndSettle();
    expect(scannerCalls, 1);
    expect(productLookupCalls, 1);
    expect(find.text(_scannerProductName), findsOneWidget);

    scannerResult = null;
    await _tapText(tester, 'Ler código de barras');
    await tester.pumpAndSettle();
    expect(scannerCalls, 2);
    expect(productLookupCalls, 1);

    scannerResult = '000000';
    lookupResult = const <ProdutoModel>[];
    await _tapText(tester, 'Ler código de barras');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(scannerCalls, 3);
    expect(productLookupCalls, 2);
    expect(find.text(_scannerProductName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout finalizes sale once with exact fake service payload', (
    WidgetTester tester,
  ) async {
    final _FakeOperacaoService operacaoService = _FakeOperacaoService(
      completer: Completer<OperacaoInserirResponse>(),
    );
    int completedFeedbackCalls = 0;

    await _pumpPdv(
      tester,
      themeCase: _darkTheme,
      operacaoService: operacaoService,
      onSaleCompleted: () async {
        completedFeedbackCalls += 1;
      },
      nowProvider: () => DateTime(2026, 8, 8, 11, 30),
      productSelectionLauncher:
          () async => <ProdutoModel>[
            _product(id: 'produto-1', name: _longProductName, price: 45.25),
            _product(id: 'produto-1', name: _longProductName, price: 45.25),
            _service(id: 'servico-1', name: _longServiceName, price: 99.5),
          ],
    );

    await _tapText(tester, 'Adicionar produto');
    await tester.pumpAndSettle();
    await _selectPayment(tester, 'Pix');
    await _selectPayment(tester, 'Dinheiro');
    await _enterPaymentValue(tester, index: 0, value: '90,50');
    await _enterPaymentValue(tester, index: 1, value: '99,50');

    await tester.tap(find.widgetWithText(FilledButton, 'Finalizar venda'));
    await tester.pump();

    expect(operacaoService.finalizarCalls, 1);
    expect(find.widgetWithText(FilledButton, 'Enviando...'), findsOneWidget);
    final FilledButton sendingButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enviando...'),
    );
    expect(sendingButton.onPressed, isNull);
    expect(operacaoService.finalizarCalls, 1);

    operacaoService.completer!.complete(
      OperacaoInserirResponse(uuid: 'operacao-pdv-1'),
    );
    await tester.pumpAndSettle();

    final OperacaoVendaInput input = operacaoService.lastInput!;
    expect(input.receberDepois, isFalse);
    expect(input.idColaborador, 'colab-pdv');
    expect(input.nomeColaborador, 'Operadora PDV');
    expect(input.dataOperacao, DateTime(2026, 8, 8, 11, 30));
    expect(input.itens, hasLength(2));
    expect(input.itens.first.idProduto, 'produto-1');
    expect(input.itens.first.quantidade, 2);
    expect(input.itens.first.valorUnitario, 45.25);
    expect(input.itens.first.ehServico, isFalse);
    expect(input.itens.last.idProduto, 'servico-1');
    expect(input.itens.last.ehServico, isTrue);
    expect(input.formasPagamento, hasLength(2));
    expect(
      input.formasPagamento.map((f) => f.codigo),
      containsAll(<String>['TIPO2', 'TIPO1']),
    );
    expect(
      input.formasPagamento.fold<double>(0, (sum, item) => sum + item.valor),
      closeTo(190, 0.001),
    );
    expect(completedFeedbackCalls, 1);
    expect(find.text('Venda finalizada com sucesso.'), findsOneWidget);
    expect(find.text(_longProductName), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout validation and receive-later error preserve cart', (
    WidgetTester tester,
  ) async {
    final _FakeOperacaoService operacaoService = _FakeOperacaoService(
      error: Exception('backend recusou a venda mobile'),
    );
    int completedFeedbackCalls = 0;

    await _pumpPdv(
      tester,
      themeCase: _lightTheme,
      operacaoService: operacaoService,
      onSaleCompleted: () async {
        completedFeedbackCalls += 1;
      },
      productSelectionLauncher:
          () async => <ProdutoModel>[
            _product(id: 'produto-erro', name: _longProductName, price: 120),
          ],
    );

    await _tapText(tester, 'Adicionar produto');
    await tester.pumpAndSettle();
    await _selectPayment(tester, 'Pix');
    await _enterPaymentValue(tester, index: 0, value: '1,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Finalizar venda'));
    await tester.pumpAndSettle();

    expect(operacaoService.finalizarCalls, 0);
    expect(
      find.text('A soma dos pagamentos precisa fechar o total da venda.'),
      findsOneWidget,
    );
    expect(find.text(_longProductName), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Receber depois'));
    await tester.pumpAndSettle();
    expect(find.text('Receber depois'), findsWidgets);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrar para receber depois'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(operacaoService.finalizarCalls, 1);
    expect(operacaoService.lastInput?.receberDepois, isTrue);
    expect(operacaoService.lastInput?.formasPagamento, isEmpty);
    expect(completedFeedbackCalls, 0);
    expect(find.text(_longProductName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout runs sale-finish procedure before continuing', (
    WidgetTester tester,
  ) async {
    final List<ProcedureExecutionConfiguration> configurations =
        <ProcedureExecutionConfiguration>[];
    final _FakeOperacaoService operacaoService = _FakeOperacaoService();

    await _pumpPdv(
      tester,
      themeCase: _darkTheme,
      operacaoService: operacaoService,
      procedureCoordinator: _procedureCoordinator(
        scenario: OperationalProcedureRuntimeMockScenario.required,
        runner: (
          _,
          OperationalProcedure procedure,
          ProcedureExecutionConfiguration configuration,
        ) async {
          configurations.add(configuration);
          expect(procedure.id, 'sale-start-required-parking');
          return const ProcedureFlowResult.continueOperation(
            completedProcedureIds: <String>['sale-start-required-parking'],
          );
        },
      ),
      productSelectionLauncher:
          () async => <ProdutoModel>[
            _product(id: 'produto-finish', name: _longProductName, price: 120),
          ],
    );

    await _tapText(tester, 'Adicionar produto');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Receber depois'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrar para receber depois'),
    );
    await tester.pumpAndSettle();

    expect(configurations, hasLength(1));
    expect(
      configurations.single.operationPoint,
      ProcedureOperationPoint.saleFinishBefore,
    );
    expect(operacaoService.finalizarCalls, 1);
  });

  testWidgets('open sale receiving liquidates selected pending sale only', (
    WidgetTester tester,
  ) async {
    final _FakeOperacaoService operacaoService = _FakeOperacaoService();
    final _FakeVendaNaoLiquidadaApiClient vendaApiClient =
        _FakeVendaNaoLiquidadaApiClient();

    await _pumpPdv(
      tester,
      themeCase: _darkTheme,
      operacaoService: operacaoService,
      vendaNaoLiquidadaApiClient: vendaApiClient,
      vendaNaoLiquidada: _pendingSale(),
    );

    expect(find.text('Venda em aberto'), findsWidgets);
    expect(find.text(_longProductName), findsOneWidget);
    await _selectPayment(tester, 'Pix');
    await tester.tap(find.widgetWithText(FilledButton, 'Receber venda'));
    await tester.pumpAndSettle();

    expect(operacaoService.finalizarCalls, 0);
    expect(vendaApiClient.liquidarCalls, 1);
    expect(vendaApiClient.lastIdRecebimento, 'recebimento-pdv');
    expect(vendaApiClient.lastInput?.codigoTipoRecebimento, 'tipo2');
    expect(vendaApiClient.lastInput?.valorRecebido, 190);
    expect(vendaApiClient.lastInput?.idSessaoCaixa, 'sessao-pdv');
    expect(vendaApiClient.lastInput?.itens, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 1.3 keeps PDV cart checkout and action reachable', (
    WidgetTester tester,
  ) async {
    for (final _ThemeCase themeCase in _themeCases) {
      await _pumpPdv(
        tester,
        themeCase: themeCase,
        size: const Size(360, 760),
        textScale: 1.3,
        paymentTypes: <TiposRecebimento>[
          _paymentType(
            codigo: 'tipo2',
            descricao: 'Pix instantâneo com confirmação operacional alongada',
            ordem: 1,
          ),
          _paymentType(
            codigo: 'tipo1',
            descricao: 'Dinheiro recebido no balcão principal',
            ordem: 2,
          ),
        ],
        productSelectionLauncher:
            () async => <ProdutoModel>[
              _product(
                id: 'produto-longo',
                name: _veryLongProductName,
                price: 98765.43,
              ),
              _service(
                id: 'servico-longo',
                name: _veryLongServiceName,
                price: 12.34,
              ),
            ],
      );

      await _tapText(tester, 'Adicionar produto');
      await tester.pumpAndSettle();
      expect(find.text(_veryLongProductName), findsOneWidget);
      expect(find.text(_veryLongServiceName), findsOneWidget);
      await _scrollUntilVisible(tester, 'Pagamento');
      expect(find.text('Pagamento'), findsOneWidget);
      expect(find.textContaining('Pix instantâneo'), findsOneWidget);
      await _scrollUntilVisible(tester, 'Finalizar venda');
      expect(
        find.widgetWithText(FilledButton, 'Finalizar venda'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('keyboard inset keeps payment field and main action reachable', (
    WidgetTester tester,
  ) async {
    await _pumpPdv(
      tester,
      themeCase: _darkTheme,
      size: const Size(360, 780),
      viewInsets: const EdgeInsets.only(bottom: 320),
      productSelectionLauncher:
          () async => <ProdutoModel>[
            _product(id: 'produto-teclado', name: _longProductName, price: 150),
          ],
    );

    await _tapText(tester, 'Adicionar produto');
    await tester.pumpAndSettle();
    await _selectPayment(tester, 'Pix');

    final Finder paymentField = find.widgetWithText(
      TextField,
      'Valor recebido',
    );
    await Scrollable.ensureVisible(
      tester.element(paymentField.first),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.showKeyboard(paymentField.first);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(paymentField.first, '150,00');
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _scrollUntilVisible(tester, 'Finalizar venda');
    expect(
      find.widgetWithText(FilledButton, 'Finalizar venda'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

const _ThemeCase _darkTheme = _ThemeCase(
  description: 'dark',
  brightness: Brightness.dark,
  colors: SixMobileColorScheme.dark,
);

const _ThemeCase _lightTheme = _ThemeCase(
  description: 'light',
  brightness: Brightness.light,
  colors: SixMobileColorScheme.light,
);

const List<_ThemeCase> _themeCases = <_ThemeCase>[_darkTheme, _lightTheme];

const String _longProductName =
    'Produto comercial de balcão com nome longo para validar o PDV Mobile';
const String _longServiceName =
    'Serviço comercial vendido como item no carrinho do PDV';
const String _scannerProductName = 'Produto encontrado pelo scanner controlado';
const String _veryLongProductName =
    'Produto com nome extremamente longo para validar catálogo carrinho total e checkout em largura reduzida';
const String _veryLongServiceName =
    'Serviço comercial com descrição extensa vendido no mesmo fluxo do PDV Mobile';

class _ThemeCase {
  const _ThemeCase({
    required this.description,
    required this.brightness,
    required this.colors,
  });

  final String description;
  final Brightness brightness;
  final SixMobileColorScheme colors;
}

Future<void> _pumpPdv(
  WidgetTester tester, {
  required _ThemeCase themeCase,
  _FakeOperacaoService? operacaoService,
  _FakeCaixaApiClient? caixaApiClient,
  _FakeVendaNaoLiquidadaApiClient? vendaNaoLiquidadaApiClient,
  OperationalProcedureFlowCoordinator? procedureCoordinator,
  VendaNaoLiquidadaModel? vendaNaoLiquidada,
  pdv_base.PdvMobileProductSelectionLauncher? productSelectionLauncher,
  pdv_base.PdvMobileBarcodeScannerLauncher? barcodeScannerLauncher,
  pdv_base.PdvMobileBarcodeProductLoader? barcodeProductLoader,
  pdv_base.PdvMobileCashOperationsLauncher? cashOperationsLauncher,
  pdv_base.PdvMobileNowProvider? nowProvider,
  pdv_base.PdvMobileSaleCompletedFeedback? onSaleCompleted,
  List<TiposRecebimento>? paymentTypes,
  Size size = const Size(390, 900),
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool settle = true,
}) {
  final _FakeCaixaApiClient effectiveCaixaApiClient =
      caixaApiClient ??
      _FakeCaixaApiClient(paymentTypes: paymentTypes ?? _paymentTypes());

  return _pumpMobile(
    tester,
    brightness: themeCase.brightness,
    size: size,
    textScale: textScale,
    viewInsets: viewInsets,
    settle: settle,
    productFetch: (_) async => <ProdutoModel>[],
    child: pdv_base.PdvMobileScreen(
      vendaNaoLiquidada: vendaNaoLiquidada,
      operacaoService: operacaoService ?? _FakeOperacaoService(),
      caixaService: CaixaService(apiClient: effectiveCaixaApiClient),
      vendaNaoLiquidadaApiClient:
          vendaNaoLiquidadaApiClient ?? _FakeVendaNaoLiquidadaApiClient(),
      productSelectionLauncher: productSelectionLauncher,
      barcodeScannerLauncher: barcodeScannerLauncher,
      barcodeProductLoader: barcodeProductLoader,
      cashOperationsLauncher: cashOperationsLauncher,
      currentUserIdProvider: () async => 'colab-pdv',
      currentUserNameProvider: () => 'Operadora PDV',
      nowProvider: nowProvider ?? () => DateTime(2026, 8, 8, 10, 0),
      procedureCoordinator: procedureCoordinator ?? _procedureCoordinator(),
      onSaleCompleted: onSaleCompleted,
    ),
  );
}

Future<void> _pumpMobile(
  WidgetTester tester, {
  required Widget child,
  required Brightness brightness,
  Size size = const Size(390, 900),
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
  Future<List<ProdutoModel>> Function(Map<String, String>? headers)?
  productFetch,
  bool settle = true,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
        ChangeNotifierProvider<ProdutosListProvider<ProdutoModel>>(
          create:
              (_) => ProdutosListProvider<ProdutoModel>(
                fetchFunction: productFetch ?? (_) async => <ProdutoModel>[],
              ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
            size: size,
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: child,
        ),
      ),
    ),
  );

  await tester.pump();
  if (settle) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final Finder finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await Scrollable.ensureVisible(
      tester.element(finder.first),
      alignment: 0.65,
    );
  }
  await tester.pump();
  await tester.tap(finder.first);
}

OperationalProcedureFlowCoordinator _procedureCoordinator({
  OperationalProcedureRuntimeMockScenario scenario =
      OperationalProcedureRuntimeMockScenario.none,
  OperationalProcedureRunner? runner,
}) {
  return OperationalProcedureFlowCoordinator(
    dataSource: OperationalProcedureMockDataSource(
      delay: Duration.zero,
      runtimeScenario: scenario,
    ),
    runner: runner,
  );
}

Future<void> _scrollUntilVisible(WidgetTester tester, String text) async {
  final Finder finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await Scrollable.ensureVisible(
      tester.element(finder.first),
      alignment: 0.7,
    );
  }
  await tester.pump();
}

Future<void> _selectPayment(WidgetTester tester, String label) async {
  await _scrollUntilVisible(tester, label);
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

Future<void> _enterPaymentValue(
  WidgetTester tester, {
  required int index,
  required String value,
}) async {
  final Finder field = find
      .widgetWithText(TextField, 'Valor recebido')
      .at(index);
  await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
  await tester.pump();
  await tester.enterText(field, value);
  await tester.pump();
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasMaterialAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Material>(
        find.ancestor(of: child, matching: find.byType(Material)),
      )
      .any((Material material) => material.color == expected);
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

ProdutoModel _product({
  required String id,
  required String name,
  double price = 45.25,
  String? barcode,
}) {
  return ProdutoModel(
    id: id,
    ativo: true,
    codigoDeBarras: barcode ?? 'COD-$id',
    nomeProduto: name,
    tipoProduto: 'PRODUTO',
    modeloProduto: 'UN',
    estoqueMaximo: 10,
    estoqueMinimo: 1,
    precoVenda: price,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
  );
}

ProdutoModel _service({
  required String id,
  required String name,
  double price = 99.5,
}) {
  return ProdutoModel(
    id: id,
    ativo: true,
    codigoDeBarras: 'SERV-$id',
    nomeProduto: name,
    tipoProduto: 'SERVICO',
    modeloProduto: 'UN',
    estoqueMaximo: 0,
    estoqueMinimo: 0,
    precoVenda: price,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
  );
}

VendaNaoLiquidadaModel _pendingSale() {
  return VendaNaoLiquidadaModel(
    idRecebimento: 'recebimento-pdv',
    idOperacaoFinanceira: 'financeiro-pdv',
    idOperacaoApp: 'operacao-pdv-aberta',
    descricao: 'Venda PDV em aberto',
    valorOriginal: 190,
    valorAberto: 190,
    status: 'PENDENTE_PAGAMENTO',
    codigoTipoRecebimento: 'tipo2',
    dataCompetencia: DateTime(2026, 8, 8),
    dataVencimento: DateTime(2026, 8, 15),
    idCliente: '',
    nomeCliente: '',
    idColaboradorCriacao: 'colab-pdv',
    nomeColaboradorCriacao: 'Operadora PDV',
    itens: <VendaNaoLiquidadaItemModel>[
      VendaNaoLiquidadaItemModel(
        idProduto: 'produto-1',
        nome: _longProductName,
        quantidade: 2,
        valorUnitario: 45.25,
        ehServico: false,
      ),
      VendaNaoLiquidadaItemModel(
        idProduto: 'servico-1',
        nome: _longServiceName,
        quantidade: 1,
        valorUnitario: 99.5,
        ehServico: true,
      ),
    ],
    recebimentos: const <VendaNaoLiquidadaRecebimentoModel>[],
  );
}

List<TiposRecebimento> _paymentTypes() {
  return <TiposRecebimento>[
    _paymentType(codigo: 'tipo2', descricao: 'Pix', ordem: 1),
    _paymentType(codigo: 'tipo1', descricao: 'Dinheiro', ordem: 2),
    _paymentType(codigo: 'tipo3', descricao: 'Cartão crédito', ordem: 3),
  ];
}

TiposRecebimento _paymentType({
  required String codigo,
  required String descricao,
  required int ordem,
}) {
  return TiposRecebimento(
    codigoTipo: codigo,
    descricaoExibicao: descricao,
    naturezaRecebimento: 'imediato',
    aceitaParcelamento: false,
    ativo: true,
    exigeCliente: false,
    ordemExibicao: ordem,
    corHex: '',
    icone: '',
  );
}

class _FakeOperacaoService implements OperacaoService {
  _FakeOperacaoService({this.completer, this.error});

  Completer<OperacaoInserirResponse>? completer;
  Object? error;
  int finalizarCalls = 0;
  int printCalls = 0;
  OperacaoVendaInput? lastInput;

  @override
  Future<OperacaoInserirResponse> finalizarVenda(OperacaoVendaInput input) {
    finalizarCalls += 1;
    lastInput = input;
    final Object? currentError = error;
    if (currentError != null) throw currentError;
    final Completer<OperacaoInserirResponse>? currentCompleter = completer;
    if (currentCompleter != null) return currentCompleter.future;
    return Future<OperacaoInserirResponse>.value(
      OperacaoInserirResponse(uuid: 'operacao-pdv'),
    );
  }

  @override
  Future<DocumentoPdfResponse> imprimirComprovanteDaOperacao({
    required String idOperacao,
    required FormatoImpressaoOperacao formato,
  }) async {
    printCalls += 1;
    return const DocumentoPdfResponse(
      arquivoBase64: '',
      nomeArquivo: 'comprovante.pdf',
      mimeType: 'application/pdf',
      tamanhoBytes: 0,
    );
  }
}

class _FakeVendaNaoLiquidadaApiClient extends VendaNaoLiquidadaApiClient {
  _FakeVendaNaoLiquidadaApiClient()
    : super(httpClient: MockClient((_) async => http.Response('{}', 200)));

  int liquidarCalls = 0;
  String? lastIdRecebimento;
  LiquidarVendaNaoLiquidadaInput? lastInput;

  @override
  Future<VendaNaoLiquidadaModel> liquidar({
    required String idRecebimento,
    required LiquidarVendaNaoLiquidadaInput input,
  }) async {
    liquidarCalls += 1;
    lastIdRecebimento = idRecebimento;
    lastInput = input;
    return _pendingSale();
  }
}

class _FakeCaixaApiClient implements CaixaApiClient {
  _FakeCaixaApiClient({
    this.sessionCompleter,
    List<TiposRecebimento>? paymentTypes,
  }) : paymentTypes = paymentTypes ?? _paymentTypes();

  CaixaSessao? session = _openSession();
  Completer<CaixaSessao?>? sessionCompleter;
  Object? sessionError;
  List<TiposRecebimento> paymentTypes;
  int informacoesBasicasCalls = 0;
  int sessaoAtualCalls = 0;

  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    informacoesBasicasCalls += 1;
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: true,
      tiposRecebimento: paymentTypes,
      caixas: const <String>[],
      caixaOuGuiche: const <CaixaOuGuiche>[],
      formas: const <FormaMovimento>[],
    );
  }

  @override
  Future<CaixaSessao?> getSessaoAtual() {
    sessaoAtualCalls += 1;
    final Object? error = sessionError;
    if (error != null) throw error;
    final Completer<CaixaSessao?>? completer = sessionCompleter;
    if (completer != null && !completer.isCompleted) {
      return completer.future;
    }
    return Future<CaixaSessao?>.value(session ?? _openSession());
  }

  @override
  Future<List<CaixaSessao>> getSessoesAbertas() {
    final CaixaSessao? currentSession = session;
    return Future<List<CaixaSessao>>.value(
      currentSession == null
          ? const <CaixaSessao>[]
          : <CaixaSessao>[currentSession],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CaixaSessao _openSession() {
  return CaixaSessao(
    idSessaoCaixa: 'sessao-pdv',
    nomeCaixa: 'Caixa PDV Mobile',
    idCaixaOuGuiche: 'caixa-pdv',
    idColaboradorAbertura: 'colab-caixa',
    nomeColaboradorAbertura: 'Operador do caixa',
    dataHoraAbertura: '2026-08-08T08:00:00',
    valorAbertura: 150,
    status: 'aberta',
  );
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
