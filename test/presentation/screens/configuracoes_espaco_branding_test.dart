import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/screens/configuracoes_espaco_web.dart';
import 'package:sixpos/presentation/screens/configuracoes_espaco_mobile.dart';

class _FinanceiroFake extends ConfiguracaoFinanceiraService {
  _FinanceiroFake({this.vazio = false}) : super('PESSOAL');
  final bool vazio;
  final List<String> consultas = [];

  @override
  Future<CatalogoInstituicoesBrasil> catalogoBrasileiro() async =>
      CatalogoInstituicoesBrasil.vazio;

  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async {
    consultas.add(grupo);
    if (vazio) return [];
    if (grupo == 'CONTAS') {
      return const [
        ConfiguracaoFinanceira(
          id: 'caixa', nome: 'Caixa da loja', instituicao: '',
          tipo: 'CAIXA', ativo: true,
        ),
        ConfiguracaoFinanceira(
          id: 'banco', nome: 'Itaú pessoal', instituicao: 'Itaú',
          tipo: 'BANCO', ativo: true,
        ),
      ];
    }
    if (grupo == 'MAQUININHAS') {
      return const [
        ConfiguracaoFinanceira(
          id: 'maquina', nome: 'Terminal 01', instituicao: 'Stone',
          tipo: 'MAQUININHA', ativo: true,
          marcaId: 'OPERADORA:STONE', contaDestinoId: 'banco',
        ),
      ];
    }
    return [];
  }
}

Future<void> _abrir(
  WidgetTester tester, _FinanceiroFake service, {
  required bool mobile,
}) async {
  tester.view.physicalSize = Size(mobile ? 390 : 1100, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(service.dispose);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData.dark(),
    home: mobile
        ? ConfiguracoesEspacoMobile(espaco: 'PESSOAL', service: service)
        : ConfiguracoesEspacoWeb(espaco: 'PESSOAL', service: service),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final mobile in [false, true]) {
    final plataforma = mobile ? 'mobile' : 'web';
    testWidgets('$plataforma mostra contas existentes e permite abrir maquininhas',
        (tester) async {
      final service = _FinanceiroFake();
      await _abrir(tester, service, mobile: mobile);
      expect(find.text('Caixa da loja'), findsOneWidget);
      expect(find.text('Itaú pessoal'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

      // Sem catálogo BR, cards permanecem operacionais com fallback visual.
      expect(tester.takeException(), isNull);
    });

    testWidgets('$plataforma tem ação específica no estado vazio',
        (tester) async {
      final service = _FinanceiroFake(vazio: true);
      await _abrir(tester, service, mobile: mobile);
      final key = mobile
          ? const ValueKey('financial-brand-first-mobile')
          : const ValueKey('financial-brand-first-web');
      expect(find.byKey(key), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile usa superfície do tema em listas', (tester) async {
    final service = _FinanceiroFake();
    await _abrir(tester, service, mobile: true);
    expect(
      tester.widget<Card>(find.byType(Card).first).color,
      SixMobileColorScheme.dark.surface,
    );
  });
}
