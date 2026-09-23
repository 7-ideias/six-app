import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/admin_portal_service.dart';
import 'package:sixpos/data/models/agenda_email_models.dart';
import 'package:sixpos/providers/agenda_email_reenvio_controller.dart';
import 'package:sixpos/presentation/components/web/six_web_agenda_email_dialog.dart';
import 'package:sixpos/presentation/components/mobile/agenda_email_reenvio_mobile_sheet.dart';

class _Service extends AdminPortalService {
  final keys = <String>[];
  Completer<AgendaEmailResultado>? pending;
  bool failOnce = false;
  @override
  Future<List<AgendaEmailDestino>> listarDestinosAgendaEmail(
    String idUsuario,
  ) async => [
    const AgendaEmailDestino(
      idEmpresa: 'a',
      nomeEmpresa: 'Comércio A',
      email: 'dono@example.test',
    ),
  ];
  @override
  Future<AgendaEmailResultado> reenviarAgendaEmail({
    required String idUsuario,
    required String idEmpresa,
    required String chaveRequisicao,
  }) async {
    keys.add(chaveRequisicao);
    if (failOnce) {
      failOnce = false;
      throw const AgendaEmailException('FALHA');
    }
    return pending == null
        ? const AgendaEmailResultado(idEnvio: 'envio', status: 'ENVIADO')
        : pending!.future;
  }
}

void main() {
  test('retry após erro de rede preserva a chave idempotente', () async {
    final service = _Service()..failOnce = true;
    final controller = AgendaEmailReenvioController(service, 'dono');
    await controller.carregar();
    await controller.enviar();
    expect(controller.mensagem, 'error');
    await controller.enviar();
    expect(service.keys.toSet(), hasLength(1));
    expect(controller.resultado?.status, 'ENVIADO');
    controller.dispose();
  });

  for (final mobile in [false, true]) {
    testWidgets(
      '${mobile ? 'mobile' : 'web'} confirma destinatário e impede clique duplo enquanto envia',
      (tester) async {
        await tester.binding.setSurfaceSize(
          mobile ? const Size(390, 844) : const Size(1280, 900),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final service = _Service()..pending = Completer<AgendaEmailResultado>();
        final controller = AgendaEmailReenvioController(service, 'dono');
        addTearDown(controller.dispose);
        await controller.carregar();
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed:
                          () =>
                              mobile
                                  ? showAgendaEmailMobileSheet(
                                    context,
                                    controller,
                                  )
                                  : showAgendaEmailWebDialog(
                                    context,
                                    controller,
                                  ),
                      child: const Text('Abrir'),
                    ),
                  ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        expect(find.text('dono@example.test'), findsOneWidget);
        expect(service.keys, isEmpty);
        await tester.ensureVisible(find.text('Confirmar envio'));
        await tester.tap(find.text('Confirmar envio'));
        await tester.pump();
        expect(find.text('Enviando resumo financeiro…'), findsOneWidget);
        await controller.enviar();
        expect(service.keys, hasLength(1));
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('Enviando resumo financeiro…'), findsOneWidget);
        service.pending!.complete(
          const AgendaEmailResultado(idEnvio: 'envio', status: 'ENVIADO'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text(
            'Resumo aceito pelo provedor de e-mail. A entrega pode levar alguns instantes.',
          ),
          findsOneWidget,
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 1000));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
