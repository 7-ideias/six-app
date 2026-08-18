class CatalogoPublicoLinkModel {
  const CatalogoPublicoLinkModel({
    required this.token,
    required this.url,
    this.criadoEm,
  });

  final String token;
  final String url;
  final DateTime? criadoEm;

  factory CatalogoPublicoLinkModel.fromJson(Map<String, dynamic> json) {
    return CatalogoPublicoLinkModel(
      token: json['token']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? ''),
    );
  }
}
