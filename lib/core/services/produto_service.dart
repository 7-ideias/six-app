import 'dart:convert';

import 'package:appplanilha/core/network/logging_interceptor.dart';
import 'package:appplanilha/data/models/produto_model.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../config/app_config.dart';

class ProdutoService {
  final String endpoint = '${AppConfig.baseUrl}/produto/lista';

  final client = InterceptedClient.build(interceptors: [LoggingInterceptor()]);

  Future<List<ProdutoModel>> ProdutosList(Map<String, String>? headers) async {
    final url = Uri.parse(endpoint);
    final bodyMap = {
      'produtosAtivos': true,
      'tipo': 'SERVICO',
    };
    final body = jsonEncode(bodyMap);

    try {
      print('🌐 POST $url');
      print('🟦 Headers: $headers');
      print('📦 Body: $body');

      final response = await client.post(url, headers: headers, body: body);

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        final double numero = jsonMap['qtNoEstoque'];
        final List produtosJson = jsonMap['produtosList'] ?? [];
        return produtosJson.map((json) => ProdutoModel.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na requisição: $e');
      rethrow;
    }
  }
}
