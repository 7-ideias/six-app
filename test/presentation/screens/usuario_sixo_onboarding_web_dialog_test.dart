import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/screens/usuario_sixo_onboarding_web_dialog.dart';

void main() {
  testWidgets('confirma, processa e conclui a alteração do onboarding', (
    WidgetTester tester,
  ) async {
    final Completer<void> operation = Completer<void>();
    bool? receivedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () async {
                  await showUsuarioSixoOnboardingWebDialog(
                    context: context,
                    nomeUsuario: 'Maria Silva',
                    valorAtual: true,
                    onConfirm: (bool value) {
                      receivedValue = value;
                      return operation.future;
                    },
                  );
                },
                child: const Text('Abrir'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitar novo onboarding?'), findsOneWidget);

    await tester.tap(find.text('Refazer onboarding'));
    await tester.pump();
    expect(receivedValue, isFalse);
    expect(find.text('Atualizando onboarding...'), findsOneWidget);

    operation.complete();
    await tester.pumpAndSettle();
    expect(find.text('Onboarding atualizado'), findsOneWidget);
  });
}
