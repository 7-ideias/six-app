import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/screens/operational_procedure_preview_mobile_screen.dart';

void main() {
  testWidgets('preview accepts no as valid response and shows summary', (
    tester,
  ) async {
    final OperationalProcedure procedure = _procedure();

    await _pumpPreview(tester, procedure);

    await tester.tap(find.byIcon(Icons.thumb_down_alt_outlined));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.ensureVisible(find.text('Finalizar'));
    await tester.pump();
    await tester.tap(find.text('Finalizar'));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Demonstração concluída'), findsOneWidget);
    expect(find.text('Nenhuma resposta foi salva.'), findsOneWidget);
    expect(
      procedure.stages.single.items.single.responseType,
      ProcedureResponseType.yesNo,
    );
  });

  testWidgets(
    'preview shows trigger configuration without blocking operation',
    (tester) async {
      final OperationalProcedure procedure = _procedure().copyWith(
        triggers: <ProcedureTrigger>[
          ProcedureTrigger(
            id: 'trigger-sale',
            operationType: ProcedureOperationType.sale,
            triggerMoment: ProcedureTriggerMoment.beforeFinish,
            activationMode: ProcedureTriggerActivationMode.automatic,
            enforcementMode: ProcedureEnforcementMode.required,
            enabled: true,
            order: 1,
            createdAt: DateTime(2026, 7, 29),
            updatedAt: DateTime(2026, 7, 29),
          ),
          ProcedureTrigger(
            id: 'trigger-delivery',
            operationType: ProcedureOperationType.delivery,
            triggerMoment: ProcedureTriggerMoment.beforeDelivery,
            activationMode: ProcedureTriggerActivationMode.manual,
            enforcementMode: ProcedureEnforcementMode.informative,
            enabled: true,
            order: 2,
            createdAt: DateTime(2026, 7, 29),
            updatedAt: DateTime(2026, 7, 29),
          ),
        ],
      );

      await _pumpPreview(tester, procedure);

      expect(find.text('Configuração de execução'), findsOneWidget);
      expect(
        find.text(
          'Simulação de gatilho. Nenhuma operação real será bloqueada.',
        ),
        findsNothing,
      );
      expect(find.text('Venda'), findsWidgets);
      expect(find.textContaining('Entrega'), findsWidgets);
    },
  );

  testWidgets('yes no item can require text when answer is no', (tester) async {
    final OperationalProcedure procedure = _procedureWithNegativeText();

    await _pumpPreview(tester, procedure);

    await tester.tap(find.byIcon(Icons.thumb_down_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('O que faltou?'), findsOneWidget);

    await tester.ensureVisible(find.text('Finalizar'));
    await tester.tap(find.text('Finalizar'));
    await tester.pump();

    expect(
      find.text('Existem ações obrigatórias pendentes nesta etapa.'),
      findsWidgets,
    );

    await tester.enterText(
      find.byType(TextFormField).last,
      'Produto complementar indisponível.',
    );
    await tester.pump();
    await tester.tap(find.text('Finalizar'));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Demonstração concluída'), findsOneWidget);
  });
}

Future<void> _pumpPreview(
  WidgetTester tester,
  OperationalProcedure procedure,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1100);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: OperationalProcedurePreviewMobileScreen(procedure: procedure),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
}

OperationalProcedure _procedure() {
  return OperationalProcedure(
    id: 'preview-test',
    name: 'Preview teste',
    description: 'Procedimento para teste.',
    operationType: ProcedureOperationType.technicalService,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: true,
    stages: <ProcedureStage>[
      ProcedureStage(
        id: 'stage',
        title: 'Etapa',
        description: '',
        order: 1,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'item',
            title: 'O aparelho possui chip?',
            guidance: '',
            responseType: ProcedureResponseType.yesNo,
            required: true,
            order: 1,
          ),
        ],
      ),
    ],
    createdAt: DateTime(2026, 7, 29),
    updatedAt: DateTime(2026, 7, 29),
  );
}

OperationalProcedure _procedureWithNegativeText() {
  return _procedure().copyWith(
    stages: <ProcedureStage>[
      ProcedureStage(
        id: 'stage',
        title: 'Etapa',
        description: '',
        order: 1,
        items: <ProcedureItem>[
          ProcedureItem(
            id: 'found-everything',
            title: 'O cliente encontrou tudo o que precisava?',
            guidance: '',
            responseType: ProcedureResponseType.yesNo,
            required: true,
            order: 1,
            configuration: const ProcedureItemConfiguration(
              requireTextWhenNo: true,
              negativeTextPlaceholder:
                  'Descreva o que o cliente ainda procura.',
            ),
          ),
        ],
      ),
    ],
  );
}
