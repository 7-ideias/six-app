class ProdutoImagemModel {
  ProdutoImagemModel({
    this.id,
    this.url,
    this.urlMiniatura,
    required this.origem,
    this.nomeArquivo,
    this.imagemBase64,
    this.sugestaoId,
  });

  final String? id;
  final String? url;
  final String? urlMiniatura;
  final String origem;
  final String? nomeArquivo;
  final String? imagemBase64;
  final int? sugestaoId;

  factory ProdutoImagemModel.fromJson(Map<String, dynamic> json) {
    final String? imagemBase64 = _stringOrNull(json['imagemBase64']);
    final String? url = _resolverUrlDaImagem(
      _stringOrNull(json['url']),
      imagemBase64,
    );

    return ProdutoImagemModel(
      id: _stringOrNull(json['id']),
      url: url,
      urlMiniatura: _stringOrNull(json['urlMiniatura']),
      origem: _stringOrNull(json['origem']) ?? 'UPLOAD',
      nomeArquivo: _stringOrNull(json['nomeArquivo']),
      imagemBase64: imagemBase64,
      sugestaoId: json['sugestaoId'] != null
          ? int.tryParse(json['sugestaoId'].toString())
          : null,
    );
  }

  static String? _resolverUrlDaImagem(String? url, String? imagemBase64) {
    if (url != null && url.isNotEmpty) {
      return url;
    }

    if (imagemBase64 == null || imagemBase64.isEmpty) {
      return null;
    }

    if (imagemBase64.startsWith('data:image')) {
      return imagemBase64;
    }

    return 'data:image/png;base64,$imagemBase64';
  }

  static String? _stringOrNull(dynamic value) {
    final String? text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'origem': origem,
    };

    if (id != null) data['id'] = id;
    if (url != null && !(url!.startsWith('data:image') && imagemBase64 != null)) {
      data['url'] = url;
    }
    if (urlMiniatura != null) data['urlMiniatura'] = urlMiniatura;
    if (nomeArquivo != null) data['nomeArquivo'] = nomeArquivo;
    if (imagemBase64 != null) data['imagemBase64'] = imagemBase64;
    if (sugestaoId != null) data['sugestaoId'] = sugestaoId;
    return data;
  }

  ProdutoImagemModel copyWith({
    String? id,
    String? url,
    String? urlMiniatura,
    String? origem,
    String? nomeArquivo,
    String? imagemBase64,
    int? sugestaoId,
  }) {
    return ProdutoImagemModel(
      id: id ?? this.id,
      url: url ?? this.url,
      urlMiniatura: urlMiniatura ?? this.urlMiniatura,
      origem: origem ?? this.origem,
      nomeArquivo: nomeArquivo ?? this.nomeArquivo,
      imagemBase64: imagemBase64 ?? this.imagemBase64,
      sugestaoId: sugestaoId ?? this.sugestaoId,
    );
  }
}
