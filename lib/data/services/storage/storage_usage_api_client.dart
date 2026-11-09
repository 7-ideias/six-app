import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/storage_usage.dart';
import '../../models/storage_plan.dart';

class StorageUsageException implements Exception {
  const StorageUsageException(this.code);
  final String code;
}

class StorageUsageApiClient {
  StorageUsageApiClient({http.Client? client, AuthService? auth})
    : _client = client ?? createHttpClient(),
      _auth = auth ?? AuthService();
  final http.Client _client;
  final AuthService _auth;

  Future<StorageUsage> load({String? adminCompanyId}) async {
    final company = adminCompanyId ?? await _auth.getEmpresaId();
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty)
      throw const StorageUsageException('session');
    if (company == null || company.isEmpty)
      throw const StorageUsageException('noCompany');
    final path = adminCompanyId == null
        ? '/private/api/armazenamento'
        : '/private/api/admin/armazenamento/${Uri.encodeComponent(company)}';
    final response = await _client
        .get(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: {
            'Authorization': 'Bearer $token',
            'idUnicoDaEmpresa': company,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401)
      throw const StorageUsageException('session');
    if (response.statusCode == 403)
      throw const StorageUsageException('forbidden');
    if (response.statusCode != 200) throw const StorageUsageException('error');
    final usage = StorageUsage.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
    if (usage.companyId != company ||
        (adminCompanyId == null && await _auth.getEmpresaId() != company)) {
      throw const StorageUsageException('companyChanged');
    }
    return usage;
  }

  Future<List<StoragePlan>> listPlans() async {
    final response = await _adminRequest('GET', '/planos');
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return data
        .map((row) => StoragePlan.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<StoragePlan> saveLimits(String id, StorageLimits limits) async {
    final response = await _adminRequest(
      'PUT',
      '/planos/${Uri.encodeComponent(id)}',
      limits.toRequest(),
    );
    return StoragePlan.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<StorageEffectivePlan> assignPlan(
    String companyId,
    String? planId,
    StorageEffectivePlan current,
  ) async {
    final response = await _adminRequest(
      'PUT',
      '/${Uri.encodeComponent(companyId)}/plano',
      current.assignmentRequest(planId),
    );
    return StorageEffectivePlan.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _adminRequest(
    String method,
    String suffix, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty)
      throw const StorageUsageException('session');
    final url = Uri.parse(
      '${AppConfig.baseUrl}/private/api/admin/armazenamento$suffix',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final response =
        await (method == 'GET'
                ? _client.get(url, headers: headers)
                : _client.put(url, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401)
      throw const StorageUsageException('session');
    if (response.statusCode == 403)
      throw const StorageUsageException('forbidden');
    if (response.statusCode == 404)
      throw const StorageUsageException('planNotFound');
    if (response.statusCode == 409)
      throw const StorageUsageException('planConflict');
    if (response.statusCode == 400)
      throw const StorageUsageException('invalidLimits');
    if (response.statusCode != 200) throw const StorageUsageException('error');
    return response;
  }

  void close() => _client.close();
}
