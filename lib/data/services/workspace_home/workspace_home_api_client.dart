import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';

abstract class WorkspaceHomeApiClient {
  Future<WorkspaceHomeModel> buscarHome();
}

abstract class WorkspaceHomeSectionsApiClient {
  Future<String> currentScope();
  Future<WorkspaceHomeModel> buscarSecao(
    WorkspaceHomeSection section,
    String scope,
  );
}

class HttpWorkspaceHomeApiClient
    implements WorkspaceHomeApiClient, WorkspaceHomeSectionsApiClient {
  HttpWorkspaceHomeApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
    Future<String?> Function()? userIdProvider,
  }) : _httpClient = httpClient ?? createHttpClient(),
       _accessTokenProvider =
           accessTokenProvider ?? AuthService().getAccessToken,
       _empresaIdProvider = empresaIdProvider ?? AuthService().getEmpresaId,
       _userIdProvider = userIdProvider ?? AuthService().getUserId;

  final http.Client _httpClient;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _empresaIdProvider;
  final Future<String?> Function() _userIdProvider;

  @override
  Future<String> currentScope() async {
    final user = await _userIdProvider();
    final company = await _empresaIdProvider();
    if (user == null || user.isEmpty || company == null || company.isEmpty) {
      throw const WorkspaceHomeApiException(
        statusCode: 401,
        body: 'workspace.home.error.credentials',
      );
    }
    return '$user|$company';
  }

  @override
  Future<WorkspaceHomeModel> buscarSecao(
    WorkspaceHomeSection section,
    String scope,
  ) async {
    if (await currentScope() != scope) throw StateError('Home context changed');
    final token = await _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const WorkspaceHomeApiException(
        statusCode: 401,
        body: 'workspace.home.error.credentials',
      );
    }
    final response = await _httpClient
        .get(
          Uri.parse(
            '${AppConfig.baseUrl}/private/api/workspace/home/${section.path}',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'idUnicoDaEmpresa': scope.split('|').last,
          },
        )
        .timeout(const Duration(seconds: 20));
    if (await currentScope() != scope) throw StateError('Home context changed');
    if (response.statusCode != 200) {
      throw WorkspaceHomeApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid home response');
    }
    return WorkspaceHomeModel.fromJson(data);
  }

  @override
  Future<WorkspaceHomeModel> buscarHome() async {
    final String? token = (await _accessTokenProvider())?.trim();
    final String? empresaId = (await _empresaIdProvider())?.trim();

    if (token == null ||
        token.isEmpty ||
        empresaId == null ||
        empresaId.isEmpty) {
      throw const WorkspaceHomeApiException(
        statusCode: 401,
        body: 'workspace.home.error.credentials',
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/web/workspace/home',
    );

    final http.Response response = await _httpClient.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'idUnicoDaEmpresa': empresaId,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw WorkspaceHomeApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw WorkspaceHomeApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return WorkspaceHomeModel.fromJson(data);
  }
}

class WorkspaceHomeApiException implements Exception {
  const WorkspaceHomeApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'WorkspaceHomeApiException(statusCode: $statusCode, body: $body)';
  }
}
