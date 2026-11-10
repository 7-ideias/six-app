import 'agenda_financeira_lancamento_model.dart';

/// Patch da classificação: null preserva; texto vazio limpa.
class AgendaClassificacaoBaixa {
  const AgendaClassificacaoBaixa({
    this.categoria,
    this.alterarCentroCusto = false,
    this.centroCustoId,
    this.nomeContato,
    this.observacoesLancamento,
  });
  final String? categoria, centroCustoId, nomeContato, observacoesLancamento;
  final bool alterarCentroCusto;
  Map<String, dynamic> toJson() => {
    if (categoria != null) 'categoria': categoria,
    if (alterarCentroCusto) ...{
      'alterarCentroCusto': true,
      'centroCustoId': centroCustoId,
    },
    if (nomeContato != null) 'nomeContato': nomeContato,
    if (observacoesLancamento != null)
      'observacoesLancamento': observacoesLancamento,
  };
}

class AgendaBaixaDados {
  const AgendaBaixaDados({
    this.categoria = '',
    this.centroCustoId,
    this.centroCustoNome = '',
    this.contato = '',
    this.contatoEditavel = false,
    this.observacoes = '',
    this.contaPrevistaId,
    this.valorOriginal = 0,
    this.valorAberto = 0,
    this.vencimento,
    this.competencia,
    this.dataInicial,
  });
  final String categoria, centroCustoNome, contato, observacoes;
  final String? centroCustoId, contaPrevistaId;
  final bool contatoEditavel;
  final double valorOriginal, valorAberto;
  final DateTime? vencimento, competencia, dataInicial;
  factory AgendaBaixaDados.fromDetalhe(
    Map<String, dynamic> detalhe,
    Map<String, dynamic> item,
  ) {
    final d = AgendaFinanceiraLancamentoDetalhe.fromJson(
      detalhe,
    ).paraEdicao(item);
    final origem = detalhe['origem'];
    final tipoOrigem = origem is Map
        ? origem['tipo']?.toString()
        : origem?.toString();
    double numero(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    DateTime? data(dynamic v) => DateTime.tryParse(v?.toString() ?? '');
    return AgendaBaixaDados(
      categoria: d['categoria']?.toString() ?? '',
      centroCustoId: d['centroCustoId']?.toString(),
      centroCustoNome: d['centroDeCusto']?.toString() ?? '',
      contato: d['contato']?.toString() ?? '',
      contatoEditavel:
          (d['idContato']?.toString() ?? '').isEmpty &&
          ['DESPESA_MANUAL', 'RECEITA_MANUAL'].contains(tipoOrigem),
      observacoes: d['observacoes']?.toString() ?? '',
      contaPrevistaId: d['contaFinanceiraId']?.toString(),
      valorOriginal: numero(d['valorOriginal']),
      valorAberto: numero(d['valorRestante']),
      vencimento: data(d['vencimento']),
      competencia: data(d['dataCompetencia']),
      dataInicial: data(item['dataLiquidacaoSolicitada']),
    );
  }
}
