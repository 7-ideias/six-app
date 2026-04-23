/// Códigos de erro retornados pelo backend no fluxo de recuperação de senha.
enum RecuperacaoSenhaErrorCode {
  emailNaoEncontrado, // PWD_001 → 404
  codigoInvalido,     // PWD_002 → 401
  codigoExpirado,     // PWD_003 → 410
  smtpFailure,        // PWD_004 → 502
  senhaInvalida,      // PWD_005 → 422
  unknown,
}

class RecuperacaoSenhaException implements Exception {
  final RecuperacaoSenhaErrorCode code;
  final String message;
  final int? statusCode;

  const RecuperacaoSenhaException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory RecuperacaoSenhaException.fromResponse({
    required int statusCode,
    required String body,
  }) {
    final codeFromStatus = switch (statusCode) {
      401 => RecuperacaoSenhaErrorCode.codigoInvalido,
      404 => RecuperacaoSenhaErrorCode.emailNaoEncontrado,
      410 => RecuperacaoSenhaErrorCode.codigoExpirado,
      422 => RecuperacaoSenhaErrorCode.senhaInvalida,
      502 => RecuperacaoSenhaErrorCode.smtpFailure,
      _ => RecuperacaoSenhaErrorCode.unknown,
    };

    return RecuperacaoSenhaException(
      code: codeFromStatus,
      message: _friendlyMessage(codeFromStatus),
      statusCode: statusCode,
    );
  }

  static String _friendlyMessage(RecuperacaoSenhaErrorCode code) {
    return switch (code) {
      RecuperacaoSenhaErrorCode.emailNaoEncontrado =>
        'E-mail não encontrado. Verifique se digitou corretamente.',
      RecuperacaoSenhaErrorCode.codigoInvalido =>
        'Código inválido. Verifique os dígitos informados.',
      RecuperacaoSenhaErrorCode.codigoExpirado =>
        'Código expirado. Solicite um novo código.',
      RecuperacaoSenhaErrorCode.smtpFailure =>
        'Não foi possível enviar o e-mail agora. Tente novamente em instantes.',
      RecuperacaoSenhaErrorCode.senhaInvalida =>
        'A nova senha não atende aos requisitos mínimos.',
      RecuperacaoSenhaErrorCode.unknown =>
        'Não foi possível concluir a operação. Tente novamente.',
    };
  }

  @override
  String toString() =>
      'RecuperacaoSenhaException($code, $statusCode): $message';
}
