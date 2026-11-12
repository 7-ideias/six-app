class CartaoCredito {
  const CartaoCredito({
    required this.id,
    required this.nome,
    required this.instituicao,
    required this.diaFechamento,
    required this.diaVencimento,
    required this.ativo,
    required this.versao,
    this.contaPrevistaId,
    this.contaPrevistaNome,
  });

  final String id, nome, instituicao;
  final int diaFechamento, diaVencimento, versao;
  final bool ativo;
  final String? contaPrevistaId, contaPrevistaNome;

  factory CartaoCredito.fromJson(Map<String, dynamic> json) {
    final card = CartaoCredito(
      id: json['id'] as String,
      nome: json['nome'] as String,
      instituicao: json['instituicao'] as String,
      diaFechamento: json['diaFechamento'] as int,
      diaVencimento: json['diaVencimento'] as int,
      ativo: json['ativo'] as bool,
      versao: json['versao'] as int,
      contaPrevistaId: json['contaPrevistaId'] as String?,
      contaPrevistaNome: json['contaPrevistaNome'] as String?,
    );
    if (card.id.isEmpty || card.nome.trim().isEmpty ||
        card.diaFechamento < 1 || card.diaFechamento > 31 ||
        card.diaVencimento < 1 || card.diaVencimento > 31 || card.versao < 0) {
      throw const FormatException('Invalid credit card');
    }
    return card;
  }
}

class CartoesCreditoResponse {
  const CartoesCreditoResponse({required this.podeEditar, required this.cartoes});
  final bool podeEditar;
  final List<CartaoCredito> cartoes;

  factory CartoesCreditoResponse.fromJson(Map<String, dynamic> json) =>
      CartoesCreditoResponse(
        podeEditar: json['podeEditar'] as bool,
        cartoes: (json['cartoes'] as List)
            .map((e) => CartaoCredito.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
      );
}

class CartaoCreditoRequest {
  const CartaoCreditoRequest({
    required this.id,
    required this.nome,
    required this.instituicao,
    required this.diaFechamento,
    required this.diaVencimento,
    required this.ativo,
    this.contaPrevistaId,
    this.versao,
  });
  final String id, nome, instituicao;
  final int diaFechamento, diaVencimento;
  final bool ativo;
  final String? contaPrevistaId;
  final int? versao;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome.trim(),
    'instituicao': instituicao.trim(),
    'diaFechamento': diaFechamento,
    'diaVencimento': diaVencimento,
    'contaPrevistaId': contaPrevistaId,
    'ativo': ativo,
    'versao': versao,
  };
}
