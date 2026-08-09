import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';

void main() {
  setUp(() {
    NotificacaoService().limpar();
  });

  tearDown(() {
    NotificacaoService().limpar();
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('notifications empty state uses dark themed surface', (
    WidgetTester tester,
  ) async {
    await _pumpNotifications(tester);

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Nenhuma mensagem recebida ainda'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhuma mensagem recebida ainda'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('notifications empty state uses light themed surface', (
    WidgetTester tester,
  ) async {
    await _pumpNotifications(tester, brightness: Brightness.light);

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    expect(find.text('Nenhuma mensagem recebida ainda'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhuma mensagem recebida ainda'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
  });

  for (final _ThemeCase themeCase in <_ThemeCase>[
    _ThemeCase(
      description: 'light',
      brightness: Brightness.light,
      readSurface: SixMobileColorScheme.light.surface,
      unreadSurface: SixMobileColorScheme.light.surfaceElevated,
      readBorder: SixMobileColorScheme.light.border,
      unreadBorder: SixMobileColorScheme.light.accent.withValues(alpha: 0.58),
      errorColor: SixMobileColorScheme.light.error,
    ),
    _ThemeCase(
      description: 'dark',
      brightness: Brightness.dark,
      readSurface: SixMobileColorScheme.dark.surface,
      unreadSurface: SixMobileColorScheme.dark.surfaceElevated,
      readBorder: SixMobileColorScheme.dark.border,
      unreadBorder: SixMobileColorScheme.dark.accent.withValues(alpha: 0.58),
      errorColor: SixMobileColorScheme.dark.error,
    ),
  ]) {
    testWidgets(
      'read and unread notifications remain distinct in ${themeCase.description} mode',
      (WidgetTester tester) async {
        NotificacaoService().registrarPayload(_payload('Mensagem lida'));
        NotificacaoService().marcarTodasComoLidas();
        NotificacaoService().registrarPayload(_payload('Mensagem nova'));

        await _pumpNotifications(
          tester,
          brightness: themeCase.brightness,
          child: const NotificacoesMobileScreen(marcarComoLidasAoAbrir: false),
        );

        expect(find.text('Mensagem lida'), findsOneWidget);
        expect(find.text('Mensagem nova'), findsOneWidget);
        expect(_unreadBadgeFinder(), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Mensagem lida'),
            themeCase.readSurface,
          ),
          isTrue,
        );
        expect(
          _hasDecoratedAncestorBorderColor(
            tester,
            find.text('Mensagem lida'),
            themeCase.readBorder,
          ),
          isTrue,
        );
        expect(
          _hasDecoratedAncestorBorderColor(
            tester,
            find.text('Mensagem nova'),
            themeCase.unreadBorder,
          ),
          isTrue,
        );
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Mensagem nova'),
            themeCase.unreadSurface,
          ),
          isTrue,
        );

        await tester.tap(find.text('Mensagem nova'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 220));

        expect(find.text('Entidade'), findsOneWidget);
        final BottomSheet sheet = tester.widget<BottomSheet>(
          find.byType(BottomSheet).last,
        );
        expect(sheet.backgroundColor, themeCase.readSurface);
      },
    );
  }

  testWidgets(
    'unread notification keeps visible non-color indicator in dark mode',
    (WidgetTester tester) async {
      await _pumpNotifications(
        tester,
        child: const NotificacoesMobileScreen(marcarComoLidasAoAbrir: false),
      );

      NotificacaoService().registrarPayload(_payload('Venda nova'));
      await tester.pump();

      expect(find.text('Venda nova'), findsOneWidget);
      expect(
        _hasDecoratedAncestorColor(
          tester,
          find.text('Venda nova'),
          SixMobileColorScheme.dark.surfaceElevated,
        ),
        isTrue,
      );
    },
  );

  testWidgets('read notification detail bottom sheet uses light mode tokens', (
    WidgetTester tester,
  ) async {
    NotificacaoService().registrarPayload(_payload('Venda conferida'));
    NotificacaoService().marcarTodasComoLidas();

    await _pumpNotifications(tester, brightness: Brightness.light);

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    expect(find.text('Venda conferida'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Venda conferida'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );

    await tester.tap(find.text('Venda conferida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Entidade'), findsOneWidget);
    final BottomSheet sheet = tester.widget<BottomSheet>(
      find.byType(BottomSheet).last,
    );
    expect(sheet.backgroundColor, SixMobileColorScheme.light.surface);
  });

  for (final _ThemeCase themeCase in <_ThemeCase>[
    _ThemeCase(
      description: 'light',
      brightness: Brightness.light,
      readSurface: SixMobileColorScheme.light.surface,
      unreadSurface: SixMobileColorScheme.light.surfaceElevated,
      readBorder: SixMobileColorScheme.light.border,
      unreadBorder: SixMobileColorScheme.light.accent.withValues(alpha: 0.58),
      errorColor: SixMobileColorScheme.light.error,
    ),
    _ThemeCase(
      description: 'dark',
      brightness: Brightness.dark,
      readSurface: SixMobileColorScheme.dark.surface,
      unreadSurface: SixMobileColorScheme.dark.surfaceElevated,
      readBorder: SixMobileColorScheme.dark.border,
      unreadBorder: SixMobileColorScheme.dark.accent.withValues(alpha: 0.58),
      errorColor: SixMobileColorScheme.dark.error,
    ),
  ]) {
    testWidgets(
      'error notification remains semantic in ${themeCase.description} mode',
      (WidgetTester tester) async {
        NotificacaoService().registrarPayload(
          _payload('Falha no pedido', status: 'ERRO_PROCESSAMENTO'),
        );

        await _pumpNotifications(
          tester,
          brightness: themeCase.brightness,
          child: const NotificacoesMobileScreen(marcarComoLidasAoAbrir: false),
        );

        expect(find.text('ERRO_PROCESSAMENTO'), findsOneWidget);
        expect(
          _hasTextWithColor(tester, 'ERRO_PROCESSAMENTO', themeCase.errorColor),
          isTrue,
        );
      },
    );
  }
}

class _ThemeCase {
  const _ThemeCase({
    required this.description,
    required this.brightness,
    required this.readSurface,
    required this.unreadSurface,
    required this.readBorder,
    required this.unreadBorder,
    required this.errorColor,
  });

  final String description;
  final Brightness brightness;
  final Color readSurface;
  final Color unreadSurface;
  final Color readBorder;
  final Color unreadBorder;
  final Color errorColor;
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpNotifications(
  WidgetTester tester, {
  Brightness brightness = Brightness.dark,
  Widget child = const NotificacoesMobileScreen(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 860);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final bool isDark = brightness == Brightness.dark;
  SixThemeResolver().atualizarTema(
    isDark ? TemaSistema.escuro : TemaSistema.claro,
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: _testSupportedLocales,
      localizationsDelegates: _testLocalizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
}

Map<String, dynamic> _payload(String title, {String status = 'NOVA'}) {
  return <String, dynamic>{
    'tipoDeEvento': 'NOVA_VENDA',
    'titulo': title,
    'mensagem': 'Pedido recebido pelo canal digital.',
    'canal': 'WEBSOCKET',
    'status': status,
    'idOperacao': title,
    'numeroOperacao': '42',
    'recebidoEmIso': DateTime(2026, 8, 8, 10, 30).toIso8601String(),
  };
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasTextWithColor(WidgetTester tester, String text, Color color) {
  return tester
      .widgetList<Text>(find.text(text))
      .any((Text widget) => widget.style?.color == color);
}

Finder _unreadBadgeFinder() {
  return find.byWidgetPredicate((Widget widget) {
    return widget is Semantics &&
        widget.properties.label == 'Notificação não lida';
  });
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

bool _hasDecoratedAncestorBorderColor(
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
        final BoxBorder? border =
            decoration is BoxDecoration ? decoration.border : null;
        return border is Border && border.top.color == expected;
      });
}
