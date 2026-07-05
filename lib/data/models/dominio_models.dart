class DominioOpcaoModel {
  const DominioOpcaoModel({
    required this.id,
    required this.grupo,
    required this.codigo,
    required this.i18nKey,
    required this.nomePadraoPtBr,
    required this.nomePadraoEnUs,
    required this.nomePadraoEsEs,
    required this.ordem,
    required this.cor,
    required this.icone,
    required this.finalizador,
  });

  final int id;
  final String grupo;
  final String codigo;
  final String i18nKey;
  final String nomePadraoPtBr;
  final String nomePadraoEnUs;
  final String nomePadraoEsEs;
  final int ordem;
  final String cor;
  final String icone;
  final bool finalizador;

  factory DominioOpcaoModel.fromJson(Map<String, dynamic> json) {
    return DominioOpcaoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      grupo: json['grupo']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      i18nKey: json['i18nKey']?.toString() ?? '',
      nomePadraoPtBr: json['nomePadraoPtBr']?.toString() ?? '',
      nomePadraoEnUs: json['nomePadraoEnUs']?.toString() ?? '',
      nomePadraoEsEs: json['nomePadraoEsEs']?.toString() ?? '',
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      cor: json['cor']?.toString() ?? '',
      icone: json['icone']?.toString() ?? '',
      finalizador: json['finalizador'] == true,
    );
  }
}

class AtendimentoTecnicoDominiosBaseModel {
  const AtendimentoTecnicoDominiosBaseModel({
    required this.tiposOperacao,
    required this.statusAtendimentoTecnico,
    required this.statusOrcamentoAtendimento,
    required this.tiposItem,
    required this.statusEstoqueAtendimento,
  });

  final List<DominioOpcaoModel> tiposOperacao;
  final List<DominioOpcaoModel> statusAtendimentoTecnico;
  final List<DominioOpcaoModel> statusOrcamentoAtendimento;
  final List<DominioOpcaoModel> tiposItem;
  final List<DominioOpcaoModel> statusEstoqueAtendimento;

  factory AtendimentoTecnicoDominiosBaseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtendimentoTecnicoDominiosBaseModel(
      tiposOperacao: _parseList(json['tiposOperacao']),
      statusAtendimentoTecnico: _parseList(json['statusAtendimentoTecnico']),
      statusOrcamentoAtendimento: _parseList(
        json['statusOrcamentoAtendimento'],
      ),
      tiposItem: _parseList(json['tiposItem']),
      statusEstoqueAtendimento: _parseList(json['statusEstoqueAtendimento']),
    );
  }

  static List<DominioOpcaoModel> _parseList(dynamic value) {
    if (value is! List) return <DominioOpcaoModel>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(DominioOpcaoModel.fromJson)
        .toList(growable: false);
  }
}
