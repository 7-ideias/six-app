class AiAssistantRequestModel {
  AiAssistantRequestModel({
    required this.pergunta,
    required this.idioma,
    required this.plataforma,
    required this.modulo,
    required this.telaAtual,
    required this.perfilUsuario,
    required this.permissoes,
  });

  final String pergunta;
  final String idioma;
  final String plataforma;
  final String modulo;
  final String telaAtual;
  final String perfilUsuario;
  final List<String> permissoes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pergunta': pergunta,
    'idioma': idioma,
    'plataforma': plataforma,
    'modulo': modulo,
    'telaAtual': telaAtual,
    'perfilUsuario': perfilUsuario,
    'permissoes': permissoes,
  };
}

class AiAssistantActionModel {
  AiAssistantActionModel({required this.label, required this.rota, required this.tipo});
  final String label;
  final String rota;
  final String tipo;

  factory AiAssistantActionModel.fromJson(Map<String, dynamic> json) => AiAssistantActionModel(
    label: json['label']?.toString() ?? '',
    rota: json['rota']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? '',
  );
}

class AiAssistantResponseModel {
  AiAssistantResponseModel({
    required this.resposta,
    required this.exemplos,
    required this.acoes,
    required this.fontes,
    required this.confianca,
  });

  final String resposta;
  final List<String> exemplos;
  final List<AiAssistantActionModel> acoes;
  final List<String> fontes;
  final String confianca;

  factory AiAssistantResponseModel.fromJson(Map<String, dynamic> json) {
    final dynamic acoesRaw = json['acoes'];
    return AiAssistantResponseModel(
      resposta: json['resposta']?.toString() ?? '',
      exemplos: (json['exemplos'] as List<dynamic>? ?? <dynamic>[]).map((dynamic item) => item.toString()).toList(growable: false),
      acoes: acoesRaw is List
          ? acoesRaw.whereType<Map<String, dynamic>>().map(AiAssistantActionModel.fromJson).toList(growable: false)
          : <AiAssistantActionModel>[],
      fontes: (json['fontes'] as List<dynamic>? ?? <dynamic>[]).map((dynamic item) => item.toString()).toList(growable: false),
      confianca: json['confianca']?.toString() ?? '',
    );
  }
}

class AiAssistantFeedbackRequestModel {
  AiAssistantFeedbackRequestModel({
    required this.pergunta,
    required this.resposta,
    required this.util,
    this.motivo,
    this.comentario,
    this.modulo,
    this.telaAtual,
    this.plataforma,
    this.idioma,
  });

  final String pergunta;
  final String resposta;
  final bool util;
  final String? motivo;
  final String? comentario;
  final String? modulo;
  final String? telaAtual;
  final String? plataforma;
  final String? idioma;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pergunta': pergunta,
    'resposta': resposta,
    'util': util,
    'motivo': motivo,
    'comentario': comentario,
    'modulo': modulo,
    'telaAtual': telaAtual,
    'plataforma': plataforma,
    'idioma': idioma,
  };
}

class AiAssistantSuggestionRequestModel {
  AiAssistantSuggestionRequestModel({
    required this.descricao,
    required this.idioma,
    required this.plataforma,
    required this.modulo,
    required this.telaAtual,
  });

  final String descricao;
  final String idioma;
  final String plataforma;
  final String modulo;
  final String telaAtual;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'descricao': descricao,
    'idioma': idioma,
    'plataforma': plataforma,
    'modulo': modulo,
    'telaAtual': telaAtual,
  };
}
