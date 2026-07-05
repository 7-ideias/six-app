class AtendimentoTecnicoEquipamentoModel {
  const AtendimentoTecnicoEquipamentoModel({
    this.tipo,
    this.marca,
    this.modelo,
    this.numeroSerie,
    this.imei,
    this.acessorios,
    this.observacoesEntrada,
  });

  final String? tipo;
  final String? marca;
  final String? modelo;
  final String? numeroSerie;
  final String? imei;
  final String? acessorios;
  final String? observacoesEntrada;

  factory AtendimentoTecnicoEquipamentoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AtendimentoTecnicoEquipamentoModel();
    return AtendimentoTecnicoEquipamentoModel(
      tipo: json['tipo']?.toString(),
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      numeroSerie: json['numeroSerie']?.toString(),
      imei: json['imei']?.toString(),
      acessorios: json['acessorios']?.toString(),
      observacoesEntrada: json['observacoesEntrada']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'numeroSerie': numeroSerie,
      'imei': imei,
      'acessorios': acessorios,
      'observacoesEntrada': observacoesEntrada,
    };
  }
}

class AtendimentoTecnicoItemModel {
  const AtendimentoTecnicoItemModel({
    required this.id,
    required this.tipoItemId,
    required this.tipoItemCodigo,
    required this.tipoItemI18nKey,
    required this.descricaoSnapshot,
    required this.quantidade,
    required this.valorUnitario,
    required this.desconto,
    required this.valorTotal,
    required this.movimentaEstoque,
    required this.statusEstoqueId,
    required this.statusEstoqueCodigo,
    this.idSku,
    this.idTecnicoResponsavel,
    this.nomeTecnicoResponsavel,
  });

  final String id;
  final int tipoItemId;
  final String tipoItemCodigo;
  final String tipoItemI18nKey;
  final String? idSku;
  final String descricaoSnapshot;
  final double quantidade;
  final double valorUnitario;
  final double desconto;
  final double valorTotal;
  final String? idTecnicoResponsavel;
  final String? nomeTecnicoResponsavel;
  final bool movimentaEstoque;
  final int statusEstoqueId;
  final String statusEstoqueCodigo;

  factory AtendimentoTecnicoItemModel.fromJson(Map<String, dynamic> json) {
    return AtendimentoTecnicoItemModel(
      id: json['id']?.toString() ?? '',
      tipoItemId: (json['tipoItemId'] as num?)?.toInt() ?? 0,
      tipoItemCodigo: json['tipoItemCodigo']?.toString() ?? '',
      tipoItemI18nKey: json['tipoItemI18nKey']?.toString() ?? '',
      idSku: json['idSku']?.toString(),
      descricaoSnapshot: json['descricaoSnapshot']?.toString() ?? '',
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0,
      valorUnitario: (json['valorUnitario'] as num?)?.toDouble() ?? 0,
      desconto: (json['desconto'] as num?)?.toDouble() ?? 0,
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0,
      idTecnicoResponsavel: json['idTecnicoResponsavel']?.toString(),
      nomeTecnicoResponsavel: json['nomeTecnicoResponsavel']?.toString(),
      movimentaEstoque: json['movimentaEstoque'] == true,
      statusEstoqueId: (json['statusEstoqueId'] as num?)?.toInt() ?? 0,
      statusEstoqueCodigo: json['statusEstoqueCodigo']?.toString() ?? '',
    );
  }
}

class AtendimentoTecnicoItemInput {
  const AtendimentoTecnicoItemInput({
    required this.tipoItemId,
    required this.tipoItemCodigo,
    required this.descricaoSnapshot,
    required this.quantidade,
    required this.valorUnitario,
    this.idSku,
    this.desconto = 0,
    this.idTecnicoResponsavel,
    this.nomeTecnicoResponsavel,
    this.movimentaEstoque,
  });

  final int tipoItemId;
  final String tipoItemCodigo;
  final String? idSku;
  final String descricaoSnapshot;
  final double quantidade;
  final double valorUnitario;
  final double desconto;
  final String? idTecnicoResponsavel;
  final String? nomeTecnicoResponsavel;
  final bool? movimentaEstoque;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tipoItemId': tipoItemId,
      'tipoItemCodigo': tipoItemCodigo,
      'idSku': idSku,
      'descricaoSnapshot': descricaoSnapshot,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'desconto': desconto,
      'idTecnicoResponsavel': idTecnicoResponsavel,
      'nomeTecnicoResponsavel': nomeTecnicoResponsavel,
      'movimentaEstoque': movimentaEstoque,
    };
  }
}

