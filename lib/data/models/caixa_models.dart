
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
  final String idMovimento;
  final String idSessaoCaixa;
  final String tipoMovimento;
  final String natureza;
  final String codigoTipoRecebimento;
  final String descricaoTipoRecebimento;
  final double valor;
  final String descricao;
  final String observacao;
  final String referencia;
  final String idColaborador;
  final String nomeColaborador;
  final String dataHoraMovimento;
  final String status;

  MovimentoCaixa({
    required this.idMovimento,
    required this.idSessaoCaixa,
    required this.tipoMovimento,
    required this.natureza,
    required this.codigoTipoRecebimento,
    required this.descricaoTipoRecebimento,
    required this.valor,
    required this.descricao,
    required this.observacao,
    required this.referencia,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.dataHoraMovimento,
    required this.status,
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
      idMovimento: id ?? this.idMovimento,
      idSessaoCaixa: idSessaoCaixa,
      tipoMovimento: tipo ?? this.tipoMovimento,
      natureza: natureza ?? this.natureza,
      codigoTipoRecebimento: codigoTipoRecebimento,
      descricaoTipoRecebimento: descricaoTipoRecebimento,
      valor: valor ?? this.valor,
      descricao: descricao,
      observacao: observacao ?? this.observacao,
      referencia: referencia ?? this.referencia,
      idColaborador: idColaborador,
      nomeColaborador: colaborador ?? this.nomeColaborador,
      dataHoraMovimento: dataHora ?? this.dataHoraMovimento,
      status: status ?? this.status,
    );
  }

  factory MovimentoCaixa.fromJson(Map<String, dynamic> json) {
    return MovimentoCaixa(
      idMovimento: json['idMovimento']?.toString() ?? '',
      idSessaoCaixa: json['idSessaoCaixa']?.toString() ?? '',
      tipoMovimento: json['tipoMovimento'] ?? '',
      natureza: json['natureza'] ?? '',
      codigoTipoRecebimento: json['codigoTipoRecebimento'] ?? '',
      descricaoTipoRecebimento: json['descricaoTipoRecebimento'] ?? '',
      valor: (json['valor'] as num? ?? 0).toDouble(),
      descricao: json['descricao'] ?? '',
      observacao: json['observacao'] ?? '',
      referencia: json['referencia'] ?? '',
      idColaborador: json['idColaborador'] ?? '',
      nomeColaborador: json['nomeColaborador'] ?? '',
      dataHoraMovimento: json['dataHoraMovimento'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class ResumoCaixa {
  final double trocoInicial;
  final double totalEntradas;
  final double totalSaidas;
  final double saldoEsperado;
  final int quantidadeMovimentos;
  final double totalDinheiro;
  final double totalPix;
  final double totalCartao;
  final double totalCartaoCredito;
  final double totalCartaoDebito;
  final double totalBoleto;
  final double totalFiado;
  final double totalCrediario;
  final double totalConvenio;
  final double totalVale;
  final double totalOutros;

  ResumoCaixa({
    required this.trocoInicial,
    required this.totalEntradas,
    required this.totalSaidas,
    required this.saldoEsperado,
    required this.quantidadeMovimentos,
    required this.totalDinheiro,
    required this.totalPix,
    required this.totalCartao,
    required this.totalCartaoCredito,
    required this.totalCartaoDebito,
    required this.totalBoleto,
    required this.totalFiado,
    required this.totalCrediario,
    required this.totalConvenio,
    required this.totalVale,
    required this.totalOutros,
  });

  factory ResumoCaixa.fromJson(Map<String, dynamic> json) {
    final totalCartaoJson = (json['totalCartao'] as num? ?? 0).toDouble();
    final totalCartaoCreditoJson =
    (json['totalCartaoCredito'] as num?)?.toDouble();
    final totalCartaoDebitoJson =
    (json['totalCartaoDebito'] as num?)?.toDouble();

    return ResumoCaixa(
      trocoInicial: (json['trocoInicial'] as num? ?? 0).toDouble(),
      totalEntradas: (json['totalEntradas'] as num? ?? 0).toDouble(),
      totalSaidas: (json['totalSaidas'] as num? ?? 0).toDouble(),
      saldoEsperado: (json['saldoEsperado'] as num? ?? 0).toDouble(),
      quantidadeMovimentos: (json['quantidadeMovimentos'] as num? ?? 0).toInt(),
      totalDinheiro: (json['totalDinheiro'] as num? ?? 0).toDouble(),
      totalPix: (json['totalPix'] as num? ?? 0).toDouble(),
      totalCartao: totalCartaoJson,
      totalCartaoCredito: totalCartaoCreditoJson ?? totalCartaoJson,
      totalCartaoDebito: totalCartaoDebitoJson ?? 0,
      totalBoleto: (json['totalBoleto'] as num? ?? 0).toDouble(),
      totalFiado: (json['totalFiado'] as num? ?? 0).toDouble(),
      totalCrediario: (json['totalCrediario'] as num? ?? 0).toDouble(),
      totalConvenio: (json['totalConvenio'] as num? ?? 0).toDouble(),
      totalVale: (json['totalVale'] as num? ?? 0).toDouble(),
      totalOutros: (json['totalOutros'] as num? ?? 0).toDouble(),
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
