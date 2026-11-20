import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/permissao_colaborador.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import 'package:sixpos/data/services/compras/compra_api_client.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final legado in [false, true]) {
    test(
      'concessão e revogação chegam ao PDV já aberto (legado: $legado)',
      () async {
        final api = _ApiDeTeste(legado: legado);
        final acesso = ColaboradorAutorizacoesProvider(
          apiClient: api.client,
          authService: _Sessao(),
          fornecedorApiClient: _Fornecedores(),
          compraApiClient: _Compras(),
        );
        await acesso.carregarAutorizacoesDoUsuarioLogado();
        expect(acesso.podeCadastrarProduto, isFalse);
        for (final conceder in [true, false]) {
          await api.client.editarColaborador(_edicao(conceder));
          final reabertas = await api.client.buscarColaborador('pessoal');
          expect(
            PermissaoColaborador.ler(
              reabertas.toJson()['objAutorizacoes'],
            ).contains(PermissaoColaborador.produtos),
            conceder,
          );
          expect(await acesso.atualizarAutorizacoesDoPdv(), isTrue);
          expect(acesso.podeCadastrarProduto, conceder);
          expect(acesso.podeCadastrarServico, isFalse);
          expect(acesso.podeReceberVendaPdv, isFalse);
          expect(acesso.podeRegistrarVendaPdv, isTrue);
        }
        acesso.dispose();
      },
    );
  }

  test(
    '200 com eco do pedido e leitura diferente não confirma a gravação',
    () async {
      final api = _ApiDeTeste(ignorarEdicao: true);
      await expectLater(
        api.client.editarColaborador(_edicao(true)),
        throwsA(isA<PermissoesNaoConfirmadas>()),
      );
      expect(
        await api.client.buscarAutorizacoes('login'),
        isNot(containsPair('podeCadastrarProduto', true)),
      );
    },
  );
}

Map<String, dynamic> _edicao(bool conceder) {
  final permissoes = <String, dynamic>{};
  PermissaoColaborador.aplicar(permissoes, {
    PermissaoColaborador.vendas,
    if (conceder) PermissaoColaborador.produtos,
  });
  return {
    'objInformacoesDoCadastro': {'idUnicoDoUsuario': 'pessoal'},
    'objAutorizacoes': permissoes,
  };
}

class _ApiDeTeste {
  _ApiDeTeste({this.legado = false, this.ignorarEdicao = false});
  final bool legado;
  final bool ignorarEdicao;
  Map<String, dynamic> salvas = _edicao(false)['objAutorizacoes'];

  late final client = HttpColaboradorUsuarioApiClient(
    accessTokenProvider: () async => 'token',
    empresaIdProvider: () async => 'loja',
    httpClient: MockClient((request) async {
      expect(request.headers['idUnicoDaEmpresa'], 'loja');
      final id = request.url.queryParameters['idUnicoDoUsuario'];
      switch (request.url.pathSegments.last) {
        case 'editar':
          final pedido = jsonDecode(request.body);
          expect(
            pedido['objInformacoesDoCadastro']['idUnicoDoUsuario'],
            'pessoal',
          );
          if (!ignorarEdicao) salvas = pedido['objAutorizacoes'];
          return http.Response(request.body, 200);
        case 'buscar':
          expect(['pessoal', 'login'], contains(id));
          return legado
              ? http.Response(jsonEncode({'objAutorizacoes': salvas}), 200)
              : http.Response('', 204);
        case 'listar':
          return http.Response(
            jsonEncode([
              {'idUnicoPessoal': 'pessoal'},
            ]),
            200,
          );
        case 'permissoes':
          expect(['pessoal', 'login'], contains(id));
          return http.Response(jsonEncode(salvas), 200);
        default:
          throw StateError(request.url.path);
      }
    }),
  );
}

class _Sessao extends Fake implements AuthService {
  @override
  Future<String?> getUserId() async => 'login';
  @override
  Future<String?> getEmpresaId() async => 'loja';
  @override
  Future<String> getUserProfileType() async => 'COLABORADOR';
  @override
  Future<bool> hasRealmRole(String role) async => false;
}

class _Fornecedores extends Fake implements FornecedorUsuarioApiClient {
  @override
  Future<FornecedorAcesso> consultarAcesso() async => FornecedorAcesso.negado;
}

class _Compras extends Fake implements CompraApiClient {
  @override
  Future<CompraAcesso> consultarAcesso() async => CompraAcesso.negado;
}
