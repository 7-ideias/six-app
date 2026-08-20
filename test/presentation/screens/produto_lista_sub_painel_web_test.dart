import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
  });

  tearDown(() {
    UsuarioProvider().clear();
  });

  testWidgets('grade de edicao pagina e inclui servicos nos filtros rapidos', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      size: const Size(1440, 900),
      viewMode: ModoDeExibicaoUsuario.grade,
      products: List<ProdutoModel>.generate(
        13,
        (int index) => _produto(
          id: 'p$index',
          nome: 'Produto ${(index + 1).toString().padLeft(2, '0')}',
          codigo: '7890000000${index + 1}',
          categoria: 'Ferramentas',
          preco: 100 + index.toDouble(),
          quantidadeEstoque: index == 0 ? 2 : 10,
          estoqueMinimo: 3,
          imagens:
              index == 0
                  ? <ProdutoImagemModel>[
                    ProdutoImagemModel(origem: 'UPLOAD', imagemBase64: _png1x1),
                  ]
                  : null,
        ),
      ),
      services: <ProdutoModel>[
        _servico(
          id: 's1',
          nome: 'Ajuste rápido',
          codigo: 'SRV-001',
          categoria: 'Serviços',
          preco: 49.9,
        ),
      ],
    );

    expect(find.text('Editar produtos'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('produto-web-quick-todos')),
      findsOneWidget,
    );
    expect(find.text('Produto 13'), findsNothing);
    expect(find.text('Ajuste rápido'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('produto-web-page-2')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('produto-web-page-2')));
    await tester.pumpAndSettle();

    expect(find.text('Produto 13'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('produto-web-quick-todos')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ajuste rápido'), findsOneWidget);
  });

  testWidgets('lista web filtra por busca e preserva estrutura no dark mode', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      size: const Size(1366, 768),
      themeMode: ThemeMode.dark,
      viewMode: ModoDeExibicaoUsuario.lista,
      products: <ProdutoModel>[
        _produto(
          id: 'p1',
          nome: 'Carregador Turbo',
          codigo: '78900001',
          categoria: 'Acessórios',
          preco: 129.9,
          quantidadeEstoque: 8,
        ),
        _produto(
          id: 'p2',
          nome: 'Cabo USB-C',
          codigo: '78900002',
          categoria: 'Cabos',
          preco: 39.9,
          quantidadeEstoque: 1,
          estoqueMinimo: 2,
        ),
      ],
      services: const <ProdutoModel>[],
    );

    expect(find.text('Produto'), findsWidgets);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Preço'), findsOneWidget);
    expect(find.text('Carregador Turbo'), findsOneWidget);
    expect(find.text('Cabo USB-C'), findsOneWidget);
    expect(find.text('Estoque baixo'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('produto-web-search-field')),
      '78900001',
    );
    await tester.pumpAndSettle();

    expect(find.text('Carregador Turbo'), findsOneWidget);
    expect(find.text('Cabo USB-C'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalogo web renderiza sem excecao em larguras de referencia', (
    WidgetTester tester,
  ) async {
    for (final Size size in const <Size>[
      Size(1440, 900),
      Size(1180, 820),
      Size(980, 768),
      Size(720, 768),
    ]) {
      await _pumpCatalog(
        tester,
        size: size,
        viewMode: ModoDeExibicaoUsuario.grade,
        products: <ProdutoModel>[
          _produto(
            id: 'p1',
            nome: 'Alicate universal',
            codigo: '78910001',
            categoria: 'Ferramentas',
            preco: 89.9,
            quantidadeEstoque: 12,
          ),
          _produto(
            id: 'p2',
            nome: 'Multímetro digital',
            codigo: '78910002',
            categoria: 'Eletrônica',
            preco: 159.9,
            quantidadeEstoque: 4,
            estoqueMinimo: 2,
          ),
        ],
        services: <ProdutoModel>[
          _servico(
            id: 's1',
            nome: 'Limpeza técnica',
            codigo: 'SRV-LIM',
            categoria: 'Serviços',
            preco: 29.9,
          ),
        ],
      );

      expect(tester.takeException(), isNull, reason: size.toString());
    }
  });

  testWidgets('dialogo de selecao web aplica backdrop com blur', (
    WidgetTester tester,
  ) async {
    UsuarioProvider().setUsuario(
      UsuarioModel(
        nome: 'Ana',
        sobrenome: 'Souza',
        cpf: '',
        registroProfissional: '',
        email: 'ana@six.test',
        nomeDeGuerra: 'Ana',
        preferenciasIndividuaisDoUsuario:
            PreferenciasIndividuaisDoUsuarioModel.padrao(),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showProdutoListaSelecaoWebDialog<ProdutoModel>(
                      context: context,
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
        products: <ProdutoModel>[
          _produto(
            id: 'p1',
            nome: 'Carregador Turbo',
            codigo: '78900001',
            categoria: 'Acessórios',
            preco: 129.9,
          ),
        ],
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Selecionar item'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selecao web usa filtro customizado e filtra favoritos e catalogo',
    (WidgetTester tester) async {
      UsuarioProvider().setUsuario(
        UsuarioModel(
          nome: 'Ana',
          sobrenome: 'Souza',
          cpf: '',
          registroProfissional: '',
          email: 'ana@six.test',
          nomeDeGuerra: 'Ana',
          preferenciasIndividuaisDoUsuario:
              PreferenciasIndividuaisDoUsuarioModel.padrao(),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        _buildTestApp(
          products: <ProdutoModel>[
            _produto(
              id: 'p1',
              nome: 'Produto favorito',
              codigo: '78920001',
              categoria: 'Cabos',
              preco: 39.9,
              favorito: true,
            ),
            _produto(
              id: 'p2',
              nome: 'Produto catalogo',
              codigo: '78920002',
              categoria: 'Cabos',
              preco: 49.9,
              disponivelParaCatalogo: true,
            ),
            _produto(
              id: 'p3',
              nome: 'Produto completo',
              codigo: '78920003',
              categoria: 'Cabos',
              preco: 59.9,
              favorito: true,
              disponivelParaCatalogo: true,
            ),
          ],
          child: const Scaffold(
            body: ProdutoListaBody(
              isSelecao: true,
              permitirSelecaoMultipla: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((Widget widget) => widget is DropdownButton),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Marcadores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favoritos').last);
      await tester.pumpAndSettle();

      expect(find.text('Produto favorito'), findsOneWidget);
      expect(find.text('Produto completo'), findsOneWidget);
      expect(find.text('Produto catalogo'), findsNothing);

      await tester.tap(find.byTooltip('Marcadores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No catálogo').last);
      await tester.pumpAndSettle();

      expect(find.text('Produto catalogo'), findsOneWidget);
      expect(find.text('Produto completo'), findsOneWidget);
      expect(find.text('Produto favorito'), findsNothing);

      await tester.tap(find.byTooltip('Marcadores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favoritos e catálogo').last);
      await tester.pumpAndSettle();

      expect(find.text('Produto completo'), findsOneWidget);
      expect(find.text('Produto favorito'), findsNothing);
      expect(find.text('Produto catalogo'), findsNothing);
    },
  );
}

Future<void> _pumpCatalog(
  WidgetTester tester, {
  required Size size,
  required ModoDeExibicaoUsuario viewMode,
  required List<ProdutoModel> products,
  required List<ProdutoModel> services,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  UsuarioProvider().setUsuario(
    UsuarioModel(
      nome: 'Ana',
      sobrenome: 'Souza',
      cpf: '',
      registroProfissional: '',
      email: 'ana@six.test',
      nomeDeGuerra: 'Ana',
      preferenciasIndividuaisDoUsuario:
          PreferenciasIndividuaisDoUsuarioModel.padrao().copyWith(
            modoDeExibicaoProdutosWeb: viewMode,
          ),
    ),
  );

  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    _buildTestApp(
      themeMode: themeMode,
      products: products,
      services: services,
      child: const Scaffold(body: ProdutoListaBody(modoEdicao: true)),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

Widget _buildTestApp({
  required Widget child,
  List<ProdutoModel> products = const <ProdutoModel>[],
  List<ProdutoModel> services = const <ProdutoModel>[],
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProdutosListProvider<ProdutoModel>>(
        create:
            (_) => ProdutosListProvider<ProdutoModel>(
              fetchFunction: (Map<String, String>? headers) async {
                final String tipo =
                    headers?['tipo']?.toUpperCase() ?? 'PRODUTO';
                final List<ProdutoModel> lista =
                    tipo == 'SERVICO' ? services : products;
                return ProdutoResponseModel(
                  skusTotaisNoEstoque: lista.length,
                  qtNoEstoque: lista.length.toDouble(),
                  erroNoEstoque: false,
                  qtSemEstoque: 0,
                  vlEstoqueEmGrana: 0,
                  produtosList: lista,
                );
              },
            ),
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
      home: child,
    ),
  );
}

ProdutoModel _produto({
  required String id,
  required String nome,
  required String codigo,
  required String categoria,
  required double preco,
  double quantidadeEstoque = 6,
  int estoqueMinimo = 1,
  bool favorito = false,
  bool disponivelParaCatalogo = false,
  List<ProdutoImagemModel>? imagens,
}) {
  return ProdutoModel(
    id: id,
    ativo: true,
    favorito: favorito,
    disponivelParaCatalogo: disponivelParaCatalogo,
    codigoDeBarras: codigo,
    nomeProduto: nome,
    tipoProduto: 'PRODUTO',
    objCategoria: ObjCategoria(
      idCategoria: categoria,
      nomeCategoria: categoria,
    ),
    objAgrupamento: ObjAgrupamento(grupoDoProduto: categoria),
    modeloProduto: 'UNIDADE',
    estoqueMaximo: 100,
    estoqueMinimo: estoqueMinimo,
    precoVenda: preco,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
    objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
      ObjEntradaSaidaProduto(
        quantidade: quantidadeEstoque,
        valorCusto: preco / 2,
        valorDaVenda: preco,
      ),
    ],
    imagens: imagens,
  );
}

ProdutoModel _servico({
  required String id,
  required String nome,
  required String codigo,
  required String categoria,
  required double preco,
}) {
  return ProdutoModel(
    id: id,
    ativo: true,
    codigoDeBarras: codigo,
    nomeProduto: nome,
    tipoProduto: 'SERVICO',
    objCategoria: ObjCategoria(
      idCategoria: categoria,
      nomeCategoria: categoria,
    ),
    objAgrupamento: ObjAgrupamento(grupoDoProduto: categoria),
    objetoServico: ObjetoServico(
      tempoDaGarantia: '90 dias',
      podeAlterarOValorNaHora: true,
    ),
    modeloProduto: 'SERVICO',
    estoqueMaximo: 0,
    estoqueMinimo: 0,
    precoVenda: preco,
    objComissao: ObjComissao(
      produtoTemComissaoEspecial: false,
      valorFixoDeComissaoParaEsseProduto: 0,
    ),
    objEntradaSaidaProduto: const <ObjEntradaSaidaProduto>[],
  );
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async {
    return _regionalizacao;
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) async {
    return _regionalizacao;
  }
}

final ConfiguracaoRegionalizacaoResponse _regionalizacao =
    ConfiguracaoRegionalizacaoResponse(
      languageCode: 'pt',
      countryCode: 'BR',
      currencyCode: 'BRL',
      timeZone: 'America/Sao_Paulo',
      dateFormat: 'dd/MM/yyyy',
      timeFormat: '24h',
      decimalSeparator: ',',
      thousandSeparator: '.',
      firstDayOfWeek: 'MONDAY',
      numberPattern: '#,##0.00',
      decimalPlaces: 2,
      allowMultipleCurrencies: false,
      applyFinancialRounding: true,
    );

const String _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p94AAAAASUVORK5CYII=';
