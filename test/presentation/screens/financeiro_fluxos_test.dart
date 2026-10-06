import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/core/services/recebivel_venda_service.dart';
import 'package:sixpos/data/models/recebimento_forma_input.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/l10n/web_i18n_store.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/mobile/destinos_recebimento_mobile.dart';
import 'package:sixpos/presentation/components/web/destinos_recebimento_web.dart';
import 'package:sixpos/presentation/components/mobile/conta_financeira_mobile_field.dart';
import 'package:sixpos/presentation/components/web/conta_financeira_web_field.dart';
import 'package:sixpos/presentation/screens/recebiveis_vendas_mobile.dart';
import 'package:sixpos/presentation/screens/configuracoes_espaco_mobile.dart';
import 'package:sixpos/presentation/screens/configuracoes_espaco_web.dart';
import 'package:sixpos/presentation/screens/recebiveis_vendas_web.dart';

class _RegionalApi implements RegionalizacaoApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected regional API call');
}

Widget _app(Widget child) => ChangeNotifierProvider(
  create:
      (_) => LocaleSettingsProvider(
        regionalizacaoService: RegionalizacaoService(apiClient: _RegionalApi()),
      ),
  child: MaterialApp(
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
    home: child,
  ),
);

String _label(WidgetTester tester, String key) =>
    tester.element(find.byType(Scaffold).first).t(key);
Finder _text(WidgetTester tester, String key) => find.text(_label(tester, key));
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _save() => find.byType(FilledButton);
void _canSave(WidgetTester tester, bool enabled) => expect(
  tester.widget<FilledButton>(_save()).onPressed,
  enabled ? isNotNull : isNull,
);

class _Settings extends ConfiguracaoFinanceiraService {
  _Settings([String espaco = 'EMPRESA']) : super(espaco);
  final groups = <String>[];
  final saves = <Map<String, dynamic>>[];
  @override
  Future<void> salvar(
    String grupo, {
    ConfiguracaoFinanceira? original,
    required String nome,
    required String tipo,
    required String instituicao,
    required bool ativo,
    String? contaDestinoId,
  }) async {
    saves.add({
      'espaco': espaco,
      'grupo': grupo,
      'nome': nome,
      'tipo': tipo,
      'instituicao': instituicao,
      'ativo': ativo,
      'contaDestinoId': contaDestinoId,
    });
  }

  Completer<List<ConfiguracaoFinanceira>>? pending;
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async {
    groups.add(grupo);
    if (pending != null) return pending!.future;
    if (grupo == 'MAQUININHAS')
      return const [
        ConfiguracaoFinanceira(
          id: 'm1',
          nome: 'Terminal A',
          tipo: 'OUTROS',
          contaDestinoId: 'a',
        ),
        ConfiguracaoFinanceira(
          id: 'm2',
          nome: 'Terminal B',
          tipo: 'OUTROS',
          contaDestinoId: 'b',
        ),
      ];
    return [
      ConfiguracaoFinanceira(id: 'a', nome: '$espaco A', tipo: 'BANCO'),
      ConfiguracaoFinanceira(id: 'b', nome: '$espaco B', tipo: 'BANCO'),
      const ConfiguracaoFinanceira(
        id: 'inactive',
        nome: 'Inativa',
        tipo: 'BANCO',
        ativo: false,
      ),
    ];
  }
}

class _Accounts extends _Settings {
  _Accounts() : super('PESSOAL');
  final created = <ConfiguracaoFinanceira>[];
  bool failCreate = false;
  int createCalls = 0;
  Completer<void>? saving;
  @override
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async => created;
  @override
  Future<ConfiguracaoFinanceira> criarConta({
    required String nome,
    required String tipo,
    required String instituicao,
  }) async {
    createCalls++;
    if (saving != null) await saving!.future;
    if (failCreate) throw StateError('forbidden');
    final conta = ConfiguracaoFinanceira(
      id: 'persisted-account-id',
      nome: nome.trim(),
      tipo: tipo,
      instituicao: instituicao.trim(),
    );
    created.add(conta);
    return conta;
  }
}

