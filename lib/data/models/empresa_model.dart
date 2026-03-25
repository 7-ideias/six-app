class EmpresaModel {
  final String nomeEmpresa;
  final String nomeFantasia;
  final String documentoNoBrasilCNPJ;

  EmpresaModel({
    required this.nomeEmpresa,
    required this.nomeFantasia,
    required this.documentoNoBrasilCNPJ,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      nomeEmpresa: json['nomeEmpresa'] ?? '',
      nomeFantasia: json['nomeFantasia'] ?? '',
      documentoNoBrasilCNPJ: json['documentoNoBrasilCNPJ'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomeEmpresa': nomeEmpresa,
      'nomeFantasia': nomeFantasia,
      'documentoNoBrasilCNPJ': documentoNoBrasilCNPJ,
    };
  }
}
