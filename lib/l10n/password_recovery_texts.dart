import 'package:flutter/widgets.dart';
import '../core/exceptions/recuperacao_senha_exception.dart';
import 'six_i18n.dart';

String passwordRecoveryText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return context.t(
    'passwordRecovery.$key',
    fallback: (_fallback[language] ?? _fallback['pt']!)[key] ?? '',
  );
}

String passwordRecoveryError(
  BuildContext context,
  RecuperacaoSenhaException error,
) {
  final key = switch (error.code) {
    RecuperacaoSenhaErrorCode.rateLimited => 'limit',
    RecuperacaoSenhaErrorCode.unavailable => 'unavailable',
    RecuperacaoSenhaErrorCode.sessionsPending => 'sessions',
    RecuperacaoSenhaErrorCode.senhaInvalida => 'password',
    RecuperacaoSenhaErrorCode.codigoInvalido ||
    RecuperacaoSenhaErrorCode.codigoExpirado => 'invalid',
    _ => 'restart',
  };
  return passwordRecoveryText(context, key);
}

const _fallback = <String, Map<String, String>>{
  "pt": {
    "change": "Alterar senha",
    "proof":
        "Confirme o código enviado ao e-mail cadastrado para escolher uma nova senha.",
    "neutral":
        "Se este e-mail estiver cadastrado, enviaremos um código. Confira também o spam.",
    "length": "A senha deve ter entre 8 e 64 caracteres.",
    "limit":
        "Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.",
    "unavailable":
        "Recuperação indisponível agora. Tente novamente mais tarde.",
    "restart":
        "Não foi possível confirmar a alteração. Solicite um novo código para tentar novamente.",
    "sessions":
        "Sua senha foi alterada, mas não foi possível encerrar todas as sessões. Entre novamente e contate o suporte.",
    "invalid":
        "Código inválido, expirado ou já utilizado. Solicite um novo código.",
    "password": "A senha não atende à política de segurança da conta.",
  },
  "en": {
    "change": "Change password",
    "proof":
        "Confirm the code sent to your registered email to choose a new password.",
    "neutral":
        "If this email is registered, we will send a code. Check your spam folder too.",
    "length": "The password must contain 8 to 64 characters.",
    "limit": "Too many attempts. Wait a few minutes before trying again.",
    "unavailable":
        "Password recovery is currently unavailable. Try again later.",
    "restart":
        "The password change could not be confirmed. Request a new code to try again.",
    "sessions":
        "Your password was changed, but some sessions could not be closed. Sign in again and contact support.",
    "invalid": "Invalid, expired or already used code. Request a new code.",
    "password": "The password does not meet the account security policy.",
  },
  "es": {
    "change": "Cambiar contraseña",
    "proof":
        "Confirma el código enviado a tu correo registrado para elegir una nueva contraseña.",
    "neutral":
        "Si este correo está registrado, enviaremos un código. Revisa también el spam.",
    "length": "La contraseña debe tener entre 8 y 64 caracteres.",
    "limit":
        "Demasiados intentos. Espera unos minutos antes de volver a intentar.",
    "unavailable":
        "La recuperación no está disponible ahora. Intenta más tarde.",
    "restart":
        "No se pudo confirmar el cambio. Solicita un nuevo código para volver a intentar.",
    "sessions":
        "Tu contraseña cambió, pero no se pudieron cerrar todas las sesiones. Inicia sesión otra vez y contacta al soporte.",
    "invalid": "Código inválido, caducado o ya utilizado. Solicita uno nuevo.",
    "password":
        "La contraseña no cumple la política de seguridad de la cuenta.",
  },
};
