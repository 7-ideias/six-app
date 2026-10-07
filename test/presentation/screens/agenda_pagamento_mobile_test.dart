import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';
import 'package:sixpos/presentation/components/web/conta_financeira_web_field.dart';
import 'package:sixpos/presentation/components/mobile/conta_financeira_mobile_field.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/recebimento_forma_input.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/components/date_selector_mobile_bottom_sheet.dart';
import 'package:sixpos/presentation/components/mobile/agenda_pagamento_mobile_fields.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_lancamento_mobile_create_screen.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_lancamento_mobile_edit_screen.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

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
  ) async => {};
  @override
  Future<Map<String, dynamic>> consultarValoresConfirmados(
    AgendaFinanceiraConsultaRequest request,
  ) async => {'itens': []};
  @override
  Future<List<CentroCustoModel>> listarCentrosCusto() async => [];
}

class _Actions extends AgendaFinanceiraAcoesFinanceiras {
  final totals = <AgendaFinanceiraLiquidacaoRequest>[];
  final partials = <AgendaFinanceiraParcialRequest>[];
  @override
  Future<LancamentoAgendaFinanceiraResponse> executarTotal({
    required String idLancamento,
    required AgendaFinanceiraLiquidacaoRequest request,
  }) async {
    expect(idLancamento, 'entry');
    totals.add(request);
    return LancamentoAgendaFinanceiraResponse(id: idLancamento, status: 'PAGO');
  }

  @override
  Future<LancamentoAgendaFinanceiraResponse> executarAbatimento({
    required String idLancamento,
    required AgendaFinanceiraParcialRequest request,
  }) async {
    partials.add(request);
    return LancamentoAgendaFinanceiraResponse(
      id: idLancamento,
      status: 'PARCIAL',
    );
  }
}

