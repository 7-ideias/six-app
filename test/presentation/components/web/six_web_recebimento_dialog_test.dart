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
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  ValueChanged<SixWebRecebimentoResultado?>? onResult,
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
