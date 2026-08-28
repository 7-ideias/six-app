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
  SixWebCreateCustomerFlow? onCreateCustomer,
  ValueChanged<ClienteIdentificacaoVendaResult?>? onResult,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
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
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
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
    return ClienteUsuarioListResponse(
      idUnicoDaEmpresa: 'empresa-1',
      total: clientes.length,
      clientes: clientes,
    );
  }
}
