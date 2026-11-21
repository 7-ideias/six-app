import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/presentation/components/web/six_web_customer_identification_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
    'shows focused modal with blurred navy backdrop and create action',
    (WidgetTester tester) async {
      await _pumpHarness(
        tester,
        apiClient: _FakeClienteUsuarioApiClient(
          clientes: <ClienteUsuario>[_cliente(id: '1', nome: 'Carlos Souza')],
        ),
      );

      await tester.tap(find.text('Abrir clientes'));
      await tester.pumpAndSettle();

      expect(find.text('Identificar cliente'), findsOneWidget);
      expect(find.text('Cadastrar cliente'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'cadastro vazio abre centralizado com uma ação de cadastro ($mode)',
      (tester) async {
        const size = Size(1920, 1000);
        await _pumpHarness(
          tester,
          apiClient: _FakeClienteUsuarioApiClient(clientes: []),
          themeMode: mode,
          size: size,
        );
        await tester.tap(find.text('Abrir clientes'));
        await tester.pumpAndSettle();

        final panel = find.byKey(
          const ValueKey('pdv-identificar-cliente-painel'),
        );
        final rect = tester.getRect(panel);
        expect(rect.center, size.center(Offset.zero));
        expect(rect.width, lessThanOrEqualTo(680));
        expect(rect.height, lessThan(400));
        expect(find.text('Nenhum cliente ativo cadastrado'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Cadastrar cliente'), findsOneWidget);
        expect(
          tester.widget<Material>(panel).color,
          WebThemeTokens.of(tester.element(panel)).surfaceElevated,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'filtra, limpa busca sem resultado e seleciona cliente no navegador compacto',
    (tester) async {
      ClienteIdentificacaoVendaResult? selected;
      await _pumpHarness(
        tester,
        size: const Size(360, 390),
        locale: const Locale('en'),
        apiClient: _FakeClienteUsuarioApiClient(
          clientes: [
            _cliente(id: '1', nome: 'Carlos Souza'),
            _cliente(id: '2', nome: 'Ana Luz', documento: '4567'),
          ],
        ),
        onResult: (result) => selected = result,
      );
      await tester.tap(find.text('Abrir clientes'));
      await tester.pumpAndSettle();
      expect(find.text('Identify customer'), findsOneWidget);
      final search = find.byKey(
        const ValueKey('customer-identification-search-field'),
      );
      await tester.enterText(search, 'inexistente');
      await tester.pumpAndSettle();
      expect(find.text('No customer found'), findsOneWidget);
      expect(find.text('Create customer'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear'));
      await tester.enterText(search, '4567');
      await tester.pumpAndSettle();
      expect(find.text('Carlos Souza'), findsNothing);
      await tester.ensureVisible(find.text('Ana Luz'));
      await tester.tap(find.text('Ana Luz'));
      await tester.pumpAndSettle();
      expect(selected?.cliente?.id, '2');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('permite remover o cliente já vinculado', (tester) async {
    ClienteIdentificacaoVendaResult? selected;
    await _pumpHarness(
      tester,
      apiClient: _FakeClienteUsuarioApiClient(clientes: []),
      current: _cliente(id: '1', nome: 'Ana Luz'),
      onResult: (result) => selected = result,
    );
    await tester.tap(find.text('Abrir clientes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ana Luz'), findsOneWidget);
    await tester.tap(find.byTooltip('Remover cliente atual'));
    await tester.pumpAndSettle();
    expect(selected?.limpar, isTrue);
  });

  testWidgets(
    'distingue falha de listagem de catálogo vazio e permite tentar novamente',
    (tester) async {
      final api = _FakeClienteUsuarioApiClient(
        clientes: [_cliente(id: '1', nome: 'Ana Luz')],
      )..failOnce = true;
      await _pumpHarness(tester, apiClient: api);
      await tester.tap(find.text('Abrir clientes'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum cliente ativo cadastrado'), findsNothing);
      expect(find.text('Cadastrar cliente'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Luz'), findsOneWidget);
    },
  );

  testWidgets(
    'cadastro em andamento bloqueia fechamento e cancelamento do cadastro retorna ao seletor',
    (tester) async {
      final pending = Completer<ClienteUsuario?>();
      await _pumpHarness(
        tester,
        apiClient: _FakeClienteUsuarioApiClient(clientes: []),
        onCreateCustomer: (_) => pending.future,
      );
      await tester.tap(find.text('Abrir clientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadastrar cliente'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Abrindo cadastro...'), findsOneWidget);
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Cadastrar cliente'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Identificar cliente'), findsNothing);
    },
  );

  testWidgets('closes on escape while interactive', (
    WidgetTester tester,
  ) async {
    ClienteIdentificacaoVendaResult? result;
    await _pumpHarness(
      tester,
      apiClient: _FakeClienteUsuarioApiClient(
        clientes: <ClienteUsuario>[_cliente(id: '1', nome: 'Carlos Souza')],
      ),
      onResult: (ClienteIdentificacaoVendaResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir clientes'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Identificar cliente'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a customer and returns it as the selected result', (
    WidgetTester tester,
  ) async {
    ClienteIdentificacaoVendaResult? result;
    final ClienteUsuario novoCliente = _cliente(
      id: '2',
      nome: 'Tatiana Cordeiro',
      documento: '12345678900',
    );
    await _pumpHarness(
      tester,
      apiClient: _FakeClienteUsuarioApiClient(
        clientes: <ClienteUsuario>[_cliente(id: '1', nome: 'Carlos Souza')],
      ),
      onCreateCustomer: (_) async => novoCliente,
      onResult: (ClienteIdentificacaoVendaResult? value) => result = value,
    );

    await tester.tap(find.text('Abrir clientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar cliente'));
    await tester.pumpAndSettle();

    expect(result?.cliente?.id, '2');
    expect(result?.cliente?.nome, 'Tatiana Cordeiro');
    expect(find.text('Identificar cliente'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required ClienteUsuarioApiClient apiClient,
  Size size = const Size(1400, 900),
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('pt', 'BR'),
  ClienteUsuario? current,
  SixWebCreateCustomerFlow? onCreateCustomer,
  ValueChanged<ClienteIdentificacaoVendaResult?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: WebThemeTokens.applyTo(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.light,
          ),
        ),
      ),
      darkTheme: WebThemeTokens.applyTo(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
          ),
        ),
      ),
      supportedLocales: const <Locale>[
        Locale('pt', 'BR'),
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder:
              (BuildContext context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    final ClienteIdentificacaoVendaResult? result =
                        await showSixWebCustomerIdentificationDialog(
                          context: context,
                          clienteAtual: current,
                          barrierDismissible: true,
                          apiClient: apiClient,
                          onCreateCustomer: onCreateCustomer,
                        );
                    onResult?.call(result);
                  },
                  child: const Text('Abrir clientes'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ClienteUsuario _cliente({
  required String id,
  required String nome,
  String documento = '',
}) {
  return ClienteUsuario(
    id: id,
    idUsuario: 'usuario-1',
    idUnicoDaEmpresa: 'empresa-1',
    criadoEm: DateTime(2026, 8, 27),
    atualizadoEm: DateTime(2026, 8, 27),
    enviadoEm: null,
    tipoPessoa: 'PF',
    documento: documento,
    nome: nome,
    email: '',
    telefone: '',
    cep: '',
    logradouro: '',
    numero: '',
    complemento: '',
    bairro: '',
    cidade: '',
    uf: '',
    observacoes: '',
    origemAutoCadastro: '',
    foto: '',
    ativo: true,
    permiteCompraFiado: false,
    limiteFiado: 0,
    saldoFiado: 0,
    prazoPagamentoDias: 30,
    bloqueadoFiado: false,
  );
}

class _FakeClienteUsuarioApiClient implements ClienteUsuarioApiClient {
  _FakeClienteUsuarioApiClient({required this.clientes});

  final List<ClienteUsuario> clientes;
  bool failOnce = false;

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
    if (failOnce) {
      failOnce = false;
      throw StateError('indisponível');
    }
    return ClienteUsuarioListResponse(
      idUnicoDaEmpresa: 'empresa-1',
      total: clientes.length,
      clientes: clientes,
    );
  }
}
