import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/domain/services/caixa/caixa_service.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/formas_recebimento_configuracao_mobile_screen.dart';

void main() {
  tearDown(() => SixThemeResolver().atualizarTema(TemaSistema.claro));

  testWidgets('dark editor saves only the display name and updates the list', (
    tester,
  ) async {
    final api = _FakeApi();
    await _open(tester, api);
    expect(
      tester.widget<Card>(find.byType(Card).first).color,
      SixMobileColorScheme.dark.surface,
    );
    await tester.tap(find.text('DINHEIRO'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  GRANA  ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(api.saved!.toJson(), {
      ...api.original.toJson(),
      'descricaoExibicao': 'GRANA',
    });
    expect(api.savedCode, api.original.codigoTipo);
    expect(find.text('GRANA'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
    'permission failure retains the draft and cancellation does not save',
    (tester) async {
      final api = _FakeApi()..reject = true;
      await _open(tester, api);
      await tester.tap(find.text('DINHEIRO'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'GRANA');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Somente administradores podem alterar as formas de recebimento.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'GRANA',
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('DINHEIRO'), findsOneWidget);
      expect(api.saved, isNull);
      expect(api.attempts, 1);
    },
  );
}

Future<void> _open(WidgetTester tester, _FakeApi api) async {
  SixThemeResolver().atualizarTema(TemaSistema.escuro);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: FormasRecebimentoConfiguracaoMobileScreen(
        service: CaixaService(apiClient: api),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeApi implements CaixaApiClient {
  final original = TiposRecebimento(
    codigoTipo: 'TIPO_1',
    descricaoExibicao: 'DINHEIRO',
    naturezaRecebimento: 'IMEDIATO',
    aceitaParcelamento: false,
    ativo: true,
    exigeCliente: false,
    ordemExibicao: 1,
    corHex: '#FFFFFF',
    icone: 'cash',
  );
  TiposRecebimento? saved;
  String? savedCode;
  bool reject = false;
  int attempts = 0;

  @override
  Future<List<TiposRecebimento>> listarTiposRecebimentoConfiguraveis() async =>
      List.unmodifiable([original]);

  @override
  Future<TiposRecebimento> atualizarTipoRecebimentoConfiguravel({
    required String codigoTipo,
    required TiposRecebimento request,
  }) async {
    attempts++;
    if (reject) throw CaixaApiException(statusCode: 403, body: '');
    savedCode = codigoTipo;
    return saved = request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
