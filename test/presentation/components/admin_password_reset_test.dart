import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_password_reset_dialog.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_password_reset_sheet.dart';

void main() {
  for (final mobile in [false, true]) {
    testWidgets('reset ${mobile ? "mobile" : "web"}: confirmation, single request and success', (tester) async {
      final operation = Completer<void>();
      var calls = 0;
      bool? result;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(builder: (context) => Scaffold(
          body: TextButton(onPressed: () async {
            Future<void> confirm() { calls++; return operation.future; }
            result = mobile
              ? await showSixMobilePasswordResetSheet(context: context, userName: 'Maria', userId: 'user-1', onConfirm: confirm)
              : await showSixWebPasswordResetDialog(context: context, userName: 'Maria', userId: 'user-1', onConfirm: confirm);
          }, child: const Text('Open')),
        )),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Reset password to 00000000?'), findsOneWidget);
      expect(calls, 0);
      await tester.tap(find.text('Confirm reset'));
      await tester.pump();
      await tester.tap(find.text('Confirm reset'));
      await tester.pump();
      expect(calls, 1);
      expect(find.text('Resetting password…'), findsOneWidget);
      operation.complete();
      await tester.pump();
      expect(find.text('Password reset to 00000000.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(tester.takeException(), isNull);
    });
    testWidgets('reset ${mobile ? "mobile" : "web"}: recoverable failure and cancel', (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
        body: TextButton(onPressed: () {
          Future<void> confirm() async { calls++; throw Exception('network'); }
          if (mobile) {
            showSixMobilePasswordResetSheet(context: context, userName: 'Maria', userId: 'user-1', onConfirm: confirm);
          } else {
            showSixWebPasswordResetDialog(context: context, userName: 'Maria', userId: 'user-1', onConfirm: confirm);
          }
        }, child: const Text('Open')),
      ))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm reset'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Maria'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
