import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/auth_entry_mobile.dart';
import 'package:sixpos/presentation/screens/conta_criada_mobile.dart';
import 'package:sixpos/presentation/screens/create_account_mobile.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_mobile.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/presentation/screens/nova_senha_mobile.dart';
import 'package:sixpos/presentation/screens/signup_onboarding_mobile.dart';
import 'package:sixpos/presentation/screens/verificar_codigo_recuperacao_mobile.dart';

void main() {
  setUp(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('auth entry mobile keeps choice cards readable in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const AuthEntryMobile());

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Bem-vindo ao Six'), findsOneWidget);
    expect(find.text('Já tenho uma conta'), findsOneWidget);
    expect(find.text('Sou novo por aqui'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Já tenho uma conta'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('login mobile renders fields and validation in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const LoginPageMobile());

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.byType(TextField), findsNWidgets(2));
    final Finder continueButtonText = find.text(
      'Continuar',
      skipOffstage: false,
    );
    expect(continueButtonText, findsOneWidget);

    final TextField firstField = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(
      firstField.decoration?.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );
    expect(firstField.cursorColor, SixMobileColorScheme.dark.accent);

    await tester.scrollUntilVisible(
      continueButtonText,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Por favor, preencha o e-mail e a senha'), findsOneWidget);
  });

  testWidgets('signup onboarding mobile keeps cards readable in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const SignupOnboardingMobile());

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Comece pelo essencial'), findsOneWidget);
    expect(find.text('Atendimento organizado'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Atendimento organizado'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('create account mobile renders form controls in dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpMobileScreen(tester, const CreateAccountMobile());

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);

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

bool _hasDecoratedAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Container>(
        find.ancestor(of: child, matching: find.byType(Container)),
      )
      .any((Container container) {
        final Decoration? decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == expected;
      });
}
