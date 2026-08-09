import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/produto_cadastrar_mobile_screen.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets(
    'product list renders cards and status chips with dark surfaces',
    (WidgetTester tester) async {
      await _pumpCatalog(
        tester,
        products: <ProdutoModel>[
          _produto(id: 'p1', nome: 'Cabo USB', ativo: true),
          _produto(id: 'p2', nome: 'Carregador', ativo: false),
        ],
      );

      expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
      expect(find.text('Cabo USB'), findsOneWidget);
      expect(find.text('Carregador'), findsOneWidget);
      expect(
        _hasMaterialAncestorColor(
          tester,
          find.text('Cabo USB'),
          SixMobileColorScheme.dark.surface,
        ),
        isTrue,
      );
      expect(
        _hasDecoratedAncestorColor(
          tester,
          find.text('Ativo'),
          const Color(0xFF052E1A),
        ),
        isTrue,
      );
      expect(
        _hasDecoratedAncestorColor(
          tester,
          find.text('Inativo'),
          const Color(0xFF450A0A),
        ),
        isTrue,
      );
    },
  );

  testWidgets('product search and sort sheet keep dark mode tokens', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      products: <ProdutoModel>[_produto(id: 'p1', nome: 'Cabo USB')],
    );

    await tester.tap(find.byTooltip('Buscar produtos'));
    await tester.pump();

    expect(find.text('Buscar produto ou código'), findsOneWidget);
    final TextField searchField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(searchField.style?.color, SixMobileColorScheme.dark.titleText);

    await tester.tap(find.byTooltip('Ordenar catálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Organizar catálogo'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Organizar catálogo'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('empty product list uses dark empty state', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(tester, products: <ProdutoModel>[]);

    expect(find.text('Nenhum item encontrado.'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhum item encontrado.'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('product loading overlay follows dark background', (
    WidgetTester tester,
  ) async {
    final Completer<List<ProdutoModel>> completer =
        Completer<List<ProdutoModel>>();

    await _pumpCatalogWithFetch(
      tester,
      fetch: (_) => completer.future,
      settle: false,
    );
    await tester.pump();

    final Finder loading = find.byKey(
      const ValueKey<String>('catalog-loading-visible'),
    );
    expect(loading, findsOneWidget);

    final ColoredBox overlay = tester.widget<ColoredBox>(
      find.descendant(of: loading, matching: find.byType(ColoredBox)),
    );
    expect(overlay.color, SixMobileColorScheme.dark.background);

    completer.complete(<ProdutoModel>[]);
    await tester.pump();
  });

  testWidgets('product list renders cards and status chips in light mode', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      brightness: Brightness.light,
      products: <ProdutoModel>[
        _produto(id: 'p1', nome: 'Cabo USB', ativo: true),
        _produto(id: 'p2', nome: 'Carregador', ativo: false),
      ],
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    expect(find.text('Cabo USB'), findsOneWidget);
    expect(find.text('Carregador'), findsOneWidget);
    expect(
      _hasMaterialAncestorColor(
        tester,
        find.text('Cabo USB'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Ativo'),
        const Color(0xFFEAF8EE),
      ),
      isTrue,
    );
    expect(_hasTextWithColor(tester, 'Ativo', const Color(0xFF16A34A)), isTrue);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Inativo'),
        const Color(0xFFFEF2F2),
      ),
      isTrue,
    );
    expect(
      _hasTextWithColor(tester, 'Inativo', const Color(0xFFDC2626)),
      isTrue,
    );
  });

  testWidgets('product search and sort sheet keep light mode tokens', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      brightness: Brightness.light,
      products: <ProdutoModel>[_produto(id: 'p1', nome: 'Cabo USB')],
    );

    await tester.tap(find.byTooltip('Buscar produtos'));
    await tester.pump();

    expect(find.text('Buscar produto ou código'), findsOneWidget);
    final TextField searchField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(searchField.style?.color, SixMobileColorScheme.light.titleText);

    await tester.tap(find.byTooltip('Ordenar catálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Organizar catálogo'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Organizar catálogo'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
  });

  testWidgets('empty product list uses light empty state', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      brightness: Brightness.light,
      products: <ProdutoModel>[],
    );

    expect(find.text('Nenhum item encontrado.'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhum item encontrado.'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
  });

  testWidgets('product loading overlay follows light background', (
    WidgetTester tester,
  ) async {
    final Completer<List<ProdutoModel>> completer =
        Completer<List<ProdutoModel>>();

    await _pumpCatalogWithFetch(
      tester,
      brightness: Brightness.light,
      fetch: (_) => completer.future,
      settle: false,
    );
    await tester.pump();

    final Finder loading = find.byKey(
      const ValueKey<String>('catalog-loading-visible'),
    );
    expect(loading, findsOneWidget);

    final ColoredBox overlay = tester.widget<ColoredBox>(
      find.descendant(of: loading, matching: find.byType(ColoredBox)),
    );
    expect(overlay.color, SixMobileColorScheme.light.background);

    completer.complete(<ProdutoModel>[]);
    await tester.pump();
  });

  testWidgets('product error state uses light surface and retry action', (
    WidgetTester tester,
  ) async {
    await _pumpCatalogWithFetch(
      tester,
      brightness: Brightness.light,
      fetch: (_) async => throw StateError('offline'),
    );

    expect(find.text('Não foi possível carregar o catálogo.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Não foi possível carregar o catálogo.'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
  });

  testWidgets('product create form and category sheet use dark mode tokens', (
    WidgetTester tester,
  ) async {
    await _pumpProductForm(
      tester,
      categories: const <CategoriaCatalogoModel>[
        CategoriaCatalogoModel(
          id: 'cat-1',
          idUnicoDaEmpresa: 'empresa-test',
          nome: 'Peças',
          descricao: 'Itens físicos',
          tipo: 'PRODUTO',
          ativo: true,
          itensVinculados: 0,
        ),
      ],
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Cadastrar produto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dados principais', skipOffstage: false),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dados principais'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);

    final Finder firstFormField = find.byType(TextFormField).first;
    final EditableText editableText = tester.widget<EditableText>(
      find
          .descendant(of: firstFormField, matching: find.byType(EditableText))
          .first,
    );
    final InputDecorator inputDecorator = tester.widget<InputDecorator>(
      find
          .descendant(of: firstFormField, matching: find.byType(InputDecorator))
          .first,
    );
    expect(editableText.cursorColor, SixMobileColorScheme.dark.accent);
    expect(editableText.style.color, SixMobileColorScheme.dark.titleText);
    expect(
      inputDecorator.decoration.fillColor,
      SixMobileColorScheme.dark.surface,
    );

    await tester.scrollUntilVisible(
      find.text('Sem categoria', skipOffstage: false),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 96));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Sem categoria'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Selecionar categoria'), findsOneWidget);
    expect(find.text('Peças'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Selecionar categoria'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
    final TextField sheetSearch = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(
      sheetSearch.decoration?.fillColor,
      SixMobileColorScheme.dark.softSurface,
    );
    expect(sheetSearch.style?.color, SixMobileColorScheme.dark.titleText);
  });

  testWidgets('product create form and category sheet use light mode tokens', (
    WidgetTester tester,
  ) async {
    await _pumpProductForm(
      tester,
      brightness: Brightness.light,
      categories: const <CategoriaCatalogoModel>[
        CategoriaCatalogoModel(
          id: 'cat-1',
          idUnicoDaEmpresa: 'empresa-test',
          nome: 'Peças',
          descricao: 'Itens físicos',
          tipo: 'PRODUTO',
          ativo: true,
          itensVinculados: 0,
        ),
      ],
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    expect(find.text('Cadastrar produto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dados principais', skipOffstage: false),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dados principais'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);

    final Finder firstFormField = find.byType(TextFormField).first;
    final EditableText editableText = tester.widget<EditableText>(
      find
          .descendant(of: firstFormField, matching: find.byType(EditableText))
          .first,
    );
    final InputDecorator inputDecorator = tester.widget<InputDecorator>(
      find
          .descendant(of: firstFormField, matching: find.byType(InputDecorator))
          .first,
    );
    expect(editableText.cursorColor, SixMobileColorScheme.light.accent);
    expect(editableText.style.color, SixMobileColorScheme.light.titleText);
    expect(
      inputDecorator.decoration.fillColor,
      SixMobileColorScheme.light.surface,
    );

    await tester.scrollUntilVisible(
      find.text('Sem categoria', skipOffstage: false),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 96));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Sem categoria'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Selecionar categoria'), findsOneWidget);
    expect(find.text('Peças'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Selecionar categoria'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
    final TextField sheetSearch = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(
      sheetSearch.decoration?.fillColor,
      SixMobileColorScheme.light.softSurface,
    );
    expect(sheetSearch.style?.color, SixMobileColorScheme.light.titleText);
  });
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpCatalog(
  WidgetTester tester, {
  required List<ProdutoModel> products,
  Brightness brightness = Brightness.dark,
}) {
  return _pumpCatalogWithFetch(
    tester,
    brightness: brightness,
    fetch: (_) async => products,
  );
}

Future<void> _pumpCatalogWithFetch(
  WidgetTester tester, {
  required Future<List<ProdutoModel>> Function(Map<String, String>? headers)
  fetch,
  bool settle = true,
  Brightness brightness = Brightness.dark,
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

  final ProdutosListProvider<ProdutoModel> provider =
      ProdutosListProvider<ProdutoModel>(fetchFunction: fetch);

  await tester.pumpWidget(
    ChangeNotifierProvider<ProdutosListProvider<ProdutoModel>>.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const ProdutolistMobileScreen(),
      ),
    ),
  );

  await tester.pump();
  if (settle) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpProductForm(
  WidgetTester tester, {
  required List<CategoriaCatalogoModel> categories,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final bool isDark = brightness == Brightness.dark;
  SixThemeResolver().atualizarTema(
    isDark ? TemaSistema.escuro : TemaSistema.claro,
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>(
      create:
          (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _FakeRegionalizacaoApiClient(),
            ),
          ),
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: CadastroProdutoMobileScreen(
          categoriaApiClient: _FakeCategoriaCatalogoApiClient(categories),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

ProdutoModel _produto({
  required String id,
  required String nome,
  bool ativo = true,
}) {
  return ProdutoModel(
    id: id,
    ativo: ativo,
    codigoDeBarras: 'COD-$id',
    nomeProduto: nome,
    tipoProduto: 'PRODUTO',
    modeloProduto: 'UN',
    estoqueMaximo: 10,
    estoqueMinimo: 1,
    precoVenda: 19.9,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
  );
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasMaterialAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Material>(
        find.ancestor(of: child, matching: find.byType(Material)),
      )
      .any((Material material) => material.color == expected);
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

bool _hasTextWithColor(WidgetTester tester, String text, Color color) {
  return tester
      .widgetList<Text>(find.text(text))
      .any((Text widget) => widget.style?.color == color);
}

class _FakeCategoriaCatalogoApiClient implements CategoriaCatalogoApiClient {
  const _FakeCategoriaCatalogoApiClient(this._categories);

  final List<CategoriaCatalogoModel> _categories;

  @override
  Future<CategoriaCatalogoListResponse> listarCategorias() async {
    return CategoriaCatalogoListResponse(
      idUnicoDaEmpresa: 'empresa-test',
      total: _categories.length,
      categorias: _categories,
    );
  }

  @override
  Future<CategoriaCatalogoModel> cadastrarCategoria(
    CategoriaCatalogoRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CategoriaCatalogoModel> atualizarCategoria(
    String idCategoria,
    CategoriaCatalogoRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> apagarCategoria(String idCategoria) {
    throw UnimplementedError();
  }
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() {
    throw UnimplementedError();
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) {
    throw UnimplementedError();
  }
}