class AtendimentoTecnicoHistoricoStatusModel {
  const AtendimentoTecnicoHistoricoStatusModel({
    this.statusAnteriorId,
    this.statusAnteriorCodigo,
    this.statusAnteriorI18nKey,
    this.statusAnteriorNomePtBr,
    this.statusAnteriorNomeEnUs,
    this.statusAnteriorNomeEsEs,
    required this.statusId,
    required this.statusCodigo,
    required this.statusI18nKey,
    this.statusNomePtBr,
    this.statusNomeEnUs,
    this.statusNomeEsEs,
    this.observacao,
    this.idUsuario,
    this.dataHora,
  });

  final int? statusAnteriorId;
  final String? statusAnteriorCodigo;
  final String? statusAnteriorI18nKey;
  final String? statusAnteriorNomePtBr;
  final String? statusAnteriorNomeEnUs;
  final String? statusAnteriorNomeEsEs;
  final int statusId;
  final String statusCodigo;
  final String statusI18nKey;
  final String? statusNomePtBr;
  final String? statusNomeEnUs;
  final String? statusNomeEsEs;
  final String? observacao;
  final String? idUsuario;
  final DateTime? dataHora;

  factory AtendimentoTecnicoHistoricoStatusModel.fromJson(Map<String, dynamic> json) {
    return AtendimentoTecnicoHistoricoStatusModel(
      statusAnteriorId: (json['statusAnteriorId'] as num?)?.toInt(),
      statusAnteriorCodigo: json['statusAnteriorCodigo']?.toString(),
      statusAnteriorI18nKey: json['statusAnteriorI18nKey']?.toString(),
      statusAnteriorNomePtBr: json['statusAnteriorNomePtBr']?.toString(),
      statusAnteriorNomeEnUs: json['statusAnteriorNomeEnUs']?.toString(),
      statusAnteriorNomeEsEs: json['statusAnteriorNomeEsEs']?.toString(),
      statusId: (json['statusId'] as num?)?.toInt() ?? 0,
      statusCodigo: json['statusCodigo']?.toString() ?? '',
      statusI18nKey: json['statusI18nKey']?.toString() ?? '',
      statusNomePtBr: json['statusNomePtBr']?.toString(),
      statusNomeEnUs: json['statusNomeEnUs']?.toString(),
      statusNomeEsEs: json['statusNomeEsEs']?.toString(),
      observacao: json['observacao']?.toString(),
      idUsuario: json['idUsuario']?.toString(),
      dataHora: DateTime.tryParse(json['dataHora']?.toString() ?? ''),
    );
  }
}

class AtendimentoTecnicoModel {
  const AtendimentoTecnicoModel({
    required this.id,
    required this.numero,
    required this.statusId,
    required this.statusCodigo,
    required this.statusI18nKey,
    required this.valorTotalProdutos,
    required this.valorTotalServicos,
    required this.valorTotalAtendimento,
    required this.itens,
    required this.historicoStatus,
    this.statusNomePtBr,
    this.statusNomeEnUs,
    this.statusNomeEsEs,
    this.assinaturaAprovada = false,
    this.assinaturaNomeAssinante,
    this.assinaturaDataHora,
    this.validadeOrcamentoEm,
    this.descricao,
    this.idCliente,
    this.nomeClienteSnapshot,
    this.equipamento,
    this.defeitoRelatado,
    this.diagnosticoTecnico,
    this.dataAtualizacao,
  });

  final String id;
  final String numero;
  final String? descricao;
  final String? idCliente;
  final String? nomeClienteSnapshot;
  final int statusId;
  final String statusCodigo;
  final String statusI18nKey;
  final String? statusNomePtBr;
  final String? statusNomeEnUs;
  final String? statusNomeEsEs;
  final bool assinaturaAprovada;
  final String? assinaturaNomeAssinante;
  final DateTime? assinaturaDataHora;
  final DateTime? validadeOrcamentoEm;
  final AtendimentoTecnicoEquipamentoModel? equipamento;
  final String? defeitoRelatado;
  final String? diagnosticoTecnico;
  final double valorTotalProdutos;
  final double valorTotalServicos;
  final double valorTotalAtendimento;
  final List<AtendimentoTecnicoItemModel> itens;
  final List<AtendimentoTecnicoHistoricoStatusModel> historicoStatus;
  final DateTime? dataAtualizacao;

