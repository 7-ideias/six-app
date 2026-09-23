import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/presentation/components/web/six_web_centro_custo_rename_dialog.dart';

const CentroCustoModel _centro = CentroCustoModel(
  id: 'centro-1',
  codigo: 'PESSOAL',
  nome: 'Funcionários',
  tipo: 'CUSTO',
  ativo: true,
);

void main() {
  testWidgets('exibe contexto e exige revisão antes de renomear', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester, onConfirm: (String nome) async => _centro);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('centro-custo-rename-backdrop')),
      findsOneWidget,
    );
    expect(find.text('Alterar nome do centro de custos'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('centro-custo-rename-name')),
      'Equipe',
    );
    await tester.tap(find.byKey(const Key('centro-custo-rename-review')));
    await tester.pumpAndSettle();

    expect(find.text('Funcionários'), findsOneWidget);
    expect(find.text('Equipe'), findsOneWidget);
    expect(
      find.byKey(const Key('centro-custo-rename-confirm')),
      findsOneWidget,
    );
  });

  testWidgets('bloqueia confirmação duplicada durante processamento', (
    WidgetTester tester,
  ) async {
    final Completer<CentroCustoModel> completer = Completer<CentroCustoModel>();
    int chamadas = 0;
    await _pumpHarness(
      tester,
      onConfirm: (String nome) {
        chamadas++;
        return completer.future;
      },
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('centro-custo-rename-name')),
      'Equipe',
    );
    await tester.tap(find.byKey(const Key('centro-custo-rename-review')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('centro-custo-rename-confirm')));
    await tester.tap(find.byKey(const Key('centro-custo-rename-confirm')));
    await tester.pump();

    expect(chamadas, 1);
    expect(
      find.byKey(const Key('centro-custo-rename-processing')),
      findsOneWidget,
    );

    completer.complete(
      const CentroCustoModel(
        id: 'centro-1',
        codigo: 'PESSOAL',
        nome: 'Equipe',
        tipo: 'CUSTO',
        ativo: true,
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('centro-custo-rename-success')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('mantém diálogo aberto e permite tentar novamente após erro', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(
      tester,
      onConfirm: (String nome) async => throw StateError('falha'),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('centro-custo-rename-name')),
      'Equipe',
    );
    await tester.tap(find.byKey(const Key('centro-custo-rename-review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('centro-custo-rename-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível alterar o nome. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<CentroCustoModel> Function(String nome) onConfirm,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showSixWebCentroCustoRenameDialog(
                context: context,
                centro: _centro,
                onConfirm: onConfirm,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}
