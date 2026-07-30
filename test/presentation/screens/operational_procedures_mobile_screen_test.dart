import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_card.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_filters.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_state_views.dart';
import 'package:sixpos/presentation/screens/operational_procedures_mobile_screen.dart';

void main() {
  testWidgets('shows procedures with success state', (tester) async {
    await _pumpProcedures(tester);

    expect(find.text('Recepção de aparelho'), findsOneWidget);
    expect(find.text('Fechamento de ordem de serviço'), findsOneWidget);
    expect(find.text('Entrega do aparelho'), findsOneWidget);
    expect(find.text('Finalização de venda'), findsOneWidget);
    expect(find.text('Dados demonstrativos'), findsAtLeastNWidgets(1));
    expect(find.text('Abrir'), findsNothing);
  });

  testWidgets('shows empty state', (tester) async {
    await _pumpProcedures(
      tester,
      scenario: OperationalProcedureMockScenario.empty,
    );

    expect(find.text('Nenhum procedimento configurado'), findsOneWidget);
    expect(find.text('Criar procedimento'), findsOneWidget);
    expect(find.text('Dados demonstrativos'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows error state without demonstration badge', (tester) async {
    await _pumpProcedures(
      tester,
      scenario: OperationalProcedureMockScenario.error,
    );

    expect(
      find.text('Não foi possível carregar os procedimentos'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Dados demonstrativos'), findsNothing);
  });

  testWidgets('filters active and inactive procedures', (tester) async {
    await _pumpProcedures(tester);

    await tester.tap(find.text('Ativos'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Recepção de aparelho'), findsOneWidget);
    expect(find.text('Finalização de venda'), findsNothing);

    await tester.tap(find.text('Inativos'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Finalização de venda'), findsOneWidget);
    expect(find.text('Recepção de aparelho'), findsNothing);

    await tester.tap(find.text('Todos'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Recepção de aparelho'), findsOneWidget);
    expect(find.text('Finalização de venda'), findsOneWidget);
  });

  testWidgets('keeps layout readable with high text scale', (tester) async {
    await _pumpProcedures(
      tester,
      mediaQueryData: const MediaQueryData(textScaler: TextScaler.linear(1.45)),
    );

    expect(find.text('Procedimentos'), findsWidgets);
    expect(find.text('Novo procedimento'), findsOneWidget);
  });

  testWidgets('shows structural loading state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OperationalProceduresMobileScreen(
          dataSource: OperationalProcedureMockDataSource(
            delay: Duration(milliseconds: 1),
          ),
        ),
      ),
    );

    expect(find.byType(OperationalProcedureLoadingState), findsOneWidget);
    expect(
      find.text('Configure orientações para vendas, atendimentos e entregas.'),
      findsOneWidget,
    );
    expect(find.text('Dados demonstrativos'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump(const Duration(milliseconds: 260));
  });

  testWidgets('invokes card callback', (tester) async {
    int taps = 0;

    await _pumpComponent(
      tester,
      OperationalProcedureCard(procedure: _procedure(), onTap: () => taps++),
    );

    await tester.tap(find.byType(OperationalProcedureCard));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('invokes new procedure callback', (tester) async {
    int taps = 0;

    await _pumpComponent(
      tester,
      OperationalProcedureNewAction(onTap: () => taps++),
    );

    await tester.tap(find.text('Novo procedimento'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('renders card with long content and high text scale', (
    tester,
  ) async {
    await _pumpComponent(
      tester,
      SizedBox(
        width: 320,
        child: OperationalProcedureCard(
          procedure: _procedure(
            name: 'Procedimento operacional com nome longo para validar quebra',
            description:
                'Descrição demonstrativa longa para validar limites de linhas, '
                'traduções maiores e escala de texto elevada.',
          ),
          onTap: () {},
        ),
      ),
      mediaQueryData: const MediaQueryData(textScaler: TextScaler.linear(1.45)),
    );

    expect(
      find.text('Procedimento operacional com nome longo para validar quebra'),
      findsOneWidget,
    );
    expect(find.byType(OperationalProcedureCard), findsOneWidget);
  });

  testWidgets('exposes main semantics for procedure card and filters', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pumpComponent(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OperationalProcedureFilters(
            selectedFilter: OperationalProcedureFilter.all,
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          OperationalProcedureCard(procedure: _procedure(), onTap: () {}),
        ],
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Recepção de aparelho, Ativo, Atendimento técnico, '
        'Antes de iniciar, 2 etapas • 5 itens, Obrigatório, '
        'Sem gatilhos configurados',
      ),
      findsOneWidget,
    );
    expect(find.byType(OperationalProcedureFilters), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('supports disabled animations', (tester) async {
    await _pumpProcedures(
      tester,
      mediaQueryData: const MediaQueryData(
        disableAnimations: true,
        accessibleNavigation: true,
      ),
    );

    expect(find.text('Recepção de aparelho'), findsOneWidget);
    expect(find.text('Novo procedimento'), findsOneWidget);
  });

  testWidgets('opens creation editor from list CTA', (tester) async {
    await _pumpProcedures(tester);

    await tester.ensureVisible(find.text('Novo procedimento'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Novo procedimento'));
    await tester.pump(const Duration(milliseconds: 320));

    expect(
      find.byType(TextFormField, skipOffstage: false),
      findsAtLeastNWidgets(2),
    );
  });

  testWidgets('opens edition editor from procedure card', (tester) async {
    await _pumpProcedures(tester);

    await tester.tap(find.text('Recepção de aparelho'));
    await tester.pump(const Duration(milliseconds: 320));

    expect(
      find.text('Recepção de aparelho', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.byType(TextFormField, skipOffstage: false),
      findsAtLeastNWidgets(2),
    );
  });

  test('declares procedures entry in management settings section', () {
    final source =
        File(
          'lib/presentation/screens/gestao_mobile_screen.dart',
        ).readAsStringSync();

    expect(source, contains("'procedimentos.title'"));
    expect(source, contains("'procedimentos.subtitle'"));
    expect(source, contains('const OperationalProceduresMobileScreen()'));
  });
}

Future<void> _pumpProcedures(
  WidgetTester tester, {
  OperationalProcedureMockScenario scenario =
      OperationalProcedureMockScenario.success,
  MediaQueryData? mediaQueryData,
}) async {
  final Widget screen = OperationalProceduresMobileScreen(
    dataSource: OperationalProcedureMockDataSource(
      scenario: scenario,
      delay: Duration.zero,
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data:
            mediaQueryData ??
            const MediaQueryData(
              disableAnimations: true,
              accessibleNavigation: true,
            ),
        child: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
}

Future<void> _pumpComponent(
  WidgetTester tester,
  Widget child, {
  MediaQueryData? mediaQueryData,
}) async {
  final Widget body = Scaffold(body: Center(child: child));

  await tester.pumpWidget(
    MaterialApp(
      home:
          mediaQueryData == null
              ? body
              : MediaQuery(data: mediaQueryData, child: body),
    ),
  );
  await tester.pump();
}

OperationalProcedure _procedure({
  String name = 'Recepção de aparelho',
  String description = 'Conferência inicial de itens, acessórios e avarias.',
}) {
  return OperationalProcedure(
    id: 'device-intake',
    name: name,
    description: description,
    operationType: ProcedureOperationType.technicalService,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: true,
    stages: <ProcedureStage>[
      ProcedureStage(
        id: 'stage-1',
        title: 'Conferência',
        description: '',
        order: 1,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'item-1',
            title: 'O aparelho possui chip?',
            guidance: '',
            responseType: ProcedureResponseType.yesNo,
            required: true,
            order: 1,
          ),
          ProcedureItem(
            id: 'item-2',
            title: 'Registrar avarias visíveis.',
            guidance: '',
            responseType: ProcedureResponseType.confirmation,
            required: true,
            order: 2,
          ),
        ],
      ),
      ProcedureStage(
        id: 'stage-2',
        title: 'Orientações',
        description: '',
        order: 2,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'item-3',
            title: 'Informe o prazo estimado.',
            guidance: '',
            responseType: ProcedureResponseType.instruction,
            required: false,
            order: 1,
          ),
          ProcedureItem(
            id: 'item-4',
            title: 'Confirmar fotos.',
            guidance: '',
            responseType: ProcedureResponseType.confirmation,
            required: true,
            order: 2,
          ),
          ProcedureItem(
            id: 'item-5',
            title: 'Conferir acessórios.',
            guidance: '',
            responseType: ProcedureResponseType.confirmation,
            required: true,
            order: 3,
          ),
        ],
      ),
    ],
    createdAt: DateTime(2026, 7, 22, 10),
    updatedAt: DateTime(2026, 7, 22, 10, 30),
  );
}
