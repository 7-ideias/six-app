import '../../lib/data/models/recebimento_forma_input.dart';
import '../../lib/data/models/venda_nao_liquidada_models.dart';
// Executável também com Dart puro, sem inicializar o Flutter.
import '../../lib/data/models/agenda_financeira_recorrencia.dart';
import '../../lib/data/models/agenda_financeira_lancamento_model.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final date = DateTime(2026, 9, 10);
  final legacy = AgendaFinanceiraRecorrencia.fromJson({});
  check(!legacy.ativa, 'Dados antigos incompletos devem continuar exibíveis');
  final recurrence = AgendaFinanceiraRecorrencia()..ativa = true;
  final infinite = recurrence.toJson(date);
  check(
    infinite['quantidadeParcelas'] == null &&
        infinite['recorrenciaFim'] == null,
    'Sem fim não pode virar uma única parcela',
  );
  recurrence.termino = 'DATA';
  recurrence.fim = DateTime(2026, 9, 9);
  check(
    recurrence.validar(date) == 'endError',
    'Rejeitar término antes do início',
  );
  recurrence.fim = date;
  check(
    recurrence.validar(date) == null,
    'Permitir uma única ocorrência por data',
  );
  recurrence.termino = 'QUANTIDADE';
  recurrence.quantidade = 0;
  check(
    recurrence.validar(date) == 'quantityError',
    'Rejeitar zero ocorrências',
  );
  recurrence.quantidade = 12;
  final request = LancamentoAgendaFinanceiraRequest(
    uuidOperacaoApp: 'test',
    descricao: 'Aluguel',
    tipoOperacao: 'PAGAR',
    statusOperacao: 'Vence hoje',
    dataOperacao: date,
    dataVencimento: date,
    dataCompetencia: date,
    statusQuitada: false,
    operacaoFinalizadaProntaCaixa: false,
    clientePediuParaApagar: false,
    origem: 'DESPESA_MANUAL',
    formaPagamento: 'tipo1',
    empresa: 'Teste',
    categoria: 'Aluguel',
    idColaborador: 'test',
    nomeColaborador: 'Teste',
    valorTotalProdutos: 0,
    valorTotalServicos: 0,
    valorTotalOperacao: 2000,
    configuracaoRecorrencia: recurrence,
    payloadOriginalJson: {'agendaFinanceira': {}, 'contato': {}},
  );
  final json = request.toJson();
  check(
    json['statusOperacao'] == 'PENDENTE',
    'Vence hoje deve ser enviado como PENDENTE',
  );
  check(
    json['payloadOriginalJson']['agendaFinanceira']['statusFiltro'] ==
        'PENDENTE',
    'Status interno e externo devem concordar',
  );
  for (final indicador in ['Vence hoje', 'VENCE_HOJE', 'Vencido', 'VENCIDA']) {
    check(
      LancamentoAgendaFinanceiraRequest.normalizarStatus(indicador) ==
          'PENDENTE',
      'Indicador de data não pode virar status financeiro',
    );
  }
  for (final estado in [
    'PREVISTO',
    'PENDENTE',
    'PAGO',
    'RECEBIDO',
    'PARCIAL',
    'CANCELADO',
  ]) {
    check(
      LancamentoAgendaFinanceiraRequest.normalizarStatus(estado) == estado,
      'Não reabrir nem alterar estado financeiro existente',
    );
  }
  final nested = json['payloadOriginalJson']['recorrencia'];
  check(
    json['recorrente'] == true && nested['recorrente'] == true,
    'Contrato externo e interno devem concordar',
  );
  check(
    json['quantidadeParcelas'] == 12 && nested['quantidadeParcelas'] == 12,
    'Quantidade deve sobreviver à serialização',
  );
  check(
    json['frequenciaRecorrencia'] == 'MENSAL' &&
        nested['frequencia'] == 'MENSAL',
    'Enviar código técnico da frequência',
  );
  check(
    request.toAgendaItem()['recorrente'] == true,
    'Resultado local mantém recorrência',
  );
  final existing = AgendaFinanceiraRecorrencia.fromJson({
    'recorrente': true,
    'serieRecorrenciaId': 'serie',
    'numeroOcorrencia': 4,
    'frequenciaRecorrencia': 'MENSAL',
    'quantidadeParcelas': 12,
    'recorrenciaInicio': '2026-01-10',
  });
  check(
    !existing.permiteConfigurar && existing.escopo == 'ESTE',
    'Edição padrão deve preservar série',
  );
  check(existing.quantidade == 9, 'Este e próximos usa a quantidade restante');
  existing.escopo = 'ESTE_E_PROXIMOS';
  check(
    existing.toJson(date)['recorrenciaInicio'] == date.toIso8601String(),
    'Nova série inicia no vencimento selecionado',
  );
  recurrence.ativa = false;
  check(
    request.toJson()['quantidadeParcelas'] == 1 &&
        request.toJson()['recorrente'] == false,
    'Desativar repetição gera lançamento único',
  );
  for (final total in [true, false]) {
    for (final multiplas in [true, false]) {
      final formas = [
        RecebimentoFormaInput(
          codigo: 'tipo1',
          valor: multiplas ? 20 : 50,
          descricao: 'Dinheiro',
        ),
        if (multiplas)
          RecebimentoFormaInput(codigo: 'tipo2', valor: 30, descricao: 'Pix'),
      ];
      final Map<String, dynamic> payload =
          total
              ? AgendaFinanceiraLiquidacaoRequest(
                tipoLiquidacao: 'TOTAL',
                dataLiquidacao: date,
                valorLiquidado: 50,
                formaPagamentoRealizada: 'tipo1',
                recebimentos: formas,
                observacoes: 'Teste',
                idSessaoCaixa: 'sessao',
              ).toJson()
              : AgendaFinanceiraParcialRequest(
                tipoLiquidacao: 'PARCIAL',
                dataLiquidacao: date,
                valorLiquidado: 50,
                formaPagamentoRealizada: 'tipo1',
                recebimentos: formas,
                observacoes: 'Teste',
                idSessaoCaixa: 'sessao',
              ).toJson();
      final linhas = payload['recebimentos'] as List;
      check(
        linhas.length == formas.length &&
            linhas.fold<double>(
                  0,
                  (sum, row) => sum + (row['valor'] as num).toDouble(),
                ) ==
                50 &&
            linhas.last['codigo'] == formas.last.codigo &&
            payload['tipoLiquidacao'] == (total ? 'TOTAL' : 'PARCIAL') &&
            payload['observacoes'] == 'Teste' &&
            payload['idSessaoCaixa'] == 'sessao',
        'Preservar formas, valores, modo e contexto em uma única requisição',
      );
    }
  }
  final detalhe = AgendaFinanceiraLancamentoDetalhe.fromJson({
    'idLancamento': 'lancamento-1',
    'codigoOperacao': 'VEN-123',
    'descricao': 'Venda',
  });
  check(
    detalhe.codigoOperacao == 'VEN-123' &&
        detalhe.toJson()['codigoOperacao'] == 'VEN-123' &&
        detalhe.toJson()['descricao'] == 'Venda',
    'Mapear código da operação sem perder os demais campos do detalhe',
  );
  final detalheManual = AgendaFinanceiraLancamentoDetalhe.fromJson({
    'idLancamento': 'manual-1',
    'codigoOperacao': null,
  });
  check(
    detalheManual.codigoOperacao == null &&
        detalheManual.toJson().containsKey('codigoOperacao'),
    'Preservar codigoOperacao nulo em lançamentos manuais',
  );
  final vendaAberta = VendaNaoLiquidadaModel.fromJson({
    'idRecebimento': 'recebimento-1',
    'idOperacaoFinanceira': 'financeiro-1',
    'idOperacaoApp': 'operacao-1',
    'codigoOperacao': 'VEN-789',
  });
  check(
    vendaAberta.codigoOperacao == 'VEN-789',
    'Mapear codigoOperacao de venda não liquidada',
  );
  print(
    '32 verificações de recorrência, status, liquidação e detalhe concluídas.',
  );
}
