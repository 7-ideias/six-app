import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/storage_usage.dart';

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

  void close() => _client.close();
}
