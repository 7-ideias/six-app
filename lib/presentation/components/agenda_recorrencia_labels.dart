import 'package:flutter/widgets.dart';
import 'package:sixpos/l10n/six_i18n.dart';

String recorrenciaLabel(BuildContext context, String key) =>
    context.t('agenda.recurrence.$key', fallback: _labels[key] ?? key);

const _labels = <String, String>{
  'RECORRENCIA_FUTURAS_COM_PAGAMENTO':
      'Há pagamentos registrados neste lançamento ou nos próximos. Altere somente um vencimento ainda pendente.',
  'RECORRENCIA_OCORRENCIA_CONFIRMADA':
      'Este vencimento possui pagamento registrado. Use as ações de pagamento e estorno da agenda.',
  'RECORRENCIA_USAR_LIQUIDACAO':
      'Use a ação Pagar ou Receber na agenda para confirmar este vencimento.',
  'RECORRENCIA_CRIAR_PENDENTE':
      'Cadastre a repetição como pendente ou prevista.',
  'RECORRENCIA_FIM_INVALIDO':
      'A data final deve ser posterior ou igual ao primeiro vencimento.',
  'RECORRENCIA_INICIO_INVALIDO':
      'O início da repetição deve ser igual ao primeiro vencimento.',
  'RECORRENCIA_QUANTIDADE_INVALIDA': 'Informe de 1 a 10.000 ocorrências.',
  'RECORRENCIA_FREQUENCIA_INVALIDA': 'Selecione uma frequência válida.',
  'RECORRENCIA_PERIODO_MUITO_EXTENSO':
      'Consulte um período menor para esta repetição.',
  'RECORRENCIA_ESCOPO_INVALIDO': 'Selecione quais vencimentos deseja alterar.',
  'RECORRENCIA_NAO_ENCONTRADA':
      'A repetição não foi encontrada. Atualize a agenda.',
  'badge': 'Recorrente',
  'title': 'Repetição do lançamento',
  'repeat': 'Repetir lançamento',
  'hint':
      'Cada vencimento terá seu próprio pagamento. O primeiro usa a data de vencimento acima.',
  'frequency': 'Frequência',
  'end': 'Encerrar repetição',
  'count': 'Quantidade de ocorrências',
  'until': 'Data final',
  'scope': 'Aplicar alteração a',
  'ESTE': 'Somente este lançamento',
  'ESTE_E_PROXIMOS': 'Este e os próximos',
  'DIARIA': 'Diária',
  'SEMANAL': 'Semanal',
  'MENSAL': 'Mensal',
  'BIMESTRAL': 'Bimestral',
  'TRIMESTRAL': 'Trimestral',
  'SEMESTRAL': 'Semestral',
  'ANUAL': 'Anual',
  'SEM_FIM': 'Sem data final',
  'DATA': 'Até uma data',
  'QUANTIDADE': 'Após uma quantidade',
  'selectDate': 'Selecionar data',
  'quantityError': 'Informe de 1 a 10.000 ocorrências.',
  'endError':
      'A data final deve ser igual ou posterior ao primeiro vencimento.',
  'pendingError':
      'Crie a recorrência como pendente ou prevista. Depois, pague cada vencimento na agenda.',
  'singleHint':
      'A repetição da série será preservada. Para mudá-la, escolha este e os próximos.',
  'saveError':
      'Não foi possível salvar. Confira sua conexão e os dados do lançamento.',
  'delete': 'Excluir conforme o alcance selecionado',
  'deleteConfirm':
      'Excluir este lançamento e, se selecionado, cancelar os próximos? Pagamentos registrados serão preservados.',
};
