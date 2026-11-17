import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/presentation/components/instituicao_open_finance_logo.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/presentation/screens/cartoes_credito_web.dart';

class _Api extends CartaoCreditoApiClient {
  _Api() : super(espaco: 'PESSOAL', client: MockClient((_) async => http.Response('{}', 200)));
  bool failLoad = false, failSave = false, canEdit = true;
  CatalogoInstituicoesBrasil catalogo = CatalogoInstituicoesBrasil.vazio;
  @override Future<CatalogoInstituicoesBrasil> listarInstituicoesBrasileiras() async => catalogo;
  String saveError = 'connection';
  final requests = <CartaoCreditoRequest>[];
  List<CartaoCredito> items = [];
  @override
  Future<CartoesCreditoResponse> listar() async {
    if (failLoad) throw const CartaoCreditoApiException('unavailable');
    return CartoesCreditoResponse(podeEditar: canEdit, cartoes: items);
  }
  @override
  Future<CartaoCredito> salvar(CartaoCreditoRequest input) async {
    requests.add(input);
    if (failSave) throw CartaoCreditoApiException(saveError);
    final card = CartaoCredito(id: input.id, nome: input.nome, instituicao: input.instituicao,
      diaFechamento: input.diaFechamento, diaVencimento: input.diaVencimento, ativo: input.ativo,
      versao: (input.versao ?? -1) + 1, contaPrevistaId: input.contaPrevistaId,
      marcaOpenFinanceId: input.marcaOpenFinanceId);
    items = [card];
    return card;
  }
}

class _Contas extends ConfiguracaoFinanceiraService {
  _Contas() : super('PESSOAL', client: MockClient((_) async => http.Response('[]', 200)));
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async => [];
}

