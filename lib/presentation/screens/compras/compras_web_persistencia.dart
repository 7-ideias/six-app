part of 'compras_web_page.dart';

/// Mapeamento de compatibilidade entre o prototipo visual e o contrato REST.
_CompraDemo _compraDaApi(Map<String, dynamic> j) {
  double n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  String t(String key) => j[key]?.toString() ?? '';
  DateTime d(String key, [DateTime? fallback]) =>
      DateTime.tryParse(t(key)) ?? fallback ?? DateTime.now();
  final status = switch (t('status').toUpperCase()) {
    'CONFIRMADA' => _CompraDemoStatus.confirmada,
    'CANCELADA' => _CompraDemoStatus.cancelada,
    _ => _CompraDemoStatus.rascunho,
  };
  final raw = j['itens'] as List? ?? [];
  return _CompraDemo(
    id: t('id'),
    numero: (j['numero'] as num?)?.toInt(),
    versao: (j['versao'] as num?)?.toInt(),
    status: status,
    criadaEm: d('criadaEm'),
    atualizadaEm: d('atualizadaEm'),
    confirmadaEm: DateTime.tryParse(t('confirmadaEm')),
    canceladaEm: DateTime.tryParse(t('canceladaEm')),
    motivoCancelamento: t('motivoCancelamento'),
    integracaoFinanceiraStatus: j['integracaoFinanceiraStatus']?.toString(),
    statusRecebimento: j['statusRecebimento']?.toString(),
    recebimentos: (j['recebimentos'] as List? ?? [])
        .whereType<Map<String,dynamic>>().toList(growable: false),
    fornecedorId: t('fornecedorId'),
    fornecedorNome: t('fornecedorNome'),
    fornecedorDocumento: t('fornecedorDocumento'),
    tipoDocumento: t('tipoDocumento').isEmpty ? 'NF-e' : t('tipoDocumento'),
    numeroDocumento: t('numeroDocumento'),
    serieDocumento: t('serieDocumento'),
    dataEmissao: d('dataEmissao'),
    dataEntrada: d('previsaoRecebimento'),
    moeda: t('moeda').isEmpty ? 'BRL' : t('moeda'),
    moedaContabil: t('moedaContabil').isEmpty ? 'BRL' : t('moedaContabil'),
    cotacao: n(j['cotacao']) == 0 ? 1 : n(j['cotacao']),
    cotacaoInformada: j['cotacao'] != null,
    observacoes: t('observacoes'),
    itens: raw.whereType<Map<String,dynamic>>().map((i) => _CompraDemoItem(
      id: i['id']?.toString() ?? '',
      produtoId: i['produtoId']?.toString(),
      descricao: i['descricao']?.toString() ?? '',
      codigo: i['codigo']?.toString() ?? '',
      unidade: i['unidade']?.toString() ?? 'UN',
      quantidade: n(i['quantidade']),
      valorUnitario: n(i['valorUnitario']),
      desconto: n(i['desconto']),
      acrescimo: n(i['acrescimo']),
      movimentaEstoque: i['movimentaEstoque'] == true,
    )).toList(),
    frete: n(j['frete']),
    descontoGeral: n(j['descontoGeral']),
    outrosAcrescimos: n(j['outrosAcrescimos']),
    gerarContaPagar: j['gerarContaPagar'] == true,
    jaPago: j['jaPago'] == true,
    formaPagamento: t('formaPagamento'),
    quantidadeParcelas: (j['quantidadeParcelas'] as num?)?.toInt() ?? 1,
    primeiroVencimento: d('primeiroVencimento'),
    intervaloDias: (j['intervaloDias'] as num?)?.toInt() ?? 30,
    contaFinanceira: t('contaFinanceira'),
    observacaoFinanceira: t('observacaoFinanceira'),
  );
}

Map<String,dynamic> _compraParaApi(_CompraDemo c) => {
  'versao': c.versao,
  'fornecedorId': c.fornecedorId,
  'tipoDocumento': c.tipoDocumento,
  'numeroDocumento': c.numeroDocumento,
  'serieDocumento': c.serieDocumento,
  'dataEmissao': c.dataEmissao.toIso8601String().substring(0, 10),
  'previsaoRecebimento': c.dataEntrada.toIso8601String().substring(0, 10),
  'moeda': c.moeda,
  'moedaContabil': c.moedaContabil,
  'cotacao': c.moeda == c.moedaContabil ? 1 : (c.cotacaoInformada ? c.cotacao : null),
  'observacoes': c.observacoes,
  'itens': [for (final i in c.itens) {
    'id': i.id,
    'produtoId': i.produtoId,
    'descricao': i.descricao,
    'codigo': i.codigo,
    'unidade': i.unidade,
    'quantidade': i.quantidade,
    'valorUnitario': i.valorUnitario,
    'desconto': i.desconto,
    'acrescimo': i.acrescimo,
    'movimentaEstoque': i.movimentaEstoque,
  }],
  'frete': c.frete,
  'descontoGeral': c.descontoGeral,
  'outrosAcrescimos': c.outrosAcrescimos,
  'gerarContaPagar': c.gerarContaPagar,
  'jaPago': c.jaPago,
  'formaPagamento': c.formaPagamento,
  'quantidadeParcelas': c.quantidadeParcelas,
  'primeiroVencimento': c.primeiroVencimento.toIso8601String().substring(0, 10),
  'intervaloDias': c.intervaloDias,
  'contaFinanceira': c.contaFinanceira,
  'observacaoFinanceira': c.observacaoFinanceira,
};
