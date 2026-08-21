enum TipoDevolucaoProduto {
  devolucao('DEVOLUCAO'),
  troca('TROCA');

  const TipoDevolucaoProduto(this.apiValue);
  final String apiValue;
}

enum CondicaoProdutoDevolvido {
  novo('NOVO'),
  aberto('ABERTO'),
  usado('USADO'),
  comDefeito('COM_DEFEITO'),
  avariado('AVARIADO'),
  outro('OUTRO');

  const CondicaoProdutoDevolvido(this.apiValue);
  final String apiValue;
}

class VendaElegivelDevolucao {
  const VendaElegivelDevolucao({
    required this.idOperacao,
    required this.codigoOperacao,
    required this.dataOperacao,
    required this.idCliente,
    required this.nomeCliente,
    required this.valorTotalProdutos,
    required this.possuiItensElegiveis,
    required this.itens,
  });

  final String idOperacao;
  final String codigoOperacao;
  final DateTime? dataOperacao;
  final String idCliente;
  final String nomeCliente;
  final double valorTotalProdutos;
  final bool possuiItensElegiveis;
  final List<ItemVendaElegivelDevolucao> itens;

  factory VendaElegivelDevolucao.fromJson(Map<String, dynamic> json) {
    return VendaElegivelDevolucao(
      idOperacao: json['idOperacao']?.toString() ?? '',
      codigoOperacao: json['codigoOperacao']?.toString() ?? '',
      dataOperacao: DateTime.tryParse(json['dataOperacao']?.toString() ?? ''),
      idCliente: json['idCliente']?.toString() ?? '',
      nomeCliente: json['nomeCliente']?.toString() ?? '',
      valorTotalProdutos: _asDouble(json['valorTotalProdutos']),
      possuiItensElegiveis: json['possuiItensElegiveis'] == true,
      itens: _asList(json['itens'])
          .whereType<Map>()
          .map(
            (Map item) => ItemVendaElegivelDevolucao.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ItemVendaElegivelDevolucao {
  const ItemVendaElegivelDevolucao({
    required this.idItemVenda,
    required this.idProduto,
    required this.nomeProduto,
    required this.quantidadeVendida,
    required this.quantidadeJaDevolvida,
    required this.quantidadeDisponivel,
    required this.valorUnitario,
    required this.valorDisponivel,
  });

  final String idItemVenda;
  final String idProduto;
  final String nomeProduto;
  final double quantidadeVendida;
  final double quantidadeJaDevolvida;
  final double quantidadeDisponivel;
  final double valorUnitario;
  final double valorDisponivel;

  factory ItemVendaElegivelDevolucao.fromJson(Map<String, dynamic> json) {
    return ItemVendaElegivelDevolucao(
      idItemVenda: json['idItemVenda']?.toString() ?? '',
      idProduto: json['idProduto']?.toString() ?? '',
      nomeProduto: json['nomeProduto']?.toString() ?? '',
      quantidadeVendida: _asDouble(json['quantidadeVendida']),
      quantidadeJaDevolvida: _asDouble(json['quantidadeJaDevolvida']),
      quantidadeDisponivel: _asDouble(json['quantidadeDisponivel']),
      valorUnitario: _asDouble(json['valorUnitario']),
      valorDisponivel: _asDouble(json['valorDisponivel']),
    );
  }
}

class ItemDevolvidoRequest {
  const ItemDevolvidoRequest({
    required this.idItemVenda,
    required this.quantidade,
    required this.motivo,
    required this.condicao,
    required this.retornarAoEstoque,
  });

  final String idItemVenda;
  final double quantidade;
  final String motivo;
  final CondicaoProdutoDevolvido condicao;
  final bool retornarAoEstoque;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'idItemVenda': idItemVenda,
        'quantidade': quantidade,
        'motivo': motivo,
        'condicao': condicao.apiValue,
        'retornarAoEstoque': retornarAoEstoque,
      };
}

class ItemTrocaRequest {
  const ItemTrocaRequest({required this.idProduto, required this.quantidade});

  final String idProduto;
  final double quantidade;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'idProduto': idProduto,
        'quantidade': quantidade,
      };
}

class RegistrarDevolucaoProdutoRequest {
  const RegistrarDevolucaoProdutoRequest({
    required this.chaveIdempotencia,
    required this.identificadorVenda,
    required this.tipo,
    required this.itensDevolvidos,
    required this.itensTroca,
    this.codigoTipoRecebimento,
    this.observacoes,
  });

  final String chaveIdempotencia;
  final String identificadorVenda;
  final TipoDevolucaoProduto tipo;
  final List<ItemDevolvidoRequest> itensDevolvidos;
  final List<ItemTrocaRequest> itensTroca;
  final String? codigoTipoRecebimento;
  final String? observacoes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chaveIdempotencia': chaveIdempotencia,
        'identificadorVenda': identificadorVenda,
        'tipo': tipo.apiValue,
        'itensDevolvidos':
            itensDevolvidos.map((ItemDevolvidoRequest item) => item.toJson()).toList(),
        'itensTroca':
            itensTroca.map((ItemTrocaRequest item) => item.toJson()).toList(),
        if (codigoTipoRecebimento != null)
          'codigoTipoRecebimento': codigoTipoRecebimento,
        if (observacoes != null && observacoes!.trim().isNotEmpty)
          'observacoes': observacoes!.trim(),
      };
}

class DevolucaoProdutoResponse {
  const DevolucaoProdutoResponse({
    required this.id,
    required this.codigoDevolucao,
    required this.idOperacaoOriginal,
    required this.codigoOperacaoOriginal,
    required this.nomeCliente,
    required this.tipo,
    required this.status,
    required this.dataCriacao,
    required this.valorTotalDevolvido,
    required this.valorTotalTroca,
    required this.saldoFinanceiro,
    required this.tipoAcertoFinanceiro,
    required this.itensDevolvidos,
    required this.itensTroca,
  });

