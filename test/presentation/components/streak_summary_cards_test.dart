import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/streak_models.dart';
import 'package:sixpos/presentation/components/mobile/streak_summary_mobile_card.dart';
import 'package:sixpos/presentation/components/web/streak_summary_web_card.dart';

void main() {
  testWidgets('mobile apresenta MOBILE e GERAL sem destacar WEB', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      StreakSummaryMobileCard(
        streaks: _streaks,
        loading: false,
        hasError: false,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ofensiva'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('5 dias'), findsOneWidget);
    expect(find.text('12 dias'), findsOneWidget);
    expect(find.text('Web'), findsNothing);
  });

  testWidgets('web apresenta WEB e GERAL sem destacar MOBILE', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      StreakSummaryWebCard(streaks: _streaks, loading: false, hasError: false),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ofensiva'), findsOneWidget);
    expect(find.text('Web'), findsOneWidget);
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('8 dias'), findsOneWidget);
    expect(find.text('12 dias'), findsOneWidget);
    expect(find.text('Mobile'), findsNothing);
  });

  testWidgets('mobile respeita singular e plural', (WidgetTester tester) async {
    await _pump(
      tester,
      const StreakSummaryMobileCard(
        streaks: UserStreaksModel(
          mobile: UserStreakScopeModel(
            currentDays: 1,
            longestDays: 1,
            activeToday: true,
          ),
          web: UserStreakScopeModel(
            currentDays: 0,
            longestDays: 0,
            activeToday: false,
          ),
          shared: UserStreakScopeModel(
            currentDays: 2,
            longestDays: 2,
            activeToday: true,
          ),
        ),
        loading: false,
        hasError: false,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 dia'), findsOneWidget);
    expect(find.text('2 dias'), findsOneWidget);
  });

  testWidgets('web mostra ofensiva zerada com microcopy discreta', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      StreakSummaryWebCard(
        streaks: UserStreaksModel.empty(),
        loading: false,
        hasError: false,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0 dias'), findsWidgets);
    expect(
      find.text('Use o SixApp todos os dias para manter sua ofensiva.'),
      findsOneWidget,
    );
  });

  testWidgets('erro temporário permite tentar novamente', (
    WidgetTester tester,
  ) async {
    var retries = 0;
    await _pump(
      tester,
      StreakSummaryMobileCard(
        streaks: null,
        loading: false,
        hasError: true,
        onRetry: () => retries += 1,
      ),
    );

    expect(
      find.text('Não foi possível carregar sua ofensiva.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    expect(retries, 1);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
          size: Size(390, 900),
        ),
        child: Scaffold(
          body: Center(child: SizedBox(width: 390, child: child)),
        ),
      ),
    ),
  );
}

const UserStreaksModel _streaks = UserStreaksModel(
  mobile: UserStreakScopeModel(
    currentDays: 5,
    longestDays: 18,
    activeToday: true,
  ),
  web: UserStreakScopeModel(currentDays: 8, longestDays: 9, activeToday: true),
  shared: UserStreakScopeModel(
    currentDays: 12,
    longestDays: 31,
    activeToday: true,
  ),
);
