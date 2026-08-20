import 'dart:async';

import 'package:http/http.dart' as http;

typedef UnauthorizedTokenRefreshHandler =
    Future<String?> Function(String rejectedAccessToken);

/// Reenvia uma única vez requests autenticados rejeitados com 401.
///
/// O refresh fica fora deste client para evitar acoplamento com armazenamento,
/// Web/Mobile e navegação. A callback registrada pelo `AuthService` já aplica
/// single-flight, rotação do refresh token e classificação de falhas.
class SessionRefreshingHttpClient extends http.BaseClient {
  SessionRefreshingHttpClient({
    required http.Client inner,
    required UnauthorizedTokenRefreshHandler? Function() refreshHandler,
  }) : _inner = inner,
       _refreshHandler = refreshHandler;

  final http.Client _inner;
  final UnauthorizedTokenRefreshHandler? Function() _refreshHandler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String? rejectedAccessToken = _bearerToken(request.headers);
    if (rejectedAccessToken == null) {
      return _inner.send(request);
    }

    final Map<String, String> headers = Map<String, String>.from(
      request.headers,
    );
    final List<int> bodyBytes = await request.finalize().toBytes();

    final http.StreamedResponse response = await _inner.send(
      _copyRequest(request, headers: headers, bodyBytes: bodyBytes),
    );
    if (response.statusCode != 401) {
      return response;
    }

    final UnauthorizedTokenRefreshHandler? refreshHandler = _refreshHandler();
    if (refreshHandler == null) {
      return response;
    }

    await response.stream.drain<void>();
    final String? renewedAccessToken = await refreshHandler(
      rejectedAccessToken,
    );
    if (renewedAccessToken == null || renewedAccessToken.trim().isEmpty) {
      throw http.ClientException(
        'A sessão não pôde ser renovada.',
        request.url,
      );
    }

    final Map<String, String> retryHeaders = Map<String, String>.from(headers);
    _replaceAuthorizationHeader(retryHeaders, renewedAccessToken);

    return _inner.send(
      _copyRequest(request, headers: retryHeaders, bodyBytes: bodyBytes),
    );
  }

  http.Request _copyRequest(
    http.BaseRequest source, {
    required Map<String, String> headers,
    required List<int> bodyBytes,
  }) {
    final Map<String, String> copiedHeaders = Map<String, String>.from(headers)
      ..removeWhere(
        (String name, String _) => name.toLowerCase() == 'content-length',
      );

    return http.Request(source.method, source.url)
      ..headers.addAll(copiedHeaders)
      ..followRedirects = source.followRedirects
      ..maxRedirects = source.maxRedirects
      ..persistentConnection = source.persistentConnection
      ..bodyBytes = bodyBytes;
  }

  String? _bearerToken(Map<String, String> headers) {
    for (final MapEntry<String, String> header in headers.entries) {
      if (header.key.toLowerCase() != 'authorization') {
        continue;
      }

      final RegExpMatch? match = RegExp(
        r'^Bearer\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(header.value.trim());
      final String token = match?.group(1)?.trim() ?? '';
      return token.isEmpty ? null : token;
    }
    return null;
  }

  void _replaceAuthorizationHeader(
    Map<String, String> headers,
    String accessToken,
  ) {
    String headerName = 'Authorization';
    for (final String name in headers.keys) {
      if (name.toLowerCase() == 'authorization') {
        headerName = name;
        break;
      }
    }
    headers[headerName] = 'Bearer $accessToken';
  }

  @override
  void close() {
    _inner.close();
  }
}
