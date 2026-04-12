import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/imagem_sugestao_model.dart';

abstract class ImagemSugestaoApiClient {
  Future<ImagemSugestaoResponse> buscarSugestoes(
    ImagemSugestaoRequest request, {
    http.Client? httpClient,
  });
}

class HttpImagemSugestaoApiClient implements ImagemSugestaoApiClient {
  HttpImagemSugestaoApiClient({
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _accessTokenProvider =
           accessTokenProvider ?? AuthService().getAccessToken,
       _empresaIdProvider = empresaIdProvider ?? AuthService().getEmpresaId;

  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _empresaIdProvider;

  Future<Map<String, String>> _headers() async {
    final String token = (await _accessTokenProvider())?.trim() ?? '';
    final String empresaId = (await _empresaIdProvider())?.trim() ?? '';

    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'idUnicoDaEmpresa': empresaId,
    };
  }

  @override
  Future<ImagemSugestaoResponse> buscarSugestoes(
    ImagemSugestaoRequest request, {
    http.Client? httpClient,
  }) async {
    final bool shouldDisposeClient = httpClient == null;
    final http.Client client = httpClient ?? http.Client();

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/imagem/sugestoes',
    );

    try {
      final http.Response response = await client.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw ImagemSugestaoApiException(
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      if (response.body.trim().isEmpty) {
        return ImagemSugestaoResponse(
          tipo: '',
          consultasExecutadas: const <String>[],
          imagens: const <ImagemSugestao>[],
        );
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw ImagemSugestaoApiException(
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      return ImagemSugestaoResponse.fromJson(data);
    } finally {
      if (shouldDisposeClient) {
        client.close();
      }
    }
  }
}

class ImagemSugestaoApiException implements Exception {
  ImagemSugestaoApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'ImagemSugestaoApiException(statusCode: $statusCode, body: $body)';
  }
}
