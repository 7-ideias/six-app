String dataCartaoIso(DateTime data) => '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

class CompraCartao {
  CompraCartao.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String, descricao = j['descricao'] as String,
      dataCompra = DateTime.parse(j['dataCompra'] as String),
      valor = (j['valor'] as num).toDouble(), categoria = j['categoria'] as String?,
      categoriaId=j['categoriaId'] as String?,versao=(j['versao'] as num?)?.toInt()??0;
  final String id, descricao;
  final String? categoria,categoriaId;
  final int versao;
  final DateTime dataCompra;
  final double valor;
}
class FaturaCartao {
  FaturaCartao.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String, cartaoId = j['cartaoId'] as String,
      nomeCartao = j['nomeCartao'] as String, idLancamento = j['idLancamento'] as String,
      fechamento = DateTime.parse(j['fechamento'] as String),
      vencimento = DateTime.parse(j['vencimento'] as String),
      total = (j['total'] as num).toDouble(), versao = j['versao'] as int,
      paga = j['paga'] as bool, contaPrevistaId = j['contaPrevistaId'] as String?,
      dataPagamento = j['dataPagamento'] == null ? null : DateTime.parse(j['dataPagamento'] as String),
      compras = (j['compras'] as List).map((e) => CompraCartao.fromJson(Map<String,dynamic>.from(e as Map))).toList(),
      porCategoria = (j['porCategoria'] as Map).map((k,v) => MapEntry(k as String, (v as num).toDouble())) {
    if (id.isEmpty || total < 0 || !total.isFinite || versao < 0) throw const FormatException('Invalid invoice');
  }
  final String id, cartaoId, nomeCartao, idLancamento;
  final DateTime fechamento, vencimento;
  final DateTime? dataPagamento;
  final double total;
  final int versao;
  final bool paga;
  final String? contaPrevistaId;
  final List<CompraCartao> compras;
  final Map<String,double> porCategoria;
}
class PreviaFaturaCartao {
  PreviaFaturaCartao.fromJson(Map<String,dynamic> j)
    : fechamento = DateTime.parse(j['fechamento'] as String),
      vencimento = DateTime.parse(j['vencimento'] as String),
      versaoCartao = j['versaoCartao'] as int, paga = j['paga'] as bool;
  final DateTime fechamento, vencimento;
  final int versaoCartao;
  final bool paga;
}
class CompraCartaoRequest {
  const CompraCartaoRequest({required this.id, required this.cartaoId, required this.descricao,
    required this.dataCompra, required this.valor, required this.previa, this.categoriaId});
  final String id,cartaoId,descricao;
  final String? categoriaId;
  final DateTime dataCompra;
  final double valor;
  final PreviaFaturaCartao previa;
  Map<String,dynamic> toJson() => {'id':id,'descricao':descricao.trim(),'dataCompra':dataCartaoIso(dataCompra),
    'valor':valor,'categoriaId':categoriaId,'vencimentoConfirmado':dataCartaoIso(previa.vencimento),'versaoCartao':previa.versaoCartao};
}
class PagarFaturaCartaoRequest {
  const PagarFaturaCartaoRequest({required this.id,required this.faturaId,required this.versao,
    required this.valor,required this.contaFinanceiraId,required this.dataPagamento,required this.formaPagamento});
  final String id,faturaId,contaFinanceiraId,formaPagamento;
  final int versao;
  final double valor;
  final DateTime dataPagamento;
  Map<String,dynamic> toJson() => {'id':id,'versao':versao,'valor':valor,'contaFinanceiraId':contaFinanceiraId,
    'dataPagamento':dataCartaoIso(dataPagamento),'formaPagamento':formaPagamento};
}
class FormaPagamentoFatura {
  const FormaPagamentoFatura(this.codigo,this.nome);
  final String codigo,nome;
}
