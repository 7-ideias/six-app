import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/presentation/components/web/conta_financeira_web_field.dart';

class _Service extends ConfiguracaoFinanceiraService {
  _Service(super.espaco);
  List<ConfiguracaoFinanceira> items = [];
  String? savedName;
  String? editedId;
  bool fail = false;
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async {
    expect(grupo, 'CATEGORIAS');
    return items;
  }

  @override
  Future<void> salvar(
    String grupo, {
    ConfiguracaoFinanceira? original,
    required String nome,
    required String tipo,
    required String instituicao,
    required bool ativo,
    String? contaDestinoId,
  }) async {
    expect(grupo, 'CATEGORIAS');
    if (fail) throw StateError('save failed');
    savedName = nome;
    editedId = original?.id;
  }
}

void main() {
  Future<void> open(
    WidgetTester tester,
    _Service service,
    ValueChanged<String?> selected,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const [Locale('pt')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Abrir'),
              onPressed: () async => selected(
                await selecionarContaWeb(
                  context,
                  service.espaco,
                  grupo: 'CATEGORIAS',
                  service: service,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Cria categoria no espaço pessoal e retorna ao lançamento', (
    tester,
  ) async {
    final service = _Service('PESSOAL');
    addTearDown(service.dispose);
    String? selected;
    await open(tester, service, (value) => selected = value);
    expect(find.text('Pessoal'), findsOneWidget);
    await tester.tap(find.text('Nova categoria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Alimentação');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(service.savedName, 'Alimentação');
    expect(service.editedId, isNull);
    expect(selected, 'Alimentação');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Edita categoria existente e seleciona o novo nome', (
    tester,
  ) async {
    final service = _Service('EMPRESA')
      ..items = [
        const ConfiguracaoFinanceira(
          id: 'cat-1',
          nome: 'Energia',
          tipo: 'DESPESA',
        ),
      ];
    addTearDown(service.dispose);
    String? selected;
    await open(tester, service, (value) => selected = value);
    await tester.tap(find.byTooltip('Editar categoria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Energia elétrica');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(service.editedId, 'cat-1');
    expect(selected, 'Energia elétrica');
  });

  testWidgets('Falha mantém editor aberto para corrigir ou tentar novamente', (
    tester,
  ) async {
    final service = _Service('PESSOAL')..fail = true;
    addTearDown(service.dispose);
    String? selected;
    await open(tester, service, (value) => selected = value);
    await tester.tap(find.text('Nova categoria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Casa');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(
      find.text(
        'Não foi possível salvar. Verifique sua permissão e tente novamente.',
      ),
      findsOneWidget,
    );
    service.fail = false;
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(selected, 'Casa');
  });
}
