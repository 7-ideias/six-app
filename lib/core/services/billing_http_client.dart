import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

final paymentRequiredCompany = ValueNotifier<String?>(null);
Future<String?> Function()? billingCompanyResolver;

/// Adds tenant context only to authenticated requests to our own API.
/// A 402 is a billing state; it must never trigger token refresh or replay.
class BillingHttpClient extends http.BaseClient {
  BillingHttpClient(this.inner);
  final http.Client inner;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final base = Uri.tryParse(AppConfig.baseUrl);
    final authenticated = request.headers.entries.any(
      (entry) =>
          entry.key.toLowerCase() == 'authorization' &&
          entry.value.startsWith('Bearer '),
    );
    final ownApi =
        base != null &&
        base.hasAuthority &&
        (base.scheme == 'https' || base.scheme == 'http') &&
        request.url.hasAuthority &&
        request.url.origin == base.origin;
    String? company;
    if (ownApi && authenticated) {
      for (final entry in request.headers.entries) {
        if (entry.key.toLowerCase() == 'idunicodaempresa')
          company = entry.value;
      }
      if (company == null) {
        company = await billingCompanyResolver?.call();
        if (company != null && company.isNotEmpty)
          request.headers['idUnicoDaEmpresa'] = company;
      }
    }
    final response = await inner.send(request);
    if (ownApi &&
        authenticated &&
        response.statusCode == 402 &&
        company != null &&
        company == await billingCompanyResolver?.call()) {
      paymentRequiredCompany.value = company;
    }
    return response;
  }

  @override
  void close() => inner.close();
}
