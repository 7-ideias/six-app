import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';

void main() {
  group('HttpColaboradorUsuarioApiClient.listarTecnicosAssistenciaTecnica', () {
    test(
      'retorna somente colaboradores ativos com flag tecnica true',
      () async {
        final client = HttpColaboradorUsuarioApiClient(
          accessTokenProvider: () async => 'token',
          empresaIdProvider: () async => 'empresa',
          httpClient: MockClient((http.Request request) async {
            expect(request.headers['idUnicoDaEmpresa'], 'empresa');
            expect(request.headers['Authorization'], 'Bearer token');

            if (request.url.path == '/private/api/colaborador/listar') {
              return http.Response(
                jsonEncode(<Map<String, dynamic>>[
                  _colaborador(
                    id: 'tecnico-direto',
                    nome: 'Tecnico direto',
                    ehTecnico: true,
                  ),
                  _colaborador(
                    id: 'nao-tecnico',
                    nome: 'Nao tecnico',
                    ehTecnico: false,
                  ),
                  _colaborador(
                    id: 'tecnico-inativo',
                    nome: 'Tecnico inativo',
                    ativo: false,
                    ehTecnico: true,
                  ),
                  _colaborador(
                    id: 'tecnico-detalhe',
                    nome: 'Tecnico por detalhe',
                  ),
                  _colaborador(
                    id: 'nao-tecnico-detalhe',
                    nome: 'Nao tecnico por detalhe',
                  ),
                ]),
                200,
              );
            }

            if (request.url.path == '/private/api/colaborador/buscar') {
              final String id =
                  request.url.queryParameters['idUnicoDoUsuario'] ?? '';
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'objAutorizacoes': <String, dynamic>{
                    'objAssistenciaTecnicaPode': <String, dynamic>{
                      'ehUmTecnicoEFazAssistenciaTecnica':
                          id == 'tecnico-detalhe',
                    },
                  },
                }),
                200,
              );
            }

            return http.Response('not found', 404);
          }),
        );

        final tecnicos = await client.listarTecnicosAssistenciaTecnica();

        expect(tecnicos.map((item) => item.idUnicoPessoal), <String>[
          'tecnico-direto',
          'tecnico-detalhe',
        ]);
        expect(
          tecnicos.every((item) => item.ehTecnicoAssistenciaTecnica),
          isTrue,
        );
      },
    );

    test('le a flag dentro de objAutorizacoes quando vier no resumo', () async {
      final client = HttpColaboradorUsuarioApiClient(
        accessTokenProvider: () async => 'token',
        empresaIdProvider: () async => 'empresa',
        httpClient: MockClient((http.Request request) async {
          if (request.url.path == '/private/api/colaborador/listar') {
            return http.Response(
              jsonEncode(<Map<String, dynamic>>[
                _colaborador(
                  id: 'tecnico-nested',
                  nome: 'Tecnico nested',
                  autorizacoesEhTecnico: true,
                ),
                _colaborador(
                  id: 'nao-tecnico-nested',
                  nome: 'Nao tecnico nested',
                  autorizacoesEhTecnico: false,
                ),
              ]),
              200,
            );
          }

          fail('Nao deve buscar detalhe quando o resumo ja informa a flag.');
        }),
      );

      final tecnicos = await client.listarTecnicosAssistenciaTecnica();

      expect(tecnicos, hasLength(1));
      expect(tecnicos.single.idUnicoPessoal, 'tecnico-nested');
      expect(tecnicos.single.ehTecnicoAssistenciaTecnica, isTrue);
    });
  });
}

Map<String, dynamic> _colaborador({
  required String id,
  required String nome,
  bool ativo = true,
  bool? ehTecnico,
  bool? autorizacoesEhTecnico,
}) {
  return <String, dynamic>{
    'idUnicoPessoal': id,
    'nome': nome,
    'nomeDeGuerra': '',
    'celularDeAcesso': '',
    'email': '$id@six.local',
    'foto': '',
    'dataCadastro': '2026-08-03T00:00:00.000',
    'ativo': ativo,
    if (ehTecnico != null) 'ehUmTecnicoEFazAssistenciaTecnica': ehTecnico,
    if (autorizacoesEhTecnico != null)
      'objAutorizacoes': <String, dynamic>{
        'objAssistenciaTecnicaPode': <String, dynamic>{
          'ehUmTecnicoEFazAssistenciaTecnica': autorizacoesEhTecnico,
        },
      },
  };
}
