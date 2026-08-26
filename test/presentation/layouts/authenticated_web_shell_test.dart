import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/sixoapp_brand_mark.dart';
import 'package:sixpos/presentation/layouts/authenticated_web_shell.dart';
import 'package:sixpos/presentation/layouts/web_header.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_navigation_registry.dart';
import 'package:sixpos/presentation/navigation/web_sidebar_navigation.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  group('AuthenticatedWebShell', () {
    testWidgets('renderiza a navegacao ativa do registry sem relatorios', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();

      await _pumpShell(tester, actions: actions);

      expect(find.text('Início'), findsWidgets);
      expect(find.text('Operações'), findsWidgets);
      expect(find.text('Catálogo'), findsWidgets);
      expect(find.text('Pessoas'), findsWidgets);
      expect(find.text('Financeiro'), findsWidgets);
      expect(find.text('Configurações'), findsWidgets);
      expect(find.text('Relatórios'), findsNothing);
      expect(find.text('SixoApp'), findsOneWidget);
      expect(find.byType(SixoAppBrandMark), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Title && widget.title == 'Início · SixoApp',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('web-shell-content')), findsOneWidget);

      await tester.tap(find.text('Operações'));
      await tester.pumpAndSettle();

      expect(find.text('Caixa'), findsWidgets);
    });

    testWidgets(
      'aciona destino filho usando WebNavigationDestinationResolver',
      (WidgetTester tester) async {
        final _RecordingActions actions = _RecordingActions();

        await _pumpShell(tester, actions: actions);

        await tester.tap(find.text('Catálogo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Produtos'));
        await tester.pumpAndSettle();

        expect(actions.calls, <WebNavigationDestination>[
          WebNavigationDestination.catalogProducts,
        ]);
      },
    );

    testWidgets('mantem acesso a filhos quando a Sidebar esta recolhida', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();

      await _pumpShell(tester, actions: actions);

      await tester.tap(find.byIcon(Icons.menu_open_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo'), findsNothing);

      await tester.tap(find.byIcon(Icons.view_module_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estoque'));
      await tester.pumpAndSettle();

      expect(actions.calls, <WebNavigationDestination>[
        WebNavigationDestination.catalogStock,
      ]);
    });

    testWidgets('renderiza sem excecao nas larguras Web de referencia', (
      WidgetTester tester,
    ) async {
      for (final Size size in _responsiveValidationSizes) {
        final _RecordingActions actions = _RecordingActions();
        await _pumpShell(tester, actions: actions, size: size);

        expect(tester.takeException(), isNull, reason: size.toString());
      }
    });

    testWidgets('usa Sidebar expandida ou recolhida conforme largura', (
      WidgetTester tester,
    ) async {
      const List<_SidebarSizeExpectation> expectations =
          <_SidebarSizeExpectation>[
            _SidebarSizeExpectation(Size(1280, 720), expanded: true),
            _SidebarSizeExpectation(Size(1366, 768), expanded: true),
            _SidebarSizeExpectation(Size(1440, 900), expanded: true),
            _SidebarSizeExpectation(Size(1920, 1080), expanded: true),
            _SidebarSizeExpectation(Size(1024, 768), expanded: false),
            _SidebarSizeExpectation(Size(920, 768), expanded: false),
          ];

      for (final _SidebarSizeExpectation expectation in expectations) {
        final _RecordingActions actions = _RecordingActions();
        await _pumpShell(tester, actions: actions, size: expectation.size);

        final WebSidebarNavigation sidebar = tester.widget(
          find.byType(WebSidebarNavigation),
        );
        expect(
          sidebar.expanded,
          expectation.expanded,
          reason: expectation.size.toString(),
        );
      }
    });

    testWidgets('mantem acesso a filhos em 920px', (WidgetTester tester) async {
      final _RecordingActions actions = _RecordingActions();

      await _pumpShell(tester, actions: actions, size: const Size(920, 768));

      final WebSidebarNavigation sidebar = tester.widget(
        find.byType(WebSidebarNavigation),
      );
      expect(sidebar.expanded, isFalse);
      expect(find.text('Catálogo'), findsNothing);

      await tester.tap(find.byIcon(Icons.view_module_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Serviços'));
      await tester.pumpAndSettle();

      expect(actions.calls, <WebNavigationDestination>[
        WebNavigationDestination.catalogServices,
      ]);
    });

    testWidgets(
      'mantem Configuracoes acessivel no rodape mesmo com grupos expandidos',
      (WidgetTester tester) async {
        final _RecordingActions actions = _RecordingActions();

        await _pumpShell(tester, actions: actions, size: const Size(1366, 768));

        for (final String groupLabel in <String>[
          'Operações',
          'Catálogo',
          'Pessoas',
          'Financeiro',
        ]) {
          await tester.tap(find.text(groupLabel));
          await tester.pumpAndSettle();
        }

        expect(
          find.descendant(
            of: find.byKey(const Key('web-sidebar-footer')),
            matching: find.text('Configurações'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('web-sidebar-main-scroll')),
            matching: find.text('Configurações'),
          ),
          findsNothing,
        );

        await tester.tap(find.text('Configurações'));
        await tester.pumpAndSettle();

        expect(actions.calls, <WebNavigationDestination>[
          WebNavigationDestination.settings,
        ]);
      },
    );

    testWidgets('atualiza o titulo ativo ao navegar entre destinos', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const _InteractiveShellTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Produtos'));
      await tester.pumpAndSettle();
      expect(_headerTitle('Produtos'), findsOneWidget);

      await tester.tap(find.text('Estoque'));
      await tester.pumpAndSettle();
      expect(_headerTitle('Estoque'), findsOneWidget);

      await tester.tap(find.text('Pessoas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();
      expect(_headerTitle('Clientes'), findsOneWidget);

      await tester.tap(find.text('Operações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caixa'));
      await tester.pumpAndSettle();
      expect(_headerTitle('Caixa'), findsWidgets);

      await tester.tap(
        find
            .descendant(
              of: find.byType(WebSidebarNavigation),
              matching: find.text('Início'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(_headerTitle('Início'), findsOneWidget);
    });

    testWidgets('renderiza em Light e Dark Mode sem excecao', (
      WidgetTester tester,
    ) async {
      for (final ThemeMode themeMode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final _RecordingActions actions = _RecordingActions();
        await _pumpShell(tester, actions: actions, themeMode: themeMode);

        expect(tester.takeException(), isNull, reason: themeMode.name);
        expect(find.byType(WebHeader), findsOneWidget);
        expect(find.byType(WebSidebarNavigation), findsOneWidget);
      }
    });

    testWidgets('aplica tokens Web no Shell, Header e Sidebar', (
      WidgetTester tester,
    ) async {
      for (final ThemeMode themeMode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final ThemeData theme =
            themeMode == ThemeMode.dark
                ? ThemeData.dark(useMaterial3: true)
                : ThemeData.light(useMaterial3: true);
        final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
        final _RecordingActions actions = _RecordingActions();

        await _pumpShell(tester, actions: actions, themeMode: themeMode);

        expect(
          _animatedContainerColor(tester, const Key('web-shell-workspace')),
          tokens.workspaceBackground,
        );
        expect(
          _animatedContainerColor(tester, const Key('web-sidebar-container')),
          tokens.sidebarBackground,
        );
        expect(
          _animatedContainerColor(tester, const Key('web-header-container')),
          tokens.headerBackground,
        );
      }
    });

    testWidgets('usa tokens no item selecionado da Sidebar expandida', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();
      final WebThemeTokens tokens = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      await _pumpShell(
        tester,
        actions: actions,
        themeMode: ThemeMode.dark,
        activeDestination: WebNavigationDestination.catalogProducts,
      );

      final AnimatedContainer selectedTile = tester.widget(
        find.byKey(const ValueKey<String>('web-sidebar-tile-Produtos')),
      );
      final BoxDecoration decoration =
          selectedTile.decoration! as BoxDecoration;

      expect(decoration.color, tokens.selectedBackground);
      expect(decoration.border, isNotNull);
    });

    testWidgets('usa tokens no item selecionado da Sidebar recolhida', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();
      final WebThemeTokens tokens = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      await _pumpShell(
        tester,
        actions: actions,
        themeMode: ThemeMode.dark,
        size: const Size(920, 768),
        activeDestination: WebNavigationDestination.catalogProducts,
      );

      final WebSidebarNavigation sidebar = tester.widget(
        find.byType(WebSidebarNavigation),
      );
      final AnimatedContainer selectedIcon = tester.widget(
        find.byKey(
          ValueKey<String>(
            'web-sidebar-icon-${Icons.view_module_outlined.codePoint}',
          ),
        ),
      );
      final BoxDecoration decoration =
          selectedIcon.decoration! as BoxDecoration;

      expect(sidebar.expanded, isFalse);
      expect(decoration.color, tokens.selectedBackground);
    });

    testWidgets('preserva grupo aberto, recolhimento e child ao trocar tema', (
      WidgetTester tester,
    ) async {
      int childMounts = 0;

      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        _ThemeSwitchingShellTestApp(onChildMounted: () => childMounts++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Produtos'), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggle-theme')));
      await tester.pumpAndSettle();
      expect(find.text('Produtos'), findsOneWidget);
      expect(childMounts, 1);

      await tester.tap(find.byIcon(Icons.menu_open_rounded));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<WebSidebarNavigation>(find.byType(WebSidebarNavigation))
            .expanded,
        isFalse,
      );

      await tester.tap(find.byKey(const Key('toggle-theme')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<WebSidebarNavigation>(find.byType(WebSidebarNavigation))
            .expanded,
        isFalse,
      );
      expect(childMounts, 1);
    });

    testWidgets('preserva grupos da Sidebar ao alternar PDV expandido', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const _ExpandedPdvShellTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Produtos'), findsOneWidget);

      await tester.tap(find.byKey(const Key('enter-pdv-expanded')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pdv-expanded-overlay')), findsOneWidget);

      final _ExpandedPdvShellTestAppState state = tester.state(
        find.byType(_ExpandedPdvShellTestApp),
      );
      state.exitExpandedMode();
      await tester.pumpAndSettle();
      expect(find.text('Produtos'), findsOneWidget);
    });

    testWidgets('possui traducoes locais da navegacao em pt, en e es', (
      WidgetTester tester,
    ) async {
      for (final Locale locale in const <Locale>[
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ]) {
        late BuildContext probeContext;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const <Locale>[
              Locale('pt'),
              Locale('en'),
              Locale('es'),
            ],
            home: Builder(
              builder: (BuildContext context) {
                probeContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final String key in _webShellI18nKeys) {
          expect(
            probeContext.t(key),
            isNot(key),
            reason: '${locale.languageCode}: $key',
          );
        }
      }
    });

    testWidgets('prefere traducao local antes do labelFallback do item', (
      WidgetTester tester,
    ) async {
      final _RecordingActions actions = _RecordingActions();

      await _pumpShell(
        tester,
        actions: actions,
        navigationItems: const <WebNavigationItem>[
          WebNavigationItem(
            id: 'test.home',
            labelKey: 'web.navigation.home',
            labelFallback: 'Fallback temporario',
            icon: Icons.home_outlined,
            visibility: WebNavigationVisibilityRule.authenticated(),
            destination: WebNavigationDestination.home,
          ),
        ],
      );

      expect(find.text('Início'), findsWidgets);
      expect(find.text('Fallback temporario'), findsNothing);
    });
  });
}

const List<Size> _responsiveValidationSizes = <Size>[
  Size(1280, 720),
  Size(1366, 768),
  Size(1440, 900),
  Size(1920, 1080),
  Size(1024, 768),
  Size(920, 768),
];

const List<String> _webShellI18nKeys = <String>[
  'app.title',
  'web.navigation.home',
  'web.navigation.operations',
  'web.navigation.operations.pos',
  'web.navigation.operations.technicalService',
  'web.navigation.operations.reservations',
  'web.navigation.catalog',
  'web.navigation.catalog.products',
  'web.navigation.catalog.services',
  'web.navigation.catalog.stock',
  'web.navigation.catalog.categories',
  'web.navigation.people',
  'web.navigation.people.customers',
  'web.navigation.people.collaborators',
  'web.navigation.people.performance',
  'web.navigation.cash',
  'web.navigation.financial',
  'web.navigation.financial.agenda',
  'web.navigation.settings',
  'web.navigation.reports',
  'web.navigation.unavailable',
  'web.shell.expandSidebar',
  'web.shell.collapseSidebar',
  'web.shell.currentCommerce',
  'web.shell.sessionContext',
  'web.shell.workspace',
  'web.shell.version',
  'web.header.profile',
  'web.header.profileTooltip',
  'web.header.userMenu',
  'web.header.myProfile',
  'web.header.theme.dark',
  'web.header.theme.dark.enable',
  'web.header.theme.dark.disable',
  'web.header.logout',
];

class _SidebarSizeExpectation {
  const _SidebarSizeExpectation(this.size, {required this.expanded});

  final Size size;
  final bool expanded;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required _RecordingActions actions,
  WebNavigationDestination activeDestination = WebNavigationDestination.home,
  Size size = const Size(1200, 800),
  ThemeMode themeMode = ThemeMode.light,
  List<WebNavigationItem>? navigationItems,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      locale: const Locale('pt'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ],
      home: Scaffold(
        body: AuthenticatedWebShell(
          navigationItems: navigationItems ?? WebNavigationRegistry.activeItems,
          resolver: WebNavigationDestinationResolver(actions: actions),
          activeDestination: activeDestination,
          appVersion: 'test',
          currentCommerceName: 'Comércio Teste',
          headerActions: const <Widget>[
            SizedBox(key: Key('header-action'), width: 24, height: 24),
          ],
          child: const SizedBox.expand(key: Key('web-shell-content')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _headerTitle(String text) {
  return find.descendant(of: find.byType(WebHeader), matching: find.text(text));
}

Color? _animatedContainerColor(WidgetTester tester, Key key) {
  final AnimatedContainer container = tester.widget(find.byKey(key));
  final Decoration? decoration = container.decoration;
  expect(decoration, isA<BoxDecoration>());
  return (decoration! as BoxDecoration).color;
}

class _InteractiveShellTestApp extends StatefulWidget {
  const _InteractiveShellTestApp();

  @override
  State<_InteractiveShellTestApp> createState() =>
      _InteractiveShellTestAppState();
}

class _InteractiveShellTestAppState extends State<_InteractiveShellTestApp> {
  WebNavigationDestination _activeDestination = WebNavigationDestination.home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      locale: const Locale('pt'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ],
      home: Scaffold(
        body: AuthenticatedWebShell(
          navigationItems: WebNavigationRegistry.activeItems,
          resolver: WebNavigationDestinationResolver(
            actions: _InteractiveActions(
              onDestination: (WebNavigationDestination destination) {
                setState(() {
                  _activeDestination = destination;
                });
              },
            ),
          ),
          activeDestination: _activeDestination,
          appVersion: 'test',
          currentCommerceName: 'Comércio Teste',
          child: const SizedBox.expand(key: Key('web-shell-content')),
        ),
      ),
    );
  }
}

class _ThemeSwitchingShellTestApp extends StatefulWidget {
  const _ThemeSwitchingShellTestApp({required this.onChildMounted});

  final VoidCallback onChildMounted;

  @override
  State<_ThemeSwitchingShellTestApp> createState() =>
      _ThemeSwitchingShellTestAppState();
}

class _ThemeSwitchingShellTestAppState
    extends State<_ThemeSwitchingShellTestApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      locale: const Locale('pt'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ],
      home: Scaffold(
        body: AuthenticatedWebShell(
          navigationItems: WebNavigationRegistry.activeItems,
          resolver: WebNavigationDestinationResolver(
            actions: _RecordingActions(),
          ),
          activeDestination: WebNavigationDestination.home,
          appVersion: 'test',
          currentCommerceName: 'Comércio Teste',
          headerActions: <Widget>[
            IconButton(
              key: const Key('toggle-theme'),
              onPressed: () {
                setState(() {
                  _themeMode =
                      _themeMode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                });
              },
              icon: const Icon(Icons.dark_mode_outlined),
            ),
          ],
          child: _MountCounterChild(onMounted: widget.onChildMounted),
        ),
      ),
    );
  }
}

class _ExpandedPdvShellTestApp extends StatefulWidget {
  const _ExpandedPdvShellTestApp();

  @override
  State<_ExpandedPdvShellTestApp> createState() =>
      _ExpandedPdvShellTestAppState();
}

class _ExpandedPdvShellTestAppState extends State<_ExpandedPdvShellTestApp> {
  bool _expanded = false;

  void exitExpandedMode() {
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      locale: const Locale('pt'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ],
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            Offstage(
              offstage: _expanded,
              child: TickerMode(
                enabled: !_expanded,
                child: IgnorePointer(
                  ignoring: _expanded,
                  child: AuthenticatedWebShell(
                    navigationItems: WebNavigationRegistry.activeItems,
                    resolver: WebNavigationDestinationResolver(
                      actions: _RecordingActions(),
                    ),
                    activeDestination:
                        WebNavigationDestination.operationsPointOfSale,
                    appVersion: 'test',
                    currentCommerceName: 'Comércio Teste',
                    headerActions: <Widget>[
                      IconButton(
                        key: const Key('enter-pdv-expanded'),
                        onPressed: () => setState(() => _expanded = true),
                        icon: const Icon(Icons.fullscreen_rounded),
                      ),
                    ],
                    child:
                        _expanded
                            ? const SizedBox.shrink(
                              key: Key('pdv-expanded-placeholder'),
                            )
                            : const SizedBox.expand(
                              key: Key('pdv-normal-content'),
                            ),
                  ),
                ),
              ),
            ),
            if (_expanded)
              Positioned.fill(
                child: Material(
                  key: const Key('pdv-expanded-overlay'),
                  child: Center(
                    child: FilledButton(
                      key: const Key('exit-pdv-expanded'),
                      onPressed: () => setState(() => _expanded = false),
                      child: const Text('Sair'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MountCounterChild extends StatefulWidget {
  const _MountCounterChild({required this.onMounted});

  final VoidCallback onMounted;

  @override
  State<_MountCounterChild> createState() => _MountCounterChildState();
}

class _MountCounterChildState extends State<_MountCounterChild> {
  @override
  void initState() {
    super.initState();
    widget.onMounted();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(key: Key('web-shell-content'));
  }
}

class _RecordingActions implements WebNavigationDestinationActions {
  final List<WebNavigationDestination> calls = <WebNavigationDestination>[];

  WebNavigationResolutionResult _record(WebNavigationDestination destination) {
    calls.add(destination);
    return WebNavigationResolutionResult.handled(destination);
  }

  @override
  WebNavigationResolutionResult openHome() {
    return _record(WebNavigationDestination.home);
  }

  @override
  WebNavigationResolutionResult openPointOfSale() {
    return _record(WebNavigationDestination.operationsPointOfSale);
  }

  @override
  WebNavigationResolutionResult openTechnicalServices() {
    return _record(WebNavigationDestination.operationsTechnicalServices);
  }

  @override
  WebNavigationResolutionResult openPurchases() {
    return _record(WebNavigationDestination.operationsPurchases);
  }

  @override
  WebNavigationResolutionResult openReservations() {
    return _record(WebNavigationDestination.operationsReservations);
  }

  @override
  WebNavigationResolutionResult openCatalogProducts() {
    return _record(WebNavigationDestination.catalogProducts);
  }

  @override
  WebNavigationResolutionResult openCatalogServices() {
    return _record(WebNavigationDestination.catalogServices);
  }

  @override
  WebNavigationResolutionResult openCatalogStock() {
    return _record(WebNavigationDestination.catalogStock);
  }

  @override
  WebNavigationResolutionResult openCatalogCategories() {
    return _record(WebNavigationDestination.catalogCategories);
  }

  @override
  WebNavigationResolutionResult openPeopleCustomers() {
    return _record(WebNavigationDestination.peopleCustomers);
  }

  @override
  WebNavigationResolutionResult openPeopleCollaborators() {
    return _record(WebNavigationDestination.peopleCollaborators);
  }

  @override
  WebNavigationResolutionResult openPeoplePerformance() {
    return _record(WebNavigationDestination.peoplePerformance);
  }

  @override
  WebNavigationResolutionResult openCash() {
    return _record(WebNavigationDestination.cash);
  }

  @override
  WebNavigationResolutionResult openFinancialAgenda() {
    return _record(WebNavigationDestination.financialAgenda);
  }

  @override
  WebNavigationResolutionResult openSettings() {
    return _record(WebNavigationDestination.settings);
  }
}

class _InteractiveActions implements WebNavigationDestinationActions {
  const _InteractiveActions({required this.onDestination});

  final ValueChanged<WebNavigationDestination> onDestination;

  WebNavigationResolutionResult _handle(WebNavigationDestination destination) {
    onDestination(destination);
    return WebNavigationResolutionResult.handled(destination);
  }

  @override
  WebNavigationResolutionResult openHome() {
    return _handle(WebNavigationDestination.home);
  }

  @override
  WebNavigationResolutionResult openPointOfSale() {
    return _handle(WebNavigationDestination.operationsPointOfSale);
  }

  @override
  WebNavigationResolutionResult openTechnicalServices() {
    return _handle(WebNavigationDestination.operationsTechnicalServices);
  }

  @override
  WebNavigationResolutionResult openPurchases() {
    return _handle(WebNavigationDestination.operationsPurchases);
  }

  @override
  WebNavigationResolutionResult openReservations() {
    return _handle(WebNavigationDestination.operationsReservations);
  }

  @override
  WebNavigationResolutionResult openCatalogProducts() {
    return _handle(WebNavigationDestination.catalogProducts);
  }

  @override
  WebNavigationResolutionResult openCatalogServices() {
    return _handle(WebNavigationDestination.catalogServices);
  }

  @override
  WebNavigationResolutionResult openCatalogStock() {
    return _handle(WebNavigationDestination.catalogStock);
  }

  @override
  WebNavigationResolutionResult openCatalogCategories() {
    return _handle(WebNavigationDestination.catalogCategories);
  }

  @override
  WebNavigationResolutionResult openPeopleCustomers() {
    return _handle(WebNavigationDestination.peopleCustomers);
  }

  @override
  WebNavigationResolutionResult openPeopleCollaborators() {
    return _handle(WebNavigationDestination.peopleCollaborators);
  }

  @override
  WebNavigationResolutionResult openPeoplePerformance() {
    return _handle(WebNavigationDestination.peoplePerformance);
  }

  @override
  WebNavigationResolutionResult openCash() {
    return _handle(WebNavigationDestination.cash);
  }

  @override
  WebNavigationResolutionResult openFinancialAgenda() {
    return _handle(WebNavigationDestination.financialAgenda);
  }

  @override
  WebNavigationResolutionResult openSettings() {
    return _handle(WebNavigationDestination.settings);
  }
}
