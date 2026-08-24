import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
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

  testWidgets('cadastro inicia com ambos os marcadores desativados', (
    WidgetTester tester,
  ) async {
    await _pumpMobileForm(
      tester,
      produto: null,
      produtoService: _FakeProdutoService(),
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.text('Qualidade do cadastro'), findsOneWidget);
    expect(find.text('Novo produto'), findsNothing);
  });

  testWidgets('edicao inicializa os marcadores a partir da API', (
    WidgetTester tester,
  ) async {
    await _pumpMobileForm(
      tester,
      produto: _produto(favorito: true, disponivelParaCatalogo: true),
      produtoService: _FakeProdutoService(),
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
  });

  testWidgets(
    'cadastro completo organiza regras e dados fiscais em cinco etapas',
    (WidgetTester tester) async {
      await _pumpMobileForm(
        tester,
        produto: _produto(),
        produtoService: _FakeProdutoService(),
      );

      await tester.tap(find.text('Cadastro completo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Etapa 1 de 5'), findsWidgets);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Regras operacionais'), findsOneWidget);
      expect(find.text('Categoria da unidade'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Dados fiscais e contábeis'), findsOneWidget);
      expect(find.text('NCM'), findsOneWidget);
    },
  );

  testWidgets(
    'nivel recolhe apos iniciar e continua disponivel para alteracao',
    (WidgetTester tester) async {
      await _pumpMobileForm(
        tester,
        produto: _produto(),
        produtoService: _FakeProdutoService(),
      );

      expect(find.text('Escolha o nível do cadastro'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('produto-tipo-cadastro-compacto-mobile'),
        ),
        findsOneWidget,
      );
      expect(find.text('Escolha o nível do cadastro'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('produto-tipo-cadastro-compacto-mobile'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escolha o nível do cadastro'), findsOneWidget);

      await tester.tap(find.text('Cadastro completo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Etapa 1 de 5'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey<String>('produto-tipo-cadastro-compacto-mobile'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('toque no coracao alterna apenas favorito e mostra feedback', (
    WidgetTester tester,
  ) async {
    final _FakeProdutoService service = _FakeProdutoService();
    await _pumpMobileForm(tester, produto: _produto(), produtoService: service);

    await tester.tap(find.byTooltip('Marcar como favorito'));
    await tester.pump();

    expect(find.text('Favorito ativado'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);

    await _avancarAteRevisao(tester);
    await tester.tap(find.text('Salvar edição'));
    await tester.pump();

    expect(service.lastUpdatedProduct?.favorito, isTrue);
    expect(service.lastUpdatedProduct?.disponivelParaCatalogo, isFalse);
  });

  testWidgets(
    'toque no catalogo alterna apenas disponivelParaCatalogo e mostra feedback',
    (WidgetTester tester) async {
      final _FakeProdutoService service = _FakeProdutoService();
      await _pumpMobileForm(
        tester,
        produto: _produto(),
        produtoService: service,
      );

      await tester.tap(find.byTooltip('Disponibilizar para catálogo'));
      await tester.pump();

      expect(find.text('Disponível para catálogo ativado'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);

      await _avancarAteRevisao(tester);
      await tester.tap(find.text('Salvar edição'));
      await tester.pump();

      expect(service.lastUpdatedProduct?.favorito, isFalse);
      expect(service.lastUpdatedProduct?.disponivelParaCatalogo, isTrue);
    },
  );

  testWidgets('coracao da lista mobile reflete o valor persistido e atualiza', (
    WidgetTester tester,
  ) async {
    final _FakeProdutoService service = _FakeProdutoService();
    final ProdutoModel produtoInicial = _produto(id: 'p1');

    await _pumpMobileCatalog(
      tester,
      produtoService: service,
      products: <ProdutoModel>[produtoInicial],
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Marcar como favorito').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(service.lastUpdatedProduct?.favorito, isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('formulario renderiza sem overflow em viewport mobile estreita', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 780);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpMobileForm(
      tester,
      produto: _produto(),
      produtoService: _FakeProdutoService(),
      manageView: false,
    );

    expect(tester.takeException(), isNull);
  });
}

Future<void> _avancarAteRevisao(WidgetTester tester) async {
  for (int etapa = 0; etapa < 2; etapa++) {
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpMobileForm(
  WidgetTester tester, {
  required ProdutoModel? produto,
  required _FakeProdutoService produtoService,
  bool manageView = true,
}) async {
  if (manageView) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>(
      create: (_) => LocaleSettingsProvider(
        regionalizacaoService: RegionalizacaoService(
          apiClient: _FakeRegionalizacaoApiClient(),
        ),
      ),
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const <Locale>[Locale('pt')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CadastroProdutoMobileScreen(
          produtoParaEdicao: produto,
          produtoService: produtoService,
          categoriaApiClient: _FakeCategoriaCatalogoApiClient(),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _pumpMobileCatalog(
  WidgetTester tester, {
  required _FakeProdutoService produtoService,
  required List<ProdutoModel> products,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 860);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final ProdutosListProvider<ProdutoModel> provider =
      ProdutosListProvider<ProdutoModel>(fetchFunction: (_) async => products);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProdutosListProvider<ProdutoModel>>.value(
          value: provider,
        ),
        ChangeNotifierProvider<LocaleSettingsProvider>(
          create: (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _FakeRegionalizacaoApiClient(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const <Locale>[Locale('pt')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ProdutolistMobileScreen(produtoService: produtoService),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

ProdutoModel _produto({
  String id = 'produto-1',
  bool favorito = false,
  bool disponivelParaCatalogo = false,
}) {
  return ProdutoModel(
    id: id,
    ativo: true,
    favorito: favorito,
    disponivelParaCatalogo: disponivelParaCatalogo,
    codigoDeBarras: '789123',
    nomeProduto: 'Cabo USB',
    tipoProduto: 'PRODUTO',
    objCategoria: ObjCategoria(idCategoria: 'cat-1', nomeCategoria: 'Peças'),
    objAgrupamento: ObjAgrupamento(grupoDoProduto: 'Cabos'),
    objetoServico: ObjetoServico(
      tempoDaGarantia: '',
      podeAlterarOValorNaHora: false,
    ),
    modeloProduto: 'UNIDADE',
    estoqueMaximo: 10,
    estoqueMinimo: 1,
    precoVenda: 25.9,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
    objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
      ObjEntradaSaidaProduto(quantidade: 1, valorCusto: 10, valorDaVenda: 25.9),
    ],
  );
}

class _FakeProdutoService extends ProdutoService {
  ProdutoModel? lastUpdatedProduct;
  ProdutoModel? lastCreatedProduct;

  @override
  Future<String?> cadastrarProduto(ProdutoModel produto) async {
    lastCreatedProduct = produto;
    return produto.id ?? 'novo-produto';
  }

  @override
  Future<void> atualizarProduto(ProdutoModel produto) async {
    lastUpdatedProduct = produto;
  }
}

class _FakeCategoriaCatalogoApiClient implements CategoriaCatalogoApiClient {
  @override
  Future<void> apagarCategoria(String idCategoria) {
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
  Future<CategoriaCatalogoModel> cadastrarCategoria(
    CategoriaCatalogoRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CategoriaCatalogoListResponse> listarCategorias() async {
    return const CategoriaCatalogoListResponse(
      idUnicoDaEmpresa: 'empresa-test',
      total: 1,
      categorias: <CategoriaCatalogoModel>[
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
