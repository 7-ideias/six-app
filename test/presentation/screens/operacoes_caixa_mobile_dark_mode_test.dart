import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/caixa_completo_movimentos_models.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/models/regionalizacao_models.dart';
import 'package:sixpos/domain/services/caixa/caixa_service.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
    SixThemeResolver().atualizarTema(TemaSistema.claro);
    UsuarioProvider().clear();
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
    UsuarioProvider().clear();
  });

  testWidgets(
    'cash operations entry covers loading closed no-cash and retry states',
    (WidgetTester tester) async {
      for (final _ThemeCase themeCase in _themeCases) {
        final Completer<InformacoesBasicasCaixaResponse> infoCompleter =
            Completer<InformacoesBasicasCaixaResponse>();
        final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
          infoCompleter: infoCompleter,
          startClosed: true,
        );

        await _pumpCash(
          tester,
          themeCase: themeCase,
          fake: fake,
          settle: false,
        );
        await tester.pump();

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        expect(find.text('Carregando operações de caixa'), findsOneWidget);
        expect(fake.informacoesBasicasCalls, 1);
        expect(fake.sessaoAtualCalls, 0);

        infoCompleter.complete(_cashInfo(cashDesks: const <CaixaOuGuiche>[]));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Abertura de caixa'), findsOneWidget);
        expect(find.text('Aguardando abertura'), findsWidgets);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Abertura de caixa'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

        await tester.tap(find.text('Selecione').first);
        await tester.pumpAndSettle();
        expect(find.text('Nenhum caixa disponível.'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final _FakeCaixaApiClient closedFake = _FakeCaixaApiClient(
          startClosed: true,
        );
        await _pumpCash(tester, themeCase: themeCase, fake: closedFake);
        await tester.tap(find.byTooltip('Nova movimentação'));
        await tester.pumpAndSettle();
        expect(
          find.text('Antes de lançar operações, faça a abertura do caixa.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        final _FakeCaixaApiClient errorFake = _FakeCaixaApiClient(
          infoError: CaixaApiException(statusCode: 403, body: 'forbidden'),
        );
        await _pumpCash(tester, themeCase: themeCase, fake: errorFake);
        expect(find.text('Não foi possível carregar'), findsOneWidget);
        expect(
          find.text('Você não possui permissão para operar este caixa.'),
          findsOneWidget,
        );

        errorFake.infoError = null;
        errorFake.session = null;
        await tester.tap(find.widgetWithText(FilledButton, 'Tentar novamente'));
        await tester.pumpAndSettle();

        expect(errorFake.informacoesBasicasCalls, 2);
        expect(find.text('Abertura de caixa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('opening cash sends selected cash and initial balance once', (
    WidgetTester tester,
  ) async {
    for (final _ThemeCase themeCase in _themeCases) {
      final Completer<void> openCompleter = Completer<void>();
      final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
        startClosed: true,
        openCompleter: openCompleter,
      );

      await _pumpCash(tester, themeCase: themeCase, fake: fake);

      await _enterTextField(tester, 'Troco inicial', '123,45');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Abrir caixa'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(fake.openCalls, 1);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Abrir caixa'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(fake.openCalls, 1);

      openCompleter.complete();
      await tester.pumpAndSettle();

      expect(fake.lastOpenRequest?.idCaixaOuGuiche, 'caixa-1');
      expect(fake.lastOpenRequest?.nomeCaixa, _longCashName);
      expect(fake.lastOpenRequest?.valorAbertura, closeTo(123.45, 0.001));
      expect(fake.informacoesBasicasCalls, 2);
      expect(fake.session?.idColaboradorAbertura, 'colab-caixa');
      expect(find.textContaining('Caixa aberto'), findsWidgets);
      expect(find.textContaining(_longCashName), findsWidgets);
      expect(tester.takeException(), isNull);
    }

    final _FakeCaixaApiClient errorFake = _FakeCaixaApiClient(
      startClosed: true,
      openError: CaixaApiException(statusCode: 500, body: 'falha abertura'),
    );
    await _pumpCash(tester, themeCase: _darkTheme, fake: errorFake);
    await _enterTextField(tester, 'Troco inicial', '55,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Abrir caixa'));
    await tester.pumpAndSettle();

    expect(errorFake.openCalls, 1);
    expect(errorFake.session, isNull);
    expect(
      find.text('Não foi possível concluir a operação de caixa.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'supply movement sends payload updates history and blocks duplicate submit',
    (WidgetTester tester) async {
      for (final _ThemeCase themeCase in _themeCases) {
        final Completer<void> registerCompleter = Completer<void>();
        final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
          registerCompleter: registerCompleter,
        );

        await _pumpCash(tester, themeCase: themeCase, fake: fake);
        await _openMovementSheet(tester);
        await _selectOperationType(tester, 'Suprimento');
        await _selectRelatedMethod(tester, 'Pix');
        await _enterTextField(tester, 'Valor', '250,50');
        await _enterTextField(tester, 'Referência / comprovante', 'SUP-777');
        await _enterTextField(
          tester,
          'Observação',
          'Suprimento operacional para reforço do caixa',
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'Registrar movimentação'),
        );
        await tester.pump();
        expect(fake.registerCalls, 1);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Registrar movimentação'),
        );
        await tester.pump();
        expect(fake.registerCalls, 1);

        registerCompleter.complete();
        await tester.pumpAndSettle();

        expect(fake.lastRegisterRequest?.idSessaoCaixa, 'sessao-caixa-1');
        expect(
          fake.lastRegisterRequest?.tipoMovimento,
          OperacaoCaixaTipo.suprimento,
        );
        expect(fake.lastRegisterRequest?.codigoTipoRecebimento, 'tipo2');
        expect(fake.lastRegisterRequest?.valor, closeTo(250.50, 0.001));
        expect(fake.lastRegisterRequest?.referencia, 'SUP-777');
        expect(fake.lastRegisterRequest?.vinculadoVenda, isFalse);
        expect(fake.movimentosCalls, greaterThanOrEqualTo(2));
        expect(fake.resumoCalls, greaterThanOrEqualTo(2));
        expect(find.text('Suprimento'), findsWidgets);
        expect(find.text('Pix'), findsWidgets);

        await _openMovementDetail(tester, 'Suprimento');
        expect(find.text('Entrada'), findsOneWidget);
        expect(find.text('SUP-777'), findsOneWidget);
        expect(
          find.text('Suprimento operacional para reforço do caixa'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }

      final _FakeCaixaApiClient errorFake = _FakeCaixaApiClient(
        registerError: CaixaApiException(
          statusCode: 500,
          body: 'falha registro',
        ),
      );
      await _pumpCash(tester, themeCase: _darkTheme, fake: errorFake);
      await _openMovementSheet(tester);
      await _selectOperationType(tester, 'Suprimento');
      await _enterTextField(tester, 'Valor', '60,00');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar movimentação'),
      );
      await tester.pumpAndSettle();

      expect(errorFake.registerCalls, 1);
      expect(errorFake.movements, isEmpty);
      expect(
        find.text('Não foi possível concluir a operação de caixa.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cash-out validates amount sends sangria and preserves outflow text',
    (WidgetTester tester) async {
      final _FakeCaixaApiClient fake = _FakeCaixaApiClient();
      await _pumpCash(tester, themeCase: _darkTheme, fake: fake);
      await _openMovementSheet(tester);
      await _selectOperationType(tester, 'Sangria');
      await _selectRelatedMethod(tester, 'Dinheiro');

      await _enterTextField(tester, 'Valor', '0');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar movimentação'),
      );
      await tester.pumpAndSettle();
      expect(fake.registerCalls, 0);
      expect(find.text('Informe um valor válido.'), findsOneWidget);

      await _enterTextField(tester, 'Valor', '-10');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar movimentação'),
      );
      await tester.pumpAndSettle();
      expect(fake.registerCalls, 0);

      await _enterTextField(tester, 'Valor', '75,25');
      await _enterTextField(tester, 'Referência / comprovante', 'SAN-001');
      await _enterTextField(
        tester,
        'Observação',
        'Sangria para depósito seguro no fim do turno',
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar movimentação'),
      );
      await tester.pumpAndSettle();

      expect(fake.registerCalls, 1);
      expect(
        fake.lastRegisterRequest?.tipoMovimento,
        OperacaoCaixaTipo.sangria,
      );
      expect(fake.lastRegisterRequest?.codigoTipoRecebimento, 'tipo1');
      expect(fake.lastRegisterRequest?.valor, closeTo(75.25, 0.001));
      expect(find.text('Sangria'), findsWidgets);

      await _openMovementDetail(tester, 'Sangria');
      expect(find.text('Saída'), findsOneWidget);
      expect(find.text('SAN-001'), findsOneWidget);
      expect(
        find.text('Sangria para depósito seguro no fim do turno'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'movement detail cancels only after confirmation and refreshes state',
    (WidgetTester tester) async {
      final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
        movements: <MovimentoCaixa>[
          _movement(
            id: 'mov-cancel',
            tipo: OperacaoCaixaTipo.suprimento,
            natureza: 'entrada',
            valor: 80,
            referencia: 'CAN-001',
          ),
        ],
      );

      await _pumpCash(tester, themeCase: _darkTheme, fake: fake);
      await _openMovementDetail(tester, 'Suprimento');
      await _scrollUntilVisible(
        tester,
        'Cancelar',
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar movimentação?'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Voltar'));
      await tester.pumpAndSettle();
      expect(fake.cancelCalls, 0);

      await _openMovementDetail(tester, 'Suprimento');
      await _scrollUntilVisible(
        tester,
        'Cancelar',
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar operação'));
      await tester.pumpAndSettle();

      expect(fake.cancelCalls, 1);
      expect(fake.lastCancelId, 'mov-cancel');
      expect(fake.movements.single.status, 'cancelada');
      expect(find.text('Movimentação cancelada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'history loading empty today filter and movement errors remain usable',
    (WidgetTester tester) async {
      final Completer<List<MovimentoCaixa>> movementsCompleter =
          Completer<List<MovimentoCaixa>>();
      final _FakeCaixaApiClient loadingFake = _FakeCaixaApiClient(
        movementsCompleter: movementsCompleter,
      );

      await _pumpCash(
        tester,
        themeCase: _darkTheme,
        fake: loadingFake,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Carregando movimentações.'), findsWidgets);
      movementsCompleter.complete(<MovimentoCaixa>[]);
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma movimentação'), findsOneWidget);

      final _FakeCaixaApiClient filteredFake = _FakeCaixaApiClient(
        movements: <MovimentoCaixa>[
          _movement(
            id: 'mov-today',
            tipo: OperacaoCaixaTipo.suprimento,
            natureza: 'entrada',
            valor: 30,
            dataHora: '2026-08-08T09:00:00',
          ),
          _movement(
            id: 'mov-old',
            tipo: OperacaoCaixaTipo.sangria,
            natureza: 'saida',
            valor: 20,
            dataHora: '2026-08-07T09:00:00',
          ),
        ],
      );

      await _pumpCash(tester, themeCase: _darkTheme, fake: filteredFake);
      expect(find.text('Suprimento'), findsOneWidget);
      expect(find.text('Sangria'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Hoje'));
      await tester.pumpAndSettle();
      expect(find.text('Suprimento'), findsOneWidget);
      expect(find.text('Sangria'), findsNothing);

      final _FakeCaixaApiClient errorFake = _FakeCaixaApiClient(
        movementsError: CaixaApiException(statusCode: 500, body: 'erro'),
      );
      await _pumpCash(tester, themeCase: _darkTheme, fake: errorFake);
      expect(
        find.text('Não foi possível concluir a operação de caixa.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'closing conference sends declared values once and closes session',
    (WidgetTester tester) async {
      for (final _ThemeCase themeCase in _themeCases) {
        final Completer<void> closeCompleter = Completer<void>();
        final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
          closeCompleter: closeCompleter,
        );

        await _pumpCash(tester, themeCase: themeCase, fake: fake);
        await _openClosingSheet(tester);

        expect(find.text('Conferência dos valores'), findsOneWidget);
        expect(find.text('Saldo esperado'), findsWidgets);
        expect(find.textContaining('R\$'), findsWidgets);

        await _enterTextField(tester, 'Dinheiro apurado', '180,10');
        await _enterTextField(tester, 'Pix apurado', '90,20');
        await _enterTextField(tester, 'Cartões apurados', '70,30');
        await _enterTextField(
          tester,
          'Observação do fechamento',
          'Fechamento sem divergência operacional',
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'Concluir fechamento'),
        );
        await tester.pump();
        expect(fake.closeCalls, 1);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Concluir fechamento'),
        );
        await tester.pump();
        expect(fake.closeCalls, 1);

        closeCompleter.complete();
        await tester.pumpAndSettle();

        expect(fake.lastCloseRequest?.idSessaoCaixa, 'sessao-caixa-1');
        expect(
          fake.lastCloseRequest?.valorDinheiroApurado,
          closeTo(180.10, 0.001),
        );
        expect(fake.lastCloseRequest?.valorPixApurado, closeTo(90.20, 0.001));
        expect(
          fake.lastCloseRequest?.valorCartaoApurado,
          closeTo(70.30, 0.001),
        );
        expect(
          fake.lastCloseRequest?.observacaoFechamento,
          'Fechamento sem divergência operacional',
        );
        expect(find.text('Caixa fechado com sucesso.'), findsOneWidget);
        expect(find.text('Abertura de caixa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('closing error preserves session and declared data for retry', (
    WidgetTester tester,
  ) async {
    final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
      closeError: CaixaApiException(statusCode: 500, body: 'falha fechamento'),
    );

    await _pumpCash(tester, themeCase: _darkTheme, fake: fake);
    await _openClosingSheet(tester);
    await _enterTextField(tester, 'Dinheiro apurado', '170,00');
    await _enterTextField(tester, 'Pix apurado', '88,00');
    await _enterTextField(tester, 'Observação do fechamento', 'Recontar caixa');

    await tester.tap(find.widgetWithText(FilledButton, 'Concluir fechamento'));
    await tester.pumpAndSettle();

    expect(fake.closeCalls, 1);
    expect(fake.session, isNotNull);
    expect(
      find.text('Não foi possível concluir a operação de caixa.'),
      findsOneWidget,
    );
    expect(find.text('Recontar caixa'), findsOneWidget);

    fake.closeError = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Concluir fechamento'));
    await tester.pumpAndSettle();

    expect(fake.closeCalls, 2);
    expect(fake.session, isNull);
    expect(find.text('Abertura de caixa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 1.3 and keyboard inset keep cash operation reachable', (
    WidgetTester tester,
  ) async {
    for (final _ThemeCase themeCase in _themeCases) {
      final _FakeCaixaApiClient fake = _FakeCaixaApiClient(
        movements: <MovimentoCaixa>[
          _movement(
            id: 'mov-long',
            tipo: OperacaoCaixaTipo.sangria,
            natureza: 'saida',
            valor: 123456.78,
            referencia: 'MOVIMENTO-COM-REFERENCIA-MUITO-LONGA',
            observacao:
                'Descrição extensa para validar rolagem e escala de texto em operação de caixa mobile.',
          ),
        ],
      );

      await _pumpCash(
        tester,
        themeCase: themeCase,
        fake: fake,
        size: const Size(360, 780),
        textScale: 1.3,
      );

      expect(find.text('Operações de caixa'), findsWidgets);
      await _scrollUntilVisible(tester, 'Histórico');
      expect(find.text('Sangria'), findsOneWidget);
      await _openClosingSheet(tester);
      expect(find.text('Concluir fechamento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    final _FakeCaixaApiClient keyboardFake = _FakeCaixaApiClient();
    await _pumpCash(
      tester,
      themeCase: _darkTheme,
      fake: keyboardFake,
      size: const Size(360, 780),
      viewInsets: const EdgeInsets.only(bottom: 320),
    );
    await _openMovementSheet(tester);
    await _selectOperationType(tester, 'Suprimento');
    await _enterTextField(
      tester,
      'Observação',
      'Campo focado com teclado aberto deve permanecer acessível.',
    );
    await _scrollUntilVisible(
      tester,
      'Registrar movimentação',
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.widgetWithText(FilledButton, 'Registrar movimentação'),
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

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

const String _longCashName =
    'Caixa balcão principal com nome longo para validar leitura mobile';
const String _operatorName =
    'Operadora de caixa com nome profissional muito longo';

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

Future<void> _pumpCash(
  WidgetTester tester, {
  required _ThemeCase themeCase,
  required _FakeCaixaApiClient fake,
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
    child: OperacoesCaixaMobileScreen(
      caixaService: CaixaService(apiClient: fake),
      usuarioAtualLoader: () async {},
      collaboratorNameProvider: () => _operatorName,
      nowProvider: () => DateTime(2026, 8, 8, 12),
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

Future<void> _openMovementSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Nova movimentação'));
  await tester.pumpAndSettle();
  expect(find.text('Lançamento operacional'), findsOneWidget);
}

Future<void> _openClosingSheet(WidgetTester tester) async {
  await _tapText(tester, 'Preparar fechamento');
  await tester.pumpAndSettle();
  expect(find.text('Conferência dos valores'), findsOneWidget);
}

Future<void> _selectOperationType(WidgetTester tester, String label) async {
  await tester.tap(find.text('Tipo da operação').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _selectRelatedMethod(WidgetTester tester, String label) async {
  await tester.tap(find.text('Forma relacionada').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _openMovementDetail(WidgetTester tester, String label) async {
  await _tapText(tester, label);
  await tester.pumpAndSettle();
  expect(find.text('Detalhes do lançamento'), findsOneWidget);
}

Future<void> _enterTextField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final Finder field = find.widgetWithText(TextField, label).last;
  await Scrollable.ensureVisible(tester.element(field), alignment: 0.55);
  await tester.pump();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await _scrollUntilVisible(tester, text);
  await tester.tap(find.text(text).first);
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  String text, {
  Finder? scrollable,
}) async {
  final Finder finder = find.text(text);
  final Finder effectiveScrollable =
      scrollable ?? find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      260,
      scrollable: effectiveScrollable,
    );
  } else {
    await Scrollable.ensureVisible(
      tester.element(finder.first),
      alignment: 0.7,
    );
  }
  await tester.pump();
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

InformacoesBasicasCaixaResponse _cashInfo({
  List<CaixaOuGuiche>? cashDesks,
  List<TiposRecebimento>? paymentTypes,
}) {
  return InformacoesBasicasCaixaResponse(
    possuiSessaoAberta: true,
    tiposRecebimento: paymentTypes ?? _paymentTypes(),
    caixas: const <String>[],
    caixaOuGuiche: cashDesks ?? <CaixaOuGuiche>[_cashDesk()],
    formas: const <FormaMovimento>[],
  );
}

CaixaOuGuiche _cashDesk({String id = 'caixa-1', String nome = _longCashName}) {
  return CaixaOuGuiche(id: id, nome: nome);
}

List<TiposRecebimento> _paymentTypes() {
  return <TiposRecebimento>[
    _paymentType(codigo: 'tipo1', descricao: 'Dinheiro', ordem: 1),
    _paymentType(codigo: 'tipo2', descricao: 'Pix', ordem: 2),
    _paymentType(codigo: 'tipo3', descricao: 'Cartão crédito', ordem: 3),
    _paymentType(codigo: 'tipo4', descricao: 'Cartão débito', ordem: 4),
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

CaixaSessao _openSession({
  String id = 'sessao-caixa-1',
  String nomeCaixa = _longCashName,
  double valorAbertura = 100,
  String status = 'aberta',
}) {
  return CaixaSessao(
    idSessaoCaixa: id,
    nomeCaixa: nomeCaixa,
    idColaboradorAbertura: 'colab-caixa',
    dataHoraAbertura: '2026-08-08T08:00:00',
    valorAbertura: valorAbertura,
    status: status,
  );
}

ResumoCaixa _summary({
  double trocoInicial = 100,
  double totalEntradas = 320.50,
  double totalSaidas = 75.25,
  double saldoEsperado = 345.25,
  int quantidadeMovimentos = 2,
  double totalDinheiro = 180,
  double totalPix = 90.75,
  double totalCartaoCredito = 50,
  double totalCartaoDebito = 20.25,
}) {
  return ResumoCaixa(
    trocoInicial: trocoInicial,
    totalEntradas: totalEntradas,
    totalSaidas: totalSaidas,
    saldoEsperado: saldoEsperado,
    quantidadeMovimentos: quantidadeMovimentos,
    totalDinheiro: totalDinheiro,
    totalPix: totalPix,
    totalCartao: totalCartaoCredito + totalCartaoDebito,
    totalCartaoCredito: totalCartaoCredito,
    totalCartaoDebito: totalCartaoDebito,
    totalBoleto: 0,
    totalFiado: 0,
    totalCrediario: 0,
    totalConvenio: 0,
    totalVale: 0,
    totalOutros: 0,
  );
}

InformacoesCaixaComSomatorioResponse _somatorio({
  double tipo1 = 180,
  double tipo2 = 90.75,
  double tipo3 = 50,
  double tipo4 = 20.25,
  List<MovimentoCaixa>? movements,
}) {
  return InformacoesCaixaComSomatorioResponse(
    tipo1: tipo1,
    tipo2: tipo2,
    tipo3: tipo3,
    tipo4: tipo4,
    tipo5: 0,
    tipo6: 0,
    tipo7: 0,
    tipo8: 0,
    tipo9: 0,
    tipo10: 0,
    movimento: movements ?? <MovimentoCaixa>[],
  );
}

MovimentoCaixa _movement({
  required String id,
  required OperacaoCaixaTipo tipo,
  required String natureza,
  required double valor,
  String codigoTipo = 'tipo2',
  String descricaoTipo = 'Pix',
  String observacao = 'Movimentação operacional registrada no caixa',
  String referencia = 'MOV-001',
  String dataHora = '2026-08-08T09:30:00',
  String status = 'concluida',
}) {
  return MovimentoCaixa(
    idMovimento: id,
    idSessaoCaixa: 'sessao-caixa-1',
    tipoMovimento: tipo.codigoApi,
    natureza: natureza,
    codigoTipoRecebimento: codigoTipo,
    descricaoTipoRecebimento: descricaoTipo,
    valor: valor,
    descricao: descricaoTipo,
    observacao: observacao,
    referencia: referencia,
    idColaborador: 'colab-caixa',
    nomeColaborador: _operatorName,
    dataHoraMovimento: dataHora,
    status: status,
  );
}

String _naturezaParaTipo(OperacaoCaixaTipo tipo) {
  switch (tipo) {
    case OperacaoCaixaTipo.sangria:
    case OperacaoCaixaTipo.retiradaDespesa:
    case OperacaoCaixaTipo.pagamentoAvulso:
      return 'saida';
    case OperacaoCaixaTipo.aberturaCaixa:
    case OperacaoCaixaTipo.fechamentoCaixa:
    case OperacaoCaixaTipo.suprimento:
    case OperacaoCaixaTipo.ajuste:
    case OperacaoCaixaTipo.estorno:
    case OperacaoCaixaTipo.recebimentoAvulso:
      return 'entrada';
  }
}

class _FakeCaixaApiClient implements CaixaApiClient {
  _FakeCaixaApiClient({
    this.infoCompleter,
    this.infoError,
    CaixaSessao? session,
    bool startClosed = false,
    List<MovimentoCaixa>? movements,
    ResumoCaixa? resumo,
    InformacoesCaixaComSomatorioResponse? somatorio,
    this.movementsCompleter,
    this.movementsError,
    this.registerCompleter,
    this.registerError,
    this.openCompleter,
    this.openError,
    this.closeCompleter,
    this.closeError,
  }) : session = startClosed ? null : (session ?? _openSession()),
       movements = movements ?? <MovimentoCaixa>[],
       resumo = resumo ?? _summary(),
       somatorio = somatorio ?? _somatorio(movements: movements);

  Completer<InformacoesBasicasCaixaResponse>? infoCompleter;
  Object? infoError;
  CaixaSessao? session = _openSession();
  List<MovimentoCaixa> movements;
  ResumoCaixa resumo;
  InformacoesCaixaComSomatorioResponse somatorio;
  Completer<List<MovimentoCaixa>>? movementsCompleter;
  Object? movementsError;
  Completer<void>? registerCompleter;
  Object? registerError;
  Completer<void>? openCompleter;
  Object? openError;
  Completer<void>? closeCompleter;
  Object? closeError;

  int informacoesBasicasCalls = 0;
  int sessaoAtualCalls = 0;
  int openCalls = 0;
  int registerCalls = 0;
  int movimentosCalls = 0;
  int somatorioCalls = 0;
  int resumoCalls = 0;
  int closeCalls = 0;
  int cancelCalls = 0;

  AbrirCaixaRequest? lastOpenRequest;
  RegistrarMovimentoRequest? lastRegisterRequest;
  FecharCaixaRequest? lastCloseRequest;
  String? lastCancelId;

  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() {
    informacoesBasicasCalls += 1;
    final Object? error = infoError;
    if (error != null) throw error;
    final Completer<InformacoesBasicasCaixaResponse>? completer = infoCompleter;
    if (completer != null) return completer.future;
    return Future<InformacoesBasicasCaixaResponse>.value(_cashInfo());
  }

  @override
  Future<CaixaSessao?> getSessaoAtual() {
    sessaoAtualCalls += 1;
    return Future<CaixaSessao?>.value(session);
  }

  @override
  Future<void> abrirCaixa(AbrirCaixaRequest request) async {
    openCalls += 1;
    lastOpenRequest = request;
    final Object? error = openError;
    if (error != null) throw error;
    final Completer<void>? completer = openCompleter;
    if (completer != null) await completer.future;
    session = _openSession(
      nomeCaixa: request.nomeCaixa,
      valorAbertura: request.valorAbertura,
    );
  }

  @override
  Future<void> registrarMovimento(RegistrarMovimentoRequest request) async {
    registerCalls += 1;
    lastRegisterRequest = request;
    final Object? error = registerError;
    if (error != null) throw error;
    final Completer<void>? completer = registerCompleter;
    if (completer != null) await completer.future;
    final String natureza = _naturezaParaTipo(request.tipoMovimento);
    final String descricaoTipo =
        _paymentTypes()
            .firstWhere(
              (TiposRecebimento item) =>
                  item.codigoTipo == request.codigoTipoRecebimento,
              orElse:
                  () => _paymentType(
                    codigo: request.codigoTipoRecebimento,
                    descricao: request.codigoTipoRecebimento,
                    ordem: 99,
                  ),
            )
            .descricaoExibicao;
    movements = <MovimentoCaixa>[
      _movement(
        id: 'mov-${registerCalls + 10}',
        tipo: request.tipoMovimento,
        natureza: natureza,
        valor: request.valor,
        codigoTipo: request.codigoTipoRecebimento,
        descricaoTipo: descricaoTipo,
        observacao: request.observacao,
        referencia: request.referencia,
      ),
      ...movements,
    ];
    final bool entrada = natureza == 'entrada';
    resumo = _summary(
      totalEntradas: resumo.totalEntradas + (entrada ? request.valor : 0),
      totalSaidas: resumo.totalSaidas + (entrada ? 0 : request.valor),
      saldoEsperado:
          resumo.saldoEsperado + (entrada ? request.valor : -request.valor),
      quantidadeMovimentos: resumo.quantidadeMovimentos + 1,
    );
    somatorio = _somatorio(movements: movements);
  }

  @override
  Future<List<MovimentoCaixa>> getMovimentos(String idSessaoCaixa) {
    movimentosCalls += 1;
    final Object? error = movementsError;
    if (error != null) throw error;
    final Completer<List<MovimentoCaixa>>? completer = movementsCompleter;
    if (completer != null) return completer.future;
    return Future<List<MovimentoCaixa>>.value(movements);
  }

  @override
  Future<InformacoesCaixaComSomatorioResponse>
  getResumoDeMovimentosComSomatorio(String idSessaoCaixa) {
    somatorioCalls += 1;
    return Future<InformacoesCaixaComSomatorioResponse>.value(
      _somatorio(movements: movements),
    );
  }

  @override
  Future<ResumoCaixa> getResumo(String idSessaoCaixa) {
    resumoCalls += 1;
    return Future<ResumoCaixa>.value(resumo);
  }

  @override
  Future<void> cancelarMovimento(String id) {
    cancelCalls += 1;
    lastCancelId = id;
    movements = movements
        .map(
          (MovimentoCaixa item) =>
              item.idMovimento == id
                  ? item.copyWith(status: 'cancelada')
                  : item,
        )
        .toList(growable: false);
    return Future<void>.value();
  }

  @override
  Future<void> fecharCaixa(FecharCaixaRequest request) async {
    closeCalls += 1;
    lastCloseRequest = request;
    final Object? error = closeError;
    if (error != null) throw error;
    final Completer<void>? completer = closeCompleter;
    if (completer != null) await completer.future;
    session = null;
    movements = <MovimentoCaixa>[];
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
