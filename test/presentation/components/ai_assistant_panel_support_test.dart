import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/ai_assistant/ai_assistant_panel.dart';

void main() {
  testWidgets('abre o suporte pela apresentação inicial da Lis', (
    WidgetTester tester,
  ) async {
    int openSupportCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantConversationBody(
            modulo: 'geral',
            telaAtual: 'inicio_mobile',
            isMobile: true,
            onOpenSupport: () => openSupportCalls += 1,
          ),
        ),
      ),
    );

    final Finder supportButton = find.widgetWithText(
      OutlinedButton,
      'Falar com o suporte',
    );
    expect(supportButton, findsOneWidget);

    await tester.tap(supportButton);
    await tester.pump();

    expect(openSupportCalls, 1);
  });
}
