class AuthResponseModel {
  final String accessToken;
  final List<String> idUnicoDaEmpresa;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final UsuarioModel usuario;

  AuthResponseModel({
    required this.accessToken,
    required this.idUnicoDaEmpresa,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.usuario,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] ?? '',
      idUnicoDaEmpresa: List<String>.from(json['idUnicoDaEmpresa'] ?? []),
      refreshToken: json['refreshToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      tokenType: json['tokenType'] ?? '',
      usuario: UsuarioModel.fromJson(json['usuario'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'idUnicoDaEmpresa': idUnicoDaEmpresa,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
      'usuario': usuario.toJson(),
    };
  }
}

class UsuarioModel {
  final String id;
  final String keycloakId;
  final String nome;
  final String email;
  final List<String> permissoes;

  UsuarioModel({
    required this.id,
    required this.keycloakId,
    required this.nome,
    required this.email,
    required this.permissoes,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] ?? '',
      keycloakId: json['keycloakId'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      permissoes: List<String>.from(json['permissoes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keycloakId': keycloakId,
      'nome': nome,
      'email': email,
      'permissoes': permissoes,
    };
  }
}
