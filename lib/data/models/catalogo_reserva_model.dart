enum CatalogoReservaStatus {
  recebida('RECEBIDA'),
  emAnalise('EM_ANALISE'),
  confirmada('CONFIRMADA'),
  cancelada('CANCELADA');

  const CatalogoReservaStatus(this.apiValue);

  final String apiValue;

  static CatalogoReservaStatus fromApi(String? value) {
    return CatalogoReservaStatus.values.firstWhere(
      (CatalogoReservaStatus status) => status.apiValue == value,
      orElse: () => CatalogoReservaStatus.recebida,
    );
  }
}

class CatalogoReservaResumoModel {
  const CatalogoReservaResumoModel({
    required this.idReserva,
    required this.status,
    required this.criadaEm,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.emailCliente,
    required this.quantidadeTotal,
    required this.valorTotal,
  });

  final String idReserva;
  final CatalogoReservaStatus status;
  final DateTime? criadaEm;
  final String nomeCliente;
  final String telefoneCliente;
  final String emailCliente;
  final int quantidadeTotal;
  final double valorTotal;

  factory CatalogoReservaResumoModel.fromJson(Map<String, dynamic> json) {
    return CatalogoReservaResumoModel(
      idReserva: json['idReserva']?.toString() ?? '',
      status: CatalogoReservaStatus.fromApi(json['status']?.toString()),
      criadaEm: DateTime.tryParse(json['criadaEm']?.toString() ?? ''),
      nomeCliente: json['nomeCliente']?.toString() ?? '',
      telefoneCliente: json['telefoneCliente']?.toString() ?? '',
      emailCliente: json['emailCliente']?.toString() ?? '',
      quantidadeTotal: (json['quantidadeTotal'] as num?)?.toInt() ?? 0,
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CatalogoReservaPaginaModel {
  const CatalogoReservaPaginaModel({
    required this.reservas,
    required this.pagina,
    required this.tamanho,
    required this.totalPaginas,
    required this.totalElementos,
  });

  final List<CatalogoReservaResumoModel> reservas;
  final int pagina;
  final int tamanho;
  final int totalPaginas;
  final int totalElementos;

  factory CatalogoReservaPaginaModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawReservas =
        json['reservas'] is List<dynamic>
            ? json['reservas'] as List<dynamic>
            : <dynamic>[];
    return CatalogoReservaPaginaModel(
      reservas:
          rawReservas
              .whereType<Map<String, dynamic>>()
              .map(CatalogoReservaResumoModel.fromJson)
              .toList(growable: false),
      pagina: (json['pagina'] as num?)?.toInt() ?? 0,
      tamanho: (json['tamanho'] as num?)?.toInt() ?? 20,
      totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      totalElementos: (json['totalElementos'] as num?)?.toInt() ?? 0,
    );
  }
}

class CatalogoReservaClienteModel {
  const CatalogoReservaClienteModel({
    required this.nome,
    required this.telefone,
    required this.email,
  });

  final String nome;
  final String telefone;
  final String email;

  factory CatalogoReservaClienteModel.fromJson(Map<String, dynamic> json) {
    return CatalogoReservaClienteModel(
      nome: json['nome']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class CatalogoReservaItemModel {
  const CatalogoReservaItemModel({
    required this.idProduto,
    required this.nomeProduto,
    required this.modeloProduto,
    required this.tipoProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  final String idProduto;
  final String nomeProduto;
  final String modeloProduto;
  final String tipoProduto;
  final int quantidade;
  final double valorUnitario;
  final double valorTotal;

  factory CatalogoReservaItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogoReservaItemModel(
      idProduto: json['idProduto']?.toString() ?? '',
      nomeProduto: json['nomeProduto']?.toString() ?? '',
      modeloProduto: json['modeloProduto']?.toString() ?? '',
      tipoProduto: json['tipoProduto']?.toString() ?? '',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
      valorUnitario: (json['valorUnitario'] as num?)?.toDouble() ?? 0,
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CatalogoReservaDetalheModel {
  const CatalogoReservaDetalheModel({
    required this.idReserva,
    required this.status,
    required this.criadaEm,
    required this.cliente,
    required this.itens,
    required this.quantidadeTotal,
    required this.valorTotal,
    required this.observacao,
  });

  final String idReserva;
  final CatalogoReservaStatus status;
  final DateTime? criadaEm;
  final CatalogoReservaClienteModel cliente;
  final List<CatalogoReservaItemModel> itens;
  final int quantidadeTotal;
  final double valorTotal;
  final String observacao;

  factory CatalogoReservaDetalheModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> cliente =
        json['cliente'] is Map<String, dynamic>
            ? json['cliente'] as Map<String, dynamic>
            : <String, dynamic>{};
    final List<dynamic> rawItens =
        json['itens'] is List<dynamic>
            ? json['itens'] as List<dynamic>
            : <dynamic>[];
    return CatalogoReservaDetalheModel(
      idReserva: json['idReserva']?.toString() ?? '',
      status: CatalogoReservaStatus.fromApi(json['status']?.toString()),
      criadaEm: DateTime.tryParse(json['criadaEm']?.toString() ?? ''),
      cliente: CatalogoReservaClienteModel.fromJson(cliente),
      itens:
          rawItens
              .whereType<Map<String, dynamic>>()
              .map(CatalogoReservaItemModel.fromJson)
              .toList(growable: false),
      quantidadeTotal: (json['quantidadeTotal'] as num?)?.toInt() ?? 0,
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0,
      observacao: json['observacao']?.toString() ?? '',
    );
  }
}
