import 'dart:convert';

import 'package:sixpos/data/models/desconto_model.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'http_client_factory.dart';

class DescontoService {
  DescontoService({http.Client? httpClient})
    : client = httpClient ?? createHttpClient();

  final String endpoint = '${AppConfig.baseUrl}/desconto/lista';

  final http.Client client;

  Future<List<DescontoModel>> DescontosList(
    Map<String, String>? headers,
  ) async {
    final url = Uri.parse(endpoint);
    final bodyMap = {'produtosAtivos': true, 'tipo': 'SERVICO'};
    final body = jsonEncode(bodyMap);

    try {
      print('🌐 POST $url');

      final response = await client.post(url, headers: headers, body: body);

      print('✅ STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        final List descontosJson = jsonMap['descontosList'] ?? [];
        return descontosJson
            .map((json) => DescontoModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Erro ao carregar descontos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na requisição: $e');
      rethrow;
    }
  }
}
