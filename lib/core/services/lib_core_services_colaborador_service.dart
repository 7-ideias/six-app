import 'dart:convert';

import 'package:appplanilha/core/network/logging_interceptor.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../../data/models/lib_data_models_colaborador_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ColaboradorService {
  final String endpointCadastro =
      '${AppConfig.baseUrl}/private/api/colaborador/novo';
  final String endpointAtualizacao =
      '${AppConfig.baseUrl}/private/api/colaborador/editar';

  final client = InterceptedClient.build(
    interceptors: <InterceptorContract>[LoggingInterceptor()],
  );

  Future<ColaboradorCadastroResponse> cadastrarColaborador(
    ColaboradorCadastroRequest request,
  ) async {
    return _sendRequest(
      url: Uri.parse(endpointCadastro),
      method: 'POST',
      body: request.toJson(),
    );
  }

  Future<ColaboradorCadastroResponse> atualizarColaborador(
    ColaboradorAtualizacaoRequest request,
  ) async {
    return _sendRequest(
      url: Uri.parse(endpointAtualizacao),
      method: 'POST',
      body: request.toJson(),
    );
  }

  Future<ColaboradorCadastroResponse> _sendRequest({
    required Uri url,
    required String method,
    required Map<String, dynamic> body,
  }) async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Authorization': 'Bearer $token',
    };

    try {
      final bodyJson = jsonEncode(body);

      print('🌐 $method $url');
      print('🟦 Headers: $headers');
      print('📦 Body: $bodyJson');

      final response = switch (method) {
        'PUT' => await client.put(url, headers: headers, body: bodyJson),
        _ => await client.post(url, headers: headers, body: bodyJson),
      };

      print('✅ STATUS: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Erro na operação de colaborador: ${response.statusCode}\n${response.body}',
        );
      }

      return ColaboradorCadastroResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    } catch (e) {
      print('❌ Erro na operação de colaborador: $e');
      rethrow;
    }
  }
}
