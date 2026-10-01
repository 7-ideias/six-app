class PerfilNegocioModel {
  PerfilNegocioModel({
    required this.segmentoPrincipal,
    this.subsegmento,
    this.descricaoOutro,
    required Iterable<String> atividades,
    required this.objetivoPrincipal,
  }) : atividades = Set<String>.unmodifiable(atividades);

  final String segmentoPrincipal;
  final String? subsegmento;
  final String? descricaoOutro;
  final Set<String> atividades;
  final String objetivoPrincipal;

  factory PerfilNegocioModel.fromJson(Map<String, dynamic> json) => PerfilNegocioModel(
    segmentoPrincipal: json['segmentoPrincipal']?.toString() ?? 'OUTRO',
    subsegmento: json['subsegmento']?.toString(),
    descricaoOutro: json['descricaoOutro']?.toString(),
    atividades: (json['atividades'] as List<dynamic>? ?? const []).whereType<String>(),
    objetivoPrincipal: json['objetivoPrincipal']?.toString() ?? 'GERAL',
  );

  Map<String, dynamic> toJson() => {
    'segmentoPrincipal': segmentoPrincipal,
    'subsegmento': subsegmento,
    'descricaoOutro': descricaoOutro,
    'atividades': atividades.toList(growable: false),
    'objetivoPrincipal': objetivoPrincipal,
  };
}

class AtualizarPerfilNegocioRequest {
  const AtualizarPerfilNegocioRequest({required this.perfil, this.versao});
  final PerfilNegocioModel perfil;
  final int? versao;
  Map<String, dynamic> toJson() => {'perfil': perfil.toJson(), 'versao': versao};
}

class PerfilNegocioEmpresaModel {
  const PerfilNegocioEmpresaModel({
    required this.perfil,
    required this.configurado,
    required this.podeEditar,
    this.versao,
  });
  final PerfilNegocioModel perfil;
  final bool configurado;
  final bool podeEditar;
  final int? versao;
  factory PerfilNegocioEmpresaModel.fromJson(Map<String, dynamic> json) => PerfilNegocioEmpresaModel(
    perfil: PerfilNegocioModel.fromJson(Map<String, dynamic>.from(json['perfil'] as Map)),
    configurado: json['configurado'] == true,
    podeEditar: json['podeEditar'] == true,
    versao: (json['versao'] as num?)?.toInt(),
  );
}

class SegmentoNegocioModel {
  const SegmentoNegocioModel({required this.codigo, required this.subsegmentos});
  final String codigo;
  final List<String> subsegmentos;
}

class CatalogoPerfilNegocioModel {
  const CatalogoPerfilNegocioModel({
    required this.segmentos, required this.atividades, required this.objetivos,
  });
  final List<SegmentoNegocioModel> segmentos;
  final List<String> atividades;
  final List<String> objetivos;
  factory CatalogoPerfilNegocioModel.fromJson(Map<String, dynamic> json) => CatalogoPerfilNegocioModel(
    segmentos: List<SegmentoNegocioModel>.unmodifiable(
      (json['segmentos'] as List<dynamic>).map((dynamic item) {
        final map = Map<String, dynamic>.from(item as Map);
        return SegmentoNegocioModel(
          codigo: map['codigo'] as String,
          subsegmentos: List<String>.unmodifiable((map['subsegmentos'] as List<dynamic>).cast<String>()),
        );
      }),
    ),
    atividades: List<String>.unmodifiable((json['atividades'] as List<dynamic>).cast<String>()),
    objetivos: List<String>.unmodifiable((json['objetivos'] as List<dynamic>).cast<String>()),
  );
}

class BannerHomeModel {
  const BannerHomeModel({
    required this.id, required this.tema, this.imagemUrl800, this.imagemUrl1200,
  });
  final String id;
  final String tema;
  final String? imagemUrl800;
  final String? imagemUrl1200;
  factory BannerHomeModel.fromJson(Map<String, dynamic> json) => BannerHomeModel(
    id: json['id'] as String,
    tema: json['tema'] as String,
    imagemUrl800: _https(json['imagemUrl800']),
    imagemUrl1200: _https(json['imagemUrl1200']),
  );

  String? imagemPara(double larguraFisica) => larguraFisica > 800
      ? imagemUrl1200 ?? imagemUrl800 : imagemUrl800 ?? imagemUrl1200;

  static String? _https(dynamic value) {
    final url = value is String ? Uri.tryParse(value) : null;
    return url != null && url.scheme == 'https' && url.host.isNotEmpty && url.userInfo.isEmpty
        ? url.toString() : null;
  }
}

class HomeBannersModel {
  const HomeBannersModel({required this.perfilNegocio, required this.banners});
  final PerfilNegocioEmpresaModel perfilNegocio;
  final List<BannerHomeModel> banners;
  factory HomeBannersModel.fromJson(Map<String, dynamic> json) => HomeBannersModel(
    perfilNegocio: PerfilNegocioEmpresaModel.fromJson(Map<String, dynamic>.from(json['perfilNegocio'] as Map)),
    banners: List<BannerHomeModel>.unmodifiable((json['banners'] as List<dynamic>)
        .map((dynamic item) => BannerHomeModel.fromJson(Map<String, dynamic>.from(item as Map)))),
  );
}