class _Receivables extends RecebivelVendaService {
  String status = 'PREVISTO';
  final confirmations = <Map<String, dynamic>>[];
  final reversals = <String>[];
  bool fail = false;
  Completer<void>? pending;
  int loads = 0;
  @override
  Future<List<RecebivelVenda>> listar() async {
    loads++;
    return [
      RecebivelVenda.fromJson({
        'id': 'r1',
        'codigoOperacao': 'VENDA-42',
        'descricao': 'Cartão',
        'contaNome': 'EMPRESA A',
        'maquininhaNome': 'Terminal A',
        'status': status,
        'bruto': 100,
        'taxa': 3,
        'liquido': 97,
        'dataPrevista': '2026-10-06',
        if (status == 'RECEBIDO') 'valorRecebido': 95.5,
        if (status == 'RECEBIDO') 'dataRecebimento': '2026-10-06',
      }),
    ];
  }

  @override
  Future<void> confirmar(String id, DateTime data, double valor) async {
    confirmations.add({
      'id': id,
      'dataRecebimento': data,
      'valorRecebido': valor,
    });
    if (pending != null) await pending!.future;
    if (fail) throw StateError('failed');
    status = 'RECEBIDO';
  }

  @override
  Future<void> estornar(String id) async {
    reversals.add(id);
    if (fail) throw StateError('failed');
    status = 'PREVISTO';
  }
}

