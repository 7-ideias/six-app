import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/caixa_models.dart';
import '../../models/devolucao_produto_models.dart';
import '../../models/produto_model.dart';

abstract interface class DevolucaoProdutoApiClient {
  Future<VendaElegivelDevolucao> buscarVendaElegivel(String identificador);

  Future<DevolucaoProdutoResponse> registrar(
    RegistrarDevolucaoProdutoRequest request,
  );

  Future<List<DevolucaoProdutoResponse>> listarRecentes();

  Future<List<ProdutoModel>> listarProdutosParaTroca();

  Future<List<TiposRecebimento>> listarTiposDeAcertoImediato();
}

class HttpDevolucaoProdutoApiClient implements DevolucaoProdutoApiClient {
  HttpDevolucaoProdutoApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getAccessToken();
    final String? empresaId = await authService.getEmpresaId();

    return <String, String>{
      'Authorization': 'Bearer ${token ?? ''}',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  @override
  Future<VendaElegivelDevolucao> buscarVendaElegivel(
    String identificador,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/devolucoes-produtos/venda',
    ).replace(queryParameters: <String, String>{
      'identificador': identificador.trim(),
    });

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    final dynamic decoded = _decodeResponse(response);
    if (response.statusCode != 200 || decoded is! Map) {
      throw _exceptionFrom(response, decoded);
    }

    return VendaElegivelDevolucao.fromJson(
      decoded.cast<String, dynamic>(),
    );
  }

  @override
  Future<DevolucaoProdutoResponse> registrar(
    RegistrarDevolucaoProdutoRequest request,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/devolucoes-produtos',
    );
    final http.Response response = await _httpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );
    final dynamic decoded = _decodeResponse(response);
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        decoded is! Map) {
      throw _exceptionFrom(response, decoded);
    }

    return DevolucaoProdutoResponse.fromJson(
      decoded.cast<String, dynamic>(),
    );
  }

  @override
  Future<List<DevolucaoProdutoResponse>> listarRecentes() async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/devolucoes-produtos/recentes',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    final dynamic decoded = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _exceptionFrom(response, decoded);
    }
    if (decoded is! List) return const <DevolucaoProdutoResponse>[];

    return decoded
        .whereType<Map>()
        .map(
          (Map item) => DevolucaoProdutoResponse.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ProdutoModel>> listarProdutosParaTroca() async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/produto/lista',
    ).replace(queryParameters: const <String, String>{'tipo': 'PRODUTO'});
    final Map<String, String> headers = await _headers();
    headers['apenas-ativos'] = 'true';

    final http.Response response = await _httpClient.get(uri, headers: headers);
    final dynamic decoded = _decodeResponse(response);
    if (response.statusCode != 200 || decoded is! Map) {
      throw _exceptionFrom(response, decoded);
    }

    return ProdutoResponseModel.fromJson(
      decoded.cast<String, dynamic>(),
    ).produtosList.where((ProdutoModel produto) {
      return produto.ativo &&
          produto.id != null &&
          produto.id!.trim().isNotEmpty &&
          produto.tipoProduto.trim().toUpperCase() == 'PRODUTO';
    }).toList(growable: false);
  }

  @override
  Future<List<TiposRecebimento>> listarTiposDeAcertoImediato() async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/caixa/informacoes-basicas',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    final dynamic decoded = _decodeResponse(response);
    if (response.statusCode != 200 || decoded is! Map) {
      throw _exceptionFrom(response, decoded);
    }

    final InformacoesBasicasCaixaResponse informacoes =
        InformacoesBasicasCaixaResponse.fromJson(
      decoded.cast<String, dynamic>(),
    );
    final List<TiposRecebimento> tipos = informacoes.tiposRecebimento
        .where(
          (TiposRecebimento item) =>
              item.ativo &&
              item.naturezaRecebimento.trim().toUpperCase() == 'IMEDIATO',
        )
        .toList(growable: false)
      ..sort(
        (TiposRecebimento a, TiposRecebimento b) =>
            a.ordemExibicao.compareTo(b.ordemExibicao),
      );
    return tipos;
  }

  dynamic _decodeResponse(http.Response response) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  DevolucaoProdutoApiException _exceptionFrom(
    http.Response response,
    dynamic decoded,
  ) {
    if (decoded is Map) {
      final Map<String, dynamic> json = decoded.cast<String, dynamic>();
      return DevolucaoProdutoApiException(
        statusCode: response.statusCode,
        codigo: json['code']?.toString(),
        titulo: json['title']?.toString(),
        mensagem: json['message']?.toString(),
        detalhe: json['detail']?.toString(),
      );
    }
    return DevolucaoProdutoApiException(
      statusCode: response.statusCode,
      mensagem: decoded?.toString(),
    );
  }
}

class DevolucaoProdutoApiException implements Exception {
  const DevolucaoProdutoApiException({
    required this.statusCode,
    this.codigo,
    this.titulo,
    this.mensagem,
    this.detalhe,
  });

  final int statusCode;
  final String? codigo;
  final String? titulo;
  final String? mensagem;
  final String? detalhe;

  String get mensagemUsuario {
    final String texto = mensagem?.trim() ?? '';
    if (texto.isNotEmpty) return texto;
    final String detalheTexto = detalhe?.trim() ?? '';
    if (detalheTexto.isNotEmpty) return detalheTexto;
    return 'Não foi possível concluir a operação.';
  }

  @override
  String toString() {
    final String prefixo = codigo == null ? '' : '$codigo: ';
    return '$prefixo$mensagemUsuario';
  }
}
