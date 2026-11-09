import 'package:flutter/material.dart';

import 'six_i18n.dart';

const billingTexts = <String, List<String>>{
  'title': [
    'Assinatura e acesso',
    'Subscription and access',
    'Suscripción y acceso',
  ],
  'blocked': [
    'Regularize o acesso ao comércio',
    'Restore business access',
    'Regulariza el acceso al comercio',
  ],
  'message': [
    'O acesso está bloqueado por falta de pagamento ou término do teste. Seus dados foram preservados. Nesta etapa, entre em contato com a administração para regularizar o acesso.',
    'Access is blocked due to missing payment or an expired trial. Your data has been preserved. At this stage, contact administration to restore access.',
    'El acceso está bloqueado por falta de pago o fin de la prueba. Tus datos se conservaron. En esta etapa, contacta con la administración para regularizar el acceso.',
  ],
  'adminMessage': [
    'A liberação vale para todos os usuários deste comércio até ser revogada. Ela não registra pagamento e não altera as franquias de armazenamento.',
    'Release applies to all users of this business until revoked. It does not record a payment or change storage allowances.',
    'La liberación se aplica a todos los usuarios de este comercio hasta su revocación. No registra un pago ni cambia las cuotas de almacenamiento.',
  ],
  'refresh': ['Verificar acesso', 'Check access', 'Verificar acceso'],
  'exit': ['Sair', 'Sign out', 'Salir'],
  'close': ['Fechar', 'Close', 'Cerrar'],
  'reason': ['Motivo da alteração', 'Reason for change', 'Motivo del cambio'],
  'release': [
    'Liberar até revogação',
    'Release until revoked',
    'Liberar hasta revocación',
  ],
  'revoke': [
    'Revogar liberação manual',
    'Revoke manual release',
    'Revocar liberación manual',
  ],
  'loading': ['Verificando acesso…', 'Checking access…', 'Verificando acceso…'],
  'error': [
    'Não foi possível concluir. Verifique sua conexão e tente novamente.',
    'Could not complete. Check your connection and try again.',
    'No se pudo completar. Revisa tu conexión e inténtalo de nuevo.',
  ],
  'conflict': [
    'O acesso foi alterado por outra operação. Atualize antes de tentar novamente.',
    'Access was changed by another operation. Refresh before trying again.',
    'Otra operación cambió el acceso. Actualiza antes de volver a intentarlo.',
  ],
  'forbidden': [
    'Você não tem permissão para esta ação.',
    'You do not have permission for this action.',
    'No tienes permiso para esta acción.',
  ],
  'session': [
    'Sua sessão expirou. Entre novamente.',
    'Your session expired. Sign in again.',
    'Tu sesión expiró. Inicia sesión nuevamente.',
  ],
  'reasonError': [
    'Informe um motivo entre 3 e 500 caracteres.',
    'Enter a reason between 3 and 500 characters.',
    'Indica un motivo de entre 3 y 500 caracteres.',
  ],
  'PAYMENT_REQUIRED': [
    'Bloqueado: pagamento necessário',
    'Blocked: payment required',
    'Bloqueado: pago necesario',
  ],
  'MANUAL_RELEASE': [
    'Liberado pelo SUPER',
    'Released by SUPER',
    'Liberado por SUPER',
  ],
  'TRIAL': ['Teste em andamento', 'Trial in progress', 'Prueba en curso'],
  'PAID': ['Pagamento vigente', 'Payment current', 'Pago vigente'],
  'SUPER': ['Acesso SUPER', 'SUPER access', 'Acceso SUPER'],
  'until': ['Válido até', 'Valid until', 'Válido hasta'],
};
String billingText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  final labels = billingTexts[key] ?? billingTexts['error']!;
  return context.t(
    'billing.$key',
    fallback:
        labels[language == 'en'
            ? 1
            : language == 'es'
            ? 2
            : 0],
  );
}
