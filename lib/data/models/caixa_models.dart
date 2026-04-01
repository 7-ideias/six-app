
class CaixaInformacoesBasicas {
  final List<String> caixas;
  final List<FormaMovimento> formas;

  CaixaInformacoesBasicas({
    required this.caixas,
    required this.formas,
  });

  factory CaixaInformacoesBasicas.fromJson(Map<String, dynamic> json) {
    return CaixaInformacoesBasicas(
      caixas: List<String>.from(json['caixas'] ?? []),
      formas: (json['formas'] as List? ?? [])
          .map((item) => FormaMovimento.fromJson(item))
          .toList(),
    );
  }
}

class FormaMovimento {
  final String codigo;
  final String descricao;
  final String natureza; // imediato, futuro

  FormaMovimento({
    required this.codigo,
    required this.descricao,
    required this.natureza,
  });

  factory FormaMovimento.fromJson(Map<String, dynamic> json) {
    return FormaMovimento(
      codigo: json['codigo'] ?? '',
      descricao: json['descricao'] ?? '',
      natureza: json['natureza'] ?? '',
    );
  }
}

class CaixaSessao {
  final String idSessaoCaixa;
  final String nomeCaixa;
  final String idColaboradorAbertura;
  final String dataHoraAbertura;
  final double valorAbertura;
  final String status; // aberta, fechada

  CaixaSessao({
    required this.idSessaoCaixa,
    required this.nomeCaixa,
    required this.idColaboradorAbertura,
    required this.dataHoraAbertura,
    required this.valorAbertura,
    required this.status,
  });

  factory CaixaSessao.fromJson(Map<String, dynamic> json) {
    return CaixaSessao(
      idSessaoCaixa: json['idSessaoCaixa']?.toString() ?? '',
      nomeCaixa: json['nomeCaixa'] ?? '',
      idColaboradorAbertura: json['idColaboradorAbertura'] ?? '',
      dataHoraAbertura: json['dataHoraAbertura'] ?? '',
      valorAbertura: (json['valorAbertura'] as num? ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
  CaixaSessao copyWith({
    String? id,
    String? caixaNome,
    String? colaborador,
    String? dataAbertura,
    double? valorAbertura,
    String? status,
  }) {
    return CaixaSessao(
      idSessaoCaixa: id ?? this.idSessaoCaixa,
      nomeCaixa: caixaNome ?? this.nomeCaixa,
      idColaboradorAbertura: colaborador ?? this.idColaboradorAbertura,
      dataHoraAbertura: dataAbertura ?? this.dataHoraAbertura,
      valorAbertura: valorAbertura ?? this.valorAbertura,
      status: status ?? this.status,
    );
  }
}

class MovimentoCaixa {
  final String id;
  final String tipo;
  final String natureza;
  final double valor;
  final FormaMovimento forma;
  final String caixaNome;
  final String colaborador;
  final String observacao;
  final String referencia;
  final String dataHora;
  final String status;
  final bool vinculadoVenda;

  MovimentoCaixa({
    required this.id,
    required this.tipo,
    required this.natureza,
    required this.valor,
    required this.forma,
    required this.caixaNome,
    required this.colaborador,
    required this.observacao,
    required this.referencia,
    required this.dataHora,
    required this.status,
    required this.vinculadoVenda,
  });

  MovimentoCaixa copyWith({
    String? id,
    String? tipo,
    String? natureza,
    double? valor,
    FormaMovimento? forma,
    String? caixaNome,
    String? colaborador,
    String? observacao,
    String? referencia,
    String? dataHora,
    String? status,
    bool? vinculadoVenda,
  }) {
    return MovimentoCaixa(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      natureza: natureza ?? this.natureza,
      valor: valor ?? this.valor,
      forma: forma ?? this.forma,
      caixaNome: caixaNome ?? this.caixaNome,
      colaborador: colaborador ?? this.colaborador,
      observacao: observacao ?? this.observacao,
      referencia: referencia ?? this.referencia,
      dataHora: dataHora ?? this.dataHora,
      status: status ?? this.status,
      vinculadoVenda: vinculadoVenda ?? this.vinculadoVenda,
    );
  }

  factory MovimentoCaixa.fromJson(Map<String, dynamic> json) {
    return MovimentoCaixa(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo'] ?? '',
      natureza: json['natureza'] ?? '',
      valor: (json['valor'] as num? ?? 0).toDouble(),
      forma: FormaMovimento.fromJson(json['forma'] ?? {}),
      caixaNome: json['caixaNome'] ?? '',
      colaborador: json['colaborador'] ?? '',
      observacao: json['observacao'] ?? '',
      referencia: json['referencia'] ?? '',
      dataHora: json['dataHora'] ?? '',
      status: json['status'] ?? '',
      vinculadoVenda: json['vinculadoVenda'] ?? false,
    );
  }
}

class ResumoCaixa {
  final double trocoInicial;
  final double totalEntradas;
  final double totalSaidas;
  final double saldoEsperado;
  final int quantidadeMovimentos;
  final double dinheiro;
  final double pix;
  final double cartao;

  ResumoCaixa({
    required this.trocoInicial,
    required this.totalEntradas,
    required this.totalSaidas,
    required this.saldoEsperado,
    required this.quantidadeMovimentos,
    required this.dinheiro,
    required this.pix,
    required this.cartao,
  });

  factory ResumoCaixa.fromJson(Map<String, dynamic> json) {
    return ResumoCaixa(
      trocoInicial: (json['trocoInicial'] as num? ?? 0).toDouble(),
      totalEntradas: (json['totalEntradas'] as num? ?? 0).toDouble(),
      totalSaidas: (json['totalSaidas'] as num? ?? 0).toDouble(),
      saldoEsperado: (json['saldoEsperado'] as num? ?? 0).toDouble(),
      quantidadeMovimentos: (json['quantidadeMovimentos'] as num? ?? 0).toInt(),
      dinheiro: (json['dinheiro'] as num? ?? 0).toDouble(),
      pix: (json['pix'] as num? ?? 0).toDouble(),
      cartao: (json['cartao'] as num? ?? 0).toDouble(),
    );
  }
}

class AbrirCaixaRequest {
  final String nomeCaixa;
  final double valorAbertura;

  AbrirCaixaRequest({
    required this.nomeCaixa,
    required this.valorAbertura,
  });

  Map<String, dynamic> toJson() {
    return {
      'caixaNome': nomeCaixa,
      'valorAbertura': valorAbertura,
    };
  }
}

class RegistrarMovimentoRequest {
  final String tipo;
  final double valor;
  final String formaPagamentoCodigo;
  final String observacao;
  final String referencia;
  final bool vincularVenda;

  RegistrarMovimentoRequest({
    required this.tipo,
    required this.valor,
    required this.formaPagamentoCodigo,
    required this.observacao,
    required this.referencia,
    required this.vincularVenda,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'valor': valor,
      'formaPagamentoCodigo': formaPagamentoCodigo,
      'observacao': observacao,
      'referencia': referencia,
      'vincularVenda': vincularVenda,
    };
  }
}

class FecharCaixaRequest {
  final double dinheiro;
  final double pix;
  final double cartao;
  final String observacao;

  FecharCaixaRequest({
    required this.dinheiro,
    required this.pix,
    required this.cartao,
    required this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'dinheiro': dinheiro,
      'pix': pix,
      'cartao': cartao,
      'observacao': observacao,
    };
  }
}
