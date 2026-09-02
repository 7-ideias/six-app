import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/chat_suporte_models.dart';
import 'package:sixpos/data/services/chat_suporte/chat_suporte_api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
  });

  test('envia mensagem sem imagem como JSON', () async {
    late http.Request capturedRequest;
    final ChatSuporteApiClient client = ChatSuporteApiClient(
      httpClient: MockClient((http.Request request) async {
        capturedRequest = request;
        return _successResponse();
      }),
    );

    final ChatSuporteEnvioMensagemModel result = await client.enviarMensagem(
      idConversa: 'conversa-1',
      idUnicoDaEmpresa: 'empresa-test',
      texto: '  ola  ',
    );

    expect(capturedRequest.method, 'POST');
    expect(
      capturedRequest.url.path,
      '/private/api/suporte/chat/conversas/conversa-1/mensagens',
    );
    expect(capturedRequest.headers['authorization'], 'Bearer token-test');
    expect(capturedRequest.headers['idUnicoDaEmpresa'], 'empresa-test');
    expect(
      capturedRequest.headers['content-type'],
      contains('application/json'),
    );
    expect(jsonDecode(capturedRequest.body), <String, dynamic>{'texto': 'ola'});
    expect(result.mensagem.texto, 'ola');
  });

  test('mantem multipart quando existe imagem', () async {
    late http.Request capturedRequest;
    final ChatSuporteApiClient client = ChatSuporteApiClient(
      httpClient: MockClient((http.Request request) async {
        capturedRequest = request;
        return _successResponse();
      }),
    );

    await client.enviarMensagem(
      idConversa: 'conversa-1',
      idUnicoDaEmpresa: 'empresa-test',
      texto: 'foto',
      imagens: <ChatSuporteImagemUpload>[
        ChatSuporteImagemUpload(
          nomeArquivo: 'foto.png',
          dados: Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47]),
        ),
      ],
    );

    expect(
      capturedRequest.headers['content-type'],
      startsWith('multipart/form-data; boundary='),
    );
    final String multipartBody = utf8.decode(
      capturedRequest.bodyBytes,
      allowMalformed: true,
    );
    expect(multipartBody, contains('name="texto"'));
    expect(multipartBody, contains('name="arquivos"'));
    expect(multipartBody, contains('filename="foto.png"'));
  });
}

http.Response _successResponse() {
  return http.Response(
    jsonEncode(<String, dynamic>{
      'conversa': <String, dynamic>{
        'id': 'conversa-1',
        'idUnicoDaEmpresa': 'empresa-test',
        'nomeEmpresa': 'Sete Ideias',
        'idSolicitante': 'usuario-1',
        'nomeSolicitante': 'Cliente',
        'status': 'AGUARDANDO_SUPORTE',
        'criadaEm': '2026-09-02T12:00:00Z',
        'atualizadaEm': '2026-09-02T12:00:00Z',
        'naoLidasPeloSuporte': 1,
        'naoLidasPeloSolicitante': 0,
        'retencaoDias': 30,
      },
      'mensagem': <String, dynamic>{
        'id': 'mensagem-1',
        'idConversa': 'conversa-1',
        'idRemetente': 'usuario-1',
        'nomeRemetente': 'Cliente',
        'remetenteTipo': 'USUARIO',
        'tipo': 'TEXTO',
        'texto': 'ola',
        'arquivos': <dynamic>[],
        'criadaEm': '2026-09-02T12:00:00Z',
        'expiraEm': '2026-10-02T12:00:00Z',
      },
    }),
    201,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