Future<void> open(WidgetTester tester, _Api api, {double width = 1100, String locale = 'pt'}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final contas = _Contas();
  addTearDown(contas.dispose);
  addTearDown(api.dispose);
  await tester.pumpWidget(MaterialApp(
    locale: Locale(locale), supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData.dark(),
    home: CartoesCreditoWeb(espaco: 'PESSOAL', client: api, contasService: contas),
  ));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('API indisponivel mostra retry, nao falso vazio e nao permite criar', (tester) async {
    final api = _Api()..failLoad = true;
    await open(tester, api);
    expect(find.byKey(const ValueKey('cards-create')), findsNothing);
    expect(find.textContaining('não está disponível'), findsOneWidget);
    api.failLoad = false;
    await tap(tester, find.widgetWithIcon(OutlinedButton, Icons.refresh).last);
    expect(find.byKey(const ValueKey('cards-create')), findsOneWidget);
    expect(find.textContaining('Nenhum cartão'), findsOneWidget);
  });

  testWidgets('empresa BR oferece escolha de banco sem impedir digitacao manual', (tester) async {
    final api = _Api()..catalogo = CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: const [
        InstituicaoOpenFinance(
          nome: 'Nubank',
          logotipoUrl: 'https://example.com/nu.svg',
        ),
      ],
    );
    await open(tester, api);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    expect(find.byKey(const ValueKey('cards-openfinance-pick')), findsOneWidget);
    expect(find.byKey(const ValueKey('cards-institution')), findsOneWidget);
  });

  testWidgets('seletor de bancos Web abre janela elevada e Esc retorna ao formulário', (tester) async {
    final api = _Api()..catalogo = const CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: [
        InstituicaoOpenFinance(
          nome: 'Banco de Teste',
          logotipoUrl: 'url-invalida-sem-http',
          marcaOpenFinanceId: 'auth-teste',
        ),
      ],
    );
    await open(tester, api);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    await tap(tester, find.byKey(const ValueKey('cards-openfinance-pick')));

    final modal = find.byKey(const ValueKey('openfinance-web-dialog'));
    expect(modal, findsOneWidget);
    expect(find.byKey(const ValueKey('openfinance-web-search')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    final tamanho = tester.getSize(modal);
    expect(tamanho.width, lessThan(700));
    expect(tamanho.height, lessThan(700));
    expect(tamanho.width, lessThan(1100));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(modal, findsNothing);
    expect(find.byKey(const ValueKey('cards-institution')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seletor Web filtra sem acentos e preserva identificador selecionado', (tester) async {
    final api = _Api()..catalogo = const CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: [
        InstituicaoOpenFinance(
          nome: 'Árvore Financeira',
          logotipoUrl: 'url-invalida-sem-http',
          marcaOpenFinanceId: 'auth-arvore',
        ),
        InstituicaoOpenFinance(
          nome: 'Outro Banco',
          logotipoUrl: 'url-invalida-sem-http',
          marcaOpenFinanceId: 'auth-outro',
        ),
      ],
    );
    await open(tester, api);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    await tap(tester, find.byKey(const ValueKey('cards-openfinance-pick')));
    await tester.enterText(find.byKey(const ValueKey('openfinance-web-search')), 'arvore');
    await tester.pumpAndSettle();

    expect(find.text('Árvore Financeira'), findsOneWidget);
    expect(find.text('Outro Banco'), findsNothing);
    await tap(tester, find.text('Árvore Financeira'));
    expect(find.byKey(const ValueKey('openfinance-web-dialog')), findsNothing);
    expect(tester.widget<TextFormField>(
      find.byKey(const ValueKey('cards-institution')),
    ).controller?.text, 'Árvore Financeira');
    expect(tester.takeException(), isNull);
  });

  testWidgets('seletor Web respeita largura compacta e botão de fechar', (tester) async {
    final api = _Api()..catalogo = const CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: [
        InstituicaoOpenFinance(
          nome: 'Instituição de Teste',
          logotipoUrl: 'url-invalida-sem-http',
        ),
      ],
    );
    await open(tester, api, width: 390);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    await tap(tester, find.byKey(const ValueKey('cards-openfinance-pick')));
    final modal = find.byKey(const ValueKey('openfinance-web-dialog'));
    expect(tester.getSize(modal).width, lessThanOrEqualTo(390));
    await tap(tester, find.byKey(const ValueKey('openfinance-web-close')));
    expect(modal, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empresa fora do Brasil continua com campo livre sem catalogo', (tester) async {
    await open(tester, _Api()..catalogo = CatalogoInstituicoesBrasil.vazio);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    expect(find.byKey(const ValueKey('cards-openfinance-pick')), findsNothing);
    expect(find.byKey(const ValueKey('cards-institution')), findsOneWidget);
  });

  testWidgets('web exibe logo no formulário depois de escolher o banco', (tester) async {
    final api = _Api()..catalogo = const CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: [
        InstituicaoOpenFinance(
          nome: 'Banco de Teste',
          logotipoUrl: 'asset-de-teste-sem-requisicao-externa',
          marcaOpenFinanceId: 'marca-banco-teste',
        ),
      ],
    );
    await open(tester, api);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    expect(find.byKey(const ValueKey('cards-institution-logo')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('cards-openfinance-pick')));
    await tap(tester, find.text('Banco de Teste').last);
    final logo = tester.widget<InstituicaoOpenFinanceLogo>(
      find.byKey(const ValueKey('cards-institution-logo')),
    );
    expect(logo.url, 'asset-de-teste-sem-requisicao-externa');
    await tester.enterText(find.byKey(const ValueKey('cards-institution')), 'Banco Manual');
    await tester.pump();
    expect(find.byKey(const ValueKey('cards-institution-logo')), findsNothing);
  });

  testWidgets('seleciona instituição, salva ID da marca e exibe na lista', (tester) async {
    final api = _Api()..catalogo = CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: const [
        InstituicaoOpenFinance(
          nome: 'Banco de Teste',
          logotipoUrl: 'arquivo-indisponivel-no-ambiente-de-testes',
          marcaOpenFinanceId: 'marca-banco-teste',
        ),
      ],
    );
    await open(tester, api);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    await tester.enterText(find.byKey(const ValueKey('cards-name')), 'Cartão do banco teste');
    await tap(tester, find.byKey(const ValueKey('cards-openfinance-pick')));
    await tap(tester, find.text('Banco de Teste').last);
    await tester.enterText(find.byKey(const ValueKey('cards.closing')), '10');
    await tester.enterText(find.byKey(const ValueKey('cards.due')), '20');
    await tap(tester, find.byKey(const ValueKey('cards-save')));

    expect(api.requests.single.instituicao, 'Banco de Teste');
    expect(api.requests.single.marcaOpenFinanceId, 'marca-banco-teste');
    expect(api.items.single.marcaOpenFinanceId, 'marca-banco-teste');
    expect(find.text('Cartão do banco teste'), findsOneWidget);
  });

  testWidgets('leitura sem escrita esconde criacao', (tester) async {
    await open(tester, _Api()..canEdit = false);
    expect(find.byKey(const ValueKey('cards-create')), findsNothing);
    expect(find.textContaining('não possui permissão'), findsOneWidget);
  });

  testWidgets('erro de validacao apos timeout permite corrigir o formulario', (tester) async {
    final api = _Api()..failSave = true;
    await open(tester, api);
    await tap(tester, find.byKey(const ValueKey('cards-create')));
    await tester.enterText(find.byKey(const ValueKey('cards-name')), 'Nubank');
    await tester.enterText(find.byKey(const ValueKey('cards-institution')), 'Nu');
    await tester.enterText(find.byKey(const ValueKey('cards.closing')), '3');
    await tester.enterText(find.byKey(const ValueKey('cards.due')), '10');
    await tap(tester, find.byKey(const ValueKey('cards-save')));
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('cards-name'))).enabled, isFalse);
    api.saveError = 'validation';
    await tap(tester, find.byKey(const ValueKey('cards-save')));
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('cards-name'))).enabled, isTrue);
    expect(find.text('Nubank'), findsOneWidget);
  });

  testWidgets('edicao inativa o cartao preservando ID e versao', (tester) async {
    final api = _Api()..items = [const CartaoCredito(
      id: 'card-existing', nome: 'Inter', instituicao: 'Inter',
      diaFechamento: 25, diaVencimento: 5, ativo: true, versao: 2,
    )];
    await open(tester, api);
    await tap(tester, find.byIcon(Icons.edit_outlined));
    await tap(tester, find.byType(SwitchListTile));
    await tap(tester, find.byKey(const ValueKey('cards-save')));
    expect(api.requests.single.id, 'card-existing');
    expect(api.requests.single.versao, 2);
    expect(api.requests.single.ativo, isFalse);
    expect(api.items.single.versao, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha de atualizacao conserva dados sem permitir edicao desatualizada', (tester) async {
    final api = _Api()..items = [const CartaoCredito(
      id: 'card-existing', nome: 'Inter', instituicao: 'Banco Inter',
      diaFechamento: 25, diaVencimento: 5, ativo: true, versao: 2,
    )];
    await open(tester, api);
    api.failLoad = true;
    await tap(tester, find.widgetWithIcon(OutlinedButton, Icons.refresh).first);
    expect(find.text('Inter'), findsOneWidget);
    expect(find.textContaining('última consulta'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byKey(const ValueKey('cards-create')), findsNothing);
  });

  for (final width in [390.0, 1100.0]) {
    for (final locale in ['pt', 'en', 'es']) {
      testWidgets('cadastro preserva formulario e ID no retry $width $locale', (tester) async {
        final api = _Api()..failSave = true;
        await open(tester, api, width: width, locale: locale);
        await tap(tester, find.byKey(const ValueKey('cards-create')));
        await tester.enterText(find.byKey(const ValueKey('cards-name')), 'Nubank pessoal');
        await tester.enterText(find.byKey(const ValueKey('cards-institution')), 'Nubank');
        await tester.enterText(find.byKey(const ValueKey('cards.closing')), '32');
        await tester.enterText(find.byKey(const ValueKey('cards.due')), '10');
        await tap(tester, find.byKey(const ValueKey('cards-save')));
        expect(api.requests, isEmpty);
        await tester.enterText(find.byKey(const ValueKey('cards.closing')), '3');
        await tap(tester, find.byKey(const ValueKey('cards-save')));
        expect(api.requests.length, 1);
        expect(find.text('Nubank pessoal'), findsOneWidget);
        expect(tester.takeException(), isNull);
        api.failSave = false;
        await tap(tester, find.byKey(const ValueKey('cards-save')));
        expect(api.requests.length, 2);
        expect(api.requests[0].toJson(), api.requests[1].toJson());
        expect(find.text('Nubank pessoal'), findsOneWidget);
        expect(find.byKey(const ValueKey('cards-save')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
