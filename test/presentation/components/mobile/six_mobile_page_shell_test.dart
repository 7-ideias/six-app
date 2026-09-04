import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';

void main() {
  testWidgets(
    'mobile shell keeps app bar title and icons legible in dark mode',
    (WidgetTester tester) async {
      const Color incompatibleGlobalOnPrimary = Colors.black;
      final ThemeData darkTheme = ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF60A5FA),
          onPrimary: incompatibleGlobalOnPrimary,
          surface: Color(0xFF0F1B2D),
          onSurface: Colors.white,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: SixMobilePageShell(
            title: 'Início',
            backgroundColor: SixMobilePalette.backgroundLight,
            primaryColor: SixMobilePalette.primaryLight,
            secondaryColor: SixMobilePalette.secondaryLight,
            accentColor: SixMobilePalette.accentLight,
            enableAnimatedBackground: false,
            leading: const BackButton(),
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>('app-bar-action'),
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
            bodyBuilder: (
              BuildContext context,
              ScrollController scrollController,
              double topInset,
            ) {
              return ListView(
                controller: scrollController,
                padding: EdgeInsets.only(top: topInset),
                children: const <Widget>[SizedBox(height: 900)],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
      final Text title = tester.widget<Text>(find.text('Início'));

      expect(appBar.foregroundColor, SixMobileColorScheme.dark.onPrimary);
      expect(appBar.foregroundColor, isNot(incompatibleGlobalOnPrimary));
      expect(title.style?.color, SixMobileColorScheme.dark.onPrimary);
    },
  );
}
