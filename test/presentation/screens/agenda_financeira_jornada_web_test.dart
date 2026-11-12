import 'package:sixpos/presentation/components/web/agenda_resumo_periodo_web.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/sub_painel_lancamento_agenda_financeira_web.dart';

class _RegionalApi implements RegionalizacaoApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected call');
}

class _Calls {
  final requests = <LancamentoAgendaFinanceiraRequest>[];
  final spaces = <String>[];
  final metadata = <AgendaFinanceiraEdicaoCadastroRequest>[];
  Completer<LancamentoAgendaFinanceiraResponse>? pending;
  bool fail = false;
}

class _Service extends AgendaFinanceiraLancamentoService {
  _Service(this.calls)
    : super(httpClient: MockClient((_) async => http.Response('[]', 200)));
  final _Calls calls;
  @override
  Future<void> editarCadastroLancamento(
    String id,
    AgendaFinanceiraEdicaoCadastroRequest request,
  ) async {
    if (calls.fail) throw StateError('offline');
    calls.metadata.add(request);
  }

  @override
  AgendaFinanceiraLancamentoService paraEspaco(String espaco) =>
      _Service(calls)..espacoFinanceiro = espaco;
  @override
  Future<List<CentroCustoModel>> listarCentrosCusto() async => [];
  @override
  Future<LancamentoAgendaFinanceiraResponse> cadastrarLancamento(
    LancamentoAgendaFinanceiraRequest request,
  ) async {
    calls.requests.add(request);
    calls.spaces.add(espacoFinanceiro);
    if (calls.fail) throw StateError('offline');
    return calls.pending?.future ??
        Future.value(
          LancamentoAgendaFinanceiraResponse(id: 'created', status: 'CRIADO'),
        );
  }
}

Finder get _next => find.byKey(const ValueKey('journey-next'));
Finder _choice(String value) => find.byKey(ValueKey('journey-$value'));
String _label(WidgetTester tester, String key) =>
    tester.element(find.byType(Scaffold).last).t(key);
Finder _field(WidgetTester tester, String key) => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == _label(tester, key),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  _Calls calls, {
  double width = 1280,
  bool dark = false,
  String language = 'pt',
  bool edit = false,
  Map<String, dynamic>? initial,
  ValueChanged<Map<String, dynamic>?>? onResult,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.resetPhysicalSize();
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LocaleSettingsProvider(
        regionalizacaoService: RegionalizacaoService(apiClient: _RegionalApi()),
      ),
      child: MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        locale: Locale(language),
        supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showSubPainelLancamentoAgendaFinanceiraWeb(
                  context,
                  empresaSelecionada: 'Michelli',
                  empresas: const ['Michelli'],
                  service: _Service(calls),
                  modoEdicao: edit,
                  lancamentoInicial: edit
                      ? initial ??
                            {
                              'id': 'existing',
                              'tipo': 'pagar',
                              'descricao': 'Aluguel',
                              'valor': 100,
                              'status': 'PENDENTE',
                            }
                      : null,
                );
                onResult?.call(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('open'));
}

