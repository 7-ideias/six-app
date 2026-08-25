import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/produto_cadastrar_mobile_screen.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
    SixThemeResolver().atualizarTema(TemaSistema.claro);
    UsuarioProvider().clear();
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
    UsuarioProvider().clear();
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

  testWidgets(
    'listagem vertical renderiza busca fixa, filtros rapidos e cards',
    (WidgetTester tester) async {
      final _FakeProdutoService service = _FakeProdutoService();

      await _pumpMobileCatalog(
        tester,
        produtoService: service,
        products: <ProdutoModel>[
          _produto(id: 'p1', codigo: '8263838373', precoVenda: 700),
          _produto(id: 'p2', ativo: false, codigo: '1782837590'),
        ],
      );

      expect(find.text('Produtos'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('produto-persistent-search-field')),
        findsOneWidget,
      );
      expect(find.text('Buscar produto ou código'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('produto-vertical-filter-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('produto-quick-filter-todos')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('produto-quick-filter-ativos')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('produto-quick-filter-low-stock')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('produto-quick-count')),
        findsOneWidget,
      );
      expect(find.byKey(_cardKey('p1')), findsOneWidget);
      expect(find.byKey(_cardKey('p2')), findsOneWidget);
      expect(find.text('R\$ 700,00'), findsOneWidget);
      expect(find.text('Cód. 8263838373'), findsOneWidget);
    },
  );

  testWidgets(
    'arrastar para esquerda revela acoes e mantem apenas um item aberto',
    (WidgetTester tester) async {
      await _pumpMobileCatalog(
        tester,
        produtoService: _FakeProdutoService(),
        products: <ProdutoModel>[_produto(id: 'p1'), _produto(id: 'p2')],
      );

      final Offset posicaoInicialPrimeiro = tester.getTopLeft(
        find.byKey(_cardKey('p1')),
      );
      final Offset posicaoInicialSegundo = tester.getTopLeft(
        find.byKey(_cardKey('p2')),
      );

      await _abrirAcoesDoCard(tester, 'p1');
      final Offset posicaoAbertaPrimeiro = tester.getTopLeft(
        find.byKey(_cardKey('p1')),
      );
      expect(posicaoAbertaPrimeiro.dx, lessThan(posicaoInicialPrimeiro.dx));

      await _abrirAcoesDoCard(tester, 'p2');
      final Offset posicaoFechadaPrimeiro = tester.getTopLeft(
        find.byKey(_cardKey('p1')),
      );
      final Offset posicaoAbertaSegundo = tester.getTopLeft(
        find.byKey(_cardKey('p2')),
      );

      expect(
        (posicaoFechadaPrimeiro.dx - posicaoInicialPrimeiro.dx).abs(),
        lessThan(1),
      );
      expect(posicaoAbertaSegundo.dx, lessThan(posicaoInicialSegundo.dx));
    },
  );

  testWidgets(
    'acao de favorito usa o servico existente e alterna para icone preenchido',
    (WidgetTester tester) async {
      final _FakeProdutoService service = _FakeProdutoService();

      await _pumpMobileCatalog(
        tester,
        produtoService: service,
        products: <ProdutoModel>[_produto(id: 'p1', favorito: false)],
      );

      await _abrirAcoesDoCard(tester, 'p1');
      await tester.tap(find.byKey(_favoriteActionKey('p1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(service.favoriteUpdateCount, 1);
      expect(service.lastFavoriteProdutoId, 'p1');
      expect(service.lastFavoriteValue, isTrue);

      final Icon icon = tester.widget<Icon>(
        find
            .descendant(
              of: find.byKey(_favoriteActionKey('p1')),
              matching: find.byType(Icon),
            )
            .first,
      );
      expect(icon.icon, Icons.favorite_rounded);
    },
  );

  testWidgets(
    'acao de catalogo usa o servico existente e alterna para icone preenchido',
    (WidgetTester tester) async {
      final _FakeProdutoService service = _FakeProdutoService();

      await _pumpMobileCatalog(
        tester,
        produtoService: service,
        products: <ProdutoModel>[
          _produto(id: 'p1', disponivelParaCatalogo: false),
        ],
      );

      await _abrirAcoesDoCard(tester, 'p1');
      await tester.tap(find.byKey(_catalogActionKey('p1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(service.catalogUpdateCount, 1);
      expect(service.lastCatalogProdutoId, 'p1');
      expect(service.lastCatalogValue, isTrue);

      final Icon icon = tester.widget<Icon>(
        find
            .descendant(
              of: find.byKey(_catalogActionKey('p1')),
              matching: find.byType(Icon),
            )
            .first,
      );
      expect(icon.icon, Icons.storefront_rounded);
    },
  );

  testWidgets('toque no card fechado dispara a abertura da edicao', (
    WidgetTester tester,
  ) async {
    final _TestNavigatorObserver observer = _TestNavigatorObserver();

    await _pumpMobileCatalog(
      tester,
      produtoService: _FakeProdutoService(),
      products: <ProdutoModel>[_produto(id: 'p1')],
      navigatorObserver: observer,
    );

    await tester.tap(find.byKey(_cardKey('p1')));
    await tester.pumpAndSettle();

    expect(observer.pushCount, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'modo de selecao preserva composicao sem swipe vertical moderno',
    (WidgetTester tester) async {
      await _pumpMobileCatalog(
        tester,
        produtoService: _FakeProdutoService(),
        products: <ProdutoModel>[_produto(id: 'p1')],
        isSelecao: true,
        permitirSelecaoMultipla: true,
      );

      expect(
        find.byKey(const ValueKey<String>('produto-persistent-search-field')),
        findsNothing,
      );
      expect(find.byKey(_cardKey('p1')), findsNothing);
      expect(find.text('Selecione um ou mais itens'), findsOneWidget);
    },
  );

  testWidgets('modo horizontal preserva a pagina em carrossel', (
    WidgetTester tester,
  ) async {
    await _pumpMobileCatalog(
      tester,
      produtoService: _FakeProdutoService(),
      products: <ProdutoModel>[_produto(id: 'p1'), _produto(id: 'p2')],
      modoExibicaoMobile: ModoDeExibicaoUsuario.horizontal,
    );

    expect(find.byType(PageView), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('produto-persistent-search-field')),
      findsNothing,
    );
    expect(find.byKey(_cardKey('p1')), findsNothing);
  });

  testWidgets(
    'lista vertical evita overflow em 320px e 390px com texto longo e sem imagem',
    (WidgetTester tester) async {
      for (final Size size in const <Size>[Size(320, 780), Size(390, 860)]) {
        await _pumpMobileCatalog(
          tester,
          produtoService: _FakeProdutoService(),
          products: <ProdutoModel>[
            _produto(
              id: 'p-long',
              nome: 'Bateria Turbo Max Ultra Longa Referencia 89573 Para Teste',
              codigo: '',
            ),
          ],
          size: size,
        );

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      }
    },
  );

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
      create:
          (_) => LocaleSettingsProvider(
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
  Size size = const Size(390, 860),
  bool isSelecao = false,
  bool permitirSelecaoMultipla = false,
  ModoDeExibicaoUsuario modoExibicaoMobile = ModoDeExibicaoUsuario.vertical,
  NavigatorObserver? navigatorObserver,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  UsuarioProvider().clear();
  if (modoExibicaoMobile != ModoDeExibicaoUsuario.vertical) {
    UsuarioProvider().setUsuario(_usuarioComModo(modoExibicaoMobile));
  }

  final ProdutosListProvider<ProdutoModel> provider =
      ProdutosListProvider<ProdutoModel>(fetchFunction: (_) async => products);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProdutosListProvider<ProdutoModel>>.value(
          value: provider,
        ),
        ChangeNotifierProvider<LocaleSettingsProvider>(
          create:
              (_) => LocaleSettingsProvider(
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
        navigatorObservers:
            navigatorObserver == null
                ? const <NavigatorObserver>[]
                : <NavigatorObserver>[navigatorObserver],
        home: ProdutolistMobileScreen(
          produtoService: produtoService,
          isSelecao: isSelecao,
          permitirSelecaoMultipla: permitirSelecaoMultipla,
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

ProdutoModel _produto({
  String id = 'produto-1',
  String nome = 'Cabo USB',
  bool favorito = false,
  bool disponivelParaCatalogo = false,
  bool ativo = true,
  String codigo = '789123',
  double precoVenda = 25.9,
  int estoqueAtual = 1,
  int estoqueMinimo = 1,
}) {
  return ProdutoModel(
    id: id,
    ativo: ativo,
    favorito: favorito,
    disponivelParaCatalogo: disponivelParaCatalogo,
    codigoDeBarras: codigo,
    nomeProduto: nome,
    tipoProduto: 'PRODUTO',
    objCategoria: ObjCategoria(idCategoria: 'cat-1', nomeCategoria: 'Peças'),
    objAgrupamento: ObjAgrupamento(grupoDoProduto: 'Cabos'),
    objetoServico: ObjetoServico(
      tempoDaGarantia: '',
      podeAlterarOValorNaHora: false,
    ),
    modeloProduto: 'UNIDADE',
    estoqueMaximo: 10,
    estoqueMinimo: estoqueMinimo,
    precoVenda: precoVenda,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
    objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
      ObjEntradaSaidaProduto(
        quantidade: estoqueAtual.toDouble(),
        valorCusto: 10,
        valorDaVenda: precoVenda,
      ),
    ],
  );
}

Future<void> _abrirAcoesDoCard(WidgetTester tester, String produtoId) async {
  await tester.drag(find.byKey(_cardKey(produtoId)), const Offset(-170, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
}

ValueKey<String> _cardKey(String produtoId) =>
    ValueKey<String>('produto-vertical-card-${_produtoChave(produtoId)}');

ValueKey<String> _favoriteActionKey(String produtoId) =>
    ValueKey<String>('produto-action-favorite-${_produtoChave(produtoId)}');

ValueKey<String> _catalogActionKey(String produtoId) =>
    ValueKey<String>('produto-action-catalog-${_produtoChave(produtoId)}');

String _produtoChave(String produtoId) => 'tipo:PRODUTO|id:$produtoId';

UsuarioModel _usuarioComModo(ModoDeExibicaoUsuario modo) {
  return UsuarioModel(
    nome: 'Teste',
    sobrenome: 'Usuário',
    cpf: '',
    registroProfissional: '',
    email: 'teste@six.app',
    preferenciasIndividuaisDoUsuario: PreferenciasIndividuaisDoUsuarioModel(
      ocultarValoresFinanceirosWeb: false,
      modoDeExibicaoProdutosMobile: modo,
    ),
  );
}

class _FakeProdutoService extends ProdutoService {
  ProdutoModel? lastUpdatedProduct;
  ProdutoModel? lastCreatedProduct;
  String? lastFavoriteProdutoId;
  bool? lastFavoriteAtivo;
  bool? lastFavoriteValue;
  int favoriteUpdateCount = 0;
  String? lastCatalogProdutoId;
  bool? lastCatalogAtivo;
  bool? lastCatalogValue;
  int catalogUpdateCount = 0;

  @override
  Future<String?> cadastrarProduto(ProdutoModel produto) async {
    lastCreatedProduct = produto;
    return produto.id ?? 'novo-produto';
  }

  @override
  Future<void> atualizarProduto(ProdutoModel produto) async {
    lastUpdatedProduct = produto;
  }

  @override
  Future<void> atualizarFavoritoProduto({
    required String produtoId,
    required bool ativo,
    required bool favorito,
  }) async {
    favoriteUpdateCount += 1;
    lastFavoriteProdutoId = produtoId;
    lastFavoriteAtivo = ativo;
    lastFavoriteValue = favorito;
  }

  @override
  Future<void> atualizarDisponivelParaCatalogoProduto({
    required String produtoId,
    required bool ativo,
    required bool disponivelParaCatalogo,
  }) async {
    catalogUpdateCount += 1;
    lastCatalogProdutoId = produtoId;
    lastCatalogAtivo = ativo;
    lastCatalogValue = disponivelParaCatalogo;
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
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
