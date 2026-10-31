import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/services/compras/compra_api_client.dart';

void main() {
  test('acesso independente por empresa e token', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/private/api/compras/acesso');
        expect(request.headers['idUnicoDaEmpresa'], 'empresa-A');
        expect(request.headers['Authorization'], 'Bearer jwt');
        return http.Response(jsonEncode({
          'consultar': true, 'criar': false, 'editar': false,
          'confirmar': false, 'cancelar': false, 'receber': true,
        }), 200);
      }),
      accessTokenProvider: () async => 'jwt',
      empresaIdProvider: () async => 'empresa-A',
    );
    final acesso = await api.consultarAcesso();
    expect(acesso.consultar, isTrue);
    expect(acesso.receber, isTrue);
    expect(acesso.confirmar, isFalse);
  });

  test('admin atualiza somente permissoes de compras no vinculo informado', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/private/api/compras/permissoes-colaboradores/v-1');
        expect(request.headers['idUnicoDaEmpresa'], 'empresa-A');
        expect(jsonDecode(request.body), ['COMPRAS_CONSULTAR','COMPRAS_RECEBER']);
        return http.Response(jsonEncode({
          'vinculoId':'v-1', 'email':'colaborador@example.com',
          'permissoes':['COMPRAS_CONSULTAR','COMPRAS_RECEBER'],
        }), 200);
      }),
      accessTokenProvider: () async => 'jwt',
      empresaIdProvider: () async => 'empresa-A',
    );
    final atualizado = await api.atualizarPermissoesColaborador(
        'v-1', ['COMPRAS_CONSULTAR','COMPRAS_RECEBER']);
    expect(atualizado.permissoes, contains('COMPRAS_RECEBER'));
    expect(atualizado.permissoes.length, 2);
  });

  test('operador de compras seleciona fornecedores sem permissao de editar cadastro', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.path, '/private/api/compras/fornecedores');
        expect(request.headers['idUnicoDaEmpresa'], 'empresa-A');
        return http.Response(jsonEncode([
          {'id':'f1','nome':'Distribuidora','ativo':true}
        ]), 200);
      }),
      accessTokenProvider: () async => 'jwt',
      empresaIdProvider: () async => 'empresa-A',
    );
    final lista = await api.listarFornecedores();
    expect(lista.single['id'], 'f1');
  });

  test('nega alteracao quando API retorna forbidden', () async {
    final api = CompraApiClient(
      httpClient: MockClient((request) async => http.Response('Sem acesso', 403)),
      accessTokenProvider: () async => 'jwt',
      empresaIdProvider: () async => 'empresa-A',
    );
    expect(api.atualizarPermissoesColaborador('v-1',['COMPRAS_CANCELAR']),
        throwsA(isA<CompraApiException>().having((e) => e.statusCode, 'status', 403)));
  });
}
