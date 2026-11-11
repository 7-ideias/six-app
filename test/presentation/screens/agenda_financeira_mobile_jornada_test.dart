import 'dart:async';
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

Widget _app(
  Widget child, {
  String language = 'pt',
  Brightness brightness = Brightness.light,
}) => ChangeNotifierProvider(
  create: (_) => LocaleSettingsProvider(
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
