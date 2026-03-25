import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';
import 'http_client_factory.dart';
import '../../data/models/empresa_model.dart';
import '../../providers/empresa_provider.dart';

class EmpresaService {
  static final EmpresaService _instance = EmpresaService._internal();
  factory EmpresaService() => _instance;
  EmpresaService._internal();

  http.Client _client() => createHttpClient();

  Future<void> buscarDadosDaEmpresa() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-empresa');
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
        final empresa = EmpresaModel.fromJson(decoded);

        // Salvar em memória usando o Provider
        EmpresaProvider().setEmpresa(empresa);
      } else {
        throw Exception('Falha ao buscar dados da empresa: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição de dados da empresa: $e');
      rethrow;
    }
  }

  Future<void> atualizarDadosDaEmpresa(EmpresaModel empresa) async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-empresa');
    final client = _client();

    try {
      final response = await client.put(
        uri,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'idUnicoDaEmpresa': empresaId,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(empresa.toJson()),
      );

      if (response.statusCode == 200) {
        // Atualizar em memória usando o Provider
        EmpresaProvider().setEmpresa(empresa);
      } else {
        throw Exception('Falha ao atualizar dados da empresa: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na atualização de dados da empresa: $e');
      rethrow;
    }
  }
}
