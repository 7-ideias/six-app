import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/components/auth/six_auth_google_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_or_divider.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('auth input preserves light colors in light mode', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpAuthSurface(
      tester,
      brightness: Brightness.light,
      child: SixAuthInput(
        controller: controller,
        label: 'Login',
        hint: 'Seu login',
      ),
    );

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.fillColor, SixAuthTokens.colorFieldFill);
    expect(field.style?.color, SixAuthTokens.colorTextPrimary);
  });

  testWidgets('auth shared components use mobile dark tokens in dark mode', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpAuthSurface(
      tester,
      brightness: Brightness.dark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SixAuthTitle(title: 'Criar conta', subtitle: 'Comece agora'),
          SixAuthInput(
            controller: controller,
            label: 'Login',
            hint: 'Seu login',
          ),
          const SizedBox(height: 12),
          SixAuthPrimaryButton(label: 'Cadastrar', onPressed: () {}),
          const SizedBox(height: 12),
          SixAuthGoogleButton(label: 'Continuar com Google', onPressed: () {}),
          const SizedBox(height: 12),
          const SixAuthOrDivider(),
        ],
      ),
    );

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.decoration?.fillColor,
      kIsWeb
          ? SixAuthTokens.colorFieldFill
          : SixMobileColorScheme.dark.softSurface,
    );
    expect(
      field.style?.color,
      kIsWeb
          ? SixAuthTokens.colorTextPrimary
          : SixMobileColorScheme.dark.titleText,
    );

    expect(
      _hasTextWithColor(
        tester,
        'Criar conta',
        kIsWeb
            ? SixAuthTokens.colorTextPrimary
            : SixMobileColorScheme.dark.titleText,
      ),
      isTrue,
    );
    expect(
      _hasDividerWithColor(
        tester,
        kIsWeb ? SixAuthTokens.colorDivider : SixMobileColorScheme.dark.border,
      ),
      isTrue,
    );

    final ElevatedButton primaryButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Cadastrar'),
    );
    expect(
      primaryButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      kIsWeb
          ? SixAuthTokens.colorButtonPrimaryBg
          : SixMobileColorScheme.dark.accent,
    );
    expect(
      primaryButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      kIsWeb
          ? SixAuthTokens.colorButtonPrimaryFg
          : SixMobileColorScheme.dark.onAccent,
    );

    final OutlinedButton googleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Continuar com Google'),
    );
    expect(
      googleButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      kIsWeb
          ? SixAuthTokens.colorButtonGoogleBg
          : SixMobileColorScheme.dark.surface,
    );
  });

  testWidgets(
    'auth shared components keep legacy web tokens when compiled for web',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpAuthSurface(
        tester,
        brightness: Brightness.dark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SixAuthTitle(title: 'Entrar', subtitle: 'Acesse sua conta'),
            SixAuthInput(
              controller: controller,
              label: 'Login',
              hint: 'Seu login',
            ),
            const SizedBox(height: 12),
            SixAuthPrimaryButton(label: 'Continuar', onPressed: () {}),
            const SizedBox(height: 12),
            SixAuthGoogleButton(
              label: 'Continuar com Google',
              onPressed: () {},
            ),
          ],
        ),
      );

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.fillColor, SixAuthTokens.colorFieldFill);
      expect(field.style?.color, SixAuthTokens.colorTextPrimary);

      final ElevatedButton primaryButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(
        primaryButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        SixAuthTokens.colorButtonPrimaryBg,
      );

      final OutlinedButton googleButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Continuar com Google'),
      );
      expect(
        googleButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        SixAuthTokens.colorButtonGoogleBg,
      );
    },
    skip: !kIsWeb,
  );

  testWidgets('auth primary button exposes disabled and loading states', (
    WidgetTester tester,
  ) async {
    await _pumpAuthSurface(
      tester,
      brightness: Brightness.dark,
      child: const SixAuthPrimaryButton(label: 'Cadastrar', onPressed: null),
    );

    ElevatedButton button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Cadastrar'),
    );
    expect(button.onPressed, isNull);

    await _pumpAuthSurface(
      tester,
      brightness: Brightness.dark,
      child: SixAuthPrimaryButton(
        label: 'Cadastrar',
        onPressed: () {},
        isLoading: true,
      ),
    );

    button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

Future<void> _pumpAuthSurface(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget child,
}) async {
  SixThemeResolver().atualizarTema(
    brightness == Brightness.dark ? TemaSistema.escuro : TemaSistema.claro,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    ),
  );
}

bool _hasTextWithColor(WidgetTester tester, String text, Color color) {
  return tester
      .widgetList<Text>(find.text(text))
      .any((Text widget) => widget.style?.color == color);
}

bool _hasDividerWithColor(WidgetTester tester, Color color) {
  return tester
      .widgetList<Divider>(find.byType(Divider))
      .any((Divider widget) => widget.color == color);
}