void main() {
  setUp(
    () => SixI18nStore.instance.setMessages('pt', {
      'machine.confirm': 'Confirmar depósito',
      'machine.reverse': 'Estornar depósito',
      'machine.PREVISTO': 'Previsto',
      'machine.RECEBIDO': 'Recebido',
      'machine.CANCELADO': 'Cancelado',
      'machine.reverseHint': 'O estorno do depósito mantém o cliente quitado.',
      'machine.machine': 'Maquininha',
      'machine.gross': 'Bruto',
      'machine.fee': 'Taxa',
      'machine.net': 'Líquido',
      'machine.future': 'Recebimento futuro',
      'machine.expectedDate': 'Previsão',
      'machine.split': 'Dividir',
      'machine.destinations': 'Destinos',
      'machine.destinationHint': 'Informe os destinos.',
      'machine.review': 'Revise contas e valores.',
      'machine.actualAmount': 'Valor recebido',
      'machine.receivables': 'Recebíveis de vendas',
      'machine.receivablesHint': 'Acompanhe os depósitos.',
      'machine.operator': 'Operadora',
      'space.MAQUININHAS': 'Maquininhas',
    }),
  );
  tearDown(() => SixI18nStore.instance.setMessages('pt', {}));
  for (final mobile in [false, true]) {
    final platform = mobile ? 'Mobile' : 'Web';
    Future<void> size(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(Size(mobile ? 430 : 1100, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    Widget destinations(
      _Settings service,
      List<RecebimentoFormaInput> formas,
    ) =>
        mobile
            ? DestinosRecebimentoMobile(formas: formas, service: service)
            : DestinosRecebimentoWeb(formas: formas, service: service);
    Widget receivables(_Receivables service) =>
        mobile
            ? RecebiveisVendasMobile(service: service)
            : RecebiveisVendasWeb(service: service);

    testWidgets(
      '$platform: configuração salva conta padrão no espaço correto após troca',
      (tester) async {
        await size(tester);
        final personal = _Settings('PESSOAL');
        final company = _Settings();
        addTearDown(personal.dispose);
        addTearDown(company.dispose);
        Widget settings(_Settings s) => _app(
          mobile
              ? ConfiguracoesEspacoMobile(espaco: s.espaco, service: s)
              : ConfiguracoesEspacoWeb(espaco: s.espaco, service: s),
        );
        await tester.pumpWidget(settings(personal));
        await tester.pumpAndSettle();
        expect(find.text('PESSOAL A'), findsOneWidget);
        await tester.pumpWidget(settings(company));
        await tester.pumpAndSettle();
        expect(find.text('PESSOAL A'), findsNothing);
        expect(find.text('EMPRESA A'), findsOneWidget);
        await _tap(tester, _text(tester, 'space.MAQUININHAS'));
        await _tap(tester, find.byIcon(Icons.edit_outlined).first);
        await tester.enterText(
          find.byType(TextFormField),
          'Terminal atualizado',
        );
        await _tap(
          tester,
          find.widgetWithIcon(OutlinedButton, Icons.account_balance_outlined),
        );
        await _tap(tester, find.text('EMPRESA B'));
        await _tap(tester, _save());
        expect(personal.saves, isEmpty);
        expect(company.saves.single, {
          'espaco': 'EMPRESA',
          'grupo': 'MAQUININHAS',
          'nome': 'Terminal atualizado',
          'tipo': 'MAQUININHA',
          'instituicao': '',
          'ativo': true,
          'contaDestinoId': 'b',
        });
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: conta obrigatória, conta padrão e divisão preservam payload',
      (tester) async {
        await size(tester);
        final service = _Settings();
        addTearDown(service.dispose);
        List<RecebimentoFormaInput>? submitted;
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Builder(
                builder:
                    (context) => TextButton(
                      child: const Text('Abrir'),
                      onPressed: () async {
                        submitted = await Navigator.of(
                          context,
                        ).push<List<RecebimentoFormaInput>>(
                          MaterialPageRoute(
                            builder:
                                (_) => Scaffold(
                                  body: destinations(service, const [
                                    RecebimentoFormaInput(
                                      codigo: 'tipo3',
                                      valor: 100,
                                    ),
                                  ]),
                                ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        );
        await _tap(tester, find.text('Abrir'));
        _canSave(tester, false);
        expect(service.groups, containsAll(['CONTAS', 'MAQUININHAS']));
        await _tap(
          tester,
          find.widgetWithIcon(OutlinedButton, Icons.point_of_sale).first,
        );
        await _tap(tester, find.text('Terminal A'));
        expect(find.textContaining('EMPRESA A'), findsOneWidget);
        _canSave(tester, true);
        await _tap(tester, find.byIcon(Icons.call_split).first);
        _canSave(tester, false);
        await _tap(
          tester,
          find.widgetWithIcon(OutlinedButton, Icons.point_of_sale).last,
        );
        await _tap(tester, find.text('Terminal B'));
        _canSave(tester, true);
        expect(find.textContaining('EMPRESA B'), findsOneWidget);
        final value = find.byKey(const ValueKey('valor-1-2'));
        await tester.ensureVisible(value);
        await tester.enterText(value, '49,00');
        await tester.pump();
        _canSave(tester, false);
        expect(submitted, isNull);
        await tester.enterText(value, '50,00');
        await tester.pump();
        _canSave(tester, true);
        // An explicit account overrides the terminal's default only on this row.
        await _tap(
          tester,
          find
              .widgetWithIcon(OutlinedButton, Icons.account_balance_outlined)
              .last,
        );
        expect(find.text('Inativa'), findsNothing);
        await _tap(tester, find.text('EMPRESA A'));
        await _tap(tester, _save());
        expect(submitted, hasLength(2));
        expect(submitted!.map((p) => p.codigo), ['tipo3', 'tipo3']);
        expect(submitted!.map((p) => p.valor), [50, 50]);
        expect(submitted!.map((p) => p.maquininhaId), ['m1', 'm2']);
        expect(submitted!.map((p) => p.contaFinanceiraId), ['a', 'a']);
        expect(
          submitted!.every(
            (p) => p.recebimentoFuturo && p.dataPrevista != null,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: mesma forma dividida entre duas contas sem maquininha',
      (tester) async {
        await size(tester);
        final service = _Settings();
        addTearDown(service.dispose);
        List<RecebimentoFormaInput>? submitted;
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Builder(
                builder:
                    (context) => TextButton(
                      child: const Text('Abrir'),
                      onPressed: () async {
                        submitted = await Navigator.of(
                          context,
                        ).push<List<RecebimentoFormaInput>>(
                          MaterialPageRoute(
                            builder:
                                (_) => Scaffold(
                                  body: destinations(service, const [
                                    RecebimentoFormaInput(
                                      codigo: 'tipo1',
                                      valor: 100,
                                    ),
                                  ]),
                                ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        );
        await _tap(tester, find.text('Abrir'));
        await _tap(
          tester,
          find
              .widgetWithIcon(OutlinedButton, Icons.account_balance_outlined)
              .first,
        );
        await _tap(tester, find.text('EMPRESA A'));
        await _tap(tester, find.byIcon(Icons.call_split).first);
        await _tap(
          tester,
          find
              .widgetWithIcon(OutlinedButton, Icons.account_balance_outlined)
              .last,
        );
        await _tap(tester, find.text('EMPRESA B'));
        await _tap(tester, _save());
        expect(submitted!.map((p) => p.contaFinanceiraId), ['a', 'b']);
        expect(submitted!.map((p) => p.valor), [50, 50]);
        expect(
          submitted!.every(
            (p) => p.maquininhaId == null && !p.recebimentoFuturo,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: confirmar e estornar enviam ID/valor/data e recarregam estado',
      (tester) async {
        await size(tester);
        final service = _Receivables();
        addTearDown(service.dispose);
        await tester.pumpWidget(_app(receivables(service)));
        await tester.pumpAndSettle();
        await _tap(tester, _text(tester, 'machine.confirm'));
        await _tap(tester, _text(tester, 'space.cancel'));
        expect(service.confirmations, isEmpty);
        await _tap(tester, _text(tester, 'machine.confirm'));
        await tester.enterText(find.byType(TextField), '0');
        await tester.pump();
        _canSave(tester, false);
        await tester.enterText(find.byType(TextField), '95,50');
        await tester.pump();
        await _tap(tester, _save());
        expect(service.confirmations, hasLength(1));
        expect(service.confirmations.single['id'], 'r1');
        expect(service.confirmations.single['valorRecebido'], 95.5);
        final date =
            service.confirmations.single['dataRecebimento'] as DateTime;
        expect(DateUtils.isSameDay(date, DateTime.now()), isTrue);
        expect(service.loads, 2);
        await _tap(tester, _text(tester, 'machine.RECEBIDO'));
        await _tap(tester, _text(tester, 'machine.reverse'));
        expect(_text(tester, 'machine.reverseHint'), findsOneWidget);
        await _tap(tester, _text(tester, 'space.cancel'));
        expect(service.reversals, isEmpty);
        await _tap(tester, _text(tester, 'machine.reverse'));
        await _tap(tester, _save());
        expect(service.reversals, ['r1']);
        expect(service.loads, 3);
        await _tap(tester, _text(tester, 'machine.PREVISTO'));
        expect(_text(tester, 'machine.confirm'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: falha ao confirmar mantém recebível previsto e permite tentar novamente',
      (tester) async {
        await size(tester);
        final service = _Receivables()..fail = true;
        addTearDown(service.dispose);
        await tester.pumpWidget(_app(receivables(service)));
        await tester.pumpAndSettle();
        await _tap(tester, _text(tester, 'machine.confirm'));
        await _tap(tester, _save());
        expect(_text(tester, 'space.saveError'), findsOneWidget);
        expect(service.status, 'PREVISTO');
        expect(service.loads, 1);
        service.fail = false;
        await _tap(tester, _text(tester, 'machine.confirm'));
        await _tap(tester, _save());
        expect(service.confirmations, hasLength(2));
        expect(service.status, 'RECEBIDO');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: confirmação em andamento bloqueia envio duplicado',
      (tester) async {
        await size(tester);
        final service = _Receivables()..pending = Completer<void>();
        addTearDown(service.dispose);
        await tester.pumpWidget(_app(receivables(service)));
        await tester.pumpAndSettle();
        await _tap(tester, _text(tester, 'machine.confirm'));
        await _tap(tester, _save());
        expect(service.confirmations, hasLength(1));
        final button = find.widgetWithText(
          OutlinedButton,
          _label(tester, 'machine.confirm'),
        );
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
        await tester.tap(button);
        await tester.pump();
        expect(service.confirmations, hasLength(1));
        service.pending!.complete();
        await tester.pumpAndSettle();
        expect(service.loads, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: cadastrar no seletor seleciona o ID e mantém o espaço',
      (tester) async {
        await size(tester);
        final service = _Accounts();
        addTearDown(service.dispose);
        String? selected;
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: StatefulBuilder(
                builder:
                    (context, setState) =>
                        mobile
                            ? ContaFinanceiraMobileField(
                              espaco: service.espaco,
                              service: service,
                              value: selected,
                              onChanged: (id) => setState(() => selected = id),
                            )
                            : ContaFinanceiraWebField(
                              espaco: service.espaco,
                              service: service,
                              value: selected,
                              onChanged: (id) => setState(() => selected = id),
                            ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.byType(OutlinedButton));
        expect(_text(tester, 'space.emptyAccountHint'), findsOneWidget);
        await _tap(
          tester,
          find.byKey(const ValueKey('cadastrar-conta-no-seletor')),
        );
        expect(_text(tester, 'space.PESSOAL'), findsOneWidget);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, _label(tester, 'space.save')),
        );
        expect(service.createCalls, 0);
        await tester.enterText(find.byType(TextFormField), 'Minha conta');
        service.saving = Completer<void>();
        await tester.tap(
          find.widgetWithText(FilledButton, _label(tester, 'space.save')),
        );
        await tester.pump();
        expect(service.createCalls, 1);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
          isNull,
        );
        service.saving!.complete();
        await tester.pumpAndSettle();
        expect(selected, 'persisted-account-id');
        expect(service.created.single.tipo, 'BANCO');
        expect(service.espaco, 'PESSOAL');
        expect(find.textContaining('Minha conta'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$platform: erro mantém cadastro aberto e cancelar preserva seleção',
      (tester) async {
        await size(tester);
        final service = _Accounts()..failCreate = true;
        addTearDown(service.dispose);
        final changes = <String?>[];
        await tester.pumpWidget(
          _app(
            Scaffold(
              body:
                  mobile
                      ? ContaFinanceiraMobileField(
                        espaco: service.espaco,
                        service: service,
                        onChanged: changes.add,
                      )
                      : ContaFinanceiraWebField(
                        espaco: service.espaco,
                        service: service,
                        onChanged: changes.add,
                      ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.byType(OutlinedButton));
        await _tap(
          tester,
          find.byKey(const ValueKey('cadastrar-conta-no-seletor')),
        );
        await tester.enterText(find.byType(TextFormField), 'Minha conta');
        await _tap(
          tester,
          find.widgetWithText(FilledButton, _label(tester, 'space.save')),
        );
        expect(_text(tester, 'space.saveError'), findsOneWidget);
        expect(changes, isEmpty);
        await _tap(
          tester,
          find.widgetWithText(TextButton, _label(tester, 'space.cancel')).last,
        );
        expect(
          find.byKey(const ValueKey('cadastrar-conta-no-seletor')),
          findsOneWidget,
        );
        expect(changes, isEmpty);
        expect(service.created, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$platform: trocar Pessoal/Empresa descarta resposta antiga', (
      tester,
    ) async {
      await size(tester);
      final personal = _Settings('PESSOAL')
        ..pending = Completer<List<ConfiguracaoFinanceira>>();
      final company = _Settings();
      addTearDown(personal.dispose);
      addTearDown(company.dispose);
      final changes = <String?>[];
      Widget field(_Settings s) => _app(
        Scaffold(
          body:
              mobile
                  ? ContaFinanceiraMobileField(
                    espaco: s.espaco,
                    service: s,
                    value: 'a',
                    onChanged: changes.add,
                  )
                  : ContaFinanceiraWebField(
                    espaco: s.espaco,
                    service: s,
                    value: 'a',
                    onChanged: changes.add,
                  ),
        ),
      );
      await tester.pumpWidget(field(personal));
      await tester.pump();
      await tester.pumpWidget(field(company));
      await tester.pumpAndSettle();
      expect(find.textContaining('EMPRESA A'), findsOneWidget);
      personal.pending!.complete(const [
        ConfiguracaoFinanceira(id: 'a', nome: 'Pessoal antiga', tipo: 'BANCO'),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Pessoal antiga'), findsNothing);
      await _tap(tester, find.byType(OutlinedButton));
      expect(find.text('EMPRESA B'), findsOneWidget);
      expect(find.textContaining('PESSOAL'), findsNothing);
      await _tap(tester, find.text('EMPRESA B'));
      expect(changes, ['b']);
      expect(tester.takeException(), isNull);
    });
  }
}
