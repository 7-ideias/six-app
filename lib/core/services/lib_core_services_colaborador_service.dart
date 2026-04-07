import 'dart:convert';

import 'package:appplanilha/core/network/logging_interceptor.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../../data/models/lib_data_models_colaborador_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ColaboradorService {
  final String endpointCadastro =
      '${AppConfig.baseUrl}/private/api/colaborador/novo';

  final client = InterceptedClient.build(
    interceptors: <InterceptorContract>[LoggingInterceptor()],
  );

  Future<ColaboradorCadastroResponse> cadastrarColaborador(
    ColaboradorCadastroRequest request,
  ) async {
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
      final body = jsonEncode(request.toJson());

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
        throw Exception(
          'Erro ao cadastrar colaborador: ${response.statusCode}\n${response.body}',
        );
      }

      return ColaboradorCadastroResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    } catch (e) {
      print('❌ Erro no cadastro de colaborador: $e');
      rethrow;
    }
  }
}
