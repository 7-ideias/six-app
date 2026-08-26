import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/auth_entry_mobile.dart';
import 'package:sixpos/presentation/screens/conta_criada_mobile.dart';
import 'package:sixpos/presentation/screens/create_account_mobile.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_mobile.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/presentation/screens/nova_senha_mobile.dart';
import 'package:sixpos/presentation/screens/verificar_codigo_recuperacao_mobile.dart';

void main() {
  setUp(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('auth entry mobile uses SixoApp brand and opens account creation', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const AuthEntryMobile());

    expect(_scaffoldBackground(tester), SixMobilePalette.brandNavyDeep);
    expect(find.text('Seu negócio, conectado.'), findsOneWidget);
    expect(find.text('Entrar na minha conta'), findsOneWidget);
    expect(find.text('Criar minha conta'), findsOneWidget);

    await tester.tap(find.text('Criar minha conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CreateAccountMobile), findsOneWidget);
    expect(find.text('Crie seu espaço'), findsOneWidget);
  });

  testWidgets('login mobile renders fields and validation in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const LoginPageMobile());

    expect(_scaffoldBackground(tester), SixMobilePalette.brandNavyDeep);
    expect(find.byType(TextField), findsNWidgets(2));
    final Finder loginButtonText = find.text('Entrar', skipOffstage: false);
    expect(loginButtonText, findsOneWidget);

    final TextField firstField = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(
      firstField.decoration?.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );
    expect(firstField.cursorColor, SixMobilePalette.brandBlue);

    await tester.scrollUntilVisible(
      loginButtonText,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(loginButtonText);
    await tester.pump();

    expect(find.text('Por favor, preencha o e-mail e a senha'), findsOneWidget);
  });

  testWidgets('login account action skips the removed signup onboarding', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const LoginPageMobile());

    final Finder createAccount = find.text(
      'Criar minha conta',
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      createAccount,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(createAccount);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CreateAccountMobile), findsOneWidget);
    expect(find.text('Crie seu espaço'), findsOneWidget);
  });

  testWidgets('create account mobile renders form controls in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const CreateAccountMobile());

    expect(_scaffoldBackground(tester), SixMobilePalette.brandNavyDeep);
    expect(find.text('Crie seu espaço'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Criar conta'), findsOneWidget);

    final TextField firstField = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(
      firstField.decoration?.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );
    expect(firstField.style?.color, SixMobileColorScheme.dark.titleText);
  });

  testWidgets('forgot password keeps validation readable in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const EsqueceuSenhaMobile());

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);

    final TextField emailField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(
      emailField.decoration?.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Enviar código de verificação'),
    );
    await tester.pump();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
  });

  testWidgets(
    'recovery code screen renders OTP fields and validation in dark mode',
    (WidgetTester tester) async {
      await _pumpMobileScreen(
        tester,
        const VerificarCodigoRecuperacaoMobile(email: 'cliente@six.app'),
      );

      expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
      expect(find.text('Verificar código'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));

      final TextField firstOtpField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(
        firstOtpField.decoration?.fillColor,
        SixMobileColorScheme.dark.softSurface,
      );
      expect(firstOtpField.style?.color, SixMobileColorScheme.dark.titleText);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verificar'));
      await tester.pump();

      expect(find.text('Digite os 6 dígitos do código'), findsOneWidget);
    },
  );

  testWidgets(
    'new password screen keeps fields and validation readable in dark mode',
    (WidgetTester tester) async {
      await _pumpMobileScreen(
        tester,
        const NovaSenhaMobile(email: 'cliente@six.app', codigo: '123456'),
      );

      expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
      expect(find.text('Nova senha'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(2));

      final TextField firstPasswordField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(
        firstPasswordField.decoration?.fillColor,
        SixMobileColorScheme.dark.softSurface,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Redefinir senha'));
      await tester.pump();

      expect(find.text('Preencha todos os campos'), findsOneWidget);
    },
  );

  testWidgets(
    'created account confirmation uses dark surface and accessible action',
    (WidgetTester tester) async {
      await _pumpMobileScreen(tester, const ContaCriadaMobile());

      expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
      expect(find.text('Tudo certo!'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Ir para o login'),
        findsOneWidget,
      );
    },
  );
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpMobileScreen(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 860);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  SixThemeResolver().atualizarTema(TemaSistema.escuro);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: _testSupportedLocales,
      localizationsDelegates: _testLocalizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: child,
    ),
  );
  await tester.pump();
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}
