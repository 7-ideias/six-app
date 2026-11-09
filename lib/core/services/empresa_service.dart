import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/empresa_model.dart';
import '../../providers/empresa_provider.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'firebase_push_notification_service.dart';
import 'http_client_factory.dart';

class EmpresaService {
  static final EmpresaService _instance = EmpresaService._internal();
  factory EmpresaService() => _instance;
  EmpresaService._internal();

  http.Client _client() => createHttpClient();

  Future<EmpresaModel> buscarDadosDaEmpresa() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas EMPRESA_SERVICE 23');
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
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final EmpresaModel empresa = _decodeEmpresa(response.body);
        EmpresaProvider().setEmpresa(empresa);

        if (!kIsWeb) {
          // Push e best-effort: indisponibilidade do Firebase/APNs nao
          // impede o carregamento da empresa nem a autenticacao.
          unawaited(
            FirebasePushNotificationService()
                .syncTokenForLoggedUser()
                .catchError((Object error, StackTrace stackTrace) {
                  debugPrint('[EmpresaService] Push adiado: $error');
                }),
          );
        }

        return empresa;
      }

      throw Exception(_mensagemFalha('buscar', response.statusCode));
    } catch (e) {
      debugPrint('Erro na requisição de dados da empresa: $e');
      rethrow;
    }
  }

  Future<EmpresaModel> atualizarDadosDaEmpresa(EmpresaModel empresa) async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas EMPRESA_SERVICE 60');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-empresa');
    final client = _client();

    try {
      final response = await client.put(
        uri,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'idUnicoDaEmpresa': empresaId,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(empresa.toJson()),
      );

      if (response.statusCode == 200) {
        final EmpresaModel empresaAtualizada = response.body.trim().isEmpty
            ? empresa
            : _decodeEmpresa(response.body);
        EmpresaProvider().setEmpresa(empresaAtualizada);
        return empresaAtualizada;
      }

      throw Exception(_mensagemFalha('atualizar', response.statusCode));
    } catch (e) {
      debugPrint('Erro na atualização de dados da empresa: $e');
      rethrow;
    }
  }

  EmpresaModel _decodeEmpresa(String body) {
    if (body.trim().isEmpty) {
      throw Exception('Resposta de empresa vazia');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta de empresa inválida');
    }

    return EmpresaModel.fromJson(decoded);
  }

  String _mensagemFalha(String acao, int statusCode) {
    return 'Falha ao $acao dados da empresa: $statusCode';
  }
}
