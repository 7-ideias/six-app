import 'dart:convert';

class ColaboradorUsuarioResumo {
  ColaboradorUsuarioResumo({
    required this.idUnicoPessoal,
    required this.nome,
    required this.nomeDeGuerra,
    required this.celularDeAcesso,
    required this.email,
    required this.foto,
    required this.dataCadastro,
  });

  final String idUnicoPessoal;
  final String nome;
  final String nomeDeGuerra;
  final String celularDeAcesso;
  final String email;
  final String foto;
  final DateTime? dataCadastro;

  factory ColaboradorUsuarioResumo.fromJson(Map<String, dynamic> json) {
    return ColaboradorUsuarioResumo(
      idUnicoPessoal: json['idUnicoPessoal']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      nomeDeGuerra: json['nomeDeGuerra']?.toString() ?? '',
      celularDeAcesso: json['celularDeAcesso']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      foto: json['foto']?.toString() ?? '',
      dataCadastro: DateTime.tryParse(json['dataCadastro']?.toString() ?? ''),
    );
  }

  ColaboradorUsuarioResumo copyWith({
    String? nome,
    String? nomeDeGuerra,
    String? celularDeAcesso,
    String? email,
    String? foto,
  }) {
    return ColaboradorUsuarioResumo(
      idUnicoPessoal: idUnicoPessoal,
      nome: nome ?? this.nome,
      nomeDeGuerra: nomeDeGuerra ?? this.nomeDeGuerra,
      celularDeAcesso: celularDeAcesso ?? this.celularDeAcesso,
      email: email ?? this.email,
      foto: foto ?? this.foto,
      dataCadastro: dataCadastro,
    );
  }
}

class ColaboradorUsuarioDetalhe {
  ColaboradorUsuarioDetalhe(this._json);

  final Map<String, dynamic> _json;

  factory ColaboradorUsuarioDetalhe.fromJson(Map<String, dynamic> json) {
    return ColaboradorUsuarioDetalhe(_deepCopyMap(json));
  }

  Map<String, dynamic> toJson() => _deepCopyMap(_json);

  String get idUnicoDoUsuario =>
      _ensureMap(
        _json['objInformacoesDoCadastro'],
      )['idUnicoDoUsuario']?.toString() ??
      '';

  String get nome => _ensureMap(_json['objPessoa'])['nome']?.toString() ?? '';

  String get nomeDeGuerra =>
      _ensureMap(_json['objPessoa'])['nomeDeGuerra']?.toString() ?? '';

  String get celularDeAcesso => _json['celularDeAcesso']?.toString() ?? '';

  String get email => _ensureMap(_json['objPessoa'])['email']?.toString() ?? '';

  static Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
