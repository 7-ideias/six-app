import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/http_client_factory.dart';
import '../../../data/models/usuario_model.dart';
import '../../../providers/usuario_provider.dart';

class UsuarioService {
  static final UsuarioService _instance = UsuarioService._internal();
  factory UsuarioService() => _instance;
  UsuarioService._internal();

  http.Client _client() => createHttpClient();

  Future<void> buscarDadosDoUsuario_atualizaProviders() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-pessoais');
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
        final usuario = UsuarioModel.fromJson(decoded);

        // Salvar em memória usando o Provider
        UsuarioProvider().setUsuario(usuario);
      } else {
        throw Exception('Falha ao buscar dados do usuário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição de dados do usuário: $e');
      rethrow;
    }
  }

  Future<void> atualizarDadosDoUsuario(UsuarioModel usuario) async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-pessoais');
    final client = _client();

    try {
      final response = await client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'idUnicoDaEmpresa': empresaId,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(usuario.toJson()),
      );

      if (response.statusCode == 200) {
        // Atualizar em memória usando o Provider
        UsuarioProvider().setUsuario(usuario);
      } else {
        throw Exception('Falha ao atualizar dados do usuário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na atualização de dados do usuário: $e');
      rethrow;
    }
  }
}