  factory AtendimentoTecnicoModel.fromJson(Map<String, dynamic> json) {
    return AtendimentoTecnicoModel(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      idCliente: json['idCliente']?.toString(),
      nomeClienteSnapshot: json['nomeClienteSnapshot']?.toString(),
      statusId: (json['statusId'] as num?)?.toInt() ?? 0,
      statusCodigo: json['statusCodigo']?.toString() ?? '',
      statusI18nKey: json['statusI18nKey']?.toString() ?? '',
      statusNomePtBr: json['statusNomePtBr']?.toString(),
      statusNomeEnUs: json['statusNomeEnUs']?.toString(),
      statusNomeEsEs: json['statusNomeEsEs']?.toString(),
      assinaturaAprovada: json['assinaturaAprovada'] == true,
      assinaturaNomeAssinante: json['assinaturaNomeAssinante']?.toString(),
      assinaturaDataHora: DateTime.tryParse(json['assinaturaDataHora']?.toString() ?? ''),
      validadeOrcamentoEm: DateTime.tryParse(json['validadeOrcamentoEm']?.toString() ?? ''),
      equipamento: AtendimentoTecnicoEquipamentoModel.fromJson(
        json['equipamento'] is Map<String, dynamic>
            ? json['equipamento'] as Map<String, dynamic>
            : null,
      ),
      defeitoRelatado: json['defeitoRelatado']?.toString(),
      diagnosticoTecnico: json['diagnosticoTecnico']?.toString(),
      valorTotalProdutos: (json['valorTotalProdutos'] as num?)?.toDouble() ?? 0,
      valorTotalServicos: (json['valorTotalServicos'] as num?)?.toDouble() ?? 0,
      valorTotalAtendimento: (json['valorTotalAtendimento'] as num?)?.toDouble() ?? 0,
      itens: _parseItens(json['itens']),
      historicoStatus: _parseHistoricoStatus(json['historicoStatus']),
      dataAtualizacao: DateTime.tryParse(json['dataAtualizacao']?.toString() ?? ''),
    );
  }

  static List<AtendimentoTecnicoItemModel> _parseItens(dynamic value) {
    if (value is! List) return <AtendimentoTecnicoItemModel>[];
    return value.whereType<Map<String, dynamic>>().map(AtendimentoTecnicoItemModel.fromJson).toList(growable: false);
  }

  static List<AtendimentoTecnicoHistoricoStatusModel> _parseHistoricoStatus(dynamic value) {
    if (value is! List) return <AtendimentoTecnicoHistoricoStatusModel>[];
    return value.whereType<Map<String, dynamic>>().map(AtendimentoTecnicoHistoricoStatusModel.fromJson).toList(growable: false);
  }
}

class AtendimentoTecnicoCreateInput {
  const AtendimentoTecnicoCreateInput({
    required this.validadeOrcamentoEm,
    this.descricao,
    this.idCliente,
    this.nomeClienteSnapshot,
    this.prioridadeId,
    this.prioridadeCodigo,
    this.origemCodigo,
    this.equipamento,
    this.defeitoRelatado,
    this.diagnosticoTecnico,
    this.itens = const <AtendimentoTecnicoItemInput>[],
  });

  final DateTime validadeOrcamentoEm;
  final String? descricao;
  final String? idCliente;
  final String? nomeClienteSnapshot;
  final int? prioridadeId;
  final String? prioridadeCodigo;
  final String? origemCodigo;
  final AtendimentoTecnicoEquipamentoModel? equipamento;
  final String? defeitoRelatado;
  final String? diagnosticoTecnico;
  final List<AtendimentoTecnicoItemInput> itens;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'descricao': descricao,
      'idCliente': idCliente,
      'nomeClienteSnapshot': nomeClienteSnapshot,
      'prioridadeId': prioridadeId,
      'prioridadeCodigo': prioridadeCodigo,
      'origemCodigo': origemCodigo,
      'validadeOrcamentoEm': _dateOnly(validadeOrcamentoEm),
      'equipamento': equipamento?.toJson(),
      'defeitoRelatado': defeitoRelatado,
      'diagnosticoTecnico': diagnosticoTecnico,
      'itens': itens.map((item) => item.toJson()).toList(),
    };
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
