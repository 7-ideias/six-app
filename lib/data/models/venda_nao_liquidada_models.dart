class VendaNaoLiquidadaModel {
  VendaNaoLiquidadaModel({
    required this.idRecebimento,
    required this.idOperacaoFinanceira,
    required this.idOperacaoApp,
    required this.descricao,
    required this.valorOriginal,
    required this.valorAberto,
    required this.status,
    required this.codigoTipoRecebimento,
    required this.dataCompetencia,
    required this.dataVencimento,
    required this.idCliente,
    required this.nomeCliente,
    required this.idColaboradorCriacao,
    required this.nomeColaboradorCriacao,
  });

  final String idRecebimento;
  final String idOperacaoFinanceira;
  final String idOperacaoApp;
  final String descricao;
  final double valorOriginal;
  final double valorAberto;
  final String status;
  final String codigoTipoRecebimento;
  final DateTime? dataCompetencia;
  final DateTime? dataVencimento;
  final String idCliente;
  final String nomeCliente;
  final String idColaboradorCriacao;
  final String nomeColaboradorCriacao;

  factory VendaNaoLiquidadaModel.fromJson(Map<String, dynamic> json) {
    return VendaNaoLiquidadaModel(
      idRecebimento: (json['idRecebimento'] ?? '').toString(),
      idOperacaoFinanceira: (json['idOperacaoFinanceira'] ?? '').toString(),
      idOperacaoApp: (json['idOperacaoApp'] ?? '').toString(),
      descricao: (json['descricao'] ?? 'Venda não liquidada').toString(),
      valorOriginal: _toDouble(json['valorOriginal']),
      valorAberto: _toDouble(json['valorAberto']),
      status: (json['status'] ?? '').toString(),
      codigoTipoRecebimento: (json['codigoTipoRecebimento'] ?? '').toString(),
      dataCompetencia: _toDateTime(json['dataCompetencia']),
      dataVencimento: _toDateTime(json['dataVencimento']),
      idCliente: (json['idCliente'] ?? '').toString(),
      nomeCliente: (json['nomeCliente'] ?? '').toString(),
      idColaboradorCriacao: (json['idColaboradorCriacao'] ?? '').toString(),
      nomeColaboradorCriacao: (json['nomeColaboradorCriacao'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString().replaceAll(',', '.')) ?? 0.0;
  }

  static DateTime? _toDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class LiquidarVendaNaoLiquidadaInput {
  LiquidarVendaNaoLiquidadaInput({
    required this.codigoTipoRecebimento,
    required this.valorRecebido,
    this.observacao,
    this.referencia,
  });

  final String codigoTipoRecebimento;
  final double valorRecebido;
  final String? observacao;
  final String? referencia;

  Map<String, dynamic> toJson() {
    return {
      'codigoTipoRecebimento': codigoTipoRecebimento,
      'valorRecebido': valorRecebido,
      'observacao': observacao,
      'referencia': referencia,
    };
  }
}
