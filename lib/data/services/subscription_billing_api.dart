import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/http_client_factory.dart';
import '../models/subscription_billing.dart';
import 'billing_access_api.dart';

class SubscriptionBillingApi {
  SubscriptionBillingApi({http.Client? client, AuthService? auth})
    : _client = client ?? createHttpClient(),
      _auth = auth ?? AuthService();
  final http.Client _client;
  final AuthService _auth;
  Future<Map<String, dynamic>> _request(
    String company,
    String action, {
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
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/assinatura/$action',
    );
    final response =
        await (body == null
                ? _client.get(uri, headers: headers)
                : _client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 60));
    if (response.statusCode == 403)
      throw const BillingAccessException('forbidden');
    if (response.statusCode == 401)
      throw const BillingAccessException('session');
    if (response.statusCode == 409) {
      if (response.body.contains('BILLING_PRICE_CHANGED')) {
        throw const BillingAccessException('priceChanged');
      }
      throw const BillingAccessException('purchaseConflict');
    }
    if (response.statusCode == 503)
      throw const BillingAccessException('paymentUnavailable');
    if (response.statusCode != 200) throw const BillingAccessException('error');
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<SubscriptionSummary> summary(
    String company, {
    bool sync = false,
    String locale = 'pt-BR',
    String currency = 'BRL',
  }) async {
    final result = SubscriptionSummary.fromJson(
      await _request(
        company,
        '${sync ? 'sincronizar' : 'resumo'}?${Uri(queryParameters: {'locale': locale, 'currency': currency}).query}',
        body: sync ? {} : null,
      ),
    );
    if (result.companyId != company)
      throw const BillingAccessException('error');
    return result;
  }

  Future<Uri> checkout(String company, BillingOffer offer) async =>
      _url(await _request(company, 'checkout', body: offer.purchase()));
  Future<Uri> portal(String company) async =>
      _url(await _request(company, 'portal', body: {}));
  static Uri _url(Map<String, dynamic> data) {
    final uri = Uri.parse(data['url'] as String);
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        !{'checkout.stripe.com', 'billing.stripe.com'}.contains(uri.host))
      throw const BillingAccessException('error');
    return uri;
  }

  void close() => _client.close();
}
