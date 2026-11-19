import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/services/recuperacao_senha_service.dart';
import 'package:sixpos/core/exceptions/recuperacao_senha_exception.dart';

void main() {
  test('shared recovery client sends locale and accepts neutral 204', () async {
    final service = RecuperacaoSenhaService(
      client: MockClient((request) async {
        expect(request.url.path, '/public/api/esqueceu-senha/enviar-codigo');
        expect(request.headers['Accept-Language'], 'es');
        expect(jsonDecode(request.body), {'email': 'user@example.test'});
        return http.Response('', 204);
      }),
    );
    await service.enviarCodigo('user@example.test', languageCode: 'es');
  });
  test(
    'troca de senha usa o endpoint autenticado para enviar o código',
    () async {
      SharedPreferences.setMockInitialValues({'accessToken': 'token-teste'});
      final service = RecuperacaoSenhaService(
        client: MockClient((request) async {
          expect(
            request.url.path,
            '/private/api/usuario/troca-senha/enviar-codigo',
          );
          expect(request.headers['Authorization'], 'Bearer token-teste');
          expect(request.headers['Accept-Language'], 'en');
          expect(jsonDecode(request.body), {'email': 'conta@example.test'});
          return http.Response('', 204);
        }),
      );
      await service.enviarCodigo(
        'conta@example.test',
        contaAutenticada: true,
        languageCode: 'en',
      );
    },
  );
  test(
    'password and code are transported without trimming or logging',
    () async {
      final service = RecuperacaoSenhaService(
        client: MockClient((request) async {
          expect(jsonDecode(request.body), {
            'email': 'user@example.test',
            'codigo': '123456',
            'novaSenha': ' password ',
          });
          return http.Response('', 204);
        }),
      );
      await service.redefinirSenha(
        email: 'user@example.test',
        codigo: '123456',
        novaSenha: ' password ',
      );
    },
  );
  test('safe errors distinguish throttling and partial session revocation', () {
    expect(
      RecuperacaoSenhaException.fromResponse(
        statusCode: 429,
        body: 'unsafe',
      ).code,
      RecuperacaoSenhaErrorCode.rateLimited,
    );
    final error = RecuperacaoSenhaException.fromResponse(
      statusCode: 502,
      body: '{"code":"PWD_SESSIONS_PENDING","password":"unsafe"}',
    );
    expect(error.code, RecuperacaoSenhaErrorCode.sessionsPending);
    expect(error.toString(), isNot(contains('unsafe')));
  });
}
