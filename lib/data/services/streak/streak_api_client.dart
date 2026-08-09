import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/streak_models.dart';

abstract class StreakApiClient {
  Future<UserStreaksModel> getStreaks({String? timezone});

  Future<UserStreaksModel> registerActivity(StreakActivityRequest request);
}

class HttpStreakApiClient implements StreakApiClient {
  HttpStreakApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;
  final AuthService _authService = AuthService();

  static final Uri _streaksUri = Uri.parse(
    '${AppConfig.baseUrl}/private/api/me/streaks',
  );
  static final Uri _activityUri = Uri.parse(
    '${AppConfig.baseUrl}/private/api/me/streaks/activity',
  );

  @override
  Future<UserStreaksModel> getStreaks({String? timezone}) async {
    final http.Response response = await _httpClient.get(
      _streaksUri,
      headers: await _headers(timezone: timezone, acceptOnly: true),
    );

    return _decodeResponse(response);
  }

  @override
  Future<UserStreaksModel> registerActivity(
    StreakActivityRequest request,
  ) async {
    final http.Response response = await _httpClient.post(
      _activityUri,
      headers: await _headers(timezone: request.timezone),
      body: jsonEncode(request.toJson()),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, String>> _headers({
    String? timezone,
    bool acceptOnly = false,
  }) async {
    final String? token = await _authService.getAccessToken();
    final String? empresaId = await _authService.getEmpresaId();

    if (token == null || token.trim().isEmpty) {
      throw const StreakApiException(statusCode: 401, body: '');
    }

    final String? normalizedTimezone = _blankAsNull(timezone);
    final String? normalizedEmpresa = _blankAsNull(empresaId);

    return <String, String>{
      if (!acceptOnly) 'Content-Type': 'application/json',
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (normalizedEmpresa != null) 'idUnicoDaEmpresa': normalizedEmpresa,
      if (normalizedTimezone != null) 'X-Six-Timezone': normalizedTimezone,
    };
  }

  UserStreaksModel _decodeResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw StreakApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const StreakApiException(statusCode: 0, body: '');
      }
      return UserStreaksModel.fromJson(decoded);
    } on FormatException catch (error) {
      throw StreakApiException(statusCode: 0, body: error.message);
    }
  }
}

class StreakApiException implements Exception {
  const StreakApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'StreakApiException(statusCode: $statusCode, body: $body)';
  }
}

String? _blankAsNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
