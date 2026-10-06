import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/configuracoes_espaco_mobile.dart';

void main() {
  tearDown(() => SixThemeResolver().atualizarTema(TemaSistema.claro));
  testWidgets(
    'personal account settings keep dark surfaces and editable names',
    (tester) async {
      SixThemeResolver().atualizarTema(TemaSistema.escuro);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          home: ConfiguracoesEspacoMobile(
            espaco: 'PESSOAL',
            service: _FakeSettings(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Minha conta'), findsOneWidget);
      expect(
        tester.widget<Card>(find.byType(Card).first).color,
        SixMobileColorScheme.dark.surface,
      );
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Minha conta'), findsOneWidget);
      expect(find.text('Empresa'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeSettings extends ConfiguracaoFinanceiraService {
  _FakeSettings() : super('PESSOAL');
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async => [
    const ConfiguracaoFinanceira(
      id: 'pessoal',
      nome: 'Minha conta',
      tipo: 'BANCO',
    ),
  ];
}
