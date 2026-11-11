import 'package:sixpos/providers/management_overview_provider.dart';
import 'package:sixpos/presentation/screens/financeiro_resumo_mobile_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/agenda_financeira_baixa_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_lancamento_mobile_create_screen.dart';

class _RegionalApi implements RegionalizacaoApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected call');
}

class _Caixa implements CaixaApiClient {
  @override
  Future<InformacoesBasicasCaixaResponse>
  getInformacoesBasicasDoCaixa() async => InformacoesBasicasCaixaResponse(
    possuiSessaoAberta: false,
    tiposRecebimento: [
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
    ],
    caixas: [],
    caixaOuGuiche: [],
    formas: [],
  );
  @override
  Future<CaixaSessao?> getSessaoAtual() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends AgendaFinanceiraLancamentoService {
  @override
  AgendaFinanceiraLancamentoService paraEspaco(String espaco) =>
      _Service()..espacoFinanceiro = espaco;

  Map<String, dynamic> detail = {
    'idLancamento': 'entry',
    'tipo': 'PAGAR',
    'status': 'PENDENTE',
    'descricao': 'Conta de teste',
    'valorOriginal': 100,
    'valorPagoRecebido': 0,
    'valorAberto': 100,
    'dataVencimento': '2026-09-10',
    'dataCompetencia': '2026-09-01',
    'dataOperacao': '2026-09-01',
    'dataPrevisaoPagamento': '2026-10-12',
    'formaPagamento': 'tipo1',
  };
  final saved = <LancamentoAgendaFinanceiraRequest>[];
  String? consultedSpace;
  AgendaFinanceiraConsultaRequest? lastQuery;
  Map<String, dynamic> agenda = {};
  bool failSave = false;
  bool failDetail = false;
  @override
  Future<Map<String, dynamic>> buscarDetalheLancamento(String id) async {
    if (failDetail) throw StateError('offline');
    return detail;
  }

  @override
  Future<LancamentoAgendaFinanceiraResponse> cadastrarLancamento(
    LancamentoAgendaFinanceiraRequest request,
  ) async {
    if (failSave) throw StateError('offline');
    saved.add(request);
    return LancamentoAgendaFinanceiraResponse(id: 'entry', status: 'PENDENTE');
  }

  @override
  Future<LancamentoAgendaFinanceiraResponse> editarLancamento(
    String id,
    LancamentoAgendaFinanceiraRequest request, {
    String escopo = 'ESTE',
  }) => cadastrarLancamento(request);
  @override
  Future<Map<String, dynamic>> consultarLancamentos(
    AgendaFinanceiraConsultaRequest request,
  ) async {
    consultedSpace = espacoFinanceiro;
    lastQuery = request;
    return agenda;
  }

  @override
  Future<Map<String, dynamic>> consultarValoresConfirmados(
    AgendaFinanceiraConsultaRequest request,
  ) async => {'itens': []};
  @override
  Future<List<CentroCustoModel>> listarCentrosCusto() async => [];
}

Widget _app(
  Widget child, {
  String language = 'pt',
  Brightness brightness = Brightness.light,
}) => ChangeNotifierProvider(
  create: (_) => LocaleSettingsProvider(
    regionalizacaoService: RegionalizacaoService(apiClient: _RegionalApi()),
  ),
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    locale: Locale(language),
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(brightness: brightness),
    home: child,
  ),
);

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final natureza in AgendaContasMobile.values) {
    testWidgets(
      'focused accounts ${natureza.name} isolate filters and show open balances',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final preference = jsonEncode({
          'agendaFinanceiraFiltrosMobile': {
            'espacoFinanceiro': 'PESSOAL',
            'tipo': 'PAGAR',
            'somenteImpostoRenda': true,
            'visaoSelecionada': 'FLUXO_PREVISTO',
          },
        });
        SharedPreferences.setMockInitialValues({
          'sixapp.preferenciasIndividuaisDoUsuario': preference,
        });
        final receber = natureza == AgendaContasMobile.receber;
        final tipo = receber ? 'RECEBER' : 'PAGAR';
        final service = _Service()
          ..agenda = {
            'gruposAgenda': [
              {
                'codigo': 'ATRASADOS',
                'itens': [
                  {
                    'idLancamento': 'open',
                    'tipo': tipo,
                    'descricao': 'Conta pendente',
                    'status': 'VENCIDO',
                    'valorOriginal': 120,
                    'valorRestante': 80,
                    'valorConfirmado': 40,
                    'dataVencimento': '2020-01-01',
                    'acoesDisponiveis': ['DETALHAR'],
                  },
                  {
                    'idLancamento': 'paid',
                    'tipo': tipo,
                    'descricao': 'Conta quitada',
                    'status': receber ? 'RECEBIDO' : 'PAGO',
                    'valorOriginal': 50,
                    'valorRestante': 0,
                    'valorConfirmado': 50,
                    'dataVencimento': '2020-01-02',
                    'acoesDisponiveis': ['DETALHAR'],
                  },
                  {
                    'idLancamento': 'other',
                    'tipo': receber ? 'PAGAR' : 'RECEBER',
                    'descricao': 'Outro tipo',
                    'status': 'PENDENTE',
                    'valor': 999,
                  },
                ],
              },
            ],
          };
        await tester.pumpWidget(
          _app(
            AgendaFinanceiraMobileScreen(
              contas: natureza,
              lancamentoService: service,
              caixaApiClient: _Caixa(),
              enablePeriodHint: false,
            ),
            brightness: Brightness.dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(service.lastQuery!.filtros.tipo, tipo);
        expect(service.lastQuery!.filtros.somenteImpostoRenda, isFalse);
        expect(service.consultedSpace, 'PESSOAL');
        expect(find.text('Conta pendente'), findsOneWidget);
        expect(find.text('Conta quitada'), findsNothing);
        expect(find.text('Outro tipo'), findsNothing);
        expect(find.text('Fluxo previsto'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('contas-mobile-filter-2')));
        await tester.pumpAndSettle();
        expect(find.text('Conta quitada'), findsOneWidget);
        expect(find.text('Conta pendente'), findsNothing);
        await tester.enterText(
          find.byKey(const ValueKey('contas-mobile-search')),
          'inexistente',
        );
        await tester.pumpAndSettle();
        expect(find.text('Conta quitada'), findsNothing);
        expect(
          (await SharedPreferences.getInstance()).getString(
            'sixapp.preferenciasIndividuaisDoUsuario',
          ),
          preference,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'financial overview shows zeros, dark surfaces and forwards selected scope and dates',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _Service();
      final provider = ManagementOverviewProvider(
        agendaFinanceiraService: service,
      );
      AgendaFinanceiraMobileScreen? destination;
      await tester.pumpWidget(
        _app(
          FinanceiroResumoMobileScreen(
            overviewProvider: provider,
            onNavigate: (_, page) =>
                destination = page as AgendaFinanceiraMobileScreen,
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('--'), findsNothing);
      expect(
        find.text('Nenhuma conta em aberto neste período.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Pessoal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contas a receber'));
      await tester.pumpAndSettle();
      expect(destination!.contas, AgendaContasMobile.receber);
      expect(destination!.espacoInicial, 'PESSOAL');
      expect(destination!.periodoInicial, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('journey preserves details when navigating back', (tester) async {
    await tester.pumpWidget(
      _app(
        AgendaFinanceiraLancamentoMobileCreateScreen(
          service: _Service(),
          caixaApiClient: _Caixa(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Etapa 1 de 4'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa 2 de 4'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Escola',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escola'), findsOneWidget);
  });
  testWidgets('restores mobile space and filters before consulting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sixapp.preferenciasIndividuaisDoUsuario': jsonEncode({
        'agendaFinanceiraFiltrosMobile': {
          'espacoFinanceiro': 'PESSOAL',
          'somenteImpostoRenda': true,
          'mostrarCancelados': true,
          'visaoSelecionada': 'FLUXO_PREVISTO',
        },
      }),
    });
    final service = _Service();
    await tester.pumpWidget(
      _app(
        AgendaFinanceiraMobileScreen(
          lancamentoService: service,
          caixaApiClient: _Caixa(),
          enablePeriodHint: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.consultedSpace, 'PESSOAL');
    expect(service.lastQuery!.filtros.somenteImpostoRenda, isTrue);
    await tester.tap(find.byKey(const ValueKey('agenda-mobile-open-filters')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(
            find.widgetWithText(FilterChip, 'Mostrar cancelados'),
          )
          .selected,
      isTrue,
    );
  });
  testWidgets(
    'surcharge and classification save atomically and prevent double submit',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<void>();
      final saved = <SixMobileRecebimentoResultado>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SixMobileRecebimentoBottomSheet(
              titulo: 'Baixa',
              descricao: 'Escola',
              valorAberto: 100,
              tipoInicial: SixMobileRecebimentoTipo.total,
              caixaApiClient: _Caixa(),
              agendaService: _Service(),
              dadosBaixa: const AgendaBaixaDados(
                valorAberto: 100,
                valorOriginal: 100,
                contato: 'Laura',
                contatoEditavel: true,
              ),
              onConfirm: (result) {
                saved.add(result);
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('agenda-surcharge')),
        '10,50',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Cliente'),
        'Laura Silva',
      );
      final confirm = find.widgetWithText(FilledButton, 'Receber total');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();
      expect(saved.single.valor, 110.50);
      expect(saved.single.acrescimo, 10.50);
      expect(saved.single.classificacao!.nomeContato, 'Laura Silva');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Laura Silva'), findsOneWidget);
      expect(saved.length, 1);
    },
  );
  testWidgets(
    'partial adjustment retains cash amount and rejects overpayment',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final saved = <SixMobileRecebimentoResultado>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SixMobileRecebimentoBottomSheet(
              titulo: 'Baixa',
              descricao: 'Escola',
              valorAberto: 100,
              tipoInicial: SixMobileRecebimentoTipo.parcial,
              caixaApiClient: _Caixa(),
              agendaService: _Service(),
              dadosBaixa: const AgendaBaixaDados(
                valorAberto: 100,
                valorOriginal: 100,
              ),
              onConfirm: (result) async {
                saved.add(result);
                throw StateError('retain');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Valor da forma 1'),
        '40',
      );
      await tester.enterText(
        find.byKey(const ValueKey('agenda-discount')),
        '10',
      );
      final confirm = find.widgetWithText(FilledButton, 'Receber parcial');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(saved.single.valor, 40);
      expect(saved.single.desconto, 10);
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Valor da forma 1'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Valor da forma 1'),
        '100',
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(saved.length, 1);
    },
  );
  for (final pagamento in [true, false]) {
    testWidgets('adjusted total and retry retained: payment=$pagamento', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final saved = <SixMobileRecebimentoResultado>[];
      bool fail = true;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SixMobileRecebimentoBottomSheet(
              titulo: 'Baixa',
              descricao: 'Escola',
              valorAberto: 1680,
              pagamento: pagamento,
              tipoInicial: SixMobileRecebimentoTipo.total,
              caixaApiClient: _Caixa(),
              agendaService: _Service(),
              dadosBaixa: const AgendaBaixaDados(
                valorAberto: 1680,
                valorOriginal: 1680,
                categoria: 'Escola',
                contato: 'Laura',
                contatoEditavel: true,
              ),
              onConfirm: (result) async {
                saved.add(result);
                if (fail) throw StateError('offline');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('agenda-discount')),
        '327,43',
      );
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(
        FilledButton,
        pagamento ? 'Pagar total' : 'Receber total',
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(saved.single.valor, closeTo(1352.57, .001));
      expect(saved.single.desconto, 327.43);
      expect(find.textContaining('Não foi possível confirmar'), findsOneWidget);
      expect(find.byType(SixMobileRecebimentoBottomSheet), findsOneWidget);
      fail = false;
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(saved.length, 2);
      expect(saved.last.valor, 1352.57);
    });
  }
}
