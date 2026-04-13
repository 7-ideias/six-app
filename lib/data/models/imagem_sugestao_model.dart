class ImagemSugestaoRequest {
  ImagemSugestaoRequest({
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.tipo,
    this.quantidade = 6,
  });

  final String titulo;
  final String descricao;
  final String categoria;
  final String tipo;
  final int quantidade;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'tipo': tipo,
      'quantidade': quantidade,
    };
  }
}

class ImagemSugestaoResponse {
  ImagemSugestaoResponse({
    required this.tipo,
    required this.consultasExecutadas,
    required this.imagens,
  });

  final String tipo;
  final List<String> consultasExecutadas;
  final List<ImagemSugestao> imagens;

  factory ImagemSugestaoResponse.fromJson(Map<String, dynamic> json) {
    return ImagemSugestaoResponse(
      tipo: json['tipo']?.toString() ?? '',
      consultasExecutadas: (json['consultasExecutadas'] as List<dynamic>? ??
              const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      imagens: (json['imagens'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ImagemSugestao.fromJson)
          .toList(growable: false),
    );
  }
}

class ImagemSugestao {
  ImagemSugestao({
    required this.id,
    required this.urlMiniatura,
    required this.urlAlta,
    required this.urlPaginaPexels,
    required this.fotografo,
    required this.descricao,
    required this.largura,
    required this.altura,
    required this.score,
    required this.motivo,
  });

  final int id;
  final String urlMiniatura;
  final String urlAlta;
  final String urlPaginaPexels;
  final String fotografo;
  final String descricao;
  final int largura;
  final int altura;
  final double score;
  final String motivo;

  factory ImagemSugestao.fromJson(Map<String, dynamic> json) {
    return ImagemSugestao(
      id: (json['id'] as num?)?.toInt() ?? 0,
      urlMiniatura: json['urlMiniatura']?.toString() ?? '',
      urlAlta: json['urlAlta']?.toString() ?? '',
      urlPaginaPexels: json['urlPaginaPexels']?.toString() ?? '',
      fotografo: json['fotografo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      largura: (json['largura'] as num?)?.toInt() ?? 0,
      altura: (json['altura'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      motivo: json['motivo']?.toString() ?? '',
    );
  }
}
