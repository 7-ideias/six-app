import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/push_campaign_service.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/presentation/screens/admin_push_campaigns_web_page.dart';
import 'package:sixpos/presentation/admin/admin_navigation_shell.dart';

class SuperProfile extends ColaboradorAutorizacoesProvider {
  @override
  String get tipoPerfilUnificado => 'SUPER';
}

class CampaignServiceFake extends PushCampaignService {
  int sends = 0;
  final recipient = CampaignRecipient.fromJson({
    'usuarioId': 'admin',
    'empresaId': 'empresa',
    'nome': 'Ana',
    'email': 'ana@example.test',
    'empresa': 'Oficina',
    'idioma': 'es',
    'assinatura': 'TRIAL',
    'dispositivos': 1,
  });
  @override
  Future<List<CampaignRecipient>> audience() async => [recipient];
  @override
  Future<List<Map<String, dynamic>>> history(int page) async => [];
  @override
  Future<List<CampaignRecipient>> review(Map<String, dynamic> body) async => [
    recipient,
  ];
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> body) async {
    sends++;
    return {'id': body['id']};
  }
}

void main() {
  for (final embedded in [false, true]) {
    for (final width in [1280.0, 600.0]) {
      testWidgets(
        'painel seleciona ADMIN exige mensagem e revisa antes de enviar $width embedded=$embedded',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final service = CampaignServiceFake();
          await tester.pumpWidget(
            ChangeNotifierProvider<ColaboradorAutorizacoesProvider>(
              create: (_) => SuperProfile(),
              child: MaterialApp(
                locale: const Locale('pt'),
                supportedLocales: const [Locale('pt')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: Scaffold(
                  body: AdminPushCampaignsWebPage(
                    service: service,
                    embeddedInMainShell: embedded,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(AdminNavigationShell),
            embedded ? findsNothing : findsOneWidget,
          );
          await tester.tap(find.text('Nova campanha'));
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsOneWidget);
          final next = find.text('Continuar para mensagem');
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(
            find.text('Selecione ao menos um destinatário para continuar.'),
            findsOneWidget,
          );
          await tester.ensureVisible(find.byType(CheckboxListTile));
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(find.byType(CheckboxListTile), findsNothing);
          final name = find.widgetWithText(
            TextField,
            'Nome interno da campanha',
          );
          await tester.ensureVisible(name);
          await tester.enterText(name, 'Campanha teste');
          final title = find.widgetWithText(TextField, 'Título da notificação');
          await tester.ensureVisible(title);
          await tester.enterText(title, 'Hola');
          final body = find.widgetWithText(TextField, 'Mensagem');
          await tester.ensureVisible(body);
          await tester.enterText(body, 'Conoce los planes');
          await tester.pumpAndSettle();
          final history = find.text('Histórico de envios');
          await tester.ensureVisible(history);
          await tester.tap(history);
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsNothing);
          final resume = find.text('Continuar campanha');
          await tester.ensureVisible(resume);
          await tester.tap(resume);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(name).controller!.text,
            'Campanha teste',
          );
          final back = find.text('Voltar aos destinatários');
          await tester.ensureVisible(back);
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<CheckboxListTile>(find.byType(CheckboxListTile))
                .value,
            isTrue,
          );
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(name).controller!.text,
            'Campanha teste',
          );
          final review = find.text('Revisar envio');
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(service.sends, 0);
          expect(find.text('Confirmar envio'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final edit = find.text('Voltar à edição');
          await tester.ensureVisible(edit);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(body).controller!.text,
            'Conoce los planes',
          );
          await tester.ensureVisible(review);
          await tester.tap(review);
          await tester.pumpAndSettle();
          final send = find.text('Confirmar envio');
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(service.sends, 1);
          expect(find.text('Nova campanha'), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          expect(
            find.text(
              'Campanha registrada. Acompanhe o processamento no histórico.',
            ),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
