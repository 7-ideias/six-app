import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_delete_visual_asset_dialog.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<void> Function() action, {
    bool dark = false,
    bool scheduled = false,
    bool reduceMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => showSixWebDeleteVisualAssetDialog(
                        context: context,
                        title: 'Home',
                        target: 'Retail · Bikes',
                        scheduled: scheduled,
                        onConfirm: action,
                      ),
                  child: const Text('Open'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows context and blur; blocks repeat submits and back until success',
    (tester) async {
      final operation = Completer<void>();
      var calls = 0;
      await open(tester, () {
        calls++;
        return operation.future;
      });
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Retail · Bikes'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete image'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete image'));
      expect(calls, 1);
      await Navigator.of(
        tester.element(find.byType(SixWebDeleteVisualAssetDialog)),
      ).maybePop();
      await tester.pump();
      expect(find.byType(SixWebDeleteVisualAssetDialog), findsOneWidget);
      operation.complete();
      await tester.pump();
      expect(
        find.text('Image removed. Global default applied.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.byType(SixWebDeleteVisualAssetDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark theme keeps recoverable error and retries once', (
    tester,
  ) async {
    var calls = 0;
    await open(tester, () async {
      if (++calls == 1) throw Exception('failure');
    }, dark: true);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete image'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not complete the action. Try again.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(SixWebDeleteVisualAssetDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scheduled removal explains that the current image is kept', (
    tester,
  ) async {
    await open(tester, () async {}, scheduled: true, dark: true);
    expect(find.textContaining('current image will be kept'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete image'));
    await tester.pump();
    expect(find.text('Scheduled image removed.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel never invokes deletion', (tester) async {
    var called = false;
    await open(tester, () async {
      called = true;
    }, reduceMotion: true);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(called, isFalse);
    expect(find.byType(SixWebDeleteVisualAssetDialog), findsNothing);
  });
}
