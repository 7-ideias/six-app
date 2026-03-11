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

  final client = InterceptedClient.build(interceptors: [LoggingInterceptor()]);

  Future<ProdutoResponseModel> ProdutosList(Map<String, String>? headers) async {
    final url = Uri.parse(endpointList);

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

  Future<void> cadastrarProduto(ProdutoModel produto) async {
    final url = Uri.parse(endpointCadastro);
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    final headers = {
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🌐 POST $url');
      print('🟦 Headers: $headers');
      print('📦 Body: ${jsonEncode(produto.toJson())}');

      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(produto.toJson()),
      );

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao cadastrar produto: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      rethrow;
    }
  }
}
