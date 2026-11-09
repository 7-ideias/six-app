import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/http_client_factory.dart';
import '../models/billing_access.dart';

class BillingAccessException implements Exception {
  const BillingAccessException(this.code);
  final String code;
}

class BillingAccessApi {
  BillingAccessApi({http.Client? client, AuthService? auth})
    : _client = client ?? createHttpClient(),
      _auth = auth ?? AuthService();
  final http.Client _client;
  final AuthService _auth;
  Future<BillingAccess> load(String company, {bool admin = false}) => _request(
    company,
    admin
        ? '/private/api/admin/assinatura/${Uri.encodeComponent(company)}/acesso'
        : '/private/api/assinatura/acesso',
  );
  Future<BillingAccess> release(
    BillingAccess current,
    bool enabled,
    String reason,
  ) => _request(
    current.companyId,
    '/private/api/admin/assinatura/${Uri.encodeComponent(current.companyId)}/liberacao',
    body: {
      'enabled': enabled,
      'reason': reason.trim(),
      'expectedVersion': current.version,
      'expiresAt': null,
    },
  );
  Future<BillingAccess> _request(
    String company,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty)
      throw const BillingAccessException('session');
    final headers = {
      'Authorization': 'Bearer $token',
      'idUnicoDaEmpresa': company,
      'Content-Type': 'application/json',
    };
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final response =
        await (body == null
                ? _client.get(uri, headers: headers)
                : _client.put(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 20));
    if (response.statusCode == 409)
      throw const BillingAccessException('conflict');
    if (response.statusCode == 403)
      throw const BillingAccessException('forbidden');
    if (response.statusCode != 200) throw const BillingAccessException('error');
    final result = BillingAccess.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
    if (result.companyId != company)
      throw const BillingAccessException('error');
    return result;
  }

  void close() => _client.close();
}
