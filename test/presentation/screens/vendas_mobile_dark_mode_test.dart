import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/models/venda_nao_liquidada_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/models/regionalizacao_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_pendentes_pagamento_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_venda_mobile_screen.dart';
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart';
import 'package:sixpos/presentation/screens/receber_mobile_screen.dart';
import 'package:sixpos/presentation/screens/vendas_nao_liquidadas_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

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

  testWidgets(
    'sales entry menus preserve navigation boundary in light and dark',
    (WidgetTester tester) async {
      for (final _ThemeCase themeCase in _themeCases) {
        final List<Widget> salesDestinations = <Widget>[];

        await _pumpMobile(
          tester,
          brightness: themeCase.brightness,
          child: OpcoesVendaMobileScreen(
            procedureCoordinator: _procedureCoordinator(),
            onNavigate: (_, Widget page) => salesDestinations.add(page),
          ),
        );

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        expect(find.text('Nova venda'), findsWidgets);
        expect(find.text('Vendas a receber'), findsOneWidget);
        expect(find.text('Consultar vendas'), findsOneWidget);
        expect(find.text('Em breve'), findsWidgets);
        expect(
          _hasMaterialAncestorColor(
            tester,
            find.text('Vendas a receber'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

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

        expect(salesDestinations, hasLength(2));
        expect(salesDestinations.first, isA<PdvMobileScreen>());
        expect(salesDestinations.last, isA<VendasNaoLiquidadasMobileScreen>());

        final List<Widget> receiveDestinations = <Widget>[];
        await _pumpMobile(
          tester,
          brightness: themeCase.brightness,
          child: ReceberMobileScreen(
            onNavigate: (_, Widget page) => receiveDestinations.add(page),
          ),
        );

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        await tester.tap(
          find.byKey(const ValueKey<String>('receber-action-sales')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('receber-action-services')),
        );
        await tester.pump();

        expect(receiveDestinations, hasLength(2));
        expect(
          receiveDestinations.first,
          isA<VendasNaoLiquidadasMobileScreen>(),
        );
        expect(
          receiveDestinations.last,
          isA<AtendimentosTecnicosPendentesPagamentoMobileScreen>(),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'receivables loading empty and error states keep themed surfaces',
    (WidgetTester tester) async {
      for (final _ThemeCase themeCase in _themeCases) {
        final Completer<List<VendaNaoLiquidadaModel>> loadingCompleter =
            Completer<List<VendaNaoLiquidadaModel>>();
        final _FakeVendaNaoLiquidadaApiClient loadingApi =
            _FakeVendaNaoLiquidadaApiClient(listCompleter: loadingCompleter);

        await _pumpReceivables(
          tester,
          themeCase: themeCase,
          apiClient: loadingApi,
          settle: false,
        );
        await tester.pump();

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        expect(
          find.byKey(const ValueKey<String>('vendas-nao-liquidadas-loading')),
          findsOneWidget,
        );
        expect(loadingApi.listCalls, 1);

        loadingCompleter.complete(<VendaNaoLiquidadaModel>[]);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Nenhuma venda em aberto'), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Nenhuma venda em aberto'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

        final _FakeVendaNaoLiquidadaApiClient errorApi =
            _FakeVendaNaoLiquidadaApiClient(
              listError: Exception('falha controlada ao carregar vendas'),
            );
        await _pumpReceivables(
          tester,
          themeCase: themeCase,
          apiClient: errorApi,
        );

        expect(find.text('Não foi possível carregar'), findsOneWidget);
        expect(
          find.textContaining('falha controlada ao carregar vendas'),
          findsOneWidget,
        );
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Não foi possível carregar'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

        errorApi.listError = null;
        errorApi.vendas = <VendaNaoLiquidadaModel>[];
        await tester.tap(find.widgetWithText(OutlinedButton, 'Atualizar'));
        await tester.pumpAndSettle();

        expect(errorApi.listCalls, 2);
        expect(find.text('Nenhuma venda em aberto'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'receivables list and detail expose sale data in light and dark',
    (WidgetTester tester) async {
      for (final _ThemeCase themeCase in _themeCases) {
        final _FakeVendaNaoLiquidadaApiClient api =
            _FakeVendaNaoLiquidadaApiClient(vendas: _sampleSales());

        await _pumpReceivables(tester, themeCase: themeCase, apiClient: api);

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        expect(find.text('Recebimentos pendentes'), findsOneWidget);
        expect(find.text('2 vendas aguardando liquidação'), findsOneWidget);
        expect(find.text('Venda PDV 1001'), findsOneWidget);
        expect(find.text(_longCustomerName), findsWidgets);
        expect(find.text('PAGAMENTO_PARCIAL'), findsWidgets);
        expect(find.text('Valor em aberto'), findsWidgets);
        expect(find.textContaining('BRL'), findsWidgets);
        expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets);

        await _openFirstSaleDetail(tester);

        expect(find.text('Resumo da venda'), findsOneWidget);
        expect(find.text('Cliente'), findsOneWidget);
        expect(find.text(_longCustomerName), findsWidgets);
        expect(find.text('Colaborador'), findsOneWidget);
        expect(find.text('Vendedora Six'), findsWidgets);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('PAGAMENTO_PARCIAL'), findsWidgets);
        expect(find.widgetWithText(FilledButton, 'Receber'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Cancelar venda'),
          findsOneWidget,
        );
        expect(find.text('Valores'), findsOneWidget);
        expect(find.text('Valor original'), findsOneWidget);
        expect(find.text('Valor já recebido'), findsOneWidget);
        await _scrollUntilVisible(
          tester,
          'Recebimentos',
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Recebimentos'), findsOneWidget);
        expect(find.text('Pix'), findsWidgets);
        expect(find.textContaining('Parcial'), findsWidgets);

        await _scrollUntilVisible(
          tester,
          _longProductName,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Itens da venda'), findsOneWidget);
        expect(find.text(_longProductName), findsOneWidget);
        expect(find.text(_longServiceName), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'receiving total liquidates the selected sale with fake services',
    (WidgetTester tester) async {
      final _FakeVendaNaoLiquidadaApiClient api =
          _FakeVendaNaoLiquidadaApiClient(
            vendas: <VendaNaoLiquidadaModel>[
              _sale(
                idRecebimento: 'recv-total',
                valorOriginal: 250,
                valorAberto: 180,
              ),
            ],
          );
      final _FakeAgendaActions actions = _FakeAgendaActions();
      final _FakeCaixaApiClient caixaApiClient = _FakeCaixaApiClient();

      await _pumpReceivables(
        tester,
        themeCase: _darkTheme,
        apiClient: api,
        acoesFinanceiras: actions,
        caixaApiClient: caixaApiClient,
      );
      await _openFirstSaleDetail(tester);

      expect(api.liquidarCalls, 0);
      expect(actions.abatimentoCalls, 0);

      await _tapScrollableButton<FilledButton>(tester, 'Receber');

      expect(find.text('Receber venda em aberto'), findsOneWidget);
      expect(find.text('Venda PDV 1001'), findsWidgets);
      expect(find.text(_longCustomerName), findsWidgets);
      expect(find.text('Valor em aberto'), findsWidgets);
      expect(caixaApiClient.informacoesBasicasCalls, 1);
      expect(api.liquidarCalls, 0);

      await _tapScrollableButton<FilledButton>(tester, 'Receber total');

      expect(api.liquidarCalls, 1);
      expect(api.lastLiquidarId, 'recv-total');
      expect(api.lastLiquidarInput?.valorRecebido, 180);
      expect(api.lastLiquidarInput?.codigoTipoRecebimento, 'tipo2');
      expect(api.lastLiquidarInput?.referencia, 'op-recv-total');
      expect(api.lastLiquidarInput?.idSessaoCaixa, 'sessao-1');
      expect(api.lastLiquidarInput?.itens, hasLength(2));
      expect(api.lastLiquidarInput?.recebimentos, hasLength(1));
      expect(api.lastLiquidarInput?.recebimentos?.single.valor, 180);
      expect(caixaApiClient.sessaoAtualCalls, 1);
      expect(actions.abatimentoCalls, 0);
      expect(find.text('Venda recebida com sucesso.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('partial receiving calls the agenda partial action only', (
    WidgetTester tester,
  ) async {
    final _FakeVendaNaoLiquidadaApiClient api = _FakeVendaNaoLiquidadaApiClient(
      vendas: <VendaNaoLiquidadaModel>[
        _sale(
          idRecebimento: 'recv-partial',
          idOperacaoFinanceira: 'fin-partial',
          idOperacaoApp: 'op-partial',
          valorOriginal: 500,
          valorAberto: 300,
          status: 'PAGAMENTO_PARCIAL',
        ),
      ],
    );
    final _FakeAgendaActions actions = _FakeAgendaActions();
    final _FakeCaixaApiClient caixaApiClient = _FakeCaixaApiClient();

    await _pumpReceivables(
      tester,
      themeCase: _lightTheme,
      apiClient: api,
      acoesFinanceiras: actions,
      caixaApiClient: caixaApiClient,
    );
    await _openFirstSaleDetail(tester);
    await _tapScrollableButton<FilledButton>(tester, 'Receber');

    await tester.tap(find.text('Parcial'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor da forma 1'),
      '90,00',
    );
    await tester.pump();
    await _tapScrollableButton<FilledButton>(tester, 'Receber parcial');

    expect(api.liquidarCalls, 0);
    expect(actions.abatimentoCalls, 1);
    expect(actions.lastIdLancamento, 'fin-partial');
    expect(actions.lastParcialRequest?.tipoLiquidacao, 'PARCIAL');
    expect(actions.lastParcialRequest?.valorLiquidado, 90);
    expect(actions.lastParcialRequest?.formaPagamentoRealizada, 'PIX');
    expect(actions.lastParcialRequest?.idSessaoCaixa, 'sessao-1');
    expect(actions.lastParcialRequest?.recebimentos, hasLength(1));
    expect(actions.lastParcialRequest?.recebimentos?.single.codigo, 'tipo2');
    expect(actions.lastParcialRequest?.recebimentos?.single.valor, 90);
    expect(caixaApiClient.sessaoAtualCalls, 1);
    expect(find.text('Parcial recebida com sucesso.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel sale bottom sheet preserves id and handles success and error',
    (WidgetTester tester) async {
      final _FakeVendaNaoLiquidadaApiClient successApi =
          _FakeVendaNaoLiquidadaApiClient(
            vendas: <VendaNaoLiquidadaModel>[
              _sale(idRecebimento: 'recv-cancelar'),
            ],
          );

      await _pumpReceivables(
        tester,
        themeCase: _darkTheme,
        apiClient: successApi,
      );
      await _openFirstSaleDetail(tester);

      await _tapScrollableButton<OutlinedButton>(tester, 'Cancelar venda');

      expect(find.text('Cancelar venda em aberto?'), findsOneWidget);
      expect(find.text('Venda PDV 1001'), findsWidgets);
      expect(find.textContaining('BRL'), findsWidgets);
      expect(successApi.cancelCalls, 0);

      await _tapScrollableButton<OutlinedButton>(tester, 'Voltar');
      expect(successApi.cancelCalls, 0);

      await _openFirstSaleDetail(tester);
      await _tapScrollableButton<OutlinedButton>(tester, 'Cancelar venda');
      await _tapScrollableButton<FilledButton>(tester, 'Confirmar');

      expect(successApi.cancelCalls, 1);
      expect(successApi.lastCancelId, 'recv-cancelar');
      expect(find.text('Venda em aberto cancelada.'), findsOneWidget);

      final _FakeVendaNaoLiquidadaApiClient errorApi =
          _FakeVendaNaoLiquidadaApiClient(
            vendas: <VendaNaoLiquidadaModel>[_sale(idRecebimento: 'recv-erro')],
            cancelError: Exception('falha ao cancelar venda'),
          );
      await _pumpReceivables(
        tester,
        themeCase: _darkTheme,
        apiClient: errorApi,
      );
      await _openFirstSaleDetail(tester);
      await _tapScrollableButton<OutlinedButton>(tester, 'Cancelar venda');
      await _tapScrollableButton<FilledButton>(tester, 'Confirmar');

      expect(errorApi.cancelCalls, 1);
      expect(errorApi.lastCancelId, 'recv-erro');
      expect(find.text('falha ao cancelar venda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'receive error does not perform partial action or duplicate call',
    (WidgetTester tester) async {
      final _FakeVendaNaoLiquidadaApiClient api =
          _FakeVendaNaoLiquidadaApiClient(
            vendas: <VendaNaoLiquidadaModel>[_sale(idRecebimento: 'recv-erro')],
            liquidarError: Exception('falha ao liquidar venda'),
          );
      final _FakeAgendaActions actions = _FakeAgendaActions();

      await _pumpReceivables(
        tester,
        themeCase: _darkTheme,
        apiClient: api,
        acoesFinanceiras: actions,
        caixaApiClient: _FakeCaixaApiClient(),
      );
      await _openFirstSaleDetail(tester);
      await _tapScrollableButton<FilledButton>(tester, 'Receber');
      await _tapScrollableButton<FilledButton>(tester, 'Receber total');

      expect(api.liquidarCalls, 1);
      expect(actions.abatimentoCalls, 0);
      expect(find.text('falha ao liquidar venda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('text scale 1.3 keeps sales list and detail scrollable', (
    WidgetTester tester,
  ) async {
    for (final _ThemeCase themeCase in _themeCases) {
      final _FakeVendaNaoLiquidadaApiClient api =
          _FakeVendaNaoLiquidadaApiClient(
            vendas: <VendaNaoLiquidadaModel>[
              _sale(
                status:
                    'AGUARDANDO_PAGAMENTO_PARCIAL_COM_VALIDACAO_OPERACIONAL',
                valorOriginal: 9876543.21,
                valorAberto: 1234567.89,
              ),
            ],
          );

      await _pumpReceivables(
        tester,
        themeCase: themeCase,
        apiClient: api,
        size: const Size(360, 760),
        textScale: 1.3,
      );

      expect(_scaffoldBackground(tester), themeCase.colors.background);
      expect(find.text(_longCustomerName), findsWidgets);
      expect(
        find.text('AGUARDANDO_PAGAMENTO_PARCIAL_COM_VALIDACAO_OPERACIONAL'),
        findsWidgets,
      );
      expect(find.textContaining('BRL'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _openFirstSaleDetail(tester);
      await _scrollUntilVisible(
        tester,
        'Valor em aberto',
        scrollable: find.byType(Scrollable).last,
      );
      await _scrollUntilVisible(
        tester,
        'Receber',
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.widgetWithText(FilledButton, 'Receber'), findsOneWidget);
      await _scrollUntilVisible(
        tester,
        _longProductName,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(_longProductName), findsOneWidget);
      expect(find.text(_longServiceName), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('receipt bottom sheet remains reachable with keyboard inset', (
    WidgetTester tester,
  ) async {
    await _pumpReceivables(
      tester,
      themeCase: _darkTheme,
      apiClient: _FakeVendaNaoLiquidadaApiClient(
        vendas: <VendaNaoLiquidadaModel>[_sale()],
      ),
      caixaApiClient: _FakeCaixaApiClient(),
      size: const Size(360, 780),
      viewInsets: const EdgeInsets.only(bottom: 320),
    );

    await _openFirstSaleDetail(tester);
    await _tapScrollableButton<FilledButton>(tester, 'Receber');

    final Finder observationField = find.widgetWithText(
      TextField,
      'Observação',
    );
    await Scrollable.ensureVisible(
      tester.element(observationField),
      alignment: 0.45,
    );
    await tester.pump();
    await tester.showKeyboard(observationField);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(
      observationField,
      'Recebimento conferido com teclado aberto no balcão de vendas.',
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _scrollUntilVisible(
      tester,
      'Receber total',
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.widgetWithText(FilledButton, 'Receber total'), findsOneWidget);
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

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

const String _longCustomerName =
    'Cliente Six Comércio de Peças Técnicas com Nome Muito Longo';
const String _longProductName =
    'Produto com nome extremamente longo para validar venda mobile';
const String _longServiceName =
    'Serviço de instalação com descrição longa para validar rolagem';

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

Future<void> _pumpReceivables(
  WidgetTester tester, {
  required _ThemeCase themeCase,
  required _FakeVendaNaoLiquidadaApiClient apiClient,
  _FakeAgendaActions? acoesFinanceiras,
  _FakeCaixaApiClient? caixaApiClient,
  Size size = const Size(390, 900),
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool settle = true,
}) {
  return _pumpMobile(
    tester,
    brightness: themeCase.brightness,
    size: size,
    textScale: textScale,
    viewInsets: viewInsets,
    settle: settle,
    child: VendasNaoLiquidadasMobileScreen(
      apiClient: apiClient,
      acoesFinanceiras: acoesFinanceiras ?? _FakeAgendaActions(),
      caixaApiClient: caixaApiClient ?? _FakeCaixaApiClient(),
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
    ChangeNotifierProvider<LocaleSettingsProvider>(
      create:
          (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _FakeRegionalizacaoApiClient(),
            ),
          ),
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
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

OperationalProcedureFlowCoordinator _procedureCoordinator() {
  return OperationalProcedureFlowCoordinator(
    dataSource: const OperationalProcedureMockDataSource(
      delay: Duration.zero,
      runtimeScenario: OperationalProcedureRuntimeMockScenario.none,
    ),
  );
}

Future<void> _openFirstSaleDetail(WidgetTester tester) async {
  final Finder detailsButton =
      find
          .byWidgetPredicate(
            (Widget widget) =>
                widget is IconButton &&
                widget.tooltip == 'Ver detalhes da venda',
          )
          .first;
  await Scrollable.ensureVisible(
    tester.element(detailsButton),
    alignment: 0.65,
  );
  await tester.pump();
  await tester.tap(detailsButton);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  String text, {
  required Finder scrollable,
}) async {
  final Finder finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 260, scrollable: scrollable);
  } else {
    await Scrollable.ensureVisible(
      tester.element(finder.first),
      alignment: 0.7,
    );
  }
  await tester.pump();
}

Future<void> _tapScrollableButton<T extends Widget>(
  WidgetTester tester,
  String text,
) async {
  await _scrollUntilVisible(
    tester,
    text,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.widgetWithText(T, text));
  await tester.pumpAndSettle();
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

List<VendaNaoLiquidadaModel> _sampleSales() {
  return <VendaNaoLiquidadaModel>[
    _sale(status: 'PAGAMENTO_PARCIAL', valorOriginal: 350, valorAberto: 180),
    _sale(
      idRecebimento: 'recv-2',
      idOperacaoFinanceira: 'fin-2',
      idOperacaoApp: 'op-2',
      descricao: 'Venda PDV 1002',
      cliente: 'Cliente de retirada rápida',
      status: 'PENDENTE_PAGAMENTO',
      valorOriginal: 48.9,
      valorAberto: 48.9,
      itens: <VendaNaoLiquidadaItemModel>[
        VendaNaoLiquidadaItemModel(
          idProduto: 'produto-zero',
          nome: 'Item unitário',
          quantidade: 1,
          valorUnitario: 48.9,
          ehServico: false,
        ),
      ],
      recebimentos: const <VendaNaoLiquidadaRecebimentoModel>[],
    ),
  ];
}

VendaNaoLiquidadaModel _sale({
  String idRecebimento = 'recv-1',
  String idOperacaoFinanceira = 'fin-1',
  String? idOperacaoApp,
  String descricao = 'Venda PDV 1001',
  String cliente = _longCustomerName,
  String status = 'PENDENTE_PAGAMENTO',
  double valorOriginal = 350,
  double valorAberto = 180,
  List<VendaNaoLiquidadaItemModel>? itens,
  List<VendaNaoLiquidadaRecebimentoModel>? recebimentos,
}) {
  return VendaNaoLiquidadaModel(
    idRecebimento: idRecebimento,
    idOperacaoFinanceira: idOperacaoFinanceira,
    idOperacaoApp: idOperacaoApp ?? 'op-$idRecebimento',
    descricao: descricao,
    valorOriginal: valorOriginal,
    valorAberto: valorAberto,
    status: status,
    codigoTipoRecebimento: 'tipo2',
    dataCompetencia: DateTime(2026, 8, 8, 14, 35),
    dataVencimento: DateTime(2026, 8, 15),
    idCliente: 'cliente-1',
    nomeCliente: cliente,
    idColaboradorCriacao: 'colab-1',
    nomeColaboradorCriacao: 'Vendedora Six',
    itens:
        itens ??
        <VendaNaoLiquidadaItemModel>[
          VendaNaoLiquidadaItemModel(
            idProduto: 'produto-1',
            nome: _longProductName,
            quantidade: 2,
            valorUnitario: 75,
            ehServico: false,
          ),
          VendaNaoLiquidadaItemModel(
            idProduto: 'servico-1',
            nome: _longServiceName,
            quantidade: 1,
            valorUnitario: 200,
            ehServico: true,
          ),
        ],
    recebimentos:
        recebimentos ??
        <VendaNaoLiquidadaRecebimentoModel>[
          VendaNaoLiquidadaRecebimentoModel(
            id: 'liq-1',
            tipoLiquidacao: 'PARCIAL',
            valorLiquidado: valorOriginal - valorAberto,
            valorRestanteAntes: valorOriginal,
            valorRestanteDepois: valorAberto,
            codigoTipoRecebimento: 'tipo2',
            formaPagamentoRealizada: 'PIX',
            descricaoTipoRecebimento: 'Pix',
            observacoes: 'Pagamento parcial registrado',
            referencia: idOperacaoApp ?? 'op-$idRecebimento',
            dataLiquidacao: DateTime(2026, 8, 8),
            registradoEm: DateTime(2026, 8, 8, 15, 10),
          ),
        ],
  );
}

class _FakeVendaNaoLiquidadaApiClient extends VendaNaoLiquidadaApiClient {
  _FakeVendaNaoLiquidadaApiClient({
    this.vendas = const <VendaNaoLiquidadaModel>[],
    this.listCompleter,
    this.listError,
    this.liquidarError,
    this.cancelError,
  }) : super(httpClient: MockClient((_) async => http.Response('[]', 200)));

  List<VendaNaoLiquidadaModel> vendas;
  Completer<List<VendaNaoLiquidadaModel>>? listCompleter;
  Object? listError;
  Object? liquidarError;
  Object? cancelError;
  int listCalls = 0;
  int liquidarCalls = 0;
  int cancelCalls = 0;
  String? lastLiquidarId;
  LiquidarVendaNaoLiquidadaInput? lastLiquidarInput;
  String? lastCancelId;

  @override
  Future<List<VendaNaoLiquidadaModel>> listar() {
    listCalls += 1;
    final Object? error = listError;
    if (error != null) throw error;
    final Completer<List<VendaNaoLiquidadaModel>>? completer = listCompleter;
    if (completer != null) return completer.future;
    return Future<List<VendaNaoLiquidadaModel>>.value(vendas);
  }

  @override
  Future<VendaNaoLiquidadaModel> liquidar({
    required String idRecebimento,
    required LiquidarVendaNaoLiquidadaInput input,
  }) async {
    liquidarCalls += 1;
    lastLiquidarId = idRecebimento;
    lastLiquidarInput = input;
    final Object? error = liquidarError;
    if (error != null) throw error;
    final VendaNaoLiquidadaModel venda = vendas.firstWhere(
      (VendaNaoLiquidadaModel item) => item.idRecebimento == idRecebimento,
      orElse: () => _sale(idRecebimento: idRecebimento),
    );
    vendas = vendas
        .where(
          (VendaNaoLiquidadaModel item) => item.idRecebimento != idRecebimento,
        )
        .toList(growable: false);
    return venda;
  }

  @override
  Future<void> cancelar({required String idRecebimento}) {
    cancelCalls += 1;
    lastCancelId = idRecebimento;
    final Object? error = cancelError;
    if (error != null) throw error;
    vendas = vendas
        .where(
          (VendaNaoLiquidadaModel item) => item.idRecebimento != idRecebimento,
        )
        .toList(growable: false);
    return Future<void>.value();
  }
}

class _FakeAgendaActions extends AgendaFinanceiraAcoesFinanceiras {
  _FakeAgendaActions()
    : super(httpClient: MockClient((_) async => http.Response('{}', 200)));

  int abatimentoCalls = 0;
  String? lastIdLancamento;
  AgendaFinanceiraParcialRequest? lastParcialRequest;

  @override
  Future<LancamentoAgendaFinanceiraResponse> executarAbatimento({
    required String idLancamento,
    required AgendaFinanceiraParcialRequest request,
  }) {
    abatimentoCalls += 1;
    lastIdLancamento = idLancamento;
    lastParcialRequest = request;
    return Future<LancamentoAgendaFinanceiraResponse>.value(
      LancamentoAgendaFinanceiraResponse(
        id: idLancamento,
        status: 'ABATIMENTO_REGISTRADO',
      ),
    );
  }
}

class _FakeCaixaApiClient implements CaixaApiClient {
  int informacoesBasicasCalls = 0;
  int sessaoAtualCalls = 0;

  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    informacoesBasicasCalls += 1;
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: true,
      tiposRecebimento: <TiposRecebimento>[
        TiposRecebimento(
          codigoTipo: 'tipo2',
          descricaoExibicao: 'Pix',
          naturezaRecebimento: 'imediato',
          aceitaParcelamento: false,
          ativo: true,
          exigeCliente: false,
          ordemExibicao: 1,
          corHex: '',
          icone: '',
        ),
        TiposRecebimento(
          codigoTipo: 'tipo1',
          descricaoExibicao: 'Dinheiro',
          naturezaRecebimento: 'imediato',
          aceitaParcelamento: false,
          ativo: true,
          exigeCliente: false,
          ordemExibicao: 2,
          corHex: '',
          icone: '',
        ),
      ],
      caixas: const <String>[],
      caixaOuGuiche: const <CaixaOuGuiche>[],
      formas: const <FormaMovimento>[],
    );
  }

  @override
  Future<CaixaSessao?> getSessaoAtual() async {
    sessaoAtualCalls += 1;
    return CaixaSessao(
      idSessaoCaixa: 'sessao-1',
      nomeCaixa: 'Caixa mobile',
      idColaboradorAbertura: 'colab-caixa',
      dataHoraAbertura: '2026-08-08T08:00:00',
      valorAbertura: 100,
      status: 'aberta',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
