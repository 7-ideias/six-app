import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/presentation/components/web/financeiro_configuracao_web_dialog.dart';
import 'package:sixpos/presentation/screens/configuracoes_espaco_web.dart';

class _Contas extends ConfiguracaoFinanceiraService {
  _Contas() : super('PESSOAL', client: MockClient((_) async => http.Response('[]', 200)));
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async => [
    const ConfiguracaoFinanceira(id: 'conta', nome: 'Conta de teste', tipo: 'BANCO'),
  ];
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('configuracoes sobrepostas preservam a agenda e fecham por Esc $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final contas = _Contas();
      addTearDown(contas.dispose);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(),
        home: Scaffold(body: Builder(builder: (context) => Column(children: [
          const Text('Agenda preservada'),
          TextButton(onPressed: () => showFinanceiroConfiguracaoWebDialog<void>(
            context: context, title: 'Configurações',
            child: ConfiguracoesEspacoWeb(espaco: 'PESSOAL', service: contas),
          ), child: const Text('Abrir')),
        ]))),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Agenda preservada'), findsOneWidget);
      expect(find.text('Conta de teste'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      final rect = tester.getRect(find.byType(Dialog));
      expect(rect.width, lessThan(width));
      expect(rect.height, lessThan(900));
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Agenda preservada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
