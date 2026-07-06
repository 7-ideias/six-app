import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/colaborador_usuario_model.dart';

abstract class ColaboradorUsuarioApiClient {
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores();
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(String idUnicoDoUsuario);
  Future<void> editarColaborador(Map<String, dynamic> payload);
}

class HttpColaboradorUsuarioApiClient implements ColaboradorUsuarioApiClient {
  HttpColaboradorUsuarioApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _accessTokenProvider = accessTokenProvider ?? AuthService().getAccessToken,
       _empresaIdProvider = empresaIdProvider ?? AuthService().getEmpresaId;

  final http.Client _httpClient;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _empresaIdProvider;

  Future<Map<String, String>> _getHeaders() async {
    final String token = (await _accessTokenProvider())?.trim() ?? '';
    final String empresaId = (await _empresaIdProvider())?.trim() ?? '';

    return <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
      'Authori' 'zation': 'Bear' 'er $token',
    };
  }

  @override
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores() async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/colaborador/listar');
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204) {
      return const <ColaboradorUsuarioResumo>[];
    }

    if (response.statusCode != 200) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return const <ColaboradorUsuarioResumo>[];
    }

    final dynamic data = jsonDecode(response.body);
    final List<dynamic> rawList;
    if (data is List<dynamic>) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      rawList = (data['colaboradores'] as List<dynamic>?) ?? <dynamic>[];
    } else {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ColaboradorUsuarioResumo.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(String idUnicoDoUsuario) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/colaborador/buscar').replace(
      queryParameters: <String, String>{'idUnicoDoUsuario': idUnicoDoUsuario},
    );

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204 || response.statusCode == 404) {
      return _buscarDetalheResumidoParaEdicao(idUnicoDoUsuario);
    }

    if (response.statusCode != 200) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return ColaboradorUsuarioDetalhe.fromJson(data);
  }

  Future<ColaboradorUsuarioDetalhe> _buscarDetalheResumidoParaEdicao(
    String idUnicoDoUsuario,
  ) async {
    final List<ColaboradorUsuarioResumo> colaboradores = await listarColaboradores();
    final ColaboradorUsuarioResumo resumo = colaboradores.firstWhere(
      (ColaboradorUsuarioResumo item) => item.idUnicoPessoal == idUnicoDoUsuario,
      orElse: () => ColaboradorUsuarioResumo(
        idUnicoPessoal: idUnicoDoUsuario,
        nome: '',
        nomeDeGuerra: '',
        celularDeAcesso: '',
        email: '',
        foto: '',
        dataCadastro: null,
      ),
    );
    final Map<String, dynamic> autorizacoes =
        await _buscarAutorizacoesParaEdicao(idUnicoDoUsuario);

    return ColaboradorUsuarioDetalhe.fromJson(<String, dynamic>{
      'foto': resumo.foto,
      'celularDeAcesso': resumo.celularDeAcesso,
      'sen' 'haParaPermitirOAcessoDoColaborador': null,
      'objInformacoesDoCadastro': <String, dynamic>{
        'idUnicoDoUsuario': resumo.idUnicoPessoal,
        'dataCadastro': resumo.dataCadastro?.toIso8601String(),
      },
      'objDadosFuncionais': <String, dynamic>{
        'dataDeContratacao': null,
        'salario': null,
      },
      'objPessoa': <String, dynamic>{
        'atencao': 'COLABORADOR',
        'nome': resumo.nome,
        'nomeDeGuerra': resumo.nomeDeGuerra,
        'celular': resumo.celularDeAcesso,
        'sen' 'ha': null,
        'cpf': null,
        'rg': null,
        'dataDeNascimento': null,
        'email': resumo.email,
        'objEndereco': <String, dynamic>{
          'cep': null,
          'logradouro': null,
          'complemento': null,
          'bairro': null,
          'localidade': null,
          'uf': null,
        },
        'DOCUMENTO_DE_IDENTIFICACAO_UNICO_DA_EMPRESA': null,
      },
      'objAutorizacoes': autorizacoes,
    });
  }

  Future<Map<String, dynamic>> _buscarAutorizacoesParaEdicao(
    String idUnicoDoUsuario,
  ) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/colaborador/permissoes').replace(
      queryParameters: <String, String>{'idUnicoDoUsuario': idUnicoDoUsuario},
    );

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 || response.body.trim().isEmpty) {
      return _autorizacoesVazias();
    }

    final dynamic data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return _autorizacoesVazias();
  }

  Map<String, dynamic> _autorizacoesVazias() {
    return <String, dynamic>{
      'podeFazerDevolucao': false,
      'podeCadastrarProduto': false,
      'objProdutosPode': <String, dynamic>{
        'podeVerEstoqueDeProduto': false,
        'podeEditarProduto': false,
        'valorDaComissao': 0,
      },
      'objVendasPode': <String, dynamic>{
        'fazVenda': false,
        'comissaoDeVendas': 0,
      },
      'objAssistenciaTecnicaPode': <String, dynamic>{
        'lancaServico': false,
        'ehUmTecnicoEFazAssistenciaTecnica': false,
        'comissaoDeAssistencia': 0,
      },
      'objClientesPode': <String, dynamic>{
        'podeEditarCliente': false,
      },
      'objRelatoriosPode': <String, dynamic>{
        'geraRelatorioDeVendas': false,
      },
      'objLancamentosFinanceirosPode': <String, dynamic>{
        'podeReceberNoCaixa': false,
        'podeVerQuantoVendeu': false,
      },
    };
  }

  @override
  Future<void> editarColaborador(Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/colaborador/editar');

    final http.Response response = await _httpClient.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class ColaboradorUsuarioApiException implements Exception {
  ColaboradorUsuarioApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'ColaboradorUsuarioApiException(statusCode: $statusCode, body: $body)';
  }
}
