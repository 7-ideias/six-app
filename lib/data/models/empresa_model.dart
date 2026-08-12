class EmpresaModel {
  final String nomeEmpresa;
  final String nomeFantasia;
  final String documentoNoBrasilCNPJ;
  final String? telefone;
  final String? whatsapp;
  final String? emailPrincipal;
  final String? siteEmpresa;
  final String? endereco;
  final String? logoBase64;

  EmpresaModel({
    required this.nomeEmpresa,
    required this.nomeFantasia,
    required this.documentoNoBrasilCNPJ,
    this.telefone,
    this.whatsapp,
    this.emailPrincipal,
    this.siteEmpresa,
    this.endereco,
    this.logoBase64,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      nomeEmpresa: json['nomeEmpresa'] ?? '',
      nomeFantasia: json['nomeFantasia'] ?? '',
      documentoNoBrasilCNPJ: json['documentoNoBrasilCNPJ'] ?? '',
      telefone: _optionalString(json['telefone']),
      whatsapp: _optionalString(json['whatsapp']),
      emailPrincipal: _optionalString(json['emailPrincipal']),
      siteEmpresa: _optionalString(json['siteEmpresa']),
      endereco: _optionalString(json['endereco']),
      logoBase64: _optionalString(json['logoBase64']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'nomeEmpresa': nomeEmpresa,
      'nomeFantasia': nomeFantasia,
      'documentoNoBrasilCNPJ': documentoNoBrasilCNPJ,
    };

    if (telefone != null) {
      json['telefone'] = telefone;
    }
    if (whatsapp != null) {
      json['whatsapp'] = whatsapp;
    }
    if (emailPrincipal != null) {
      json['emailPrincipal'] = emailPrincipal;
    }
    if (siteEmpresa != null) {
      json['siteEmpresa'] = siteEmpresa;
    }
    if (endereco != null) {
      json['endereco'] = endereco;
    }
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
