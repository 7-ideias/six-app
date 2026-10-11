import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/models/fornecedor_usuario_model.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';

void main() {
  test('consulta filtra pela empresa e envia o token', () async {
    final api = HttpFornecedorUsuarioApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/private/api/fornecedores');
        expect(request.headers['idUnicoDaEmpresa'], 'empresa-A');
        expect(request.headers['Authorization'], 'Bearer token-A');
        return http.Response(jsonEncode([
          {'id': 'f1', 'idUnicoDaEmpresa': 'empresa-A', 'ativo': true,
            'nome': 'Distribuidora A', 'tipoPessoa': 'PJ'}
        ]), 200);
      }),
      accessTokenProvider: () async => 'token-A',
      empresaIdProvider: () async => 'empresa-A',
    );
    final suppliers = await api.listar();
    expect(suppliers.single.nome, 'Distribuidora A');
    expect(suppliers.single.ativo, isTrue);
  });

  test('nao aceita requisicao sem empresa ativa', () async {
    final api = HttpFornecedorUsuarioApiClient(
      httpClient: MockClient((_) async => fail('Nao deve consultar sem empresa')),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => '',
    );
    expect(api.listar(), throwsStateError);
  });

  test('cadastro envia dados e nao inclui id ou empresa no payload', () async {
    final api = HttpFornecedorUsuarioApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['nome'], 'Fornecedor A');
        expect(payload.containsKey('id'), isFalse);
        expect(payload.containsKey('idUnicoDaEmpresa'), isFalse);
        return http.Response(jsonEncode({
          'id': 'criado', 'idUnicoDaEmpresa': 'empresa-A',
          'nome': payload['nome'], 'ativo': true,
        }), 201);
      }),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => 'empresa-A',
    );
    final result = await api.cadastrar(const FornecedorUsuarioDraft(
      ativo: true, tipoPessoa: 'PJ', nome: 'Fornecedor A', documento: '',
      telefone: '', email: '', cep: '', logradouro: '', numero: '',
      complemento: '', bairro: '', cidade: '', uf: '', pais: '',
      contatoResponsavel: '', condicoesPagamento: '', observacoes: '',
    ));
    expect(result.id, 'criado');
  });

  test('API propaga duplicidade de documento como conflito', () async {
    final api = HttpFornecedorUsuarioApiClient(
      httpClient: MockClient((_) async => http.Response('Conflito', 409)),
      accessTokenProvider: () async => 'token',
      empresaIdProvider: () async => 'empresa-A',
    );
    expect(
      api.listar(),
      throwsA(isA<FornecedorUsuarioApiException>()
          .having((error) => error.statusCode, 'statusCode', 409)),
    );
  });
}
