import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';

/// Busca as traduções de UI no endpoint público do backend.
///
/// `GET {baseUrl}/public/api/i18n/{languageTag}` → `{ locale, version, messages }`.
///
/// Estratégia resiliente:
/// - mantém uma cópia em [SharedPreferences] (corpo + ETag);
/// - envia `If-None-Match` e trata `304 Not Modified` reutilizando o cache;
/// - em qualquer falha (sem rede, baseUrl vazia, timeout, erro HTTP) retorna o
///   cache local se houver, ou `null` — nunca lança para a UI.
class WebI18nApiClient {
  WebI18nApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const String _bodyPrefix = 'web_i18n_body_';
  static const String _etagPrefix = 'web_i18n_etag_';
  static const Duration _timeout = Duration(seconds: 6);

  /// Retorna a árvore `messages` para [languageTag] (ex.: 'pt-BR'), ou `null`.
  Future<Map<String, dynamic>?> fetchMessages(String languageTag) async {
    final prefs = await SharedPreferences.getInstance();
    final bodyKey = '$_bodyPrefix$languageTag';
    final etagKey = '$_etagPrefix$languageTag';
    final cachedBody = prefs.getString(bodyKey);

    if (AppConfig.baseUrl.isEmpty) {
      return _extractMessages(cachedBody);
    }

    try {
      final cachedEtag = prefs.getString(etagKey);
      final uri = Uri.parse('${AppConfig.baseUrl}/public/api/i18n/$languageTag');

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (cachedEtag != null && cachedBody != null) {
        headers['If-None-Match'] = cachedEtag;
      }

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 304) {
        return _extractMessages(cachedBody);
      }

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        await prefs.setString(bodyKey, body);
        final etag = response.headers['etag'];
        if (etag != null && etag.isNotEmpty) {
          await prefs.setString(etagKey, etag);
        }
        return _extractMessages(body);
      }

      return _extractMessages(cachedBody);
    } catch (_) {
      return _extractMessages(cachedBody);
    }
  }

  Map<String, dynamic>? _extractMessages(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['messages'] is Map) {
        return (decoded['messages'] as Map).map(
          (k, v) => MapEntry(k.toString(), v),
        );
      }
    } catch (_) {
      // Cache corrompido — ignora e deixa o fallback assumir.
    }
    return null;
  }
}
