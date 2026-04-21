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
      '194419403668-manc56voom9d29bv0n7m4pilub8j864a.apps.googleusercontent.com';

  static GoogleSignIn _defaultGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: _serverClientId,
        scopes: const ['email', 'profile', 'openid'],
      );
    }

    final config = resolveGoogleAuthPlatformConfig();
    return GoogleSignIn(
      clientId: config.clientId,
      serverClientId: _serverClientId,
      scopes: const ['email', 'profile', 'openid'],
    );
  }

  final http.Client _client;
  final GoogleSignIn _googleSignIn;

  StreamSubscription<GoogleSignInAccount?>? _webAccountSub;
  Completer<AuthResponseModel>? _webCompleter;

  GoogleSignIn get googleSignIn => _googleSignIn;

  Uri get _googleLoginUri {
    final path = kIsWeb ? 'web' : 'mobile';
    return Uri.parse('${AppConfig.baseUrl}/auth/$path/google');
  }

  /// Mobile/desktop entry point. Opens the native Google picker and exchanges
  /// the resulting idToken with the backend.
  Future<AuthResponseModel> signIn() async {
    if (kIsWeb) {
      throw const GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message:
            'No web, utilize o botão oficial do Google renderizado na tela.',
      );
    }

    _ensurePlatformConfigured();

    final GoogleSignInAccount? account;
    try {
      await _googleSignIn.signOut();
      account = await _googleSignIn.signIn();
    } on PlatformException catch (e, s) {
      debugPrint('GoogleSignIn PlatformException: ${e.code} | ${e.message}');
      debugPrint('$s');
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        throw GoogleAuthException.cancelled();
      }
      if (e.code == GoogleSignIn.kNetworkError) {
        throw GoogleAuthException.network();
      }
      throw GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message: 'Falha no Google Sign-In (${e.code}): ${e.message ?? ''}',
      );
    } catch (e, s) {
      debugPrint('GoogleSignIn error: $e');
      debugPrint('$s');
      throw GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message: 'Falha no Google Sign-In: $e',
      );
    }

    if (account == null) {
      throw GoogleAuthException.cancelled();
    }

    final GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication;
    } catch (e, s) {
      debugPrint('GoogleSignIn authentication error: $e');
      debugPrint('$s');
      throw GoogleAuthException.missingIdToken();
    }

    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleAuthException.missingIdToken();
    }

    return _exchangeIdToken(idToken);
  }

  /// Web entry point. Starts listening for an account emitted by the
  /// `onCurrentUserChanged` stream (triggered when the user taps the rendered
  /// Google button) and also attempts a silent sign-in for returning users.
  ///
  /// The returned Future completes with the backend auth response once the
  /// user finishes the Google flow.
  Future<AuthResponseModel> awaitWebSignIn() {
    assert(kIsWeb, 'awaitWebSignIn must only be used on Flutter web.');

    final existing = _webCompleter;
    if (existing != null && !existing.isCompleted) {
      return existing.future;
    }

    final completer = Completer<AuthResponseModel>();
    _webCompleter = completer;

    _webAccountSub?.cancel();
    _webAccountSub = _googleSignIn.onCurrentUserChanged.listen(
      (account) async {
        if (account == null || completer.isCompleted) return;
        try {
          final auth = await account.authentication;
          final idToken = auth.idToken;
          if (idToken == null || idToken.isEmpty) {
            completer.completeError(GoogleAuthException.missingIdToken());
            return;
          }
          final response = await _exchangeIdToken(idToken);
          if (!completer.isCompleted) completer.complete(response);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(
            GoogleAuthException(
              code: GoogleAuthErrorCode.unknown,
              message: 'Falha no Google Sign-In: $e',
            ),
          );
        }
      },
    );

    // Fire-and-forget silent sign-in for returning users.
    unawaited(_googleSignIn.signInSilently().catchError((_) => null));

    return completer.future;
  }

  void cancelWebSignIn() {
    _webAccountSub?.cancel();
    _webAccountSub = null;
    final completer = _webCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(GoogleAuthException.cancelled());
    }
    _webCompleter = null;
  }

  Future<AuthResponseModel> _exchangeIdToken(String idToken) async {
    final http.Response response;
    try {
      response = await _client.post(
        _googleLoginUri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
    } on http.ClientException {
      throw GoogleAuthException.network();
    } catch (e) {
      if (isGoogleAuthNetworkError(e)) throw GoogleAuthException.network();
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseModel.fromJson(decoded);
    }

    throw GoogleAuthException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<void> signOut() async {
    cancelWebSignIn();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  void _ensurePlatformConfigured() {
    if (kIsWeb) return;
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    if (defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isEmpty) {
      throw const GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message:
            'Google Sign-In não configurado para iOS. Defina GOOGLE_IOS_CLIENT_ID via --dart-define e atualize o Info.plist.',
      );
    }
  }
}
