import 'package:flutter/widgets.dart';

String campaignText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  final values = _texts[key];
  return values == null
      ? key
      : values[language == 'en'
          ? 1
          : language == 'es'
          ? 2
          : 0];
}

const _texts = <String, List<String>>{
  'acceptedCount': ['Aceitos', 'Accepted', 'Aceptados'],
  'failedCount': ['Falhas', 'Failures', 'Errores'],
  'authorId': ['ID do autor', 'Author ID', 'ID del autor'],
  'language_pt': ['Português', 'Portuguese', 'Portugués'],
  'language_en': ['Inglês', 'English', 'Inglés'],
  'language_es': ['Espanhol', 'Spanish', 'Español'],
  'reviewStage': ['Revisão', 'Review', 'Revisión'],
  'journeyIntro': [
    'Prepare sua campanha em três etapas.',
    'Prepare your campaign in three steps.',
    'Prepara tu campaña en tres pasos.',
  ],
  'resume': ['Continuar campanha', 'Resume campaign', 'Continuar campaña'],
  'continueMessage': [
    'Continuar para mensagem',
    'Continue to message',
    'Continuar al mensaje',
  ],
  'backAudience': [
    'Voltar aos destinatários',
    'Back to recipients',
    'Volver a destinatarios',
  ],
  'audienceRequired': [
    'Selecione ao menos um destinatário para continuar.',
    'Select at least one recipient to continue.',
    'Selecciona al menos un destinatario para continuar.',
  ],
  'audienceStep': [
    'Escolha quem vai receber a campanha.',
    'Choose who will receive the campaign.',
    'Elige quién recibirá la campaña.',
  ],
  'messageStep': [
    'Dê um nome à campanha e escreva a mensagem em cada idioma.',
    'Name your campaign and write the message in each language.',
    'Nombra tu campaña y escribe el mensaje en cada idioma.',
  ],
  'reviewStep': [
    'Confira as mensagens e os destinatários antes de confirmar o envio.',
    'Check messages and recipients before confirming the send.',
    'Revisa los mensajes y destinatarios antes de confirmar el envío.',
  ],
  'title': ['Campanhas de push', 'Push campaigns', 'Campañas push'],
  'intro': [
    'Envie mensagens aos ADMINs no idioma de cada empresa.',
    'Send messages to ADMINs in each company’s language.',
    'Envía mensajes a los ADMINs en el idioma de cada empresa.',
  ],
  'new': ['Nova campanha', 'New campaign', 'Nueva campaña'],
  'audience': ['Destinatários', 'Recipients', 'Destinatarios'],
  'search': [
    'Buscar nome, e-mail ou empresa',
    'Search name, email or company',
    'Buscar nombre, correo o empresa',
  ],
  'all': [
    'Selecionar todos os filtrados',
    'Select all filtered recipients',
    'Seleccionar todos los filtrados',
  ],
  'clear': ['Limpar seleção', 'Clear selection', 'Borrar selección'],
  'allLanguages': ['Todos os idiomas', 'All languages', 'Todos los idiomas'],
  'allStatuses': [
    'Todas as assinaturas',
    'All subscriptions',
    'Todas las suscripciones',
  ],
  'companyRule': [
    'Selecione uma empresa por ADMIN. Se houver mais de uma, escolha explicitamente o contexto do envio.',
    'Select one company per ADMIN. If there is more than one, explicitly choose the sending context.',
    'Selecciona una empresa por ADMIN. Si hay más de una, elige el contexto del envío.',
  ],
  'duplicate': [
    'Há ADMINs com várias empresas. Selecione uma empresa para cada um antes de revisar.',
    'Some ADMINs have several companies. Select one company for each before reviewing.',
    'Hay ADMINs con varias empresas. Selecciona una para cada uno antes de revisar.',
  ],
  'name': [
    'Nome interno da campanha',
    'Internal campaign name',
    'Nombre interno de campaña',
  ],
  'messageTitle': [
    'Título da notificação',
    'Notification title',
    'Título de notificación',
  ],
  'body': ['Mensagem', 'Message', 'Mensaje'],
  'previewTitle': [
    'O título aparecerá aqui',
    'The title will appear here',
    'El título aparecerá aquí',
  ],
  'previewBody': [
    'Escreva a mensagem para visualizar a notificação.',
    'Write a message to preview the notification.',
    'Escribe el mensaje para ver la notificación.',
  ],
  'preview': ['Prévia da notificação', 'Notification preview', 'Vista previa'],
  'review': ['Revisar envio', 'Review sending', 'Revisar envío'],
  'send': ['Confirmar envio', 'Confirm sending', 'Confirmar envío'],
  'test': [
    'Enviar teste para este ADMIN',
    'Send test to this ADMIN',
    'Enviar prueba a este ADMIN',
  ],
  'testHelp': [
    'Selecione um único ADMIN para enviar um teste.',
    'Select a single ADMIN to send a test.',
    'Selecciona un único ADMIN para enviar una prueba.',
  ],
  'back': ['Voltar à edição', 'Back to editing', 'Volver a editar'],
  'destination': [
    'Ao tocar: assinatura e planos da empresa selecionada.',
    'On tap: subscription and plans for the selected company.',
    'Al tocar: suscripción y planes de la empresa seleccionada.',
  ],
  'required': [
    'Preencha o nome, selecione os ADMINs e escreva título e mensagem em todos os idiomas necessários.',
    'Enter the name, select ADMINs and write a title and message in every required language.',
    'Escribe el nombre, selecciona ADMINs y completa título y mensaje en todos los idiomas necesarios.',
  ],
  'selected': ['Selecionados', 'Selected', 'Seleccionados'],
  'noDevice': [
    'Sem dispositivo disponível',
    'No device available',
    'Sin dispositivo disponible',
  ],
  'devices': ['Dispositivos', 'Devices', 'Dispositivos'],
  'queued': [
    'Campanha registrada. Acompanhe o processamento no histórico.',
    'Campaign recorded. Follow processing in history.',
    'Campaña registrada. Sigue el procesamiento en el historial.',
  ],
  'requestError': [
    'Não foi possível concluir. Confira público, idiomas e conexão e tente novamente. Se o envio ficou incerto, repita a confirmação: a mesma campanha não será duplicada.',
    'Unable to complete. Check audience, languages and connection and try again. If sending is uncertain, repeat confirmation: the same campaign will not be duplicated.',
    'No se pudo completar. Revisa destinatarios, idiomas y conexión. Si el envío es incierto, repite la confirmación: la campaña no se duplicará.',
  ],
  'access': [
    'Acesso exclusivo do SUPER. Entre com uma conta autorizada.',
    'SUPER access only. Sign in with an authorized account.',
    'Acceso exclusivo del SUPER. Inicia sesión con una cuenta autorizada.',
  ],
  'history': ['Histórico de envios', 'Sending history', 'Historial de envíos'],
  'empty': [
    'Nenhum registro encontrado.',
    'No records found.',
    'No se encontraron registros.',
  ],
  'refresh': ['Atualizar', 'Refresh', 'Actualizar'],
  'next': ['Próxima página', 'Next page', 'Página siguiente'],
  'previous': ['Página anterior', 'Previous page', 'Página anterior'],
  'acceptedNote': [
    'Aceito pelo provedor não comprova entrega ou leitura. Envios interrompidos não são repetidos automaticamente.',
    'Provider acceptance does not prove delivery or reading. Interrupted sends are not automatically repeated.',
    'La aceptación del proveedor no confirma entrega ni lectura. Los envíos interrumpidos no se repiten automáticamente.',
  ],
  'PENDENTE': ['Na fila', 'Queued', 'En cola'],
  'PROCESSANDO': ['Processando', 'Processing', 'Procesando'],
  'CONCLUIDA': [
    'Processamento concluído',
    'Processing completed',
    'Procesamiento finalizado',
  ],
  'INTERROMPIDA': [
    'Interrompida — revisar resultados',
    'Interrupted — review results',
    'Interrumpida — revisar resultados',
  ],
  'ACEITO': [
    'Aceito pelo provedor',
    'Accepted by provider',
    'Aceptado por el proveedor',
  ],
  'FALHA': ['Falha', 'Failed', 'Error'],
  'PARCIAL': ['Aceitação parcial', 'Partially accepted', 'Aceptación parcial'],
  'SEM_DISPOSITIVO': ['Sem dispositivo', 'No device', 'Sin dispositivo'],
  'IGNORADO': [
    'ADMIN não elegível',
    'ADMIN no longer eligible',
    'ADMIN no elegible',
  ],
  'TRIAL': ['Em teste', 'Trial', 'En prueba'],
  'PAID': ['Assinatura ativa', 'Paid subscription', 'Suscripción activa'],
  'PAYMENT_REQUIRED': [
    'Pagamento necessário',
    'Payment required',
    'Pago necesario',
  ],
  'MANUAL_RELEASE': ['Acesso liberado', 'Access granted', 'Acceso habilitado'],
  'testLabel': ['Teste', 'Test', 'Prueba'],
};
