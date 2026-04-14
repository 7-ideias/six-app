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
    return ProdutoImagemModel(
      id: json['id']?.toString(),
      url: json['url']?.toString(),
      urlMiniatura: json['urlMiniatura']?.toString(),
      origem: json['origem']?.toString() ?? 'UPLOAD',
      nomeArquivo: json['nomeArquivo']?.toString(),
      imagemBase64: json['imagemBase64']?.toString(),
      sugestaoId: json['sugestaoId'] != null
          ? int.tryParse(json['sugestaoId'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'origem': origem,
    };

    if (id != null) data['id'] = id;
    if (url != null) data['url'] = url;
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
