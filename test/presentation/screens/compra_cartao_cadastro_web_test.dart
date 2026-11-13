import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web/cartao_credito_web_editor.dart';
import 'package:sixpos/presentation/components/web/compra_cartao_web_editor.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

import '../../data/services/fatura_cartao_api_client_test.dart'
    show invoiceJson;
import 'faturas_cartao_web_test.dart' show RegionalClient;

const existing = CartaoCredito(
  id: 'old',
  nome: 'Meu cartão',
  instituicao: 'Banco',
  diaFechamento: 3,
  diaVencimento: 10,
  ativo: true,
  versao: 0,
);

class _Api extends CartaoCreditoApiClient {
  _Api() : super(espaco: 'PESSOAL');
  bool allowed = true, failSave = false;
  List<CartaoCredito> cards = [];
  final saves = <CartaoCreditoRequest>[];
  final purchases = <CompraCartaoRequest>[];
  final previews = <String>[];
  Completer<CartaoCredito>? pending;
  @override
  Future<CartoesCreditoResponse> listar() async =>
      CartoesCreditoResponse(podeEditar: allowed, cartoes: cards);
  @override
  Future<CartaoCredito> salvar(CartaoCreditoRequest request) async {
    saves.add(request);
    if (failSave) throw const CartaoCreditoApiException('connection');
    return pending?.future ??
        CartaoCredito(
          id: request.id,
          nome: request.nome,
          instituicao: request.instituicao,
          diaFechamento: request.diaFechamento,
          diaVencimento: request.diaVencimento,
          ativo: true,
          versao: 0,
        );
  }

  @override
  Future<PreviaFaturaCartao> previa(String id, DateTime date) async {
    previews.add(id);
    return PreviaFaturaCartao.fromJson({
      'fechamento': '2026-12-03',
      'vencimento': '2026-12-10',
      'versaoCartao': 0,
      'paga': false,
    });
  }

  @override
  Future<PreviaFaturaCartao> previaRecorrencia(String id, DateTime date) =>
      previa(id, date);
  @override
  Future<FaturaCartao> comprar(CompraCartaoRequest request) async {
    purchases.add(request);
    return FaturaCartao.fromJson(invoiceJson());
  }

  @override
  Future<FaturaCartao> criarRecorrencia(
    CompraCartaoRequest request,
    DateTime? end,
  ) => comprar(request);
}

class _Config extends ConfiguracaoFinanceiraService {
  _Config() : super('PESSOAL');
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String group) async =>
      group == 'CATEGORIAS'
          ? const [
            ConfiguracaoFinanceira(
              id: 'category',
              nome: 'Assinaturas',
              tipo: 'DESPESA',
            ),
          ]
          : [];
}

class _Regional extends LocaleSettingsProvider {
  _Regional(this.lang)
    : super(
        regionalizacaoService: RegionalizacaoService(
          apiClient: RegionalClient(),
        ),
      );
  final String lang;
  @override
  String get decimalSeparator => lang == 'en' ? '.' : ',';
  @override
  String get currencyCode => lang == 'en' ? 'USD' : 'BRL';
}

class _Draft {
  final key = GlobalKey<CompraCartaoWebEditorState>();
  final description = TextEditingController(text: 'Hostinger');
  final amount = TextEditingController(text: '108,99');
  final category = TextEditingController(text: 'Assinaturas');
  final busy = <bool>[];
  void dispose() {
    description.dispose();
    amount.dispose();
    category.dispose();
  }
}