Future<void> _details(WidgetTester tester, {bool personal = true}) async {
  await _tap(tester, _choice('receive'));
  await _tap(tester, _next);
  await _tap(tester, _choice(personal ? 'personal' : 'company'));
  await _tap(tester, _next);
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(_field(tester, 'agenda.form.description'), 'Aluguel');
  await tester.enterText(_field(tester, 'agenda.form.amount'), '150');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pagar exige escolha antes de mostrar campos e preserva ao voltar', (tester) async {
    await _open(tester, _Calls());
    await _tap(tester, _choice('pay'));
    await _tap(tester, _next);
    await _tap(tester, _choice('personal'));
    await _tap(tester, _next);
    final selector=find.byKey(const ValueKey('journey-payment-destination'));
    expect(tester.widget<SegmentedButton<bool>>(selector).selected,isEmpty);
    expect(_field(tester,'agenda.form.description'),findsNothing);
    expect(tester.widget<FilledButton>(_next).onPressed,isNull);
    await _tap(tester,find.text('Pagamento direto'));
    expect(_field(tester,'agenda.form.description'),findsOneWidget);
    await _fill(tester);
    await _tap(tester,find.text('Voltar'));
    await _tap(tester,_next);
    expect(tester.widget<SegmentedButton<bool>>(selector).selected,{false});
    expect(tester.widget<TextField>(_field(tester,'agenda.form.description')).controller!.text,'Aluguel');
    expect(tester.takeException(),isNull);
  });

  for (final width in [390.0, 900.0, 1500.0]) {
    for (final language in ['pt', 'en', 'es']) {
      testWidgets('resumo do período em $language com largura $width', (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var receivedTaps = 0;
        var paidTaps = 0;
        await tester.pumpWidget(MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: width == 900 ? ThemeData.light() : ThemeData.dark(),
          home: Scaffold(body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AgendaResumoPeriodoWeb(
                receberAberto: 22800,
                pagarAberto: 1200,
                saldoARealizar: 21600,
                recebido: 11281.12,
                pago: 1380,
                realizado: 9901.12,
                projetado: 31501.12,
                formatarMoeda: (value) => value.toStringAsFixed(2),
                onRecebido: () => receivedTaps++,
                onPago: () => paidTaps++,
              ),
            ),
          )),
        ));
        await tester.pumpAndSettle();
        if (width >= 900) {
          final openRect = tester.getRect(
            find.byKey(const ValueKey('period-summary-panel-open')),
          );
          final actualRect = tester.getRect(
            find.byKey(const ValueKey('period-summary-panel-actual')),
          );
          expect(actualRect.top, openRect.top);
          expect(actualRect.height, openRect.height);
          if (width >= 1500) {
            final forecastRect = tester.getRect(
              find.byKey(const ValueKey('period-summary-panel-forecast')),
            );
            expect(forecastRect.top, openRect.top);
            expect(forecastRect.height, openRect.height);
          }
        }
        expect(find.text('31501.12'), findsOneWidget);
        expect(find.text('21600.00'), findsNWidgets(2));
        expect(find.text('9901.12'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        for (final key in ['received', 'paid']) {
          final row = find.byKey(ValueKey('period-summary-$key'));
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          await tester.tap(row);
        }
        expect(receivedTaps, 1);
        expect(paidTaps, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final status in ['PAGO', 'RECEBIDO', 'PARCIAL']) {
    testWidgets('edição web $status preserva baixa e recorrência no contrato', (
      tester,
    ) async {
      final calls = _Calls();
      await _open(
        tester,
        calls,
        edit: true,
        dark: status == 'PAGO',
        initial: {
          'id': 'existing',
          'tipo': status == 'RECEBIDO' ? 'receber' : 'pagar',
          'descricao': 'Escola',
          'status': status,
          'valorOriginal': 1680,
          'valorConfirmado': 1380,
          'valorRestante': status == 'PARCIAL' ? 300 : 0,
          'somenteCadastro': true,
          'serieRecorrenciaId': 'serie',
          'recorrente': true,
          'dataLiquidacao': '2026-11-11',
          'categoria': 'Educação',
          'observacoes': 'Preservar',
        },
      );
      expect(
        tester.widget<TextField>(_field(tester, 'agenda.form.amount')).enabled,
        false,
      );
      expect(_field(tester, 'agenda.form.due'), findsNothing);
      expect(find.text('Cancelar ocorrência'), findsNothing);
      await tester.enterText(
        _field(tester, 'agenda.form.description'),
        'Escola atualizada',
      );
      await _tap(tester, find.text('Atualizar lançamento'));
      expect(calls.requests, isEmpty);
      final data = calls.metadata.single.toJson();
      expect(data['descricao'], 'Escola atualizada');
      expect(data['observacoes'], 'Preservar');
      for (final key in [
        'valorTotalOperacao',
        'dataQuitacao',
        'statusOperacao',
        'recorrente',
        'formaPagamento',
        'contaFinanceiraId',
      ]) {
        expect(data.containsKey(key), false, reason: key);
      }
    });
  }

  testWidgets('erro de edição cadastral mantém os dados para nova tentativa', (
    tester,
  ) async {
    final calls = _Calls()..fail = true;
    await _open(
      tester,
      calls,
      edit: true,
      initial: {
        'id': 'existing',
        'tipo': 'pagar',
        'descricao': 'Escola',
        'status': 'PAGO',
        'valorOriginal': 1680,
        'valorConfirmado': 1380,
        'valorRestante': 0,
        'somenteCadastro': true,
      },
    );
    await tester.enterText(
      _field(tester, 'agenda.form.description'),
      'Correção',
    );
    await _tap(tester, find.text('Atualizar lançamento'));
    expect(find.text('Correção'), findsOneWidget);
    expect(calls.metadata, isEmpty);
    expect(find.byType(SnackBar), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    calls.fail = false;
    await _tap(tester, find.text('Atualizar lançamento'));
    expect(calls.metadata.single.descricao, 'Correção');
  });

  testWidgets(
    'exige escolhas e detalhes; voltar preserva dados e trocar espaço limpa categoria',
    (tester) async {
      final calls = _Calls();
      await _open(tester, calls);
      expect(tester.widget<FilledButton>(_next).onPressed, isNull);
      expect(find.byType(TextFormField), findsNothing);
      await _tap(tester, _choice('receive'));
      await _tap(tester, _next);
      expect(tester.widget<FilledButton>(_next).onPressed, isNull);
      await _tap(tester, _choice('personal'));
      await _tap(tester, _next);
      await _tap(tester, _next);
      expect(find.text('Quais são os dados do lançamento?'), findsOneWidget);
      expect(calls.requests, isEmpty);
      await _fill(tester);
      final category = _field(tester, 'agenda.form.category');
      await tester.ensureVisible(category);
      await tester.enterText(category, 'Moradia');
      await _tap(tester, _next);
      expect(find.text('Esse lançamento se repete?'), findsOneWidget);
      await _tap(tester, find.text('Voltar'));
      expect(
        tester
            .widget<TextField>(_field(tester, 'agenda.form.description'))
            .controller!
            .text,
        'Aluguel',
      );
      await _tap(tester, find.text('Voltar'));
      await _tap(tester, _choice('company'));
      await _tap(tester, _next);
      expect(
        tester
            .widget<TextField>(_field(tester, 'agenda.form.category'))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(_field(tester, 'agenda.form.amount'))
            .controller!
            .text,
        '150',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'salva uma vez, bloqueia fechamento e retorna o espaço escolhido',
    (tester) async {
      final calls = _Calls()
        ..pending = Completer<LancamentoAgendaFinanceiraResponse>();
      Map<String, dynamic>? saved;
      await _open(tester, calls, onResult: (value) => saved = value);
      await _details(tester);
      await _fill(tester);
      await _tap(tester, _next);
      await tester.tap(_next);
      await tester.pump();
      expect(calls.requests, hasLength(1));
      expect(calls.spaces, ['PESSOAL']);
      expect(tester.widget<FilledButton>(_next).onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Esse lançamento se repete?'), findsOneWidget);
      calls.pending!.complete(
        LancamentoAgendaFinanceiraResponse(id: 'created', status: 'CRIADO'),
      );
      await tester.pumpAndSettle();
      expect(saved?['espacoFinanceiro'], 'PESSOAL');
      expect(saved?['registrarPagamento'], false);
      expect(calls.requests.single.configuracaoRecorrencia!.ativa, false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recorrência valida quantidade e erro permite repetir a mesma operação',
    (tester) async {
      final calls = _Calls()..fail = true;
      await _open(tester, calls);
      await _details(tester, personal: false);
      await _fill(tester);
      await _tap(tester, _next);
      await _tap(tester, _choice('repeat'));
      await _tap(tester, find.text('Encerrar repetição: Sem data final'));
      await _tap(tester, find.text('Após uma quantidade').last);
      final count = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Quantidade de ocorrências',
      );
      await tester.ensureVisible(count);
      await tester.enterText(count, '0');
      await _tap(tester, _next);
      expect(calls.requests, isEmpty);
      await tester.enterText(count, '3');
      await _tap(tester, _next);
      expect(calls.requests, hasLength(1));
      expect(find.text('Esse lançamento se repete?'), findsOneWidget);
      calls.fail = false;
      await _tap(tester, _next);
      expect(calls.requests, hasLength(2));
      expect(
        calls.requests.first.uuidOperacaoApp,
        calls.requests.last.uuidOperacaoApp,
      );
      expect(calls.requests.last.configuracaoRecorrencia!.quantidade, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirma descarte e mantém edição direta', (tester) async {
    await _open(tester, _Calls());
    await _tap(tester, _choice('pay'));
    await _tap(tester, find.byIcon(Icons.close_rounded));
    expect(find.text('Descartar este lançamento?'), findsOneWidget);
    await _tap(tester, find.text('Continuar preenchendo'));
    expect(find.text('Você vai pagar ou receber?'), findsOneWidget);
    await _tap(tester, find.byIcon(Icons.close_rounded));
    await _tap(tester, find.text('Descartar'));
    expect(find.text('open'), findsOneWidget);
    await _open(tester, _Calls(), edit: true);
    expect(_next, findsNothing);
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('sem overflow compacto em $language e tema escuro', (
      tester,
    ) async {
      await _open(tester, _Calls(), width: 600, dark: true, language: language);
      await _details(tester);
      await _fill(tester);
      await _tap(tester, _next);
      await _tap(tester, _choice('repeat'));
      expect(tester.takeException(), isNull);
    });
  }
}
