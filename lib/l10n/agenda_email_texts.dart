import 'package:flutter/widgets.dart';
import 'six_i18n.dart';

String agendaEmailText(BuildContext context, String key) => context.t(
  'usuariosSixo.agendaEmail.$key',
  fallback: _fallback[key] ?? _fallback['error']!,
);

const _fallback = <String, String>{
  'action': 'Reenviar resumo financeiro',
  'title': 'Reenviar Agenda Financeira?',
  'description':
      'Selecione o comércio. O resumo do mês será recalculado e enviado somente ao e-mail cadastrado deste proprietário, mesmo que já tenha recebido hoje.',
  'empty': 'Este usuário não possui comércio elegível com e-mail cadastrado.',
  'loading': 'Consultando comércios elegíveis…',
  'sending': 'Enviando resumo financeiro…',
  'confirm': 'Confirmar envio',
  'cancel': 'Cancelar',
  'close': 'Fechar',
  'retry': 'Tentar novamente',
  'success':
      'Resumo aceito pelo provedor de e-mail. A entrega pode levar alguns instantes.',
  'error':
      'Não foi possível confirmar a operação. Tente novamente nesta janela para consultar a mesma tentativa sem duplicar o envio.',
  'failed':
      'Não foi possível preparar o resumo. Nenhum e-mail foi enviado nesta tentativa.',
  'uncertain':
      'O resultado do envio é incerto. Confira o provedor antes de solicitar outro reenvio.',
  'processingRecorded':
      'Esta solicitação já está em processamento. Não inicie outro envio; consulte o provedor.',
  'cancelled':
      'Envio cancelado porque o destinatário ou a configuração mudou. Atualize os dados antes de tentar novamente.',
  'disabled': 'O envio da Agenda Financeira está desabilitado no servidor.',
  'ineligible':
      'O usuário não é um proprietário elegível deste comércio ou não possui e-mail válido.',
  'forbidden': 'Ação disponível somente para SUPER com sessão válida.',
  'cooldown':
      'Já existe um envio em andamento ou recente. Aguarde pelo menos um minuto e tente novamente.',
};
