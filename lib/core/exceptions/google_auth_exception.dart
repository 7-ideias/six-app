import 'dart:convert';

enum GoogleAuthErrorCode {
  cancelledByUser,
  missingIdToken,
  missingAccessToken,
  registrationRequired,
  linkRequired,
  termsRequired,
  invalidExistingPassword,
  backendRejected,
  unavailable,
  network,
  unknown,
}

class GoogleAuthException implements Exception {
  final GoogleAuthErrorCode code;
  final String message;
  final int? statusCode;
  final String? backendCode;

  const GoogleAuthException({
    required this.code,
    required this.message,
    this.statusCode,
    this.backendCode,
  });

  factory GoogleAuthException.fromResponse({
    required int statusCode,
    required String body,
    bool linking = false,
  }) {
    final String? backendCode = _extractBackendCode(body);

    if (statusCode == 404 || backendCode == 'GOOGLE_CONTA_NAO_CADASTRADA') {
      return GoogleAuthException(
        code: GoogleAuthErrorCode.registrationRequired,
        message: 'Esta Conta Google ainda não possui uma conta SixoApp.',
        statusCode: statusCode,
        backendCode: backendCode,
      );
    }
    if (statusCode == 409 || backendCode == 'GOOGLE_VINCULACAO_NECESSARIA') {
      return GoogleAuthException(
        code: GoogleAuthErrorCode.linkRequired,
        message:
            'Já existe uma conta SixoApp com este e-mail. Confirme sua senha atual para vincular o Google.',
        statusCode: statusCode,
        backendCode: backendCode,
      );
    }
    if (statusCode == 422 || backendCode == 'GOOGLE_ACEITE_TERMOS_OBRIGATORIO') {
      return GoogleAuthException(
        code: GoogleAuthErrorCode.termsRequired,
        message: 'Aceite os Termos e a Política de Privacidade para continuar.',
        statusCode: statusCode,
        backendCode: backendCode,
      );
    }
    if (linking && statusCode == 401) {
      return GoogleAuthException(
        code: GoogleAuthErrorCode.invalidExistingPassword,
        message: 'A senha atual informada não foi aceita.',
        statusCode: statusCode,
        backendCode: backendCode,
      );
    }
    if (statusCode >= 500) {
      return GoogleAuthException(
        code: GoogleAuthErrorCode.unavailable,
        message: 'O login com Google está temporariamente indisponível.',
        statusCode: statusCode,
        backendCode: backendCode,
      );
    }

    return GoogleAuthException(
      code: GoogleAuthErrorCode.backendRejected,
      message: statusCode == 401
          ? 'Não foi possível validar sua Conta Google.'
          : 'Não foi possível concluir a autenticação com Google.',
      statusCode: statusCode,
      backendCode: backendCode,
    );
  }

  static String? _extractBackendCode(String body) {
    final String text = body.trim();
    if (text.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        for (final String key in <String>['code', 'error', 'detail', 'message']) {
          final dynamic value = decoded[key];
          if (value is String) {
            final RegExpMatch? match =
                RegExp(r'GOOGLE_[A-Z0-9_]+').firstMatch(value);
            if (match != null) return match.group(0);
          }
        }
      }
    } catch (_) {}
    return RegExp(r'GOOGLE_[A-Z0-9_]+').firstMatch(text)?.group(0);
  }

  factory GoogleAuthException.cancelled() => const GoogleAuthException(
        code: GoogleAuthErrorCode.cancelledByUser,
        message: 'Login com Google cancelado.',
      );

  factory GoogleAuthException.missingIdToken() => const GoogleAuthException(
        code: GoogleAuthErrorCode.missingIdToken,
        message: 'Não foi possível obter a identidade da Conta Google.',
      );

  factory GoogleAuthException.missingAccessToken() => const GoogleAuthException(
        code: GoogleAuthErrorCode.missingAccessToken,
        message: 'Não foi possível obter a autorização da Conta Google.',
      );

  factory GoogleAuthException.network() => const GoogleAuthException(
        code: GoogleAuthErrorCode.network,
        message: 'Falha de conexão. Verifique sua internet e tente novamente.',
      );

  factory GoogleAuthException.unknown() => const GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message: 'Não foi possível concluir a autenticação com Google.',
      );

  @override
  String toString() =>
      'GoogleAuthException($code, $statusCode, $backendCode): $message';
}
