import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/screens/certeza_mobile_screen.dart';

void main() {
  testWidgets('transparent mobile app bar remains legible in dark mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const CertezaMobileScreen()),
    );

    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    final IconButton closeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close),
    );

    expect(scaffold.backgroundColor, SixMobileColorScheme.dark.background);
    expect(appBar.foregroundColor, SixMobileColorScheme.dark.titleText);
    expect(closeButton.tooltip, isNotNull);
    expect(closeButton.tooltip, isNotEmpty);
  });
}
