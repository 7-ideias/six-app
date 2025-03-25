import 'dart:convert';

import 'package:appplanilha/data/models/produto_model.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ProdutoService {
  final String endpoint = '${AppConfig.baseUrl}/produto/lista';

  Future<List<ProdutoModel>> ProdutosList(Map<String, String>? headers) async {
    final url = Uri.parse(endpoint);

    final body = jsonEncode({'produtosAtivos': true, 'tipo': 'SERVICO'});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      final List produtosJson = jsonMap['produtosList'] ?? [];
      return produtosJson.map((json) => ProdutoModel.fromJson(json)).toList();
    } else {
      print('🔴 Erro: status ${response.statusCode}');
      print('🔴 Body: ${response.body}');
      throw Exception('Erro ao carregar produtos: ${response.statusCode}');
    }
  }
}
