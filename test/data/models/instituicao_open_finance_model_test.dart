import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';

void main() {
  test('catálogo desabilitado jamais expõe logotipo', () {
    final catalogo = CatalogoInstituicoesBrasil.fromJson({
      'habilitado': false,
      'instituicoes': [
        {'nome': 'Nubank', 'logotipoUrl': 'https://example.com/nubank.svg'},
      ],
    });
    expect(catalogo.habilitado, isFalse);
    expect(catalogo.instituicoes, isEmpty);
    expect(catalogo.logotipoDe('Nu'), isNull);
  });

  test('faz match exato e compatibilidade controlada com Nu', () {
    final catalogo = CatalogoInstituicoesBrasil.fromJson({
      'habilitado': true,
      'instituicoes': [
        {'nome': 'Nubank', 'marcaOpenFinanceId': 'auth-nu', 'logotipoUrl': 'https://example.com/99pay.svg'},
        {'nome': 'Banco Inter', 'logotipoUrl': 'https://example.com/inter.svg'},
        {'nome': 'Inseguro', 'logotipoUrl': 'http://example.com/unsafe.svg'},
      ],
    });
    expect(catalogo.instituicoes.length, 2);
    expect(catalogo.logotipoDe('Nu'), 'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg');
    expect(catalogo.logotipoDe('Nu Pagamentos'), 'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg');
    expect(catalogo.logotipoDe('Nubank', marcaOpenFinanceId: 'auth-nu'), 'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg');
    expect(catalogo.logotipoDe('Banco Inter'), 'https://example.com/inter.svg');
    expect(catalogo.logotipoDe('Banco'), isNull);
    expect(catalogo.logotipoDe('Outra instituição'), isNull);
  });

  test('Itaucard usa marca Itaú mesmo que Open Finance informe logo 99Pay', () {
    final catalogo = CatalogoInstituicoesBrasil.fromJson({
      'habilitado': true,
      'instituicoes': [
        {
          'nome': 'Itaucard',
          'marcaOpenFinanceId': 'itau-auth',
          'logotipoUrl': 'https://example.com/99pay.svg',
        },
      ],
    });
    const logoItau =
        'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60701190.svg';
    expect(catalogo.instituicoes.single.logotipoUrl, logoItau);
    expect(catalogo.logotipoDe('Itaucard', marcaOpenFinanceId: 'itau-auth'), logoItau);
    expect(catalogo.logotipoDe('Itaú'), logoItau);
    expect(catalogo.logotipoDe('itau card'), logoItau);
    // Um ID de marca não deve roubar a imagem de uma instituição diferente.
    expect(catalogo.logotipoDe('ItaúBank', marcaOpenFinanceId: 'itau-auth'), isNull);
    expect(InstituicaoOpenFinance(
      nome: 'Itaucard', logotipoUrl: 'https://example.com/99pay.svg',
    ).logotipoExibicao, logoItau);
    expect(CatalogoInstituicoesBrasil.vazio.logotipoDe('Itaucard'), isNull);
  });

  test('espaço pessoal envia a empresa selecionada somente para o catálogo', () async {
    final headers = <String, String?>{};
    final client = CartaoCreditoApiClient(
      espaco: 'PESSOAL',
      client: MockClient((request) async {
        headers[request.url.path] = request.headers['idUnicoDaEmpresa'];
        if (request.url.path.endsWith('/instituicoes')) {
          return http.Response(jsonEncode({
            'habilitado': true,
            'instituicoes': [
              {'nome': 'Nubank', 'logotipoUrl': 'https://example.com/nu.svg'},
            ],
          }), 200);
        }
        return http.Response(jsonEncode({
          'podeEditar': true,
          'cartoes': [],
        }), 200);
      }),
      tokenProvider: () async => 'token',
      empresaProvider: () async => 'empresa-ativa',
    );
    addTearDown(client.dispose);

    await client.listar();
    final catalogo = await client.listarInstituicoesBrasileiras();
    expect(headers['/private/api/agenda-financeira/cartoes'], isNull);
    expect(headers['/private/api/agenda-financeira/cartoes/instituicoes'], 'empresa-ativa');
    expect(catalogo.habilitado, isTrue);
    expect(catalogo.logotipoDe('Nubank'), 'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg');
  });
}
