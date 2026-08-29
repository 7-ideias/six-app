import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  testWidgets('clients list keeps dark themed surfaces', (
    WidgetTester tester,
  ) async {
    await _pumpClients(
      tester,
      apiClient: _FakeClienteUsuarioApiClient(
        response: ClienteUsuarioListResponse(
          idUnicoDaEmpresa: 'empresa-1',
          total: 2,
          clientes: <ClienteUsuario>[
            _cliente(
              id: 'cliente-1',
              nome: 'cliente cadastrado no servico',
              documento: '32321321',
              telefone: '+55',
              cidade: '',
              uf: '',
              email: '',
              permiteCompraFiado: true,
              limiteFiado: 0,
              prazoPagamentoDias: 30,
            ),
            _cliente(
              id: 'cliente-2',
              nome: 'carlos Pijanowski cartaxo',
              documento: '281272529',
              telefone: '35992736863',
              cidade: '',
              uf: 'SP',
              email: '',
              permiteCompraFiado: false,
            ),
          ],
        ),
      ),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Clientes encontrados'), findsOneWidget);
    expect(find.text('cliente cadastrado no servico'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Buscar cliente...'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('cliente cadastrado no servico'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );

    await tester.tap(find.text('cliente cadastrado no servico').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Telefone'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Telefone'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('clients empty state keeps dark themed surface', (
    WidgetTester tester,
  ) async {
    await _pumpClients(
      tester,
      apiClient: _FakeClienteUsuarioApiClient(
        response: ClienteUsuarioListResponse(
          idUnicoDaEmpresa: 'empresa-1',
          total: 0,
          clientes: const <ClienteUsuario>[],
        ),
      ),
    );

    expect(_scaffoldBackground(tester), SixMobileColorScheme.dark.background);
    expect(find.text('Nenhum cliente encontrado'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Nenhum cliente encontrado'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
  });

  testWidgets('auto signup sheet keeps dark themed surfaces', (
    WidgetTester tester,
  ) async {
    await _pumpClients(
      tester,
      apiClient: _FakeClienteUsuarioApiClient(
        response: ClienteUsuarioListResponse(
          idUnicoDaEmpresa: 'empresa-1',
          total: 1,
          clientes: <ClienteUsuario>[
            _cliente(
              id: 'cliente-1',
              nome: 'cliente cadastrado no servico',
              documento: '32321321',
              telefone: '+55',
              cidade: '',
              uf: '',
              email: '',
              permiteCompraFiado: true,
              limiteFiado: 0,
              prazoPagamentoDias: 30,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byTooltip('Novo cliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar ao cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Auto cadastro'), findsOneWidget);
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Auto cadastro'),
        SixMobileColorScheme.dark.surface,
      ),
      isTrue,
    );
    expect(
      _hasDecoratedAncestorColor(
        tester,
        find.text('Gerar link'),
        SixMobileColorScheme.dark.surfaceElevated,
      ),
      isTrue,
    );
  });
}

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpClients(
  WidgetTester tester, {
  required ClienteUsuarioApiClient apiClient,
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
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
            size: Size(390, 900),
            devicePixelRatio: 1,
          ),
          child: ClientesUsuarioMobileScreen(apiClient: apiClient),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

ClienteUsuario _cliente({
  required String id,
  required String nome,
  required String documento,
  required String telefone,
  required String cidade,
  required String uf,
  required String email,
  required bool permiteCompraFiado,
  double limiteFiado = 0,
  int prazoPagamentoDias = 0,
}) {
  return ClienteUsuario(
    id: id,
    idUsuario: 'usuario-$id',
    idUnicoDaEmpresa: 'empresa-1',
    ativo: true,
    tipoPessoa: 'PF',
    documento: documento,
    nome: nome,
    telefone: telefone,
    email: email,
    cep: '',
    logradouro: '',
    numero: '',
    complemento: '',
    bairro: '',
    cidade: cidade,
    uf: uf,
    observacoes: '',
    origemAutoCadastro: '',
    enviadoEm: null,
    criadoEm: DateTime(2026, 8, 16),
    atualizadoEm: DateTime(2026, 8, 16),
    foto: '',
    permiteCompraFiado: permiteCompraFiado,
    limiteFiado: limiteFiado,
    saldoFiado: 0,
    prazoPagamentoDias: prazoPagamentoDias,
    bloqueadoFiado: false,
  );
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

class _FakeClienteUsuarioApiClient implements ClienteUsuarioApiClient {
  const _FakeClienteUsuarioApiClient({required this.response});

  final ClienteUsuarioListResponse response;

  @override
  Future<ClienteUsuario> atualizarClienteUsuario(
    String idCliente,
    ClienteUsuarioRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ClienteUsuario> cadastrarClienteUsuario(
    ClienteUsuarioRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ClienteUsuarioListResponse> listarClientesUsuario() async {
    return response;
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