Future<_Draft> _open(
  WidgetTester tester,
  _Api api, {
  double width = 1100,
  String lang = 'pt',
  bool dark = false,
  bool cached = false,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final draft = _Draft(), config = _Config();
  if (lang == 'en') draft.amount.text = '108.99';
  addTearDown(draft.dispose);
  addTearDown(config.dispose);
  addTearDown(api.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>(
      create: (_) => _Regional(lang),
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: Scaffold(
          body: CompraCartaoWebEditor(
            key: draft.key,
            client: api,
            configuracoes: config,
            embedded: true,
            cartaoInicial: api.cards.isEmpty ? null : api.cards.first.id,
            cartoes: cached ? const [existing] : null,
            descricaoController: draft.description,
            valorController: draft.amount,
            categoriaController: draft.category,
            onBusy: draft.busy.add,
            onSaved: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return draft;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillCard(WidgetTester tester) async {
  for (final entry
      in {
        'cards-name': 'Viagens',
        'cards-institution': 'Banco',
        'cards.closing': '3',
        'cards.due': '10',
      }.entries) {
    final field = find.byKey(ValueKey(entry.key));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
  await tester.pumpAndSettle();
}

Finder get addCard => find.byKey(const ValueKey('purchase-add-card'));
Finder get saveCard => find.byKey(const ValueKey('cards-save'));
Finder get amount => find.byKey(const ValueKey('purchase-amount'));

void main() {
  testWidgets(
    'cadastra na compra mensal, seleciona retorno confirmado e preserva rascunho',
    (tester) async {
      final api = _Api();
      final draft = await _open(tester, api);
      await tap(tester, find.text('Mensal'));
      await tap(tester, addCard);
      await fillCard(tester);
      api.pending = Completer<CartaoCredito>();
      await tester.ensureVisible(saveCard);
      await tester.tap(saveCard);
      await tester.pump();
      expect(api.saves, hasLength(1));
      expect(draft.busy.last, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(CartaoCreditoWebEditor), findsOneWidget);
      expect(tester.widget<FilledButton>(saveCard).onPressed, isNull);
      api.pending!.complete(
        const CartaoCredito(
          id: 'new',
          nome: 'Viagens',
          instituicao: 'Banco',
          diaFechamento: 3,
          diaVencimento: 10,
          ativo: true,
          versao: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CartaoCreditoWebEditor), findsNothing);
      expect(find.byKey(const ValueKey('purchase-card-new')), findsOneWidget);
      expect(api.previews.last, 'new');
      expect(draft.busy.last, isFalse);
      expect(draft.description.text, 'Hostinger');
      expect(draft.amount.text, '108,99');
      expect(draft.key.currentState!.validate(), isTrue);
      await draft.key.currentState!.submit();
      await tester.pumpAndSettle();
      expect(api.purchases.single.cartaoId, 'new');
      expect(api.purchases.single.valor, 108.99);
      expect(api.purchases.single.categoriaId, 'category');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelar mantém cartão selecionado e valores', (tester) async {
    final api = _Api()..cards = [existing];
    final draft = await _open(tester, api);
    await tap(tester, addCard);
    await fillCard(tester);
    await tap(tester, find.widgetWithText(TextButton, 'Cancelar'));
    expect(api.saves, isEmpty);
    expect(draft.busy.last, isFalse);
    expect(find.byKey(const ValueKey('purchase-card-old')), findsOneWidget);
    expect(draft.description.text, 'Hostinger');
    expect(draft.amount.text, '108,99');
    expect(draft.key.currentState!.validate(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha no cadastro mantém editor e repete o mesmo comando', (
    tester,
  ) async {
    final api = _Api()..failSave = true;
    final draft = await _open(tester, api);
    await tap(tester, addCard);
    await fillCard(tester);
    await tap(tester, saveCard);
    expect(find.byType(CartaoCreditoWebEditor), findsOneWidget);
    expect(api.previews, isEmpty);
    expect(draft.description.text, 'Hostinger');
    expect(draft.busy.last, isTrue);
    api.failSave = false;
    await tap(tester, saveCard);
    expect(api.saves, hasLength(2));
    expect(api.saves.first.id, api.saves.last.id);
    expect(
      find.byKey(ValueKey('purchase-card-${api.saves.last.id}')),
      findsOneWidget,
    );
    expect(draft.key.currentState!.validate(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permissão atual prevalece sobre lista de cartões em cache', (
    tester,
  ) async {
    final api =
        _Api()
          ..allowed = false
          ..cards = [existing];
    final draft = await _open(tester, api, cached: true);
    expect(addCard, findsNothing);
    expect(draft.key.currentState!.validate(), isFalse);
    await draft.key.currentState!.submit();
    expect(api.purchases, isEmpty);
  });

  for (final width in [390.0, 1100.0]) {
    for (final lang in ['pt', 'en', 'es']) {
      testWidgets('valor compacto, moeda e cadastro responsivo $width $lang', (
        tester,
      ) async {
        final api = _Api()..cards = [existing];
        final draft = await _open(
          tester,
          api,
          width: width,
          lang: lang,
          dark: lang != 'pt',
        );
        final sep = lang == 'en' ? '.' : ',';
        expect(tester.getSize(amount).width, lessThanOrEqualTo(240));
        await tester.enterText(amount, '108.9');
        await tester.pumpAndSettle();
        expect(draft.amount.text, '108${sep}9');
        final description = find.byWidgetPredicate(
          (w) => w is TextField && w.controller == draft.description,
        );
        await tap(tester, description);
        expect(draft.amount.text, '108${sep}90');
        await tester.enterText(amount, '12${sep}34');
        await tester.enterText(amount, '12${sep}345');
        expect(draft.amount.text, '12${sep}34');
        expect(draft.key.currentState!.validate(), isTrue);
        if (width > 600) {
          final amountTop = tester.getTopLeft(amount).dy;
          final dateTop =
              tester.getTopLeft(find.byKey(const ValueKey('purchase-date'))).dy;
          expect((amountTop - dateTop).abs(), lessThan(1));
        }
        await tap(tester, addCard);
        await fillCard(tester);
        expect(tester.takeException(), isNull);
        final cancel = tester
            .element(find.byType(CartaoCreditoWebEditor))
            .t('space.cancel');
        await tap(tester, find.widgetWithText(TextButton, cancel));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
