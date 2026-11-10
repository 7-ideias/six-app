import 'package:flutter/material.dart';
import 'six_i18n.dart';

const adminPasswordResetTexts = <String, List<String>>{
  "action": ["Resetar senha padrão", "Reset default password", "Restablecer contraseña predeterminada"],
  "title": ["Resetar senha para 00000000?", "Reset password to 00000000?", "¿Restablecer la contraseña a 00000000?"],
  "message": ["A senha atual será substituída imediatamente por 00000000, sem confirmação por e-mail. Oriente o usuário a alterá-la após entrar.", "The current password will immediately become 00000000, without email confirmation. Ask the user to change it after signing in.", "La contraseña actual se reemplazará inmediatamente por 00000000, sin confirmación por correo. Indica al usuario que la cambie después de iniciar sesión."],
  "confirm": ["Confirmar reset", "Confirm reset", "Confirmar restablecimiento"],
  "cancel": ["Cancelar", "Cancel", "Cancelar"],
  "processing": ["Redefinindo senha…", "Resetting password…", "Restableciendo contraseña…"],
  "success": ["Senha redefinida para 00000000.", "Password reset to 00000000.", "Contraseña restablecida a 00000000."],
  "error": ["Não foi possível confirmar o reset. Verifique a conexão e tente novamente.", "Could not confirm the reset. Check your connection and try again.", "No se pudo confirmar el restablecimiento. Revisa la conexión e inténtalo de nuevo."],
  "forbidden": ["Ação exclusiva para SUPER. Verifique sua sessão.", "SUPER-only action. Check your session.", "Acción exclusiva para SUPER. Verifica tu sesión."],
  "notFound": ["Usuário não encontrado. Atualize a lista.", "User not found. Refresh the list.", "Usuario no encontrado. Actualiza la lista."],
  "policy": ["O provedor de acesso rejeitou a senha padrão. Verifique a política de senhas.", "The identity provider rejected the default password. Check its password policy.", "El proveedor de acceso rechazó la contraseña predeterminada. Revisa la política de contraseñas."],
  "retry": ["Tentar novamente", "Try again", "Intentar de nuevo"],
};

String adminPasswordResetText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  final labels = adminPasswordResetTexts[key] ?? adminPasswordResetTexts['error']!;
  return context.t('usuariosSixo.defaultPasswordReset.$key',
    fallback: labels[language == 'en' ? 1 : language == 'es' ? 2 : 0]);
}
