import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/admin_portal_service.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/data/models/agenda_email_models.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/screens/super_panel_mobile_screen.dart';
import 'package:sixpos/presentation/screens/super_panel_web_page.dart';
import 'package:sixpos/presentation/controllers/super_panel_controller.dart';

const _summary = AdminPortalResumo(
  totalEmpresasCadastradas: 1,
  totalEmpresasAtivas: 1,
  bancosDeDados: [
    AdminBancoDadosResumo(
      nome: 'database-private',
      tamanhoDadosBytes: 512,
      tamanhoArmazenadoBytes: 1024,
      tamanhoIndicesBytes: 128,
      tamanhoTotalBytes: 2048,
      quantidadeColecoes: 2,
      quantidadeObjetos: 8,
    ),
  ],
  requestsHttp: AdminRequestStatusResumo(
    status200: 7,
    status400: 1,
    status500: 0,
    janelaValor: 15,
    janelaUnidade: AdminRequestWindowUnit.minutes,
  ),
);

class _Service implements AdminPortalService {
  AdminPortalResumo summary = _summary;
  int calls = 0;
  int? window;
  AdminRequestWindowUnit? unit;
  Completer<AdminPortalResumo>? pending;
  bool fail = false;
  @override
  Future<AdminPortalResumo> buscarResumo({
    int? janelaValor,
    AdminRequestWindowUnit? janelaUnidade,
  }) async {
    calls++;
    window = janelaValor;
    unit = janelaUnidade;
    if (fail) throw StateError('private backend error');
    return pending == null ? summary : pending!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResendService extends _Service {
  final destinosConsultados = <String>[];
  final envios = <(String, String)>[];

  @override
  Future<List<AdminUsuarioEmpresaAtiva>> listarUsuariosSixo() async => [
    AdminUsuarioEmpresaAtiva.fromJson({'keycloakId': 'ana-id', 'nome': 'Ana'}),
  ];

  @override
  Future<List<AgendaEmailDestino>> listarDestinosAgendaEmail(
    String idUsuario,
  ) async {
    destinosConsultados.add(idUsuario);
    return [
      for (final nome in ['Loja A', 'Loja B'])
        AgendaEmailDestino(
          idEmpresa: nome,
          nomeEmpresa: nome,
          email: 'ana@example.test',
        ),
    ];
  }

  @override
  Future<AgendaEmailResultado> reenviarAgendaEmail({
    required String idUsuario,
    required String idEmpresa,
    required String chaveRequisicao,
  }) async {
    envios.add((idUsuario, idEmpresa));
    return const AgendaEmailResultado(idEnvio: 'envio', status: 'ENVIADO');
  }
}

class _Permissions extends ColaboradorAutorizacoesProvider {
  _Permissions(this.allowed, {this.admin = false});
  bool allowed;
  final bool admin;
  @override
  bool get ehSuperUsuario => allowed;
  @override
  bool get ehAdministrador => admin;
  void revoke() {
    allowed = false;
    notifyListeners();
  }
}

class _Locale extends ChangeNotifier implements LocaleSettingsProvider {
  @override
  String get timeZone => 'UTC';
  @override
  Locale get currentLocale => const Locale('pt', 'BR');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'controller does not query without SUPER, and ignores late responses after revocation',
    () async {
      final service = _Service()..pending = Completer<AdminPortalResumo>();
      final controller = SuperPanelController(service: service);
      await controller.reload();
      expect(service.calls, 0);
      controller.setAuthorized(true);
      expect(service.calls, 1);
      controller.setAuthorized(false);
      service.pending!.complete(_summary);
      await Future<void>.delayed(Duration.zero);
      expect(controller.resumo, isNull);
      expect(controller.loading, isFalse);
      controller.dispose();
    },
  );

  test(
    'controller preserves window, reports refresh errors and supports retry',
    () async {
      final service = _Service();
      final controller = SuperPanelController(service: service);
      controller.setAuthorized(true);
      await Future<void>.delayed(Duration.zero);
      service.fail = true;
      await controller.changeWindow(2, AdminRequestWindowUnit.hours);
      expect(service.window, 2);
      expect(service.unit, AdminRequestWindowUnit.hours);
      expect(controller.hasError, isTrue);
      expect(controller.resumo, isNull);
      service.fail = false;
      await controller.reload();
      expect(controller.hasError, isFalse);
      controller.dispose();
    },
  );

  testWidgets(
    'Web renders observed metrics, restart and an unavailable database',
    (tester) async {
      final service =
          _Service()
            ..summary = AdminPortalResumo.fromJson({
              'bancosDeDados': [
                {'nome': 'MongoDB', 'available': false},
              ],
              'cockpit': {
                'startedAt': 90000,
                'collectedAt': 145000,
                'observedMs': 55000,
                'total': 2,
                'serverErrors': 1,
                'p95': 200,
                'points': [
                  {
                    'time': 0,
                    'observedMs': 0,
                    'total': 0,
                    'clientErrors': 0,
                    'serverErrors': 0,
                  },
                  {
                    'time': 60000,
                    'observedMs': 30000,
                    'total': 2,
                    'clientErrors': 0,
                    'serverErrors': 1,
                    'p50': 40,
                    'p95': 200,
                  },
                  {
                    'time': 120000,
                    'observedMs': 25000,
                    'total': 0,
                    'clientErrors': 0,
                    'serverErrors': 0,
                  },
                ],
                'events': [
                  {'time': 90000, 'type': 'START'},
                ],
              },
            });
      await _pump(tester, false, service, _Permissions(true));
      expect(find.text('1 · 50%'), findsOneWidget);
      expect(find.text('≈ 200 ms'), findsOneWidget);
      expect(find.textContaining('Backend iniciado'), findsOneWidget);
      expect(find.text('Indisponível'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mobile in [false, true]) {
    for (final admin in [false, true]) {
      testWidgets(
        '${mobile ? 'Mobile' : 'Web'} blocks direct entry for non-SUPER, admin=$admin',
        (tester) async {
          final service = _Service();
          final permissions = _Permissions(false, admin: admin);
          await _pump(tester, mobile, service, permissions);
          expect(
            find.byKey(const Key('super-panel-restricted')),
            findsOneWidget,
          );
          expect(service.calls, 0);
          expect(find.text('Usuários do Sixo'), findsNothing);
          expect(find.text('database-private'), findsNothing);
        },
      );
    }
    testWidgets(
      '${mobile ? 'Mobile' : 'Web'} loads for SUPER and hides data when permission is revoked',
      (tester) async {
        final service = _Service();
        final permissions = _Permissions(true);
        await _pump(tester, mobile, service, permissions);
        expect(service.calls, 1);
        expect(find.text('database-private'), findsOneWidget);
        permissions.revoke();
        await tester.pump();
        expect(find.byKey(const Key('super-panel-restricted')), findsOneWidget);
        expect(find.text('database-private'), findsNothing);
        expect(service.calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final dark in [false, true]) {
    testWidgets('SUPER reenvia pela lista mobile, tema escuro=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _ResendService();
      await _pump(tester, true, service, _Permissions(true), dark: dark);
      await tester.tap(find.text('Usuários do Sixo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      final atalho = find.text('Reenviar resumo financeiro');
      await tester.ensureVisible(atalho);
      expect(service.destinosConsultados, isEmpty);
      await tester.tap(atalho);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(service.destinosConsultados, ['ana-id']);
      expect(find.text('ana@example.test'), findsNWidgets(2));
      expect(service.envios, isEmpty);
      await tester.tap(find.text('Loja B'));
      await tester.pump();
      final confirmar = find.text('Confirmar envio');
      await tester.ensureVisible(confirmar);
      await tester.tap(confirmar);
      await tester.pump();
      expect(service.envios, [('ana-id', 'Loja B')]);
      expect(find.text('Fechar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Mobile preserves the request window selector and cancel does not reload',
    (tester) async {
      final service = _Service();
      await _pump(tester, true, service, _Permissions(true));
      final filter = find.byIcon(Icons.schedule_rounded);
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), '2');
      await tester.ensureVisible(find.text('Horas'));
      await tester.tap(find.text('Horas'));
      await tester.ensureVisible(find.text('Aplicar janela'));
      await tester.tap(find.text('Aplicar janela'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.calls, 2);
      expect(service.window, 2);
      expect(service.unit, AdminRequestWindowUnit.hours);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mobile dark mode keeps semantic surfaces and expandable details',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, true, _Service(), _Permissions(true), dark: true);
      expect(find.byType(ExpansionTile), findsWidgets);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        SixMobileColorScheme.dark.background,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  bool mobile,
  _Service service,
  _Permissions permissions, {
  bool dark = false,
}) async {
  final locale = _Locale();
  addTearDown(locale.dispose);
  addTearDown(permissions.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>.value(
          value: permissions,
        ),
        ChangeNotifierProvider<LocaleSettingsProvider>.value(value: locale),
      ],
      child: MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home:
            mobile
                ? SuperPanelMobileScreen(service: service)
                : Scaffold(body: SuperPanelWebPage(service: service)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}
