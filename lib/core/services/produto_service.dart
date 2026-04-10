import 'dart:convert';

import 'package:appplanilha/core/network/logging_interceptor.dart';
import 'package:appplanilha/data/models/produto_model.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

class ProdutoService {
  final String endpointList = '${AppConfig.baseUrl}/private/api/produto/lista';
  final String endpointCadastro =
      '${AppConfig.baseUrl}/private/api/produto/cadastro';
  final String endpointAtualizacao =
      '${AppConfig.baseUrl}/private/api/produto/atualizacao';

  final String endpointRelatorioListagemPdf =
      '${AppConfig.baseUrl}/private/api/produto/relatorio/listagem/pdf';


  final client = InterceptedClient.build(interceptors: [LoggingInterceptor()]);

  Future<ProdutoResponseModel> produtosList(Map<String, String>? headers) async {
    final queryParams = <String, String>{};
    if (headers != null && headers.containsKey('tipo')) {
      queryParams['tipo'] = headers['tipo']!;
    }

    final url = Uri.parse(endpointList).replace(queryParameters: queryParams);

    try {
      print('🌐 GET $url');
      print('🟦 Headers: $headers');

      final response = await client.get(url, headers: headers);

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        return ProdutoResponseModel.fromJson(jsonMap);
      } else {
        throw Exception('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na requisição: $e');
      rethrow;
    }
  }


  Future<String?> cadastrarProduto(ProdutoModel produto) async {
    final url = Uri.parse(endpointCadastro);
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Authorization': 'Bearer $token',
    };

    try {
      final body = jsonEncode(produto.toJson());

      print('🌐 POST $url');
      print('🟦 Headers: $headers');
      print('📦 Body: $body');

      final response = await client.post(
        url,
        headers: headers,
        body: body,
      );

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao cadastrar produto: ${response.statusCode}');
      }

      if (response.body.isEmpty) {
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['id']?.toString();
      }

      return null;
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      rethrow;
    }
  }

  Future<void> atualizarProduto(ProdutoModel produto) async {
    final url = Uri.parse(endpointAtualizacao);
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Authorization': 'Bearer $token',
    };

    if (produto.id == null || produto.id!.isEmpty) {
      throw Exception('Produto sem ID para atualização.');
    }

    try {
      final body = jsonEncode(produto.toJson());

      print('🌐 PUT $url');
      print('🟦 Headers: $headers');
      print('📦 Body: $body');

      final response = await client.put(
        url,
        headers: headers,
        body: body,
      );

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao atualizar produto: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na atualização: $e');
      rethrow;
    }
  }

  Future<RelatorioProdutoPdfResponse> gerarRelatorioListagemPdf() async {
    final url = Uri.parse(endpointRelatorioListagemPdf);
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🌐 GET $url');
      print('🟦 Headers: $headers');

      final response = await client.get(url, headers: headers);

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Erro ao gerar relatório de produtos: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao gerar relatório de produtos.');
      }

      return RelatorioProdutoPdfResponse.fromJson(decoded);
    } catch (e) {
      print('❌ Erro ao gerar relatório PDF: $e');
      rethrow;
    }
  }
}

class RelatorioProdutoPdfResponse {
  final String arquivoBase64;
  final String nomeArquivo;
  final String mimeType;

  RelatorioProdutoPdfResponse({
    required this.arquivoBase64,
    required this.nomeArquivo,
    required this.mimeType,
  });

  factory RelatorioProdutoPdfResponse.fromJson(Map<String, dynamic> json) {
    return RelatorioProdutoPdfResponse(
      arquivoBase64: json['arquivoBase64']?.toString() ?? '',
      nomeArquivo: json['nomeArquivo']?.toString() ?? 'relatorio-produtos.pdf',
      mimeType: json['mimeType']?.toString() ?? 'application/pdf',
    );
  }
}
