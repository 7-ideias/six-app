import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import '../../data/models/auth_response_model.dart';
import '../config/app_config.dart';
import '../exceptions/google_auth_exception.dart';
import 'http_client_factory.dart';

class MobileOidcConfig {
  const MobileOidcConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.logoutEndpoint,
    required this.identityProviderAlias,
    required this.scopes,
  });

  final String issuer;
  final String clientId;
  final String redirectUri;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String logoutEndpoint;
  final String identityProviderAlias;
  final List<String> scopes;

  factory MobileOidcConfig.fromJson(Map<String, dynamic> json) {
    return MobileOidcConfig(
      issuer: json['issuer']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      redirectUri: json['redirectUri']?.toString() ?? '',
      authorizationEndpoint: json['authorizationEndpoint']?.toString() ?? '',
      tokenEndpoint: json['tokenEndpoint']?.toString() ?? '',
      logoutEndpoint: json['logoutEndpoint']?.toString() ?? '',
      identityProviderAlias:
          json['identityProviderAlias']?.toString() ?? 'google',
      scopes: List<String>.from(json['scopes'] ?? const <String>[]),
    );
  }

  AuthorizationServiceConfiguration get serviceConfiguration =>
      AuthorizationServiceConfiguration(
        authorizationEndpoint: authorizationEndpoint,
        tokenEndpoint: tokenEndpoint,
      );
}

class MobileOidcTokenSet {
  const MobileOidcTokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
}

class MobileOidcAuthService {
  MobileOidcAuthService({
    FlutterAppAuth? appAuth,
    http.Client? client,
  }) : _appAuth = appAuth ?? const FlutterAppAuth(),
       _client = client ?? createHttpClient();

  final FlutterAppAuth _appAuth;
  final http.Client _client;
  MobileOidcConfig? _cachedConfig;

  Future<AuthResponseModel> loginComGoogle() async {
    final MobileOidcConfig config = await _config();

    final AuthorizationTokenResponse result =
        await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            config.clientId,
            config.redirectUri,
            serviceConfiguration: config.serviceConfiguration,
            scopes: config.scopes,
            promptValues: const <String>['login'],
            externalUserAgent: _interactiveExternalUserAgent,
            additionalParameters: <String, String>{
              'kc_idp_hint': config.identityProviderAlias,
            },
          ),
        );

    final String accessToken = result.accessToken?.trim() ?? '';
    final String refreshToken = result.refreshToken?.trim() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError(
        'Keycloak não retornou access/refresh token para a sessão mobile offline.',
      );
    }

    final Map<String, dynamic> bootstrap = await _bootstrap(accessToken);
    return AuthResponseModel.fromJson(<String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': _expiresIn(result.accessTokenExpirationDateTime),
      'refreshExpiresIn': 0,
      'tokenType': result.tokenType ?? 'Bearer',
      'idUnicoDaEmpresa': bootstrap['idUnicoDaEmpresa'] ?? const <String>[],
      'usuario': bootstrap['usuario'] ?? const <String, dynamic>{},
    });
  }

  Future<MobileOidcTokenSet> refresh(String refreshToken) async {
    final MobileOidcConfig config = await _config();
    final TokenResponse result = await _appAuth.token(
      TokenRequest(
        config.clientId,
        config.redirectUri,
        serviceConfiguration: config.serviceConfiguration,
        refreshToken: refreshToken,
        scopes: config.scopes,
      ),
    );

    final String accessToken = result.accessToken?.trim() ?? '';
    if (accessToken.isEmpty) {
      throw StateError('Keycloak não retornou access token no refresh mobile.');
    }

    return MobileOidcTokenSet(
      accessToken: accessToken,
      refreshToken: result.refreshToken?.trim().isNotEmpty == true
          ? result.refreshToken!.trim()
          : refreshToken,
      expiresIn: _expiresIn(result.accessTokenExpirationDateTime),
      tokenType: result.tokenType ?? 'Bearer',
    );
  }

  Future<void> logout(String refreshToken) async {
    if (refreshToken.trim().isEmpty) return;
    final MobileOidcConfig config = await _config();
    try {
      await _client.post(
        Uri.parse(config.logoutEndpoint),
        headers: const <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'client_id': config.clientId,
          'refresh_token': refreshToken,
        },
      );
    } catch (_) {
      // Logout remoto é best-effort. A sessão local será apagada pelo AuthService.
    }
  }

  ExternalUserAgent? get _interactiveExternalUserAgent {
    // No iOS, uma autenticação interativa deve ser independente da sessão
    // persistida no Safari/ASWebAuthenticationSession. Isso evita que logout,
    // reinstalação ou troca de usuário reutilizem silenciosamente a conta Google
    // anterior. A sessão longa do SixoApp continua sendo mantida pelo refresh
    // token offline salvo no Keychain; esta opção só afeta uma nova entrada
    // manual no fluxo Google.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return ExternalUserAgent.ephemeralAsWebAuthenticationSession;
    }
    return null;
  }

  Future<MobileOidcConfig> _config() async {
    final MobileOidcConfig? cached = _cachedConfig;
    if (cached != null) return cached;

    final http.Response response = await _client.get(
      Uri.parse('${AppConfig.baseUrl}/public/auth/mobile/oidc/config'),
      headers: const <String, String>{'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Não foi possível carregar a configuração OIDC mobile (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Configuração OIDC mobile inválida.');
    }

    final MobileOidcConfig config = MobileOidcConfig.fromJson(decoded);
    if (config.clientId.isEmpty ||
        config.redirectUri.isEmpty ||
        config.authorizationEndpoint.isEmpty ||
        config.tokenEndpoint.isEmpty) {
      throw const FormatException('Configuração OIDC mobile incompleta.');
    }
    _cachedConfig = config;
    return config;
  }

  Future<Map<String, dynamic>> _bootstrap(String accessToken) async {
    final http.Response response = await _client.get(
      Uri.parse(
        '${AppConfig.baseUrl}/private/api/auth/mobile/session/bootstrap',
      ),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 404) {
      throw const GoogleAuthException(
        code: GoogleAuthErrorCode.registrationRequired,
        message: 'Esta Conta Google ainda não possui uma conta SixoApp.',
        statusCode: 404,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Não foi possível concluir a sessão SixoApp (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Bootstrap da sessão mobile inválido.');
    }
    return decoded;
  }

  int _expiresIn(DateTime? expiresAt) {
    if (expiresAt == null) return 0;
    final int seconds = expiresAt.toUtc().difference(DateTime.now().toUtc()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }
}
