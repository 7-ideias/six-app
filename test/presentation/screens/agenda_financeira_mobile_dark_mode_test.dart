import 'dart:async';

import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_lancamento_mobile_edit_screen.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('editing payment name preserves selection in the mobile filter', (
    tester,
  ) async {
    final api = _EditableCaixaApiClient();
    await _pumpAgenda(tester, service: _FakeAgendaService(), caixa: api);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Pix'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pix'));
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Editar nome').last);
    await tester.tap(find.byTooltip('Editar nome').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Pix da loja');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(api.saved!.codigoTipo, 'tipo2');
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pix da loja'))
          .selected,
      isTrue,
    );
    expect(find.widgetWithText(ChoiceChip, 'Pix'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment edit is hidden without backend permission', (
    tester,
  ) async {
    await _pumpAgenda(tester, service: _FakeAgendaService());
    await tester.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Editar nome'), findsNothing);
  });

  testWidgets('mobile omite contato nao informado e destaca entrada e status', (
    WidgetTester tester,
  ) async {
    final vendaSemContato = <String, dynamic>{
      ..._agendaItem('sem-contato', 'RECEBER', 'Venda', 'VENCIDO', 150),
      'nomeContato': 'Não informado',
      'formaPagamento': 'BUFUNFA',
      'valorConfirmado': 0,
      'valorRestante': 150,
    };
    await _pumpAgenda(
      tester,
      brightness: Brightness.light,
      service: _FakeAgendaService(agendaPayload: <String, dynamic>{
        'gruposAgenda': <Map<String, dynamic>>[
          <String, dynamic>{
            'titulo': 'A receber',
            'itens': <Map<String, dynamic>>[vendaSemContato],
          },
        ],
      }),
    );
    expect(find.text('Venda'), findsOneWidget);
    expect(find.textContaining('Não informado'), findsNothing);
    expect(find.textContaining('BUFUNFA'), findsNothing);
    final card = find.ancestor(of: find.text('Venda'), matching: find.byType(InkWell)).first;
    final seta = find.descendant(
      of: card, matching: find.byIcon(Icons.south_west_rounded),
    );
    expect(tester.widget<Icon>(seta).color, const Color(0xFF047857));

    await tester.tap(find.text('Venda'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Ações'), findsOneWidget);
    expect(find.text('Não informado'), findsNothing);
    expect(find.text('BUFUNFA'), findsNothing);
  });

  testWidgets('agenda renders financial states with dark themed surfaces', (
    WidgetTester tester,
  ) async {
    await _pumpAgenda(
      tester,
      service: _FakeAgendaService(agendaPayload: _agendaPayload),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Conta pendente'), findsOneWidget);
    expect(find.text('Conta vencida'), findsOneWidget);
    expect(find.text('Recebimento confirmado'), findsOneWidget);
    expect(find.text('Pagamento realizado'), findsOneWidget);
    expect(find.textContaining('Pendente'), findsWidgets);
    expect(find.textContaining('Vencido'), findsWidgets);
    expect(find.textContaining('Recebido'), findsWidgets);
    expect(find.textContaining('Pago'), findsWidgets);
    expect(find.byIcon(Icons.south_west_rounded), findsWidgets);
    expect(find.byIcon(Icons.north_east_rounded), findsWidgets);
    expect(find.byIcon(Icons.flag_outlined), findsWidgets);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Conta vencida'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );

    await tester.ensureVisible(find.text('Conta pendente'));
    final Finder lancamentoCompacto =
        find
            .ancestor(
              of: find.text('Conta pendente'),
              matching: find.byType(InkWell),
            )
            .first;
    expect(tester.getSize(lancamentoCompacto).height, lessThan(90));
    await tester.tap(find.text('Conta pendente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Ações'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Liquidar'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Registrar parcial'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Detalhes'), findsOneWidget);
    expect(find.byIcon(Icons.pending_actions_outlined), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Ações'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('agenda filters and bottom sheet keep light mode tokens', (
    WidgetTester tester,
  ) async {
    await _pumpAgenda(
      tester,
      brightness: Brightness.light,
      service: _FakeAgendaService(agendaPayload: _agendaPayload),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Filtrar agenda'), findsOneWidget);
    expect(find.text('Período'), findsOneWidget);
    await tester.tap(find.text('Intervalo personalizado'));
    await tester.pump();
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Fim'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Filtrar agenda'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
  });

  testWidgets('agenda empty state keeps dark themed surface', (
    WidgetTester tester,
  ) async {
    await _pumpAgenda(tester, service: _FakeAgendaService());

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Nenhum lançamento encontrado'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhum lançamento encontrado'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('agenda exposes loading state without light surfaces', (
    WidgetTester tester,
  ) async {
    final Completer<Map<String, dynamic>> completer =
        Completer<Map<String, dynamic>>();

    await _pumpAgenda(
      tester,
      service: _FakeAgendaService(agendaCompleter: completer),
      settleInitialLoad: false,
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsWidgets);
    completer.complete(_agendaPayload);
    await tester.pump(const Duration(milliseconds: 1800));
  });

  testWidgets('agenda exposes themed error state in light mode', (
    WidgetTester tester,
  ) async {
    await _pumpAgenda(
      tester,
      brightness: Brightness.light,
      service: _FakeAgendaService(throwOnConsult: true),
      settleInitialLoad: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Agenda indisponível'), findsOneWidget);
    expect(
      find.text('Não foi possível consultar a agenda financeira.'),
      findsWidgets,
    );
    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
  });

  testWidgets('agenda edit screen and date selector use dark mode tokens', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(
      tester,
      AgendaFinanceiraLancamentoMobileEditScreen(
        lancamento: _editItem,
        service: _FakeAgendaService(detailPayload: _detailPayload),
        caixaApiClient: _FakeCaixaApiClient(),
      ),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Editar lançamento'), findsWidgets);

    final InputDecorator firstField = tester.widget<InputDecorator>(
      find
          .descendant(
            of: find.byType(TextFormField).first,
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(
      firstField.decoration.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );

    await tester.scrollUntilVisible(
      find.text('Vencimento original'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Vencimento original'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Vencimento original'), findsWidgets);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Vencimento original').last,
        SixMobileColorScheme.dark.background,
      ),
      isTrue,
    );
  });
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpAgenda(
  WidgetTester tester, {
  required _FakeAgendaService service,
  CaixaApiClient? caixa,
  Brightness brightness = Brightness.dark,
  bool settleInitialLoad = true,
}) {
  return _pumpScreen(
    tester,
    AgendaFinanceiraMobileScreen(
      lancamentoService: service,
      acoesFinanceiras: _FakeAgendaActions(),
      caixaApiClient: caixa ?? _FakeCaixaApiClient(),
      enablePeriodHint: false,
    ),
    brightness: brightness,
    settleInitialLoad: settleInitialLoad,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  bool settleInitialLoad = true,
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
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: _testSupportedLocales,
      localizationsDelegates: _testLocalizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: ChangeNotifierProvider(
        create:
            (_) => LocaleSettingsProvider(
              regionalizacaoService: RegionalizacaoService(
                apiClient: _RegionalApi(),
              ),
            ),
        child: child,
      ),
    ),
  );
  await tester.pump();
  if (settleInitialLoad) {
    await tester.pump(const Duration(milliseconds: 1800));
  }
}

class _FakeAgendaService extends AgendaFinanceiraLancamentoService {
  _FakeAgendaService({
    this.agendaPayload = const <String, dynamic>{},
    this.detailPayload = const <String, dynamic>{},
    this.agendaCompleter,
    this.throwOnConsult = false,
  }) : super();

  final Map<String, dynamic> agendaPayload;
  final Map<String, dynamic> detailPayload;
  final Completer<Map<String, dynamic>>? agendaCompleter;
  final bool throwOnConsult;

  @override
  Future<Map<String, dynamic>> consultarLancamentos(
    AgendaFinanceiraConsultaRequest request,
  ) {
    if (throwOnConsult) throw StateError('offline');
    return agendaCompleter?.future ??
        Future<Map<String, dynamic>>.value(agendaPayload);
  }

  @override
  Future<Map<String, dynamic>> consultarValoresConfirmados(
    AgendaFinanceiraConsultaRequest request,
  ) {
    return Future<Map<String, dynamic>>.value(const <String, dynamic>{
      'itens': <Object>[],
    });
  }

  @override
  Future<Map<String, dynamic>> buscarDetalheLancamento(String idLancamento) {
    return Future<Map<String, dynamic>>.value(detailPayload);
  }

  @override
  Future<LancamentoAgendaFinanceiraResponse> editarLancamento(
    String idLancamento,
    LancamentoAgendaFinanceiraRequest request, {
    String escopo = 'ESTE',
  }) {
    return Future<LancamentoAgendaFinanceiraResponse>.value(
      LancamentoAgendaFinanceiraResponse(id: idLancamento, status: 'OK'),
    );
  }
}

class _FakeAgendaActions extends AgendaFinanceiraAcoesFinanceiras {
  _FakeAgendaActions() : super();

  @override
  Future<LancamentoAgendaFinanceiraResponse> executarTotal({
    required String idLancamento,
    required AgendaFinanceiraLiquidacaoRequest request,
  }) {
    return Future<LancamentoAgendaFinanceiraResponse>.value(
      LancamentoAgendaFinanceiraResponse(id: idLancamento, status: 'OK'),
    );
  }

  @override
  Future<LancamentoAgendaFinanceiraResponse> executarAbatimento({
    required String idLancamento,
    required AgendaFinanceiraParcialRequest request,
  }) {
    return Future<LancamentoAgendaFinanceiraResponse>.value(
      LancamentoAgendaFinanceiraResponse(id: idLancamento, status: 'OK'),
    );
  }
}

class _FakeCaixaApiClient implements CaixaApiClient {
  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: false,
      tiposRecebimento: <TiposRecebimento>[
        TiposRecebimento(
          codigoTipo: 'tipo1',
          descricaoExibicao: 'Dinheiro',
          naturezaRecebimento: 'imediato',
          aceitaParcelamento: false,
          ativo: true,
          exigeCliente: false,
          ordemExibicao: 1,
          corHex: '',
          icone: '',
        ),
        TiposRecebimento(
          codigoTipo: 'tipo2',
          descricaoExibicao: 'Pix',
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
  Future<CaixaSessao?> getSessaoAtual() async => null;

  @override
  Future<List<CaixaSessao>> getSessoesAbertas() async => const <CaixaSessao>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

final Map<String, dynamic> _agendaPayload = <String, dynamic>{
  'gruposAgenda': <Map<String, dynamic>>[
    <String, dynamic>{
      'titulo': 'Hoje',
      'itens': <Map<String, dynamic>>[
        _agendaItem('1', 'RECEBER', 'Conta pendente', 'PENDENTE', 120),
        _agendaItem('2', 'PAGAR', 'Conta vencida', 'VENCIDO', 80),
        _agendaItem('3', 'RECEBER', 'Recebimento confirmado', 'RECEBIDO', 55),
        _agendaItem('4', 'PAGAR', 'Pagamento realizado', 'PAGO', 40),
      ],
    },
  ],
};

Map<String, dynamic> _agendaItem(
  String id,
  String tipo,
  String descricao,
  String status,
  double valor,
) {
  return <String, dynamic>{
    'idLancamento': id,
    'uuidOperacaoApp': id,
    'tipo': tipo,
    'descricao': descricao,
    'nomeContato': tipo == 'RECEBER' ? 'Cliente Six' : 'Fornecedor Six',
    'valorOriginal': valor,
    'valorConfirmado': status == 'PAGO' || status == 'RECEBIDO' ? valor : 0,
    'valorRestante': status == 'PAGO' || status == 'RECEBIDO' ? 0 : valor,
    'dataVencimento': '2026-08-08',
    'status': status,
    'formaPagamento': 'PIX',
    'codigoTipoRecebimento': 'tipo2',
    'categoria': 'Operacional',
    'responsavel': 'Mobile',
    'acoesDisponiveis':
        status == 'PENDENTE' || status == 'VENCIDO'
            ? <String>[
              'EDITAR',
              'REGISTRAR_RECEBIMENTO',
              'REGISTRAR_PARCIAL',
              'DETALHES',
            ]
            : <String>['DETALHES', 'EDITAR'],
  };
}

final Map<String, dynamic> _editItem = <String, dynamic>{
  'id': '1',
  'uuidOperacaoApp': '1',
  'tipo': 'receber',
  'descricao': 'Conta pendente',
  'contato': 'Cliente Six',
  'valorOriginal': 120,
  'valorConfirmado': 0,
  'valorRestante': 120,
  'vencimento': '08/08/2026',
  'status': 'Pendente',
  'formaPagamento': 'Pix',
  'codigoTipoRecebimento': 'tipo2',
};

final Map<String, dynamic> _detailPayload = <String, dynamic>{
  'idLancamento': '1',
  'tipo': 'RECEBER',
  'descricao': 'Conta pendente',
  'valorOriginal': 120,
  'valorPagoRecebido': 0,
  'valorAberto': 120,
  'status': 'PENDENTE',
  'dataCompetencia': '2026-08-08',
  'dataVencimento': '2026-08-08',
  'dataOperacao': '2026-08-08',
  'formaPagamento': 'tipo2',
  'contato': <String, dynamic>{
    'id': 'c1',
    'nome': 'Cliente Six',
    'tipo': 'CLIENTE',
  },
  'categoria': <String, dynamic>{'nome': 'Operacional'},
  'empresa': <String, dynamic>{'nome': 'Six App'},
  'origem': <String, dynamic>{'tipo': 'VENDA'},
  'responsavel': <String, dynamic>{'nome': 'Mobile'},
  'payloadOriginalJson': <String, dynamic>{},
};

class _RegionalApi implements RegionalizacaoApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected call');
}

class _EditableCaixaApiClient extends _FakeCaixaApiClient {
  TiposRecebimento? saved;

  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    final original = await super.getInformacoesBasicasDoCaixa();
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: false,
      podeEditarTiposRecebimento: true,
      tiposRecebimento: original.tiposRecebimento,
      caixas: [],
      caixaOuGuiche: [],
      formas: [],
    );
  }

  @override
  Future<List<TiposRecebimento>> listarTiposRecebimentoConfiguraveis() async =>
      (await getInformacoesBasicasDoCaixa()).tiposRecebimento;

  @override
  Future<TiposRecebimento> atualizarTipoRecebimentoConfiguravel({
    required String codigoTipo,
    required TiposRecebimento request,
  }) async {
    saved = request;
    return request;
  }
}
