import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/atendimento_tecnico_models.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_editar_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  testWidgets('renderiza backdrop dark e fecha com escape', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir edição'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('atendimento-tecnico-edit-dialog')),
      findsOneWidget,
    );
    expect(find.text('Editar AT-42'), findsOneWidget);
    expect(find.text('Cliente teste'), findsWidgets);
    expect(find.text('R\$ 249,90'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('atendimento-tecnico-edit-dialog')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final LocaleSettingsProvider localeSettingsProvider = LocaleSettingsProvider(
    regionalizacaoService: RegionalizacaoService(
      apiClient: _FakeRegionalizacaoApiClient(),
    ),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>.value(
      value: localeSettingsProvider,
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: WebThemeTokens.applyTo(ThemeData.light(useMaterial3: true)),
        darkTheme: WebThemeTokens.applyTo(ThemeData.dark(useMaterial3: true)),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Builder(
            builder:
                (BuildContext context) => Center(
                  child: FilledButton(
                    onPressed: () {
                      showAtendimentoTecnicoEditarDialog(
                        context: context,
                        atendimento: _buildAtendimento(),
                        clienteApiClient: _FakeClienteUsuarioApiClient(),
                        colaboradorApiClient:
                            _FakeColaboradorUsuarioApiClient(),
                      );
                    },
                    child: const Text('Abrir edição'),
                  ),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AtendimentoTecnicoModel _buildAtendimento() {
  return AtendimentoTecnicoModel(
    id: 'at-1',
    numero: 'AT-42',
    statusId: 1,
    statusCodigo: 'OPEN',
    statusI18nKey: 'status.open',
    valorTotalProdutos: 149.90,
    valorTotalServicos: 100,
    valorTotalAtendimento: 249.90,
    valorRecebido: 0,
    valorEmAberto: 249.90,
    operacaoLiquidada: false,
    statusLiquidacaoCodigo: 'OPEN',
    itens: const <AtendimentoTecnicoItemModel>[
      AtendimentoTecnicoItemModel(
        id: 'item-1',
        tipoItemId: 1,
        tipoItemCodigo: 'PRODUCT',
        tipoItemI18nKey: 'product',
        descricaoSnapshot: 'Película',
        quantidade: 1,
        valorUnitario: 149.90,
        desconto: 0,
        valorTotal: 149.90,
        movimentaEstoque: true,
        statusEstoqueId: 1,
        statusEstoqueCodigo: 'OK',
      ),
      AtendimentoTecnicoItemModel(
        id: 'item-2',
        tipoItemId: 2,
        tipoItemCodigo: 'SERVICE',
        tipoItemI18nKey: 'service',
        descricaoSnapshot: 'Troca de tela',
        quantidade: 1,
        valorUnitario: 100,
        desconto: 0,
        valorTotal: 100,
        movimentaEstoque: false,
        statusEstoqueId: 1,
        statusEstoqueCodigo: 'OK',
      ),
    ],
    historicoStatus: const <AtendimentoTecnicoHistoricoStatusModel>[],
    historicoAuditoria: const <AtendimentoTecnicoAuditoriaModel>[],
    recebimentos: const <AtendimentoTecnicoRecebimentoModel>[],
    nomeClienteSnapshot: 'Cliente teste',
    idCliente: 'cli-1',
    nomeTecnicoResponsavelSnapshot: 'Técnico teste',
    idTecnicoResponsavel: 'tec-1',
    descricao: 'Aparelho com tela quebrada',
    equipamento: const AtendimentoTecnicoEquipamentoModel(
      tipo: 'SMARTPHONE',
      marca: 'Marca',
      modelo: 'Modelo',
    ),
    validadeOrcamentoEm: DateTime(2026, 8, 26),
    dataVencimentoEm: DateTime(2026, 8, 26),
    dataEntregaPrevista: DateTime(2026, 8, 27),
  );
}

class _FakeClienteUsuarioApiClient implements ClienteUsuarioApiClient {
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
      total: 1,
      clientes: <ClienteUsuario>[
        ClienteUsuario(
          id: 'cli-1',
          idUsuario: 'user-1',
          idUnicoDaEmpresa: 'empresa-1',
          ativo: true,
          tipoPessoa: 'PF',
          documento: '123',
          nome: 'Cliente teste',
          telefone: '',
          email: '',
          cep: '',
          logradouro: '',
          numero: '',
          complemento: '',
          bairro: '',
          cidade: '',
          uf: '',
          observacoes: '',
          origemAutoCadastro: '',
          enviadoEm: null,
          criadoEm: null,
          atualizadoEm: null,
          foto: '',
          permiteCompraFiado: false,
          limiteFiado: 0,
          saldoFiado: 0,
          prazoPagamentoDias: 0,
          bloqueadoFiado: false,
        ),
      ],
    );
  }
}

class _FakeColaboradorUsuarioApiClient implements ColaboradorUsuarioApiClient {
  @override
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(String idUnicoDoUsuario) {
    throw UnimplementedError();
  }

  @override
  Future<void> editarColaborador(Map<String, dynamic> payload) {
    throw UnimplementedError();
  }

  @override
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores() async {
    return <ColaboradorUsuarioResumo>[
      ColaboradorUsuarioResumo(
        idUnicoPessoal: 'tec-1',
        nome: 'Técnico teste',
        nomeDeGuerra: 'Técnico teste',
        celularDeAcesso: '',
        email: 'tecnico@six.test',
        foto: '',
        dataCadastro: null,
        ehUmTecnicoEFazAssistenciaTecnica: true,
      ),
    ];
  }

  @override
  Future<List<ColaboradorUsuarioResumo>> listarTecnicosAssistenciaTecnica() =>
      listarColaboradores();
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async {
    return ConfiguracaoRegionalizacaoResponse.fromJson(
      _defaultRegionalizacaoJson(),
    );
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) async {
    return ConfiguracaoRegionalizacaoResponse.fromJson(request.toJson());
  }
}

Map<String, dynamic> _defaultRegionalizacaoJson() {
  return <String, dynamic>{
    'languageCode': 'pt',
    'countryCode': 'BR',
    'locale': 'pt-BR',
    'formatting': <String, dynamic>{
      'currencyCode': 'BRL',
      'timeZone': 'America/Sao_Paulo',
      'dateFormat': 'dd/MM/yyyy',
      'timeFormat': 'HH:mm',
      'decimalSeparator': ',',
      'thousandSeparator': '.',
      'firstDayOfWeek': 'MONDAY',
      'numberPattern': '#,##0.00',
      'decimalPlaces': 2,
      'allowMultipleCurrencies': false,
      'applyFinancialRounding': false,
    },
  };
}
