
import 'dart:convert';

import 'package:appplanilha/providers/telainicial_web_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../../data/models/tela_inicial_models.dart';

class TelaInicialWebService {
  static final TelaInicialWebService _instance = TelaInicialWebService._internal();
  factory TelaInicialWebService() => _instance;
  TelaInicialWebService._internal();

  http.Client _client() => createHttpClient();

  Future<void> atualizaProviders() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/web/telainicial');
    final client = _client();

    try {
      final response = await client.get(
        uri,
        headers: {
          'accept': 'application/json',
          'idUnicoDaEmpresa': empresaId,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dados = TelaInicialModel.fromJson(decoded);

        // Salvar em memória usando o Provider
        TelaInicialWebProvider().setTelaInicial(dados);
      } else {
        throw Exception('Falha ao buscar dados da tela inicial: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição de dados da tela inicial: $e');
      rethrow;
    }
  }
}




