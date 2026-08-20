import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../data/services/usuario/usuario_api_client.dart';
import '../navigation/web_auth_route_utils.dart';

enum WebAuthGateStatus {
  initializing,
  checkingSession,
  restoringSession,
  bootstrapping,
  authenticated,
  unauthenticated,
  temporaryError,
}

enum WebAuthGateAccessTokenStatus { absent, valid, refreshRequired }

enum WebAuthGateFailureType { invalidSession, temporary }

abstract class WebAuthGateSession {
  Future<WebAuthGateAccessTokenStatus> currentAccessTokenStatus();

  Future<void> restoreSession();

  Future<void> clearLocalSession();
}

abstract class WebAuthGateBootstrap {
  Future<void> bootstrap({bool force = false});

  void reset();
}

class AuthServiceWebAuthGateSession implements WebAuthGateSession {
  AuthServiceWebAuthGateSession({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Future<WebAuthGateAccessTokenStatus> currentAccessTokenStatus() async {
    final AuthAccessTokenStatus status =
        await _authService.getCurrentWebAccessTokenStatus();
    return switch (status) {
      AuthAccessTokenStatus.absent => WebAuthGateAccessTokenStatus.absent,
      AuthAccessTokenStatus.valid => WebAuthGateAccessTokenStatus.valid,
      AuthAccessTokenStatus.refreshRequired =>
        WebAuthGateAccessTokenStatus.refreshRequired,
    };
  }

  @override
  Future<void> restoreSession() {
    return _authService.restoreWebSession();
  }

  @override
  Future<void> clearLocalSession() {
    return _authService.clearLocalWebSession();
  }
}

class WebAuthGateFailure implements Exception {
  const WebAuthGateFailure({required this.type, this.statusCode, this.message});

  final WebAuthGateFailureType type;
  final int? statusCode;
  final String? message;

  static WebAuthGateFailure fromError(Object error) {
    if (error is WebAuthGateFailure) {
      return error;
    }

    if (error is AuthRefreshException) {
      return WebAuthGateFailure(
        type:
            error.isInvalidSession
                ? WebAuthGateFailureType.invalidSession
                : WebAuthGateFailureType.temporary,
        statusCode: error.statusCode,
        message: error.message,
      );
    }

    final int? statusCode = _statusCodeFromError(error);
    if (statusCode == 401) {
      return WebAuthGateFailure(
        type: WebAuthGateFailureType.invalidSession,
        statusCode: statusCode,
      );
    }

    if (error is TimeoutException || error is http.ClientException) {
      return WebAuthGateFailure(
        type: WebAuthGateFailureType.temporary,
        statusCode: statusCode,
        message: error.toString(),
      );
    }

    return WebAuthGateFailure(
      type: WebAuthGateFailureType.temporary,
      statusCode: statusCode,
      message: error.toString(),
    );
  }

  static int? _statusCodeFromError(Object error) {
    if (error is UsuarioApiException) {
      return error.statusCode;
    }
    if (error is ColaboradorUsuarioApiException) {
      return error.statusCode;
    }
    if (error is RegionalizacaoApiException) {
      return error.statusCode;
    }

    final RegExpMatch? match = RegExp(
      r'(?:statusCode|status|c[oó]digo)\D*(\d{3})',
      caseSensitive: false,
    ).firstMatch(error.toString());
    return int.tryParse(match?.group(1) ?? '');
  }

  @override
  String toString() {
    final String status = statusCode == null ? '' : ', statusCode: $statusCode';
    final String detail = message == null ? '' : ', message: $message';
    return 'WebAuthGateFailure(type: $type$status$detail)';
  }
}

class WebAuthGateController extends ChangeNotifier {
  WebAuthGateController({
    required WebAuthGateSession session,
    required WebAuthGateBootstrap bootstrap,
    required String requestedLocation,
  }) : _session = session,
       _bootstrap = bootstrap,
       requestedLocation = normalizeAuthenticatedWebLocation(requestedLocation);

  final WebAuthGateSession _session;
  final WebAuthGateBootstrap _bootstrap;

  final String requestedLocation;
  Future<void>? _initialization;

  WebAuthGateStatus _status = WebAuthGateStatus.initializing;
  WebAuthGateFailure? _failure;

  WebAuthGateStatus get status => _status;

  WebAuthGateFailure? get failure => _failure;

  String get loginRoute =>
      buildLoginRouteForAuthenticatedWebRedirect(requestedLocation);

  Future<void> start() {
    if (_status == WebAuthGateStatus.authenticated ||
        _status == WebAuthGateStatus.unauthenticated) {
      return Future<void>.value();
    }

    final Future<void>? current = _initialization;
    if (current != null) {
      return current;
    }

    final Future<void> initialization = _run();
    _initialization = initialization;
    initialization.whenComplete(() {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });
    return initialization;
  }

  Future<void> retry() {
    if (_initialization != null) {
      return _initialization!;
    }

    _failure = null;
    final Future<void> initialization = _run();
    _initialization = initialization;
    initialization.whenComplete(() {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });
    return initialization;
  }

  Future<void> _run() async {
    try {
      _setStatus(WebAuthGateStatus.checkingSession);
      final WebAuthGateAccessTokenStatus tokenStatus =
          await _session.currentAccessTokenStatus();

      if (tokenStatus == WebAuthGateAccessTokenStatus.valid) {
        await _bootstrapAuthenticatedContext(allowRestoreOnAuthFailure: true);
        return;
      }

      final bool restored = await _restoreSession();
      if (!restored) {
        return;
      }

      await _bootstrapAuthenticatedContext(allowRestoreOnAuthFailure: false);
    } catch (error) {
      await _handleFailure(error);
    }
  }

  Future<bool> _restoreSession() async {
    _setStatus(WebAuthGateStatus.restoringSession);
    try {
      await _session.restoreSession();
      return true;
    } catch (error) {
      await _handleFailure(error);
      return false;
    }
  }

  Future<void> _bootstrapAuthenticatedContext({
    required bool allowRestoreOnAuthFailure,
  }) async {
    _setStatus(WebAuthGateStatus.bootstrapping);
    try {
      await _bootstrap.bootstrap();
      _failure = null;
      _setStatus(WebAuthGateStatus.authenticated);
    } catch (error) {
      final WebAuthGateFailure failure = WebAuthGateFailure.fromError(error);
      if (allowRestoreOnAuthFailure &&
          failure.type == WebAuthGateFailureType.invalidSession) {
        final bool restored = await _restoreSession();
        if (restored) {
          await _bootstrapAuthenticatedContext(
            allowRestoreOnAuthFailure: false,
          );
        }
        return;
      }

      await _handleFailure(failure);
    }
  }

  Future<void> _handleFailure(Object error) async {
    final WebAuthGateFailure failure = WebAuthGateFailure.fromError(error);
    _failure = failure;

    if (failure.type == WebAuthGateFailureType.invalidSession) {
      await _session.clearLocalSession();
      _bootstrap.reset();
      _setStatus(WebAuthGateStatus.unauthenticated);
      return;
    }

    _setStatus(WebAuthGateStatus.temporaryError);
  }

  void _setStatus(WebAuthGateStatus status) {
    if (_status == status && status != WebAuthGateStatus.temporaryError) {
      return;
    }

    _status = status;
    notifyListeners();
  }
}
