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
    required this.itens,
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
  final List<VendaNaoLiquidadaItemModel> itens;

  factory VendaNaoLiquidadaModel.fromJson(Map<String, dynamic> json) {
    final dynamic itensJson = json['itens'];
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
      itens: itensJson is List
          ? itensJson
              .whereType<Map<String, dynamic>>()
              .map(VendaNaoLiquidadaItemModel.fromJson)
              .toList(growable: false)
          : <VendaNaoLiquidadaItemModel>[],
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

class VendaNaoLiquidadaItemModel {
  VendaNaoLiquidadaItemModel({
    required this.idProduto,
    required this.nome,
    required this.quantidade,
    required this.valorUnitario,
    required this.ehServico,
  });

  final String idProduto;
  final String nome;
  final int quantidade;
  final double valorUnitario;
  final bool ehServico;

  factory VendaNaoLiquidadaItemModel.fromJson(Map<String, dynamic> json) {
    return VendaNaoLiquidadaItemModel(
      idProduto: (json['idProduto'] ?? '').toString(),
      nome: (json['nome'] ?? 'Item da venda').toString(),
      quantidade: _toInt(json['quantidade']),
      valorUnitario: _toDouble(json['valorUnitario']),
      ehServico: json['ehServico'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProduto': idProduto,
      'nome': nome,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'ehServico': ehServico,
    };
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '1').toString()) ?? 1;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class LiquidarVendaNaoLiquidadaInput {
  LiquidarVendaNaoLiquidadaInput({
    required this.codigoTipoRecebimento,
    required this.valorRecebido,
    required this.itens,
    this.observacao,
    this.referencia,
  });

  final String codigoTipoRecebimento;
  final double valorRecebido;
  final List<VendaNaoLiquidadaItemModel> itens;
  final String? observacao;
  final String? referencia;

  Map<String, dynamic> toJson() {
    return {
      'codigoTipoRecebimento': codigoTipoRecebimento,
      'valorRecebido': valorRecebido,
      'itens': itens.map((item) => item.toJson()).toList(growable: false),
      'observacao': observacao,
      'referencia': referencia,
    };
  }
}
