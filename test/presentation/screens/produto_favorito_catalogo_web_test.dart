import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/imagem_sugestao_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/data/services/imagem_sugestao/imagem_sugestao_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/sub_painel_cadastro_produto_web.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
  });

  testWidgets('modal web alterna marcacoes e salva payload atual', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1180, 860);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final _FakeProdutoService service = _FakeProdutoService();

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
          home: Scaffold(
            body: CadastroProdutoWebBody(
              modoEdicao: true,
              produtoParaEdicao: _produto(),
              produtoService: service,
              categoriaApiClient: _FakeCategoriaCatalogoApiClient(),
              imagemSugestaoApiClient: _FakeImagemSugestaoApiClient(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Marcar como favorito'), findsOneWidget);
    expect(find.byTooltip('Disponibilizar para catálogo'), findsOneWidget);

    await tester.tap(find.byTooltip('Marcar como favorito'));
    await tester.pump();
    expect(find.text('Favorito ativado'), findsOneWidget);

    await tester.tap(find.byTooltip('Disponibilizar para catálogo'));
    await tester.pump();
    expect(find.text('Disponível para catálogo ativado'), findsOneWidget);

    for (int etapa = 0; etapa < 2; etapa++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Salvar alteração'));
    await tester.pump();

    expect(service.lastUpdatedProduct?.favorito, isTrue);
    expect(service.lastUpdatedProduct?.disponivelParaCatalogo, isTrue);
    expect(tester.takeException(), isNull);
  });
}

ProdutoModel _produto() {
  return ProdutoModel(
    id: 'produto-1',
    ativo: true,
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

class _FakeImagemSugestaoApiClient implements ImagemSugestaoApiClient {
  @override
  Future<ImagemSugestaoResponse> buscarSugestoes(
    ImagemSugestaoRequest request, {
    dynamic httpClient,
  }) async {
    return ImagemSugestaoResponse(
      tipo: request.tipo,
      consultasExecutadas: const <String>[],
      imagens: const <ImagemSugestao>[],
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
