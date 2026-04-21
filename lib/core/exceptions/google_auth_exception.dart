enum GoogleAuthErrorCode {
  cancelledByUser,
  missingIdToken,
  backendRejected,
  network,
  unknown,
}

class GoogleAuthException implements Exception {
  final GoogleAuthErrorCode code;
  final String message;
  final int? statusCode;

  const GoogleAuthException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory GoogleAuthException.fromResponse({
    required int statusCode,
    required String body,
  }) {
    return GoogleAuthException(
      code: GoogleAuthErrorCode.backendRejected,
      message: _friendlyMessage(GoogleAuthErrorCode.backendRejected),
      statusCode: statusCode,
    );
  }

  static String _friendlyMessage(GoogleAuthErrorCode code) {
    return switch (code) {
      GoogleAuthErrorCode.cancelledByUser =>
        'Login com Google cancelado.',
      GoogleAuthErrorCode.missingIdToken =>
        'Não foi possível obter o token do Google. Tente novamente.',
      GoogleAuthErrorCode.backendRejected =>
        'Não foi possível autenticar com Google. Tente novamente.',
      GoogleAuthErrorCode.network =>
        'Falha de conexão. Verifique sua internet e tente novamente.',
      GoogleAuthErrorCode.unknown =>
        'Não foi possível concluir o login com Google.',
    };
  }

  factory GoogleAuthException.cancelled() => const GoogleAuthException(
        code: GoogleAuthErrorCode.cancelledByUser,
        message: 'Login com Google cancelado.',
      );

  factory GoogleAuthException.missingIdToken() => const GoogleAuthException(
        code: GoogleAuthErrorCode.missingIdToken,
        message: 'Não foi possível obter o token do Google. Tente novamente.',
      );

  factory GoogleAuthException.network() => const GoogleAuthException(
        code: GoogleAuthErrorCode.network,
        message: 'Falha de conexão. Verifique sua internet e tente novamente.',
      );

  factory GoogleAuthException.unknown() => const GoogleAuthException(
        code: GoogleAuthErrorCode.unknown,
        message: 'Não foi possível concluir o login com Google.',
      );

  @override
  String toString() => 'GoogleAuthException($code, $statusCode): $message';
}
