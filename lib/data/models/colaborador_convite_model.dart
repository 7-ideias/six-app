class ColaboradorConviteRequest {
  const ColaboradorConviteRequest({
    required this.nome,
    required this.email,
    required this.celular,
    required this.permissoes,
  });

  final String nome;
  final String email;
  final String celular;
  final List<String> permissoes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nome': nome,
      'email': email,
      'celular': celular,
      'permissoes': permissoes,
    };
  }
}

class ColaboradorConviteResponse {
  const ColaboradorConviteResponse({
    required this.id,
    required this.emailConvidado,
    required this.nomeConvidado,
    required this.idUnicoDaEmpresa,
    required this.nomeFantasia,
    required this.papel,
    required this.status,
    required this.permissoes,
    required this.codigo,
    required this.expiraEm,
  });

  final String id;
  final String emailConvidado;
  final String nomeConvidado;
  final String idUnicoDaEmpresa;
  final String nomeFantasia;
  final String papel;
  final String status;
  final List<String> permissoes;
  final String codigo;
  final DateTime? expiraEm;

  factory ColaboradorConviteResponse.fromJson(Map<String, dynamic> json) {
    return ColaboradorConviteResponse(
      id: json['id']?.toString() ?? '',
      emailConvidado: json['emailConvidado']?.toString() ?? '',
      nomeConvidado: json['nomeConvidado']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      papel: json['papel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      permissoes: (json['permissoes'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      codigo: json['token']?.toString() ?? '',
      expiraEm: DateTime.tryParse(json['expiraEm']?.toString() ?? ''),
    );
  }
}

class ColaboradorConvitePublicoResponse {
  const ColaboradorConvitePublicoResponse({
    required this.emailConvidado,
    required this.nomeConvidado,
    required this.idUnicoDaEmpresa,
    required this.nomeFantasia,
    required this.status,
    required this.expiraEm,
  });

  final String emailConvidado;
  final String nomeConvidado;
  final String idUnicoDaEmpresa;
  final String nomeFantasia;
  final String status;
  final DateTime? expiraEm;

  factory ColaboradorConvitePublicoResponse.fromJson(Map<String, dynamic> json) {
    return ColaboradorConvitePublicoResponse(
      emailConvidado: json['emailConvidado']?.toString() ?? '',
      nomeConvidado: json['nomeConvidado']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      expiraEm: DateTime.tryParse(json['expiraEm']?.toString() ?? ''),
    );
  }
}

class EmpresaVinculoWebModel {
  const EmpresaVinculoWebModel({
    required this.idUnicoDaEmpresa,
    required this.nomeFantasia,
    required this.papel,
    required this.status,
    required this.permissoes,
  });

  final String idUnicoDaEmpresa;
  final String nomeFantasia;
  final String papel;
  final String status;
  final List<String> permissoes;

  factory EmpresaVinculoWebModel.fromJson(Map<String, dynamic> json) {
    return EmpresaVinculoWebModel(
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      papel: json['papel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      permissoes: (json['permissoes'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }

  bool get ativo => status.toUpperCase() == 'ATIVO';
  bool get administrador => papel.toUpperCase() == 'ADMINISTRADOR';

  bool pode(String permissao) {
    if (!ativo) {
      return false;
    }
    if (administrador || permissoes.contains('TODAS')) {
      return true;
    }
    return permissoes.contains(permissao);
  }
}
