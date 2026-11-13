import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/screens/compra_cartao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/cartoes_credito_mobile_screen.dart';
import 'cartoes_mobile_test.dart' show Api, Config, invoice;
import 'faturas_cartao_web_test.dart' show RegionalClient;

class _Api extends Api {
  bool inactive = false, failSave = false, saveInactive = false;
  final saves = <CartaoCreditoRequest>[];
  Completer<CartoesCreditoResponse>? pendingList;
  @override
  Future<CartoesCreditoResponse> listar() async {
    if (pendingList != null) return pendingList!.future;
    if (failRead) throw const CartaoCreditoApiException('connection');
    return CartoesCreditoResponse(
      podeEditar: editable,
      cartoes:
          inactive
              ? const [
                CartaoCredito(
                  id: 'old',
                  nome: 'Antigo',
                  instituicao: 'Banco',
                  diaFechamento: 3,
                  diaVencimento: 10,
                  ativo: false,
                  versao: 0,
                ),
              ]
              : [],
    );
  }

  @override
  Future<CartaoCredito> salvar(CartaoCreditoRequest request) async {
    saves.add(request);
    if (failSave) throw const CartaoCreditoApiException('connection');
    return CartaoCredito(
      id: request.id,
      nome: request.nome,
      instituicao: request.instituicao,
      diaFechamento: request.diaFechamento,
      diaVencimento: request.diaVencimento,
      ativo: !saveInactive,
      versao: 0,
    );
  }

  @override
  Future<FaturaCartao> comprar(CompraCartaoRequest request) async {
    purchases.add(request);
    return invoice();
  }
}

Future<void> _open(
  WidgetTester t,
  _Api api, {
  String lang = 'pt',
  bool dark = true,
  bool settle = true,
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(api.dispose);
  final config = Config();
  addTearDown(config.dispose);
  await t.pumpWidget(
    ChangeNotifierProvider(
      create:
          (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: RegionalClient(),
            ),
          ),
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: const TextScaler.linear(1.25),
              ),
              child: child!,
            ),
        home: CompraCartaoMobileScreen(
          espaco: 'PESSOAL',
          client: api,
          configuracoes: config,
          duplicarCompra: CompraCartao.fromJson({
            'id': 'source',
            'descricao': 'Hostinger',
            'valor': 108.99,
            'dataCompra': '2020-01-01',
            'categoriaId': 'category',
          }),
        ),
      ),
    ),
  );
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

String _label(WidgetTester t, String key) =>
    t.element(find.byType(Scaffold).last).t(key);
Finder _field(WidgetTester t, String key) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == _label(t, key),
);
Future<void> _fillCard(WidgetTester t) async {
  for (final entry
      in {
        'space.name': 'Viagens',
        'cards.institution': 'Banco',
        'cards.closing': '3',
        'cards.due': '10',
      }.entries) {
    final f = _field(t, entry.key);
    await t.ensureVisible(f);
    await t.enterText(f, entry.value);
  }
  await t.pumpAndSettle();
}

Finder get _gate => find.byKey(const ValueKey('mobile-purchase-card-required'));
Finder get _add => find.byKey(const ValueKey('mobile-purchase-add-card'));
void main() {
  testWidgets('mobile aguarda a consulta antes de anunciar falta de cartão', (
    t,
  ) async {
    final api = _Api()..pendingList = Completer<CartoesCreditoResponse>();
    await _open(t, api, settle: false);
    expect(_gate, findsNothing);
    expect(_add, findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    api.pendingList!.complete(
      const CartoesCreditoResponse(podeEditar: true, cartoes: []),
    );
    await t.pumpAndSettle();
    expect(_gate, findsOneWidget);
    expect(_add, findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final lang in ['pt', 'en', 'es'])
    for (final inactive in [false, true]) {
      testWidgets(
        'mobile pede cartão antes do formulário $lang inactive=$inactive',
        (t) async {
          final api = _Api()..inactive = inactive;
          await _open(t, api, lang: lang, dark: inactive);
          expect(_gate, findsOneWidget);
          expect(find.byType(TextFormField), findsNothing);
          expect(find.text(_label(t, 'mobile.cards.review')), findsNothing);
          final style = t.widget<FilledButton>(_add).style!;
          final colors =
              inactive ? SixMobileColorScheme.dark : SixMobileColorScheme.light;
          expect(style.backgroundColor!.resolve({}), colors.accent);
          expect(style.foregroundColor!.resolve({}), colors.onAccent);
          await _tap(t, _add);
          await _fillCard(t);
          await _tap(t, find.byIcon(Icons.arrow_back).first);
          expect(_gate, findsOneWidget);
          expect(find.byType(TextFormField), findsNothing);
          expect(api.saves, isEmpty);
          await _tap(t, _add);
          await _fillCard(t);
          await _tap(
            t,
            find.widgetWithText(FilledButton, _label(t, 'space.save')),
          );
          expect(find.byType(CartaoCreditoMobileEditor), findsNothing);
          expect(_gate, findsNothing);
          expect(find.text('Viagens'), findsOneWidget);
          expect(_field(t, 'invoices.description'), findsOneWidget);
          expect(
            t
                .widget<TextField>(_field(t, 'invoices.description'))
                .controller!
                .text,
            contains('Hostinger'),
          );
          await _tap(t, find.text(_label(t, 'mobile.cards.review')));
          await _tap(
            t,
            find.widgetWithText(
              FilledButton,
              _label(t, 'invoices.savePurchase'),
            ),
          );
          expect(api.purchases.single.cartaoId, api.saves.single.id);
          expect(api.purchases.single.valor, 108.99);
          expect(api.purchases.single.categoriaId, 'category');
          expect(t.takeException(), isNull);
        },
      );
    }
  for (final mode in ['permission', 'error'])
    testWidgets('mobile distingue $mode de ausência de cartão', (t) async {
      final api =
          _Api()
            ..editable = mode != 'permission'
            ..failRead = mode == 'error';
      await _open(t, api);
      expect(_gate, findsNothing);
      expect(_add, findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.text(
          _label(
            t,
            mode == 'error'
                ? 'cards.error.connection'
                : 'invoices.cardPermissionHint',
          ),
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  testWidgets('mobile mantém bloqueio após erro e após salvar cartão inativo', (
    t,
  ) async {
    final api = _Api()..failSave = true;
    await _open(t, api);
    await _tap(t, _add);
    await _fillCard(t);
    await _tap(t, find.widgetWithText(FilledButton, _label(t, 'space.save')));
    expect(find.byType(CartaoCreditoMobileEditor), findsOneWidget);
    expect(api.purchases, isEmpty);
    api.failSave = false;
    api.saveInactive = true;
    await t.drag(find.byType(ListView).last, const Offset(0, -400));
    await t.pumpAndSettle();
    await _tap(t, find.widgetWithText(FilledButton, _label(t, 'space.retry')));
    expect(api.saves.first.id, api.saves.last.id);
    expect(_gate, findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(t.takeException(), isNull);
  });
}
