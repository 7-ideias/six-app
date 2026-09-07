import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../exceptions/google_auth_exception.dart';
import '../../data/models/auth_response_model.dart';
import 'google_auth_platform_stub.dart'
    if (dart.library.io) 'google_auth_platform_io.dart';
import 'http_client_factory.dart';

enum GoogleAuthIntent { login, registration }

class _GoogleCredentials {
  const _GoogleCredentials({required this.idToken, required this.accessToken});

  final String idToken;
  final String accessToken;
}

class GoogleAuthService {
  GoogleAuthService._internal({http.Client? client, GoogleSignIn? googleSignIn})
      : _client = client ?? createHttpClient(),
        _googleSignIn = googleSignIn ?? _defaultGoogleSignIn();

  static GoogleAuthService? _instance;

  factory GoogleAuthService({
    http.Client? client,
    GoogleSignIn? googleSignIn,
  }) {
    _instance ??= GoogleAuthService._internal(
      client: client,
      googleSignIn: googleSignIn,
    );
    return _instance!;
  }

  static const String _serverClientId =
      '841074493827-srvp19o45fh2edon9gq1kgcr1nhrtk5u.apps.googleusercontent.com';

  static GoogleSignIn _defaultGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: _serverClientId,
        scopes: const <String>['email', 'profile', 'openid'],
      );
    }

    final config = resolveGoogleAuthPlatformConfig();
    return GoogleSignIn(
      clientId: config.clientId,
      serverClientId: _serverClientId,
      scopes: const <String>['email', 'profile', 'openid'],
    );
  }

  final http.Client _client;
  final GoogleSignIn _googleSignIn;

  StreamSubscription<GoogleSignInAccount?>? _webAccountSub;
  Completer<AuthResponseModel>? _webCompleter;
  _GoogleCredentials? _pendingCredentials;

  GoogleSignIn get googleSignIn => _googleSignIn;

  Uri get _googleLoginUri {
    final String path = kIsWeb ? 'web' : 'mobile';
    return Uri.parse('${AppConfig.baseUrl}/auth/$path/google');
  }

  Uri get _googleLinkUri {
    final String path = kIsWeb ? 'web' : 'mobile';
    return Uri.parse('${AppConfig.baseUrl}/auth/$path/google/link');
  }

  Future<AuthResponseModel> signIn({
    GoogleAuthIntent intent = GoogleAuthIntent.login,
    bool aceiteTermos = false,
    required String idioma,
  }) async {
    if (kIsWeb) {
      throw const GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message: 'No Web, utilize o botão Google exibido na página.',
      );
    }

    final GoogleSignInAccount? account;
    try {
      await _googleSignIn.signOut();
      account = await _googleSignIn.signIn();
    } on PlatformException catch (error, stack) {
      debugPrint('GoogleSignIn PlatformException: ${error.code}');
      debugPrint('$stack');
      if (error.code == GoogleSignIn.kSignInCanceledError) {
        throw GoogleAuthException.cancelled();
      }
      if (error.code == GoogleSignIn.kNetworkError) {
        throw GoogleAuthException.network();
      }
      throw GoogleAuthException.unknown();
    } catch (error, stack) {
      debugPrint('GoogleSignIn error: ${error.runtimeType}');
      debugPrint('$stack');
      throw GoogleAuthException.unknown();
    }

    if (account == null) throw GoogleAuthException.cancelled();

    final _GoogleCredentials credentials = await _credentialsFromAccount(account);
    _pendingCredentials = credentials;
    try {
      final AuthResponseModel response = await _exchangeCredentials(
        credentials,
        intent: intent,
        aceiteTermos: aceiteTermos,
        idioma: idioma,
      );
      _pendingCredentials = null;
      return response;
    } on GoogleAuthException catch (error) {
      if (error.code != GoogleAuthErrorCode.linkRequired) {
        _pendingCredentials = null;
      }
      rethrow;
    }
  }

  Future<AuthResponseModel> linkPendingAccount({
    required String senha,
    required GoogleAuthIntent intent,
    required bool aceiteTermos,
    required String idioma,
  }) async {
    final _GoogleCredentials? credentials = _pendingCredentials;
    if (credentials == null) {
      throw const GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message: 'A autorização Google expirou. Tente novamente.',
      );
    }

    final http.Response response;
    try {
      response = await _client.post(
        _googleLinkUri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, Object?>{
          'idToken': credentials.idToken,
          'accessToken': credentials.accessToken,
          'senha': senha,
          'fluxo': _flow(intent),
          'aceiteTermos': aceiteTermos,
          'idioma': idioma,
        }),
      );
    } on http.ClientException {
      throw GoogleAuthException.network();
    } catch (error) {
      if (isGoogleAuthNetworkError(error)) throw GoogleAuthException.network();
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _pendingCredentials = null;
      final dynamic decoded = jsonDecode(response.body);
      return AuthResponseModel.fromJson(decoded as Map<String, dynamic>);
    }

    throw GoogleAuthException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
      linking: true,
    );
  }

  Future<_GoogleCredentials> _credentialsFromAccount(
    GoogleSignInAccount account,
  ) async {
    final GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication;
    } catch (_) {
      throw GoogleAuthException.missingIdToken();
    }

    final String idToken = auth.idToken?.trim() ?? '';
    final String accessToken = auth.accessToken?.trim() ?? '';
    if (idToken.isEmpty) throw GoogleAuthException.missingIdToken();
    if (accessToken.isEmpty) throw GoogleAuthException.missingAccessToken();
    return _GoogleCredentials(idToken: idToken, accessToken: accessToken);
  }

  Future<AuthResponseModel> _exchangeCredentials(
    _GoogleCredentials credentials, {
    required GoogleAuthIntent intent,
    required bool aceiteTermos,
    required String idioma,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        _googleLoginUri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, Object?>{
          'idToken': credentials.idToken,
          'accessToken': credentials.accessToken,
          'fluxo': _flow(intent),
          'aceiteTermos': aceiteTermos,
          'idioma': idioma,
        }),
      );
    } on http.ClientException {
      throw GoogleAuthException.network();
    } catch (error) {
      if (isGoogleAuthNetworkError(error)) throw GoogleAuthException.network();
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded = jsonDecode(response.body);
      return AuthResponseModel.fromJson(decoded as Map<String, dynamic>);
    }

    throw GoogleAuthException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<AuthResponseModel> awaitWebSignIn({
    String idioma = 'pt-BR',
  }) {
    assert(kIsWeb, 'awaitWebSignIn must only be used on Flutter web.');

    final Completer<AuthResponseModel>? existing = _webCompleter;
    if (existing != null && !existing.isCompleted) return existing.future;

    final Completer<AuthResponseModel> completer = Completer<AuthResponseModel>();
    _webCompleter = completer;
    _webAccountSub?.cancel();
    _webAccountSub = _googleSignIn.onCurrentUserChanged.listen(
      (GoogleSignInAccount? account) async {
        if (account == null || completer.isCompleted) return;
        try {
          final _GoogleCredentials credentials =
              await _credentialsFromAccount(account);
          _pendingCredentials = credentials;
          final AuthResponseModel response = await _exchangeCredentials(
            credentials,
            intent: GoogleAuthIntent.login,
            aceiteTermos: false,
            idioma: idioma,
          );
          _pendingCredentials = null;
          if (!completer.isCompleted) completer.complete(response);
        } catch (error) {
          if (!completer.isCompleted) completer.completeError(error);
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    unawaited(_googleSignIn.signInSilently().catchError((_) => null));
    return completer.future;
  }

  void cancelWebSignIn() {
    _webAccountSub?.cancel();
    _webAccountSub = null;
    final Completer<AuthResponseModel>? completer = _webCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(GoogleAuthException.cancelled());
    }
    _webCompleter = null;
  }

  Future<void> signOut() async {
    cancelWebSignIn();
    _pendingCredentials = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  static String _flow(GoogleAuthIntent intent) =>
      intent == GoogleAuthIntent.registration ? 'CADASTRO' : 'LOGIN';
}
