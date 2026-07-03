import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';

/// Busca as traduções de UI no endpoint público do backend.
///
/// `GET {baseUrl}/public/api/i18n/{languageTag}` → `{ locale, version, messages }`.
///
/// Estratégia resiliente:
/// - mantém uma cópia local apenas do idioma ativo (corpo + ETag);
/// - ao trocar de idioma, remove os caches dos demais idiomas suportados;
/// - envia `If-None-Match` e trata `304 Not Modified` reutilizando o cache;
/// - em qualquer falha retorna o cache local do idioma ativo se houver, ou `null`.
class SixI18nApiClient {
  SixI18nApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const String _bodyPrefix = 'web_i18n_body_';
  static const String _etagPrefix = 'web_i18n_etag_';
  static const String _activeLocaleKey = 'web_i18n_active_locale';
  static const List<String> _supportedLanguageTags = <String>[
    'pt-BR',
    'en-US',
    'es-ES',
  ];
  static const Duration _timeout = Duration(seconds: 12);

  /// Retorna a árvore `messages` para [languageTag] (ex.: 'pt-BR'), ou `null`.
  ///
  /// A resposta representa todos os namespaces daquele idioma já mesclados pelo
  /// backend. Assim, ao trocar o idioma, o app baixa o pacote completo que será
  /// usado à medida que o usuário navega pelas telas.
  Future<Map<String, dynamic>?> fetchMessages(
    String languageTag, {
    bool force = false,
  }) async {
    final normalizedTag = _normalizeLanguageTag(languageTag);
    final prefs = await SharedPreferences.getInstance();
    final bodyKey = '$_bodyPrefix$normalizedTag';
    final etagKey = '$_etagPrefix$normalizedTag';
    final cachedBody = prefs.getString(bodyKey);

    if (AppConfig.baseUrl.isEmpty) {
      return _extractMessages(cachedBody);
    }

    try {
      final cachedEtag = prefs.getString(etagKey);
      final baseUri = Uri.parse('${AppConfig.baseUrl}/public/api/i18n/$normalizedTag');
      final uri = force
          ? baseUri.replace(
              queryParameters: <String, String>{
                '_refresh': DateTime.now().millisecondsSinceEpoch.toString(),
              },
            )
          : baseUri;

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (!force && cachedEtag != null && cachedBody != null) {
        headers['If-None-Match'] = cachedEtag;
      }

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 304) {
        await _markLocaleAsActiveAndPruneOthers(prefs, normalizedTag);
        return _extractMessages(cachedBody);
      }

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        await prefs.setString(bodyKey, body);
        final etag = response.headers['etag'];
        if (etag != null && etag.isNotEmpty) {
          await prefs.setString(etagKey, etag);
        }
        await _markLocaleAsActiveAndPruneOthers(prefs, normalizedTag);
        return _extractMessages(body);
      }

      return _extractMessages(cachedBody);
    } catch (_) {
      return _extractMessages(cachedBody);
    }
  }

  Future<void> _markLocaleAsActiveAndPruneOthers(
    SharedPreferences prefs,
    String activeTag,
  ) async {
    await prefs.setString(_activeLocaleKey, activeTag);

    for (final tag in _supportedLanguageTags) {
      if (tag == activeTag) continue;
      await prefs.remove('$_bodyPrefix$tag');
      await prefs.remove('$_etagPrefix$tag');
    }
  }

  String _normalizeLanguageTag(String languageTag) {
    final raw = languageTag.trim();
    if (raw.toLowerCase().startsWith('en')) return 'en-US';
    if (raw.toLowerCase().startsWith('es')) return 'es-ES';
    return 'pt-BR';
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

/// Alias de compatibilidade para chamadas antigas enquanto o app migra de
/// `WebI18n*` para `SixI18n*` em web, Android e iOS.
class WebI18nApiClient extends SixI18nApiClient {
  WebI18nApiClient({super.httpClient});
}
