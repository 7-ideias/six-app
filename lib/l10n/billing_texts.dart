import 'package:flutter/material.dart';

import 'six_i18n.dart';

const billingTexts = <String, List<String>>{
  'plansIntro': [
    'Escolha o plano para o seu comércio.',
    'Choose the plan for your business.',
    'Elige el plan para tu comercio.',
  ],
  'popular': ['Popular', 'Popular', 'Popular'],
  "selectedPlan": [
    "Plano escolhido no site",
    "Plan selected on the website",
    "Plan elegido en el sitio",
  ],
  "selectedPlanUnavailable": [
    "O plano escolhido não está disponível nesta moeda. Confira os planos e valores antes de continuar.",
    "The selected plan is unavailable in this currency. Review plans and prices before continuing.",
    "El plan elegido no está disponible en esta moneda. Revisa planes y precios antes de continuar.",
  ],
  "priceChanged": [
    "O preço foi atualizado. Atualize os planos e confira o novo valor antes de assinar.",
    "The price has changed. Refresh plans and review the new price before subscribing.",
    "El precio cambió. Actualiza los planes y revisa el nuevo valor antes de suscribirte.",
  ],
  "plans": ["Planos e pagamento", "Plans and payment", "Planes y pago"],
  "month": ["Mensal", "Monthly", "Mensual"],
  "year": ["Anual", "Annual", "Anual"],
  "monthCycle": [
    "por mês, com renovação automática",
    "per month, automatically renewed",
    "por mes, con renovación automática",
  ],
  "yearCycle": [
    "por ano, em cobrança única com renovação automática",
    "per year, one payment with automatic renewal",
    "por año, un pago con renovación automática",
  ],
  "purchase": [
    "Assinar com Stripe",
    "Subscribe with Stripe",
    "Suscribirse con Stripe",
  ],
  "portal": [
    "Gerenciar pagamento e cancelamento",
    "Manage payment and cancellation",
    "Gestionar pago y cancelación",
  ],
  "sync": [
    "Já paguei / atualizar pagamento",
    "I have paid / refresh payment",
    "Ya pagué / actualizar pago",
  ],
  "paymentTerms": [
    "Ao confirmar na Stripe, a cobrança começa imediatamente, inclusive durante o teste. O valor e a periodicidade são os do plano selecionado. O anual dá acesso por 12 meses. Cancelar interrompe a próxima renovação; o acesso segue até o fim do período pago.",
    "Confirming in Stripe starts billing immediately, including during your trial. The selected plan determines the price and billing interval. Annual billing includes 12 months of access. Cancellation stops the next renewal; access continues until the paid period ends.",
    "Al confirmar en Stripe, el cobro empieza inmediatamente, incluso durante la prueba. El plan seleccionado define el precio y la periodicidad. El anual incluye 12 meses de acceso. La cancelación detiene la próxima renovación; el acceso continúa hasta finalizar el período pagado.",
  ],
  "paymentTest": [
    "Ambiente de testes · sem cobrança real",
    "Test mode · no real charges",
    "Modo de prueba · sin cobros reales",
  ],
  "paymentUnavailable": [
    "Pagamento indisponível no momento. Tente novamente mais tarde ou contate o suporte.",
    "Payment is currently unavailable. Try later or contact support.",
    "Pago no disponible. Intenta más tarde o contacta con soporte.",
  ],
  "purchaseConflict": [
    "Atualize o pagamento antes de continuar. Se já existe uma contratação aberta, retome o mesmo plano; para uma assinatura existente, use Gerenciar pagamento.",
    "Refresh payment before continuing. Resume the same plan if checkout is already open; use Manage payment for an existing subscription.",
    "Actualiza el pago antes de continuar. Retoma el mismo plan si ya hay una contratación abierta; usa Gestionar pago para una suscripción existente.",
  ],
  "ownerOnly": [
    "A contratação é feita pelo administrador deste comércio.",
    "Only this business administrator can subscribe.",
    "Solo el administrador de este comercio puede contratar.",
  ],
  "noPlans": [
    "Nenhum plano disponível para contratação. Contate o suporte.",
    "No plans available. Contact support.",
    "No hay planes disponibles. Contacta con soporte.",
  ],
  "cancelScheduled": [
    "Cancelamento agendado para o fim do período pago.",
    "Cancellation scheduled for the end of the paid period.",
    "Cancelación programada al finalizar el período pagado.",
  ],
  "selectCompany": [
    "Selecione um comércio para gerenciar sua assinatura.",
    "Select a business to manage its subscription.",
    "Selecciona un comercio para gestionar su suscripción.",
  ],
  "active": ["Assinatura ativa", "Active subscription", "Suscripción activa"],
  "past_due": ["Pagamento pendente", "Payment overdue", "Pago pendiente"],
  "unpaid": [
    "Pagamento não regularizado",
    "Unpaid subscription",
    "Suscripción impagada",
  ],
  "incomplete": [
    "Confirmação do pagamento pendente",
    "Payment confirmation pending",
    "Confirmación de pago pendiente",
  ],
  "incomplete_expired": [
    "Contratação expirada",
    "Checkout expired",
    "Contratación caducada",
  ],
  "canceled": [
    "Assinatura cancelada",
    "Subscription canceled",
    "Suscripción cancelada",
  ],
  "paused": [
    "Assinatura pausada",
    "Subscription paused",
    "Suscripción pausada",
  ],
  "trialing": [
    "Teste da assinatura",
    "Subscription trial",
    "Prueba de suscripción",
  ],

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
    'O acesso está bloqueado por falta de pagamento ou término do teste. Seus dados foram preservados. O administrador pode escolher um plano ou regularizar o pagamento abaixo.',
    'Access is blocked due to missing payment or an expired trial. Your data has been preserved. The administrator can choose a plan or resolve payment below.',
    'El acceso está bloqueado por falta de pago o fin de la prueba. Tus datos se conservaron. El administrador puede elegir un plan o regularizar el pago abajo.',
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