Widget _app(
  Widget child, {
  String language = 'pt',
  Brightness brightness = Brightness.light,
}) => ChangeNotifierProvider(
  create:
      (_) => LocaleSettingsProvider(
        regionalizacaoService: RegionalizacaoService(apiClient: _RegionalApi()),
      ),
  child: MaterialApp(
    locale: Locale(language),
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(brightness: brightness),
    home: child,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String language = 'pt',
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(child, language: language, brightness: brightness),
  );
  await tester.pumpAndSettle();
  if (child is AgendaFinanceiraLancamentoMobileEditScreen) {
    await tester.scrollUntilVisible(
      find.byType(AgendaPagamentoMobileFields),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _key(String key) => find.byKey(ValueKey(key));
AgendaPagamentoMobileFields _fields(WidgetTester tester) =>
    tester.widget(find.byType(AgendaPagamentoMobileFields));

Future<void> _date(WidgetTester tester, String key, DateTime date) async {
  await _tap(tester, _key(key));
  // Return the same typed result as the calendar. Calendar interaction has its own test below.
  Navigator.of(
    tester.element(find.byType(DateSelectorMobileBottomSheet)),
  ).pop(date);
  await tester.pumpAndSettle();
}

Future<void> _fillCreate(WidgetTester tester) async {
  final description = find.widgetWithText(TextFormField, 'Descrição');
  await tester.ensureVisible(description);
  await tester.enterText(description, 'Conta de teste');
  final amount = find.widgetWithText(TextFormField, 'Valor total');
  if (amount.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      amount,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(amount);
  await tester.enterText(amount, '100');
  await tester.pumpAndSettle();
}

const _item = <String, dynamic>{
  'id': 'entry',
  'tipo': 'pagar',
  'status': 'Pendente',
  'valor': 100,
  'descricao': 'Conta de teste',
  'formaPagamento': 'tipo1',
  'dataPrevisaoPagamento': '2026-11-20',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final web in [true, false]) {
    testWidgets(
      '$web: novo permite escolher espaço sem alterar a Agenda ao cancelar',
      (tester) async {
        final service = _Service();
        await _pump(
          tester,
          Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    child: const Text('Abrir formulário'),
                    onPressed: () {
                      if (web) {
                        showSubPainelLancamentoAgendaFinanceiraWeb(
                          context,
                          service: service,
                          empresaSelecionada: 'Empresa',
                          empresas: const ['Empresa'],
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    AgendaFinanceiraLancamentoMobileCreateScreen(
                                      service: service,
                                      caixaApiClient: _Caixa(),
                                    ),
                          ),
                        );
                      }
                    },
                  ),
                ),
          ),
        );
        if (web) {
          tester.view.physicalSize = const Size(1200, 1000);
          await tester.pumpAndSettle();
        }
        await _tap(tester, find.text('Abrir formulário'));
        final selector = find.byKey(const ValueKey('lancamento-espaco'));
        if (selector.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            selector,
            250,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(selector);
        await tester.pumpAndSettle();
        if (web) {
          tester
              .widget<ContaFinanceiraWebField>(
                find.byType(ContaFinanceiraWebField),
              )
              .onChanged('conta-empresa');
        } else {
          tester
              .widget<ContaFinanceiraMobileField>(
                find.byType(ContaFinanceiraMobileField),
              )
              .onChanged('conta-empresa');
        }
        await tester.pumpAndSettle();
        final widget = tester.widget<SegmentedButton<String>>(selector);
        final pessoal =
            widget.segments.firstWhere((s) => s.value == 'PESSOAL').label
                as Text;
        await _tap(
          tester,
          find.descendant(of: selector, matching: find.text(pessoal.data!)),
        );
        expect(tester.widget<SegmentedButton<String>>(selector).selected, {
          'PESSOAL',
        });
        if (web) {
          final account = tester.widget<ContaFinanceiraWebField>(
            find.byType(ContaFinanceiraWebField),
          );
          expect(account.espaco, 'PESSOAL');
          expect(account.value, isNull);
        } else {
          final account = tester.widget<ContaFinanceiraMobileField>(
            find.byType(ContaFinanceiraMobileField),
          );
          expect(account.espaco, 'PESSOAL');
          expect(account.value, isNull);
        }
        expect(service.espacoFinanceiro, 'EMPRESA');
        Navigator.of(tester.element(selector)).pop();
        await tester.pumpAndSettle();
        expect(service.espacoFinanceiro, 'EMPRESA');
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'detail supports nested dates and explicit null overrides stale nested data',
    () {
      final nested = AgendaFinanceiraLancamentoDetalhe.fromJson({
        'dadosEdicao': {
          'dataPrevisaoPagamento': '2026-10-20',
          'dataQuitacao': '2026-09-03T14:20:00',
        },
      });
      expect(nested.dataPrevisaoPagamento, DateTime(2026, 10, 20));
      expect(nested.dataLiquidacao, DateTime(2026, 9, 3, 14, 20));
      final cleared = AgendaFinanceiraLancamentoDetalhe.fromJson({
        'dataPrevisaoPagamento': null,
        'dataLiquidacao': null,
        'dadosEdicao': {
          'dataPrevisaoPagamento': '2026-10-20',
          'dataQuitacao': '2026-09-03T14:20:00',
        },
      });
      expect(cleared.dataPrevisaoPagamento, isNull);
      expect(cleared.dataLiquidacao, isNull);
    },
  );

  testWidgets(
    'failed save keeps form and unchecking does not request settlement',
    (tester) async {
      final service = _Service()..failSave = true;
      Map<String, dynamic>? result;
      await _pump(
        tester,
        Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(
                      context,
                    ).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder:
                            (_) => AgendaFinanceiraLancamentoMobileEditScreen(
                              lancamento: _item,
                              service: service,
                              caixaApiClient: _Caixa(),
                            ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
        ),
      );
      await _tap(tester, find.text('open'));
      await _tap(tester, _key('agenda-registrar-pagamento'));
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Salvar e confirmar pagamento'),
      );
      expect(
        find.byType(AgendaFinanceiraLancamentoMobileEditScreen),
        findsOneWidget,
      );
      expect(service.saved, isEmpty);
      expect(result, isNull);
      service.failSave = false;
      await _tap(tester, _key('agenda-registrar-pagamento'));
      expect(_key('agenda-data-efetiva'), findsNothing);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Atualizar lançamento'),
      );
      expect(result!['registrarPagamento'], false);
      expect(service.saved.single.statusQuitada, false);
      expect(
        service
            .saved
            .single
            .payloadOriginalJson['agendaFinanceira']['dataPrevisaoPagamento'],
        '2026-10-12',
      );
    },
  );

  testWidgets(
    'create saves forecast separately and returns settlement intent with effective date',
    (tester) async {
      final service = _Service();
      Map<String, dynamic>? result;
      await _pump(
        tester,
        Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(
                      context,
                    ).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder:
                            (_) => AgendaFinanceiraLancamentoMobileCreateScreen(
                              service: service,
                              caixaApiClient: _Caixa(),
                            ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
        ),
      );
      await _tap(tester, find.text('open'));
      await _fillCreate(tester);
      final forecast = DateTime(2026, 12, 15);
      await _date(tester, 'agenda-previsao', forecast);
      await _tap(tester, _key('agenda-registrar-pagamento'));
      final effective = DateTime(2026, 9, 5);
      await _date(tester, 'agenda-data-efetiva', effective);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Salvar e confirmar pagamento'),
      );
      final request = service.saved.single;
      final agenda =
          (request.toJson()['payloadOriginalJson'] as Map)['agendaFinanceira']
              as Map;
      expect(agenda['dataPrevisaoPagamento'], '2026-12-15');
      expect(agenda['atualizarPrevisaoPagamento'], true);
      expect(request.dataVencimento, isNot(forecast));
      expect(request.statusQuitada, false);
      expect(request.dataQuitacao, isNull);
      expect(result!['registrarPagamento'], true);
      expect(DateTime.parse(result!['dataLiquidacaoSolicitada']), effective);
    },
  );

  testWidgets(
    'edit loads authoritative dates and sends explicit forecast removal',
    (tester) async {
      final service = _Service();
      await _pump(
        tester,
        AgendaFinanceiraLancamentoMobileEditScreen(
          lancamento: _item,
          service: service,
          caixaApiClient: _Caixa(),
        ),
      );
      expect(_fields(tester).previsao, DateTime(2026, 10, 12));
      await _tap(tester, _key('agenda-limpar-previsao'));
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Atualizar lançamento'),
      );
      final request = service.saved.single;
      final agenda = request.payloadOriginalJson['agendaFinanceira'] as Map;
      expect(agenda.containsKey('dataPrevisaoPagamento'), true);
      expect(agenda['dataPrevisaoPagamento'], isNull);
      expect(agenda['atualizarPrevisaoPagamento'], true);
      expect(request.dataVencimento, DateTime(2026, 9, 10));
    },
  );

  for (final status in ['PAGO', 'RECEBIDO', 'PARCIAL', 'CANCELADO']) {
    testWidgets('$status hides new settlement and preserves historical date', (
      tester,
    ) async {
      final service = _Service();
      service.detail.addAll({
        'status': status,
        'dataLiquidacao': '2026-09-03T14:20:00',
        'valorPagoRecebido': status == 'CANCELADO' ? 0 : 50,
        'valorAberto': status == 'PARCIAL' ? 50 : 0,
      });
      await _pump(
        tester,
        AgendaFinanceiraLancamentoMobileEditScreen(
          lancamento: _item,
          service: service,
          caixaApiClient: _Caixa(),
        ),
      );
      expect(_fields(tester).permitirLiquidacao, false);
      expect(
        _fields(tester).liquidacaoPersistida,
        DateTime(2026, 9, 3, 14, 20),
      );
      expect(_key('agenda-registrar-pagamento'), findsNothing);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Atualizar lançamento'),
      );
      if (status == 'PAGO' || status == 'RECEBIDO') {
        expect(service.saved.single.dataQuitacao, DateTime(2026, 9, 3, 14, 20));
      }
    });
  }

  testWidgets(
    'null detail clears stale forecast and unavailable detail prevents saving',
    (tester) async {
      final service = _Service()..detail['dataPrevisaoPagamento'] = null;
      await _pump(
        tester,
        AgendaFinanceiraLancamentoMobileEditScreen(
          lancamento: _item,
          service: service,
          caixaApiClient: _Caixa(),
        ),
      );
      expect(_fields(tester).previsao, isNull);
      await tester.pumpWidget(const SizedBox());
      service.failDetail = true;
      await tester.pumpWidget(
        _app(
          AgendaFinanceiraLancamentoMobileEditScreen(
            lancamento: _item,
            service: service,
            caixaApiClient: _Caixa(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(AgendaPagamentoMobileFields),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_fields(tester).enabled, false);
      expect(_fields(tester).permitirLiquidacao, false);
      expect(service.saved, isEmpty);
    },
  );

  for (final mode in ['cancel', 'total', 'partial']) {
    testWidgets(
      'agenda handles $mode after save without automatic settlement',
      (tester) async {
        final service = _Service();
        final actions = _Actions();
        await _pump(
          tester,
          AgendaFinanceiraMobileScreen(
            lancamentoService: service,
            acoesFinanceiras: actions,
            caixaApiClient: _Caixa(),
            enablePeriodHint: false,
          ),
        );
        await _tap(tester, find.byTooltip('Novo lançamento'));
        await _fillCreate(tester);
        await _tap(tester, _key('agenda-registrar-pagamento'));
        final effective = DateTime(2026, 9, 5);
        await _date(tester, 'agenda-data-efetiva', effective);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Salvar e confirmar pagamento'),
        );
        expect(find.byType(SixMobileRecebimentoBottomSheet), findsOneWidget);
        expect(service.saved.single.statusQuitada, false);
        expect(actions.totals, isEmpty);
        expect(actions.partials, isEmpty);
        final navigator = Navigator.of(
          tester.element(find.byType(SixMobileRecebimentoBottomSheet)),
        );
        if (mode == 'cancel') {
          navigator.pop();
        } else {
          navigator.pop(
            SixMobileRecebimentoResultado(
              tipo:
                  mode == 'total'
                      ? SixMobileRecebimentoTipo.total
                      : SixMobileRecebimentoTipo.parcial,
              valor: mode == 'total' ? 100 : 40,
              codigoTipoRecebimento: 'tipo1',
              descricaoTipoRecebimento: 'Dinheiro',
              formaPagamentoBackend: 'tipo1',
              recebimentos: [
                RecebimentoFormaInput(
                  codigo: 'tipo1',
                  valor: mode == 'total' ? 100 : 40,
                  contaFinanceiraId: 'account',
                ),
              ],
            ),
          );
        }
        await tester.pumpAndSettle();
        if (mode == 'cancel') {
          expect(actions.totals, isEmpty);
          expect(actions.partials, isEmpty);
        } else if (mode == 'total') {
          expect(actions.totals.single.dataLiquidacao, effective);
          expect(actions.totals.single.contaFinanceiraId, 'account');
        } else {
          expect(actions.partials.single.dataLiquidacao, effective);
        }
      },
    );
  }

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('calendar and payment labels use $language in dark mode', (
      tester,
    ) async {
      DateTime? forecast;
      bool register = false;
      await _pump(
        tester,
        Scaffold(
          body: StatefulBuilder(
            builder:
                (context, setState) => SingleChildScrollView(
                  child: AgendaPagamentoMobileFields(
                    receber: true,
                    previsao: forecast,
                    registrarPagamento: register,
                    dataEfetiva: DateTime.now(),
                    onPrevisaoChanged:
                        (date) => setState(() => forecast = date),
                    onRegistrarChanged:
                        (value) => setState(() => register = value),
                    onDataEfetivaChanged: (_) {},
                  ),
                ),
          ),
        ),
        language: language,
        brightness: Brightness.dark,
      );
      expect(
        find.text(
          {
            'pt': 'Já recebi este valor',
            'en': 'I have received this amount',
            'es': 'Ya cobré este importe',
          }[language]!,
        ),
        findsOneWidget,
      );
      final fieldMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: _key('agenda-previsao'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(fieldMaterial.color, SixMobileColorScheme.dark.softSurface);
      await _tap(tester, _key('agenda-previsao'));
      await _tap(
        tester,
        find.text(
          {'pt': 'Amanhã', 'en': 'Tomorrow', 'es': 'Mañana'}[language]!,
        ),
      );
      expect(forecast, isNull);
      await _tap(
        tester,
        find.widgetWithText(
          OutlinedButton,
          language == 'en' ? 'Cancel' : 'Cancelar',
        ),
      );
      expect(forecast, isNull);
      await _tap(tester, _key('agenda-previsao'));
      await _tap(
        tester,
        find.text(
          {'pt': 'Amanhã', 'en': 'Tomorrow', 'es': 'Mañana'}[language]!,
        ),
      );
      await _tap(
        tester,
        find.widgetWithText(
          FilledButton,
          language == 'en' ? 'Apply' : 'Aplicar',
        ),
      );
      expect(
        forecast,
        DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1))),
      );
      await _tap(tester, _key('agenda-registrar-pagamento'));
      await _tap(tester, _key('agenda-data-efetiva'));
      final calendar = tester.widget<DateSelectorMobileBottomSheet>(
        find.byType(DateSelectorMobileBottomSheet),
      );
      expect(calendar.lastDate, DateUtils.dateOnly(DateTime.now()));
      expect(
        find.text(
          {'pt': 'Amanhã', 'en': 'Tomorrow', 'es': 'Mañana'}[language]!,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
