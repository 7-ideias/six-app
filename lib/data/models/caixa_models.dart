
import '../../presentation/screens/operacoes_caixa_web_page.dart';

class InformacoesBasicasCaixaResponse {
  final bool possuiSessaoAberta;
  // final SessaoAtual sessaoAtual;
  final List<TiposRecebimento> tiposRecebimento;
  final List<String> caixas;
  final List<FormaMovimento> formas;

  InformacoesBasicasCaixaResponse({
    required this.possuiSessaoAberta,
    // required this.sessaoAtual,
    required this.tiposRecebimento,
    required this.caixas,
    required this.formas,
  });

  factory InformacoesBasicasCaixaResponse.fromJson(Map<String, dynamic> json) {
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: json['possuiSessaoAberta'] ?? false,
      // sessaoAtual: SessaoAtual.fromJson(json['sessaoAtual']),
      tiposRecebimento:
      (json['tiposRecebimento'] as List? ?? [])
          .map((item) => TiposRecebimento.fromJson(item))
          .toList(),
      caixas: List<String>.from(json['caixas'] ?? []),
      formas: (json['formas'] as List? ?? [])
          .map((item) => FormaMovimento.fromJson(item))
          .toList(),
    );
  }
}

class TiposRecebimento {
  final String codigoTipo;
  final String descricaoExibicao;
  final String naturezaRecebimento;
  final bool aceitaParcelamento;
  final bool ativo;
  final bool exigeCliente;
  final int ordemExibicao;
  final String corHex;
  final String icone;

  TiposRecebimento({
    required this.codigoTipo,
    required this.descricaoExibicao,
    required this.naturezaRecebimento,
    required this.aceitaParcelamento,
    required this.ativo,
    required this.exigeCliente,
    required this.ordemExibicao,
    required this.corHex,
    required this.icone,
  });

  factory TiposRecebimento.fromJson(Map<String, dynamic> json) {
    return TiposRecebimento(
      codigoTipo: json['codigoTipo'] ?? '',
      descricaoExibicao: json['descricaoExibicao'] ?? '',
      naturezaRecebimento: json['naturezaRecebimento'] ?? '',
      aceitaParcelamento: json['aceitaParcelamento'] ?? false,
      ativo: json['ativo'] ?? false,
      exigeCliente: json['exigeCliente'] ?? false,
      ordemExibicao: (json['ordemExibicao'] as num? ?? 0).toInt(),
      corHex: json['corHex'] ?? '',
      icone: json['icone'] ?? '',
    );
  }
}

class SessaoAtual {
  final String idSessaoCaixa;
  final String nomeCaixa;
  final String idColaboradorAbertura;
  final String nomeColaboradorAbertura;
  final String dataHoraAbertura;
  final double valorAbertura;
  final bool status;

  SessaoAtual({
    required this.idSessaoCaixa,
    required this.nomeCaixa,
    required this.idColaboradorAbertura,
    required this.nomeColaboradorAbertura,
    required this.dataHoraAbertura,
    required this.valorAbertura,
    required this.status,
  });

  factory SessaoAtual.fromJson(Map<String, dynamic> json) {
    return SessaoAtual(
      idSessaoCaixa: json['idSessaoCaixa']?.toString() ?? '',
      nomeCaixa: json['nomeCaixa'] ?? '',
      idColaboradorAbertura: json['idColaboradorAbertura'] ?? '',
      nomeColaboradorAbertura: json['nomeColaboradorAbertura'] ?? '',
      dataHoraAbertura: json['dataHoraAbertura'] ?? '',
      valorAbertura: (json['valorAbertura'] as num? ?? 0).toDouble(),
      status: json['status'] ?? false,
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

  AbrirCaixaRequest({required this.nomeCaixa, required this.valorAbertura});

  Map<String, dynamic> toJson() {
    return {'caixaNome': nomeCaixa, 'valorAbertura': valorAbertura};
  }
}

class RegistrarMovimentoRequest {
  final String idSessaoCaixa;
  final OperacaoCaixaTipo tipoMovimento;
  final String codigoTipoRecebimento;
  final double valor;
  final String observacao;
  final String referencia;
  final bool vinculadoVenda;

  RegistrarMovimentoRequest({
    required this.idSessaoCaixa,
    required this.tipoMovimento,
    required this.codigoTipoRecebimento,
    required this.valor,
    required this.observacao,
    required this.referencia,
    required this.vinculadoVenda,
  });

  Map<String, dynamic> toJson() {
    return {
      'idSessaoCaixa': idSessaoCaixa,
      'tipoMovimento': tipoMovimento.OperacaoCaixaTipoEnum,
      'codigoTipoRecebimento': codigoTipoRecebimento,
      'valor': valor,
      'observacao': observacao,
      'referencia': referencia,
      'vinculadoVenda': vinculadoVenda,
    };
  }
}

class FecharCaixaRequest {
  final String idSessaoCaixa;
  final double valorDinheiroApurado;
  final double valorPixApurado;
  final double valorCartaoApurado;
  final String observacaoFechamento;

  FecharCaixaRequest({
    required this.idSessaoCaixa,
    required this.valorDinheiroApurado,
    required this.valorPixApurado,
    required this.valorCartaoApurado,
    required this.observacaoFechamento,
  });

  Map<String, dynamic> toJson() {
    return {
      'idSessaoCaixa': idSessaoCaixa,
      'valorDinheiroApurado': valorDinheiroApurado,
      'valorPixApurado': valorPixApurado,
      'valorCartaoApurado': valorCartaoApurado,
      'observacaoFechamento': observacaoFechamento,
    };
  }
}