  final String id;
  final String codigoDevolucao;
  final String idOperacaoOriginal;
  final String codigoOperacaoOriginal;
  final String nomeCliente;
  final String tipo;
  final String status;
  final DateTime? dataCriacao;
  final double valorTotalDevolvido;
  final double valorTotalTroca;
  final double saldoFinanceiro;
  final String tipoAcertoFinanceiro;
  final List<Map<String, dynamic>> itensDevolvidos;
  final List<Map<String, dynamic>> itensTroca;

  factory DevolucaoProdutoResponse.fromJson(Map<String, dynamic> json) {
    return DevolucaoProdutoResponse(
      id: json['id']?.toString() ?? '',
      codigoDevolucao: json['codigoDevolucao']?.toString() ?? '',
      idOperacaoOriginal: json['idOperacaoOriginal']?.toString() ?? '',
      codigoOperacaoOriginal:
          json['codigoOperacaoOriginal']?.toString() ?? '',
      nomeCliente: json['nomeCliente']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dataCriacao: DateTime.tryParse(json['dataCriacao']?.toString() ?? ''),
      valorTotalDevolvido: _asDouble(json['valorTotalDevolvido']),
      valorTotalTroca: _asDouble(json['valorTotalTroca']),
      saldoFinanceiro: _asDouble(json['saldoFinanceiro']),
      tipoAcertoFinanceiro: json['tipoAcertoFinanceiro']?.toString() ?? '',
      itensDevolvidos: _asList(json['itensDevolvidos'])
          .whereType<Map>()
          .map((Map item) => item.cast<String, dynamic>())
          .toList(growable: false),
      itensTroca: _asList(json['itensTroca'])
          .whereType<Map>()
          .map((Map item) => item.cast<String, dynamic>())
          .toList(growable: false),
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<dynamic> _asList(dynamic value) => value is List ? value : const <dynamic>[];
