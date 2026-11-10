import 'dart:async';
import 'package:sixpos/data/models/agenda_financeira_baixa_model.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/caixa_completo_movimentos_models.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/components/web/six_web_recebimento_dialog.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows impact route surface with contextual summary', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();

    expect(find.text('Receber venda em aberto'), findsOneWidget);
    expect(
      find.text('Venda web para receber depois 2026-08-25T13:30:33.043'),
      findsOneWidget,
    );
    expect(find.text('R\$ 99,00'), findsWidgets);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Formas de recebimento'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes with escape while interactive', (
    WidgetTester tester,
  ) async {
    SixWebRecebimentoResultado? result;
    await _pumpHarness(
      tester,
      onResult: (SixWebRecebimentoResultado? value) {
        result = value;
      },
    );

    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Receber venda em aberto'), findsNothing);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses semantic state color for total and partial', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();

    expect(_stateStripColor(tester), const Color(0xFF22C55E));

    await tester.tap(find.text('Parcial'));
    await tester.pumpAndSettle();

    expect(_stateStripColor(tester), const Color(0xFFF59E0B));
    expect(tester.takeException(), isNull);
  });
  for (final pagamento in [false, true]) {
    testWidgets('adjusted total returns cash separately, payment=$pagamento', (
      tester,
    ) async {
      SixWebRecebimentoResultado? result;
      await _pumpHarness(
        tester,
        permitirAjustes: true,
        pagamento: pagamento,
        onResult: (v) => result = v,
      );
      await tester.tap(find.text('Abrir recebimento'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('settlement-discount')),
        '10,00',
      );
      await tester.enterText(
        find.byKey(const ValueKey('settlement-surcharge')),
        '2,00',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('settlement-method-0')),
            )
            .controller!
            .text,
        '91,00',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(pagamento ? 'Pagar total' : 'Receber total'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.valor, 91);
      expect(result!.desconto, 10);
      expect(result!.acrescimo, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('partial keeps remaining balance and rejects full discount', (
    tester,
  ) async {
    SixWebRecebimentoResultado? result;
    await _pumpHarness(
      tester,
      permitirAjustes: true,
      onResult: (v) => result = v,
    );
    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settlement-discount')),
      '99',
    );
    await tester.tap(find.text('Receber total'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('settlement-discount')),
      '10',
    );
    await tester.enterText(
      find.byKey(const ValueKey('settlement-surcharge')),
      '2',
    );
    await tester.tap(find.text('Parcial'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settlement-method-0')),
      '40',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receber parcial'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.valor, 40);
    expect(result!.desconto, 10);
    expect(result!.acrescimo, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other flows do not display settlement adjustments', (
    tester,
  ) async {
    await _pumpHarness(tester);
    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settlement-discount')), findsNothing);
  });
  testWidgets('classification and notes stay local until settlement', (
    tester,
  ) async {
    SixWebRecebimentoResultado? submitted;
    final date = DateTime(2026, 1, 20);
    await _pumpHarness(
      tester,
      permitirAjustes: true,
      dadosBaixa: AgendaBaixaDados(
        categoria: 'Escola',
        contato: 'Fornecedor original',
        contatoEditavel: true,
        observacoes: 'Nota original',
        dataInicial: date,
        valorOriginal: 99,
        valorAberto: 99,
      ),
      onConfirm: (v) async => submitted = v,
    );
    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Escola ·'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settlement-classification')),
    );
    await tester.tap(find.text('Editar classificação'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('settlement-contact')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('settlement-contact')),
      'Escola da Laura',
    );
    expect(submitted, isNull);
    await tester.tap(find.text('Receber total'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(submitted!.dataLiquidacao, date);
    expect(submitted!.classificacao!.nomeContato, 'Escola da Laura');
    expect(submitted!.classificacao!.categoria, isNull);
    expect(submitted!.classificacao!.observacoesLancamento, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel discards edited contact without calling backend', (
    tester,
  ) async {
    var calls = 0;
    await _pumpHarness(
      tester,
      dadosBaixa: const AgendaBaixaDados(
        contato: 'Original',
        contatoEditavel: true,
      ),
      onConfirm: (_) async {
        calls++;
      },
    );
    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('settlement-classification')),
    );
    await tester.tap(find.text('Editar classificação'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('settlement-contact')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('settlement-contact')),
      'Alterado',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Abrir recebimento'), findsOneWidget);
  });

  testWidgets(
    'save failure preserves form and processing blocks duplicate submits',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await _pumpHarness(
        tester,
        permitirAjustes: true,
        onConfirm: (_) async {
          calls++;
          if (calls == 1) throw StateError('offline');
          await pending.future;
        },
      );
      await tester.tap(find.text('Abrir recebimento'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('settlement-discount')),
        '10',
      );
      await tester.tap(find.text('Receber total'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível confirmar a baixa'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('settlement-discount')),
            )
            .controller!
            .text,
        '10',
      );
      await tester.tap(find.text('Receber total'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Receber venda em aberto'), findsOneWidget);
      expect(calls, 2);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Abrir recebimento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'classification patch preserves omitted fields and clears explicitly',
    () {
      final request = AgendaFinanceiraLiquidacaoRequest(
        tipoLiquidacao: 'TOTAL',
        dataLiquidacao: DateTime(2026, 1, 20),
        valorLiquidado: 99,
        formaPagamentoRealizada: 'tipo2',
        classificacao: const AgendaClassificacaoBaixa(
          categoria: '',
          alterarCentroCusto: true,
        ),
      );
      expect(request.toJson()['classificacao'], {
        'categoria': '',
        'alterarCentroCusto': true,
        'centroCustoId': null,
      });
    },
  );
  testWidgets('multiple methods preserve allocation and block excess', (
    tester,
  ) async {
    SixWebRecebimentoResultado? result;
    await _pumpHarness(
      tester,
      permitirAjustes: true,
      onResult: (v) => result = v,
    );
    await tester.tap(find.text('Abrir recebimento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settlement-method-0')),
      '60',
    );
    await tester.ensureVisible(find.text('Adicionar forma'));
    await tester.tap(find.text('Adicionar forma'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('settlement-discount')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('settlement-discount')),
      '10',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('settlement-method-0')))
          .controller!
          .text,
      '60',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('settlement-method-1')))
          .controller!
          .text,
      '39,00',
    );
    expect(find.textContaining('Valor excedente'), findsWidgets);
    final button = find.widgetWithText(FilledButton, 'Receber total');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settlement-method-1')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('settlement-method-1')),
      '29',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receber total'));
    await tester.pumpAndSettle();
    expect(result!.valor, 89);
  });
}

