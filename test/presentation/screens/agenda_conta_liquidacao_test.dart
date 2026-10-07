import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/web/six_web_recebimento_dialog.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_recebimento_bottom_sheet.dart';

class _Regional extends Fake implements RegionalizacaoApiClient {}

class _Contas extends ConfiguracaoFinanceiraService {
  _Contas() : super('PESSOAL');
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async => const [
    ConfiguracaoFinanceira(id: 'a', nome: 'Conta original', tipo: 'BANCO'),
    ConfiguracaoFinanceira(id: 'b', nome: 'Outra conta', tipo: 'BANCO'),
  ];
}

class _Caixa extends Fake implements CaixaApiClient {
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
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final web in [true, false]) {
    for (final pagamento in [true, false]) {
      for (final parcial in [true, false]) {
        testWidgets(
          '$web/$pagamento/$parcial: conta visível, obrigatória e enviada',
          (tester) async {
            tester.view.physicalSize = Size(web ? 1200 : 430, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final contas = _Contas();
            addTearDown(contas.dispose);
            dynamic resultado;
            var encerrado = false;
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create:
                    (_) => LocaleSettingsProvider(
                      regionalizacaoService: RegionalizacaoService(
                        apiClient: _Regional(),
                      ),
                    ),
                child: MaterialApp(
                  locale: const Locale('pt', 'BR'),
                  supportedLocales: const [Locale('pt', 'BR')],
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  home: Scaffold(
                    body: Builder(
                      builder:
                          (context) => TextButton(
                            child: const Text('Abrir'),
                            onPressed: () async {
                              if (web) {
                                resultado = await SixWebRecebimentoDialog.show(
                                  context,
                                  titulo: 'Liquidar',
                                  descricao: 'Conta de teste',
                                  valorAberto: 100,
                                  pagamento: pagamento,
                                  exigirConta: true,
                                  espacoFinanceiro: 'PESSOAL',
                                  contaFinanceiraInicial: 'a',
                                  contaService: contas,
                                  caixaApiClient: _Caixa(),
                                  tipoInicial:
                                      parcial
                                          ? SixWebRecebimentoTipo.parcial
                                          : SixWebRecebimentoTipo.total,
                                );
                              } else {
                                resultado =
                                    await SixMobileRecebimentoBottomSheet.show(
                                      context,
                                      titulo: 'Liquidar',
                                      descricao: 'Conta de teste',
                                      valorAberto: 100,
                                      pagamento: pagamento,
                                      exigirConta: true,
                                      espacoFinanceiro: 'PESSOAL',
                                      contaFinanceiraInicial: 'a',
                                      contaService: contas,
                                      caixaApiClient: _Caixa(),
                                      tipoInicial:
                                          parcial
                                              ? SixMobileRecebimentoTipo.parcial
                                              : SixMobileRecebimentoTipo.total,
                                    );
                              }
                              encerrado = true;
                            },
                          ),
                    ),
                  ),
                ),
              ),
            );
            await _tap(tester, find.text('Abrir'));
            final field = find.byKey(const ValueKey('settlement-account'));
            final context = tester.element(field);
            final label = context.t(
              pagamento
                  ? 'agenda.settlement.sourceAccount'
                  : 'agenda.settlement.destinationAccount',
            );
            expect(find.text('$label: Conta original'), findsOneWidget);
            if (parcial) {
              await tester.enterText(find.byType(TextField).first, '40');
              await tester.pumpAndSettle();
            }
            // Remover a conta não pode fechar o modal nem disparar a liquidação.
            await _tap(tester, field);
            await _tap(tester, find.text(context.t('space.none')).last);
            await _tap(tester, find.byType(FilledButton).last);
            expect(encerrado, isFalse);
            expect(
              find.text(context.t('agenda.settlement.accountRequired')),
              findsOneWidget,
            );
            await _tap(tester, field);
            await _tap(tester, find.text('Outra conta'));
            expect(find.text('$label: Outra conta'), findsOneWidget);
            await _tap(tester, find.byType(FilledButton).last);
            expect(encerrado, isTrue);
            expect(resultado.recebimentos.single.contaFinanceiraId, 'b');
            expect(resultado.valor, parcial ? 40 : 100);
            expect(resultado.parcial, parcial);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
