import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/services/colaborador_convite_web_service.dart';
import 'package:sixpos/core/services/primeiro_acesso_convite.dart';
import 'package:sixpos/data/models/convite_link.dart';
import 'package:sixpos/presentation/screens/colaborador_convite_mobile_page.dart';
import 'package:sixpos/presentation/screens/colaborador_convite_publico_web_page.dart';

void main() {
  const code = '0123456789abcdef0123456789abcdef';
  http.Response invite() => http.Response(
    jsonEncode({
      'nomeFantasia': 'Loja Michelli',
      'emailConvidado': 'a***@example.test',
      'contaExistente': false,
      'status': 'PENDENTE',
    }),
    200,
  );

  test('handoff leva somente o endereço ao login, Android e iOS', () {
    for (final path in [
      'com.sixoapp.app://colaborador/convites/',
      '/convites/',
      '/colaborador/convites/',
    ]) {
      final link =
          ConviteLink.parse('$path$code?login=1&email=ana%40example.test')!;
      expect(link.email, 'ana@example.test');
      expect(link.login, isTrue);
      expect(link.codigo, code);
    }
    expect(ConviteLink.parse('https://example.test/convites/$code'), isNull);
  });

  test(
    'somente envia senha com a prova recebida e após confirmar os dois campos',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((r) async {
        requests.add(r);
        if (r.method == 'GET') return invite();
        if (r.url.path.endsWith('confirmar-email')) {
          return http.Response(
            '{"prova":"prova-teste","email":"ana@example.test"}',
            200,
          );
        }
        return http.Response('', 204);
      });
      final flow = PrimeiroAcessoConvite(
        code,
        service: ColaboradorConviteWebService(client: client),
      );
      await flow.carregar();
      await flow.enviar('es');
      expect(requests.last.headers['Accept-Language'], 'es');
      await flow.verificar('001234');
      expect(flow.etapa, EtapaConvite.senha);
      await flow.salvar('12345678', 'outra');
      expect(flow.erro, 'mismatch');
      expect(requests.length, 3);
      await flow.salvar('uma senha válida', 'uma senha válida');
      expect(jsonDecode(requests.last.body), {
        'prova': 'prova-teste',
        'senha': 'uma senha válida',
      });
      expect(flow.etapa, EtapaConvite.criado);
    },
  );

  for (final mobile in [true, false]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Convite ${mobile ? "mobile" : "web"} em ${brightness.name}',
        (tester) async {
          final client = MockClient(
            (r) async => r.method == 'GET' ? invite() : http.Response('', 204),
          );
          await http.runWithClient(() async {
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(brightness: brightness),
                home:
                    mobile
                        ? const ColaboradorConviteMobilePage(codigo: code)
                        : const ColaboradorConvitePublicoWebPage(codigo: code),
              ),
            );
            await tester.pump();
            expect(find.text('Loja Michelli'), findsOneWidget);
            final button = find.widgetWithText(FilledButton, 'Send code');
            await tester.tap(button);
            await tester.pump();
            expect(find.byType(TextField), findsOneWidget);
            expect(find.text('Send another code'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }, () => client);
        },
      );
    }
  }
}
