import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/estoque_dashboard_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_mobile_loading_scene.dart';
import 'package:sixpos/presentation/screens/estoque_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('stock dashboard loading follows dark theme', (
    WidgetTester tester,
  ) async {
    final Completer<EstoqueDashboardModel> completer =
        Completer<EstoqueDashboardModel>();

    await _pumpStock(
      tester,
      service: _FakeProdutoService(() => completer.future),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    final Finder loading = find.byType(SixoAppMobileLoadingScene);
    expect(loading, findsOneWidget);
    final ColoredBox background = tester.widget<ColoredBox>(
      find.descendant(of: loading, matching: find.byType(ColoredBox)),
    );
    expect(background.color, SixMobileColorScheme.dark.background);
    expect(find.text('SixoApp'), findsOneWidget);

    completer.complete(_emptyDashboard);
    await tester.pump();
  });

  testWidgets('stock dashboard loading follows light theme', (
    WidgetTester tester,
  ) async {
    final Completer<EstoqueDashboardModel> completer =
        Completer<EstoqueDashboardModel>();

    await _pumpStock(
      tester,
      brightness: Brightness.light,
      service: _FakeProdutoService(() => completer.future),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.light.background);
    final Finder loading = find.byType(SixoAppMobileLoadingScene);
    expect(loading, findsOneWidget);
    final ColoredBox background = tester.widget<ColoredBox>(
      find.descendant(of: loading, matching: find.byType(ColoredBox)),
    );
    expect(background.color, SixMobileColorScheme.light.background);
    expect(find.text('SixoApp'), findsOneWidget);

    completer.complete(_emptyDashboard);
    await tester.pump();
  });

  testWidgets('stock dashboard empty state uses dark text hierarchy', (
    WidgetTester tester,
  ) async {
    await _pumpStock(
      tester,
      service: _FakeProdutoService(() async => _emptyDashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estoque vazio'), findsOneWidget);
    expect(
      _hasTextWithColor(
        tester,
        'Estoque vazio',
        SixMobileColorScheme.dark.titleText,
      ),
      isTrue,
    );
  });

  testWidgets('stock dashboard empty state uses light text hierarchy', (
    WidgetTester tester,
  ) async {
    await _pumpStock(
      tester,
      brightness: Brightness.light,
      service: _FakeProdutoService(() async => _emptyDashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estoque vazio'), findsOneWidget);
    expect(
      _hasTextWithColor(
        tester,
        'Estoque vazio',
        SixMobileColorScheme.light.titleText,
      ),
      isTrue,
    );
  });

  testWidgets(
    'stock dashboard data preserves semantic stock states in dark mode',
    (WidgetTester tester) async {
      await _pumpStock(
        tester,
        service: _FakeProdutoService(() async => _loadedDashboard),
      );
      await tester.pumpAndSettle();

      expect(find.text('Controle de estoque'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Baixo estoque'), findsOneWidget);
      expect(find.text('Sem estoque'), findsWidgets);
      expect(
        _hasDecoratedAncestorColor(
          tester,
          find.text('Situação do estoque'),
          SixMobileColorScheme.dark.surface,
        ),
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.text('Cabo USB'),
        420,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Cabo USB'), findsWidgets);
    },
  );

  testWidgets('stock dashboard error state uses dark surface', (
    WidgetTester tester,
  ) async {
    await _pumpStock(
      tester,
      service: _FakeProdutoService(() async => throw StateError('offline')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o estoque.'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Não foi possível carregar o estoque.'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('stock dashboard error state uses light surface', (
    WidgetTester tester,
  ) async {
    await _pumpStock(
      tester,
      brightness: Brightness.light,
      service: _FakeProdutoService(() async => throw StateError('offline')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o estoque.'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Não foi possível carregar o estoque.'),
        SixMobileColorScheme.light.surface,
      ),
      isTrue,
    );
  });

  testWidgets(
    'stock dashboard data preserves semantic stock states in light mode',
    (WidgetTester tester) async {
      await _pumpStock(
        tester,
        brightness: Brightness.light,
        service: _FakeProdutoService(() async => _loadedDashboardWithAllStates),
      );
      await tester.pumpAndSettle();

      expect(
        _scaffoldBackground(tester),
        SixMobileColorScheme.light.background,
      );
      expect(find.text('Controle de estoque'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Baixo estoque'), findsOneWidget);
      expect(find.text('Sem estoque'), findsWidgets);
      expect(find.text('Estoque negativo'), findsWidgets);
      expect(find.text('Acima do máximo'), findsWidgets);
      expect(
        _hasDecoratedAncestorColor(
          tester,
          find.text('Situação do estoque'),
          SixMobileColorScheme.light.surface,
        ),
        isTrue,
      );

      await tester.scrollUntilVisible(
        find.text('Produto negativo'),
        420,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Produto negativo'), findsOneWidget);
      expect(find.text('Produto em excesso'), findsOneWidget);
      expect(find.text('Estoque negativo'), findsWidgets);
      expect(find.text('Acima do máximo'), findsWidgets);
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

Future<void> _pumpStock(
  WidgetTester tester, {
  required ProdutoService service,
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
        home: EstoqueMobileScreen(produtoService: service),
      ),
    ),
  );
  await tester.pump();
}

const EstoqueDashboardModel _emptyDashboard = EstoqueDashboardModel(
  valorTotalEstoque: 0,
  quantidadeTotalEstoque: 0,
  totalProdutos: 0,
  produtosAbaixoMinimo: 0,
  produtosSemEstoque: 0,
  produtosEstoqueNegativo: 0,
  produtosAcimaMaximo: 0,
  produtosSemMovimentacao: 0,
  entradasRecentes: 0,
  saidasRecentes: 0,
  situacaoEstoque: <EstoqueDashboardSerieItem>[],
  valorEstoquePorCategoria: <EstoqueDashboardSerieItem>[],
  produtosParaReposicao: <EstoqueDashboardProdutoItem>[],
  produtosComErroEstoque: <EstoqueDashboardProdutoItem>[],
  produtosMaiorValorParado: <EstoqueDashboardProdutoItem>[],
  movimentacoesRecentes: <EstoqueDashboardMovimentoItem>[],
  alertas: <EstoqueDashboardAlerta>[],
);

final EstoqueDashboardModel _loadedDashboard = EstoqueDashboardModel(
  valorTotalEstoque: 420,
  quantidadeTotalEstoque: 12,
  totalProdutos: 3,
  produtosAbaixoMinimo: 1,
  produtosSemEstoque: 1,
  produtosEstoqueNegativo: 0,
  produtosAcimaMaximo: 0,
  produtosSemMovimentacao: 1,
  entradasRecentes: 2,
  saidasRecentes: 1,
  situacaoEstoque: const <EstoqueDashboardSerieItem>[
    EstoqueDashboardSerieItem(label: 'Normal', quantidade: 1, valor: 0),
    EstoqueDashboardSerieItem(label: 'Baixo estoque', quantidade: 1, valor: 0),
    EstoqueDashboardSerieItem(label: 'Sem estoque', quantidade: 1, valor: 0),
  ],
  valorEstoquePorCategoria: const <EstoqueDashboardSerieItem>[
    EstoqueDashboardSerieItem(label: 'Acessórios', quantidade: 0, valor: 420),
  ],
  produtosParaReposicao: const <EstoqueDashboardProdutoItem>[
    EstoqueDashboardProdutoItem(
      id: 'p1',
      nome: 'Cabo USB',
      codigoDeBarras: '001',
      categoria: 'Acessórios',
      quantidadeEstoque: 0,
      estoqueMinimo: 2,
      estoqueMaximo: 10,
      diferencaParaMinimo: -2,
      precoVenda: 29.9,
      ultimoCusto: 12,
      valorEstoque: 0,
      problema: 'Sem estoque',
    ),
  ],
  produtosComErroEstoque: const <EstoqueDashboardProdutoItem>[],
  produtosMaiorValorParado: const <EstoqueDashboardProdutoItem>[
    EstoqueDashboardProdutoItem(
      id: 'p2',
      nome: 'Fonte 12V',
      codigoDeBarras: '002',
      categoria: 'Acessórios',
      quantidadeEstoque: 12,
      estoqueMinimo: 1,
      estoqueMaximo: 20,
      diferencaParaMinimo: 11,
      precoVenda: 39.9,
      ultimoCusto: 20,
      valorEstoque: 240,
      problema: 'Normal',
    ),
  ],
  movimentacoesRecentes: const <EstoqueDashboardMovimentoItem>[
    EstoqueDashboardMovimentoItem(
      idProduto: 'p2',
      nomeProduto: 'Fonte 12V',
      categoria: 'Acessórios',
      tipo: 'ENTRADA',
      dataCadastro: null,
      quantidade: 2,
      valorCusto: 20,
      valorVenda: 39.9,
    ),
  ],
  alertas: const <EstoqueDashboardAlerta>[
    EstoqueDashboardAlerta(
      tipo: 'SEM_ESTOQUE',
      titulo: 'Sem estoque',
      descricao: 'Itens precisam de reposição.',
      quantidade: 1,
    ),
  ],
);

final EstoqueDashboardModel
_loadedDashboardWithAllStates = EstoqueDashboardModel(
  valorTotalEstoque: 690,
  quantidadeTotalEstoque: 18,
  totalProdutos: 5,
  produtosAbaixoMinimo: 1,
  produtosSemEstoque: 1,
  produtosEstoqueNegativo: 1,
  produtosAcimaMaximo: 1,
  produtosSemMovimentacao: 1,
  entradasRecentes: 2,
  saidasRecentes: 1,
  situacaoEstoque: const <EstoqueDashboardSerieItem>[
    EstoqueDashboardSerieItem(label: 'Normal', quantidade: 1, valor: 0),
    EstoqueDashboardSerieItem(label: 'Baixo estoque', quantidade: 1, valor: 0),
    EstoqueDashboardSerieItem(label: 'Sem estoque', quantidade: 1, valor: 0),
    EstoqueDashboardSerieItem(
      label: 'Estoque negativo',
      quantidade: 1,
      valor: 0,
    ),
    EstoqueDashboardSerieItem(
      label: 'Acima do máximo',
      quantidade: 1,
      valor: 0,
    ),
  ],
  valorEstoquePorCategoria: const <EstoqueDashboardSerieItem>[
    EstoqueDashboardSerieItem(label: 'Acessórios', quantidade: 0, valor: 420),
    EstoqueDashboardSerieItem(label: 'Peças', quantidade: 0, valor: 270),
  ],
  produtosParaReposicao: const <EstoqueDashboardProdutoItem>[
    EstoqueDashboardProdutoItem(
      id: 'p1',
      nome: 'Cabo USB',
      codigoDeBarras: '001',
      categoria: 'Acessórios',
      quantidadeEstoque: 0,
      estoqueMinimo: 2,
      estoqueMaximo: 10,
      diferencaParaMinimo: -2,
      precoVenda: 29.9,
      ultimoCusto: 12,
      valorEstoque: 0,
      problema: 'Sem estoque',
    ),
    EstoqueDashboardProdutoItem(
      id: 'p2',
      nome: 'Bateria',
      codigoDeBarras: '002',
      categoria: 'Peças',
      quantidadeEstoque: 1,
      estoqueMinimo: 3,
      estoqueMaximo: 8,
      diferencaParaMinimo: -2,
      precoVenda: 89.9,
      ultimoCusto: 45,
      valorEstoque: 45,
      problema: 'Baixo estoque',
    ),
  ],
  produtosComErroEstoque: const <EstoqueDashboardProdutoItem>[
    EstoqueDashboardProdutoItem(
      id: 'p3',
      nome: 'Produto negativo',
      codigoDeBarras: '003',
      categoria: 'Peças',
      quantidadeEstoque: -2,
      estoqueMinimo: 1,
      estoqueMaximo: 8,
      diferencaParaMinimo: -3,
      precoVenda: 49.9,
      ultimoCusto: 20,
      valorEstoque: -40,
      problema: 'Estoque negativo',
    ),
    EstoqueDashboardProdutoItem(
      id: 'p4',
      nome: 'Produto em excesso',
      codigoDeBarras: '004',
      categoria: 'Acessórios',
      quantidadeEstoque: 18,
      estoqueMinimo: 2,
      estoqueMaximo: 10,
      diferencaParaMinimo: 16,
      precoVenda: 39.9,
      ultimoCusto: 20,
      valorEstoque: 360,
      problema: 'Acima do máximo',
    ),
  ],
  produtosMaiorValorParado: const <EstoqueDashboardProdutoItem>[
    EstoqueDashboardProdutoItem(
      id: 'p5',
      nome: 'Fonte 12V',
      codigoDeBarras: '005',
      categoria: 'Acessórios',
      quantidadeEstoque: 12,
      estoqueMinimo: 1,
      estoqueMaximo: 20,
      diferencaParaMinimo: 11,
      precoVenda: 39.9,
      ultimoCusto: 20,
      valorEstoque: 240,
      problema: 'Normal',
    ),
  ],
  movimentacoesRecentes: const <EstoqueDashboardMovimentoItem>[
    EstoqueDashboardMovimentoItem(
      idProduto: 'p5',
      nomeProduto: 'Fonte 12V',
      categoria: 'Acessórios',
      tipo: 'ENTRADA',
      dataCadastro: null,
      quantidade: 2,
      valorCusto: 20,
      valorVenda: 39.9,
    ),
  ],
  alertas: const <EstoqueDashboardAlerta>[
    EstoqueDashboardAlerta(
      tipo: 'SEM_ESTOQUE',
      titulo: 'Sem estoque',
      descricao: 'Itens precisam de reposição.',
      quantidade: 1,
    ),
    EstoqueDashboardAlerta(
      tipo: 'NEGATIVO',
      titulo: 'Estoque negativo',
      descricao: 'Revise movimentações com quantidade negativa.',
      quantidade: 1,
    ),
    EstoqueDashboardAlerta(
      tipo: 'ACIMA_MAXIMO',
      titulo: 'Acima do máximo',
      descricao: 'Estoque acima do máximo configurado.',
      quantidade: 1,
    ),
  ],
);

class _FakeProdutoService extends ProdutoService {
  _FakeProdutoService(this._fetch);

  final Future<EstoqueDashboardModel> Function() _fetch;

  @override
  Future<EstoqueDashboardModel> buscarDashboardEstoque() {
    return _fetch();
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

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasTextWithColor(WidgetTester tester, String text, Color color) {
  return tester
      .widgetList<Text>(find.text(text))
      .any((Text widget) => widget.style?.color == color);
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