Color? _stateStripColor(WidgetTester tester) {
  final Container strip = tester.widget<Container>(
    find.byKey(const Key('six-web-recebimento-state-strip')),
  );
  return strip.color;
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  ValueChanged<SixWebRecebimentoResultado?>? onResult,
  bool permitirAjustes = false,
  bool pagamento = false,
  AgendaBaixaDados? dadosBaixa,
  Future<void> Function(SixWebRecebimentoResultado)? onConfirm,
}) async {
  tester.view.physicalSize = const Size(1440, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final LocaleSettingsProvider localeProvider = LocaleSettingsProvider(
    regionalizacaoService: RegionalizacaoService(
      apiClient: _FakeRegionalizacaoApiClient(),
    ),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>.value(
      value: localeProvider,
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return Center(
                child: FilledButton(
                  onPressed: () async {
                    final SixWebRecebimentoResultado?
                    dialogResult = await SixWebRecebimentoDialog.show(
                      context,
                      titulo: 'Receber venda em aberto',
                      permitirAjustes: permitirAjustes,
                      pagamento: pagamento,
                      dadosBaixa: dadosBaixa,
                      agendaService: _FakeAgendaService(),
                      onConfirm: onConfirm,
                      descricao:
                          'Venda web para receber depois 2026-08-25T13:30:33.043',
                      valorAberto: 99,
                      contato: 'Cliente balcão',
                      permitirParcial: true,
                      observacaoInicial:
                          'Recebimento realizado no frente de caixa web.',
                      caixaApiClient: _FakeCaixaApiClient(),
                    );
                    onResult?.call(dialogResult);
                  },
                  child: const Text('Abrir recebimento'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async {
    return _defaultRegionalizacao();
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) async {
    return _defaultRegionalizacao();
  }

  ConfiguracaoRegionalizacaoResponse _defaultRegionalizacao() {
    return ConfiguracaoRegionalizacaoResponse(
      languageCode: 'pt',
      countryCode: 'BR',
      currencyCode: 'BRL',
      timeZone: 'America/Sao_Paulo',
      dateFormat: 'dd/MM/yyyy',
      timeFormat: '24h',
      decimalSeparator: ',',
      thousandSeparator: '.',
      firstDayOfWeek: 'MONDAY',
      numberPattern: '#,##0.00',
      decimalPlaces: 2,
      allowMultipleCurrencies: false,
      applyFinancialRounding: true,
    );
  }
}

class _FakeCaixaApiClient implements CaixaApiClient {
  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: true,
      tiposRecebimento: <TiposRecebimento>[
        TiposRecebimento(
          codigoTipo: 'tipo1',
          descricaoExibicao: 'Dinheiro',
          naturezaRecebimento: 'IMEDIATO',
          aceitaParcelamento: false,
          ativo: true,
          exigeCliente: false,
          ordemExibicao: 1,
          corHex: '#2563EB',
          icone: 'payments',
        ),
        TiposRecebimento(
          codigoTipo: 'tipo2',
          descricaoExibicao: 'Pix',
          naturezaRecebimento: 'IMEDIATO',
          aceitaParcelamento: false,
          ativo: true,
          exigeCliente: false,
          ordemExibicao: 2,
          corHex: '#2563EB',
          icone: 'qr_code',
        ),
      ],
      caixas: const <String>[],
      caixaOuGuiche: const <CaixaOuGuiche>[],
      formas: const <FormaMovimento>[],
    );
  }

  @override
  Future<void> abrirCaixa(AbrirCaixaRequest request) => _unsupported();

  @override
  Future<TiposRecebimento> atualizarTipoRecebimentoConfiguravel({
    required String codigoTipo,
    required TiposRecebimento request,
  }) => _unsupported();

  @override
  Future<void> cancelarMovimento(String id) => _unsupported();

  @override
  Future<void> fecharCaixa(FecharCaixaRequest request) => _unsupported();

  @override
  Future<CaixaOuGuiche> criarCaixaOuGuiche(String nome) => _unsupported();

  @override
  Future<CaixaOuGuiche> editarCaixaOuGuiche({
    required String id,
    required String nome,
  }) => _unsupported();

  @override
  Future<List<MovimentoCaixa>> getMovimentos(String idSessaoCaixa) =>
      _unsupported();

  @override
  Future<ResumoCaixa> getResumo(String idSessaoCaixa) => _unsupported();

  @override
  Future<InformacoesCaixaComSomatorioResponse>
  getResumoDeMovimentosComSomatorio(String idSessaoCaixa) => _unsupported();

  @override
  Future<CaixaSessao?> getSessaoAtual() => _unsupported();

  @override
  Future<List<CaixaSessao>> getSessoesAbertas() => _unsupported();

  @override
  Future<List<TiposRecebimento>> listarTiposRecebimentoConfiguraveis() =>
      _unsupported();

  @override
  Future<void> registrarMovimento(RegistrarMovimentoRequest request) =>
      _unsupported();

  @override
  Future<void> restaurarTiposRecebimentoPadrao() => _unsupported();

  Future<T> _unsupported<T>() {
    throw UnimplementedError();
  }
}

class _FakeAgendaService extends AgendaFinanceiraLancamentoService {
  @override
  Future<List<CentroCustoModel>> listarCentrosCusto() async => [];
}
