import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/mobile/catalog_health_score_indicator.dart';

void main() {
  testWidgets('renders critical zero percent state', (
    WidgetTester tester,
  ) async {
    await _pumpIndicator(tester, percentage: 0, statusLabel: 'Crítico');

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Crítico'), findsOneWidget);
    expect(find.text('30 itens precisam de atenção'), findsOneWidget);
  });

  testWidgets('renders attention state at forty eight percent', (
    WidgetTester tester,
  ) async {
    await _pumpIndicator(tester, percentage: 48, statusLabel: 'Atenção');

    expect(find.text('48%'), findsOneWidget);
    expect(find.text('Atenção'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });

  testWidgets('renders healthy one hundred percent state', (
    WidgetTester tester,
  ) async {
    await _pumpIndicator(tester, percentage: 100, statusLabel: 'Saudável');

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Saudável'), findsOneWidget);
  });

  testWidgets('keeps narrow mobile layout readable with larger text', (
    WidgetTester tester,
  ) async {
    await _pumpIndicator(
      tester,
      percentage: 48,
      statusLabel: 'Atenção necessária',
      textScaler: const TextScaler.linear(1.35),
      width: 320,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Atenção necessária'), findsOneWidget);
  });

  testWidgets('restarts percentage animation when animation key changes', (
    WidgetTester tester,
  ) async {
    await _pumpIndicator(
      tester,
      percentage: 48,
      statusLabel: 'Atenção',
      reduceMotion: false,
      animationKey: 1,
    );

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('48%'), findsOneWidget);

    await _pumpIndicator(
      tester,
      percentage: 48,
      statusLabel: 'Atenção',
      reduceMotion: false,
      animationKey: 2,
    );

    expect(find.text('0%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('48%'), findsOneWidget);
  });
}

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required int percentage,
  required String statusLabel,
  TextScaler textScaler = TextScaler.noScaling,
  double width = 360,
  bool reduceMotion = true,
  Object? animationKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 640), textScaler: textScaler),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CatalogHealthScoreIndicator(
                  percentage: percentage,
                  statusLabel: statusLabel,
                  semanticColorCode: 'ALERTA',
                  attentionLabel: '30 itens precisam de atenção',
                  reduceMotion: reduceMotion,
                  animationKey: animationKey,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
