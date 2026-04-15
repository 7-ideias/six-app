/// Códigos de erro retornados pelo backend no fluxo de registro com OTP.
enum RegistroOtpErrorCode {
  invalidOrExpired, // OTP_001 → 401
  smtpFailure,      // OTP_002 → 502
  emailNotVerified, // OTP_003 → 403
  unknown,
}

class RegistroOtpException implements Exception {
  final RegistroOtpErrorCode code;
  final String message;
  final int? statusCode;

  const RegistroOtpException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory RegistroOtpException.fromResponse({
    required int statusCode,
    required String body,
  }) {
    final codeFromStatus = switch (statusCode) {
      401 => RegistroOtpErrorCode.invalidOrExpired,
      403 => RegistroOtpErrorCode.emailNotVerified,
      502 => RegistroOtpErrorCode.smtpFailure,
      _ => RegistroOtpErrorCode.unknown,
    };

    return RegistroOtpException(
      code: codeFromStatus,
      message: _friendlyMessage(codeFromStatus),
      statusCode: statusCode,
    );
  }

  static String _friendlyMessage(RegistroOtpErrorCode code) {
    return switch (code) {
      RegistroOtpErrorCode.invalidOrExpired =>
        'Código inválido ou expirado. Solicite um novo código.',
      RegistroOtpErrorCode.smtpFailure =>
        'Não foi possível enviar o e-mail agora. Tente novamente em instantes.',
      RegistroOtpErrorCode.emailNotVerified =>
        'E-mail não verificado. Confirme o código enviado para prosseguir.',
      RegistroOtpErrorCode.unknown =>
        'Não foi possível concluir a operação. Tente novamente.',
    };
  }

  @override
  String toString() => 'RegistroOtpException($code, $statusCode): $message';
}
