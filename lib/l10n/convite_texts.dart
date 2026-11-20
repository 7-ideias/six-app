import 'package:flutter/widgets.dart';
import 'six_i18n.dart';

String conviteText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return context.t(
    'colaborador.convite.$key',
    fallback: (_labels[language] ?? _labels['pt']!)[key],
  );
}

const _labels = <String, Map<String, String>>{
  "pt": {
    "send": "Enviar código",
    "confirm": "Confirmar código",
    "code": "Código de 6 dígitos",
    "resend": "Enviar outro código",
    "password": "Senha (8 a 64 caracteres)",
    "repeat": "Confirme a senha",
    "show": "Mostrar senhas",
    "save": "Criar senha",
    "accept": "Aceitar convite",
    "signIn": "Entrar com a conta convidada",
    "done":
        "Senha criada. Entre com seu e-mail e a senha que acabou de escolher.",
    "login": "Ir para o login",
    "open": "Abrir no aplicativo",
    "title": "Convite de colaborador",
    "invalid":
        "Código incorreto ou expirado. Confira os 6 dígitos ou solicite outro código.",
    "verifyAgain": "Confirme seu e-mail novamente para criar a senha.",
    "length": "Escolha uma senha de 8 a 64 caracteres.",
    "mismatch": "As senhas precisam ser iguais.",
    "wait": "Aguarde um minuto antes de pedir outro código.",
    "wrongAccount": "Entre com a conta que recebeu este convite.",
    "unavailable": "Não foi possível concluir. Tente novamente.",
    "closed": "Convite indisponível. Se já aceitou, entre com sua conta.",
    "retry": "Tentar novamente",
    "mail": "E-mail do convite",
  },
  "en": {
    "send": "Send code",
    "confirm": "Verify code",
    "code": "6-digit code",
    "resend": "Send another code",
    "password": "Password (8 to 64 characters)",
    "repeat": "Confirm password",
    "show": "Show passwords",
    "save": "Create password",
    "accept": "Accept invitation",
    "signIn": "Sign in with the invited account",
    "done":
        "Password created. Sign in with your email and the password you just chose.",
    "login": "Go to sign in",
    "open": "Open in the app",
    "title": "Team invitation",
    "invalid":
        "Incorrect or expired code. Check all 6 digits or request a new code.",
    "verifyAgain": "Verify your email again to create a password.",
    "length": "Choose a password with 8 to 64 characters.",
    "mismatch": "The passwords must match.",
    "wait": "Wait one minute before requesting another code.",
    "wrongAccount": "Sign in with the account that received this invitation.",
    "unavailable": "Could not complete this step. Please try again.",
    "closed": "Invitation unavailable. If you already accepted it, sign in.",
    "retry": "Try again",
    "mail": "Invited email",
  },
  "es": {
    "send": "Enviar código",
    "confirm": "Confirmar código",
    "code": "Código de 6 dígitos",
    "resend": "Enviar otro código",
    "password": "Contraseña (8 a 64 caracteres)",
    "repeat": "Confirma la contraseña",
    "show": "Mostrar contraseñas",
    "save": "Crear contraseña",
    "accept": "Aceptar invitación",
    "signIn": "Entrar con la cuenta invitada",
    "done":
        "Contraseña creada. Entra con tu correo y la contraseña que acabas de elegir.",
    "login": "Ir al inicio de sesión",
    "open": "Abrir en la aplicación",
    "title": "Invitación de colaborador",
    "invalid":
        "Código incorrecto o caducado. Revisa los 6 dígitos o solicita otro código.",
    "verifyAgain": "Confirma tu correo de nuevo para crear la contraseña.",
    "length": "Elige una contraseña de 8 a 64 caracteres.",
    "mismatch": "Las contraseñas deben coincidir.",
    "wait": "Espera un minuto antes de solicitar otro código.",
    "wrongAccount": "Entra con la cuenta que recibió esta invitación.",
    "unavailable": "No se pudo completar este paso. Inténtalo de nuevo.",
    "closed": "Invitación no disponible. Si ya la aceptaste, inicia sesión.",
    "retry": "Volver a intentar",
    "mail": "Correo de la invitación",
  },
};
