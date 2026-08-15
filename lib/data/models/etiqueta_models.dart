class EtiquetaModelo {
  const EtiquetaModelo({
    this.id,
    required this.nome,
    this.descricao = '',
    this.ativo = true,
    required this.papel,
    required this.grade,
    required this.etiqueta,
    this.elementos = const <EtiquetaElemento>[],
    this.criadoEm,
    this.atualizadoEm,
  });

  final String? id;
  final String nome;
  final String descricao;
  final bool ativo;
  final EtiquetaPapel papel;
  final EtiquetaGrade grade;
  final EtiquetaTamanho etiqueta;
  final List<EtiquetaElemento> elementos;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  factory EtiquetaModelo.fromJson(Map<String, dynamic> json) {
    return EtiquetaModelo(
      id: _textOrNull(json['id']),
      nome: _text(json['nome']),
      descricao: _text(json['descricao']),
      ativo: _bool(json['ativo'], fallback: true),
      papel: EtiquetaPapel.fromJson(_map(json['papel'])),
      grade: EtiquetaGrade.fromJson(_map(json['grade'])),
      etiqueta: EtiquetaTamanho.fromJson(_map(json['etiqueta'])),
      elementos: _list(json['elementos'])
          .whereType<Map>()
          .map((Map value) => EtiquetaElemento.fromJson(
                value.map((dynamic key, dynamic value) =>
                    MapEntry<String, dynamic>(key.toString(), value)),
              ))
          .toList(growable: false),
      criadoEm: _date(json['criadoEm']),
      atualizadoEm: _date(json['atualizadoEm']),
    );
  }

  Map<String, dynamic> toJson({bool includeServerFields = true}) {
    return <String, dynamic>{
      if (includeServerFields && id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'papel': papel.toJson(),
      'grade': grade.toJson(),
      'etiqueta': etiqueta.toJson(),
      'elementos': elementos.map((EtiquetaElemento e) => e.toJson()).toList(),
      if (includeServerFields && criadoEm != null)
        'criadoEm': criadoEm!.toUtc().toIso8601String(),
      if (includeServerFields && atualizadoEm != null)
        'atualizadoEm': atualizadoEm!.toUtc().toIso8601String(),
    };
  }

  EtiquetaModelo copyWith({
    String? id,
    bool clearId = false,
    String? nome,
    String? descricao,
    bool? ativo,
    EtiquetaPapel? papel,
    EtiquetaGrade? grade,
    EtiquetaTamanho? etiqueta,
    List<EtiquetaElemento>? elementos,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return EtiquetaModelo(
      id: clearId ? null : id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      papel: papel ?? this.papel,
      grade: grade ?? this.grade,
      etiqueta: etiqueta ?? this.etiqueta,
      elementos: elementos ?? this.elementos,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}

class EtiquetaPapel {
  const EtiquetaPapel({
    required this.preset,
    required this.larguraMm,
    required this.alturaMm,
    this.orientacao = 'PORTRAIT',
  });

  final String preset;
  final double larguraMm;
  final double alturaMm;
  final String orientacao;

  factory EtiquetaPapel.fromJson(Map<String, dynamic> json) => EtiquetaPapel(
        preset: _text(json['preset'], fallback: 'CUSTOM'),
        larguraMm: _number(json['larguraMm'], 210),
        alturaMm: _number(json['alturaMm'], 297),
        orientacao: _text(json['orientacao'], fallback: 'PORTRAIT'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'preset': preset,
        'larguraMm': larguraMm,
        'alturaMm': alturaMm,
        'orientacao': orientacao,
      };

  EtiquetaPapel copyWith({
    String? preset,
    double? larguraMm,
    double? alturaMm,
    String? orientacao,
  }) =>
      EtiquetaPapel(
        preset: preset ?? this.preset,
        larguraMm: larguraMm ?? this.larguraMm,
        alturaMm: alturaMm ?? this.alturaMm,
        orientacao: orientacao ?? this.orientacao,
      );
}

class EtiquetaGrade {
  const EtiquetaGrade({
    required this.colunas,
    required this.linhas,
    this.margemSuperiorMm = 0,
    this.margemInferiorMm = 0,
    this.margemEsquerdaMm = 0,
    this.margemDireitaMm = 0,
    this.espacamentoHorizontalMm = 0,
    this.espacamentoVerticalMm = 0,
  });

  final int colunas;
  final int linhas;
  final double margemSuperiorMm;
  final double margemInferiorMm;
  final double margemEsquerdaMm;
  final double margemDireitaMm;
  final double espacamentoHorizontalMm;
  final double espacamentoVerticalMm;

  factory EtiquetaGrade.fromJson(Map<String, dynamic> json) => EtiquetaGrade(
        colunas: _integer(json['colunas'], 1),
        linhas: _integer(json['linhas'], 1),
        margemSuperiorMm: _number(json['margemSuperiorMm'], 0),
        margemInferiorMm: _number(json['margemInferiorMm'], 0),
        margemEsquerdaMm: _number(json['margemEsquerdaMm'], 0),
        margemDireitaMm: _number(json['margemDireitaMm'], 0),
        espacamentoHorizontalMm:
            _number(json['espacamentoHorizontalMm'], 0),
        espacamentoVerticalMm: _number(json['espacamentoVerticalMm'], 0),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'colunas': colunas,
        'linhas': linhas,
        'margemSuperiorMm': margemSuperiorMm,
        'margemInferiorMm': margemInferiorMm,
        'margemEsquerdaMm': margemEsquerdaMm,
        'margemDireitaMm': margemDireitaMm,
        'espacamentoHorizontalMm': espacamentoHorizontalMm,
        'espacamentoVerticalMm': espacamentoVerticalMm,
      };

  EtiquetaGrade copyWith({
    int? colunas,
    int? linhas,
    double? margemSuperiorMm,
    double? margemInferiorMm,
    double? margemEsquerdaMm,
    double? margemDireitaMm,
    double? espacamentoHorizontalMm,
    double? espacamentoVerticalMm,
  }) =>
      EtiquetaGrade(
        colunas: colunas ?? this.colunas,
        linhas: linhas ?? this.linhas,
        margemSuperiorMm: margemSuperiorMm ?? this.margemSuperiorMm,
        margemInferiorMm: margemInferiorMm ?? this.margemInferiorMm,
        margemEsquerdaMm: margemEsquerdaMm ?? this.margemEsquerdaMm,
        margemDireitaMm: margemDireitaMm ?? this.margemDireitaMm,
        espacamentoHorizontalMm:
            espacamentoHorizontalMm ?? this.espacamentoHorizontalMm,
        espacamentoVerticalMm:
            espacamentoVerticalMm ?? this.espacamentoVerticalMm,
      );
}

class EtiquetaTamanho {
  const EtiquetaTamanho({required this.larguraMm, required this.alturaMm});

  final double larguraMm;
  final double alturaMm;

  factory EtiquetaTamanho.fromJson(Map<String, dynamic> json) => EtiquetaTamanho(
        larguraMm: _number(json['larguraMm'], 50),
        alturaMm: _number(json['alturaMm'], 30),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'larguraMm': larguraMm,
        'alturaMm': alturaMm,
      };

  EtiquetaTamanho copyWith({double? larguraMm, double? alturaMm}) =>
      EtiquetaTamanho(
        larguraMm: larguraMm ?? this.larguraMm,
        alturaMm: alturaMm ?? this.alturaMm,
      );
}

class EtiquetaElemento {
  const EtiquetaElemento({
    required this.id,
    required this.tipo,
    required this.bindingKey,
    required this.xMm,
    required this.yMm,
    required this.larguraMm,
    required this.alturaMm,
    this.zIndex = 0,
    this.propriedades = const <String, dynamic>{},
  });

  final String id;
  final String tipo;
  final String bindingKey;
  final double xMm;
  final double yMm;
  final double larguraMm;
  final double alturaMm;
  final int zIndex;
  final Map<String, dynamic> propriedades;

  factory EtiquetaElemento.fromJson(Map<String, dynamic> json) =>
      EtiquetaElemento(
        id: _text(json['id']),
        tipo: _text(json['tipo'], fallback: 'TEXT'),
        bindingKey: _text(json['bindingKey'], fallback: 'FREE_TEXT'),
        xMm: _number(json['xMm'] ?? json['XMm'], 0),
        yMm: _number(json['yMm'] ?? json['YMm'], 0),
        larguraMm: _number(json['larguraMm'], 20),
        alturaMm: _number(json['alturaMm'], 5),
        zIndex: _integer(json['zIndex'], 0),
        propriedades: Map<String, dynamic>.from(_map(json['propriedades'])),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'tipo': tipo,
        'bindingKey': bindingKey,
        'xMm': xMm,
        'yMm': yMm,
        'larguraMm': larguraMm,
        'alturaMm': alturaMm,
        'zIndex': zIndex,
        'propriedades': propriedades,
      };

  EtiquetaElemento copyWith({
    String? id,
    String? tipo,
    String? bindingKey,
    double? xMm,
    double? yMm,
    double? larguraMm,
    double? alturaMm,
    int? zIndex,
    Map<String, dynamic>? propriedades,
  }) =>
      EtiquetaElemento(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        bindingKey: bindingKey ?? this.bindingKey,
        xMm: xMm ?? this.xMm,
        yMm: yMm ?? this.yMm,
        larguraMm: larguraMm ?? this.larguraMm,
        alturaMm: alturaMm ?? this.alturaMm,
        zIndex: zIndex ?? this.zIndex,
        propriedades: propriedades ?? this.propriedades,
      );
}

class EtiquetaImpressaoItem {
  const EtiquetaImpressaoItem({required this.sourceId, required this.quantidade});

  final String sourceId;
  final int quantidade;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sourceId': sourceId,
        'quantidade': quantidade,
      };
}

class EtiquetaPdfResponse {
  const EtiquetaPdfResponse({
    required this.arquivoBase64,
    required this.nomeArquivo,
    required this.mimeType,
    required this.totalEtiquetas,
    required this.totalPaginas,
  });

  final String arquivoBase64;
  final String nomeArquivo;
  final String mimeType;
  final int totalEtiquetas;
  final int totalPaginas;

  factory EtiquetaPdfResponse.fromJson(Map<String, dynamic> json) =>
      EtiquetaPdfResponse(
        arquivoBase64: _text(json['arquivoBase64']),
        nomeArquivo: _text(json['nomeArquivo'], fallback: 'etiquetas.pdf'),
        mimeType: _text(json['mimeType'], fallback: 'application/pdf'),
        totalEtiquetas: _integer(json['totalEtiquetas'], 0),
        totalPaginas: _integer(json['totalPaginas'], 0),
      );
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((dynamic key, dynamic value) =>
        MapEntry<String, dynamic>(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : <dynamic>[];
String _text(dynamic value, {String fallback = ''}) =>
    value?.toString() ?? fallback;
String? _textOrNull(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

double _number(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _integer(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}

DateTime? _date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
