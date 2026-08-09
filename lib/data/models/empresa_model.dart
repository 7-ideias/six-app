class EmpresaModel {
  final String nomeEmpresa;
  final String nomeFantasia;
  final String documentoNoBrasilCNPJ;
  final String? logoBase64;

  EmpresaModel({
    required this.nomeEmpresa,
    required this.nomeFantasia,
    required this.documentoNoBrasilCNPJ,
    this.logoBase64,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      nomeEmpresa: json['nomeEmpresa'] ?? '',
      nomeFantasia: json['nomeFantasia'] ?? '',
      documentoNoBrasilCNPJ: json['documentoNoBrasilCNPJ'] ?? '',
      logoBase64: _optionalString(json['logoBase64']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'nomeEmpresa': nomeEmpresa,
      'nomeFantasia': nomeFantasia,
      'documentoNoBrasilCNPJ': documentoNoBrasilCNPJ,
    };

    if (logoBase64 != null) {
      json['logoBase64'] = logoBase64;
    }

    return json;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}
