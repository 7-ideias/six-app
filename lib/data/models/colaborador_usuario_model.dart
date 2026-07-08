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
    this.status = 'ATIVO',
    this.ativo = true,
  });

  final String idUnicoPessoal;
  final String nome;
  final String nomeDeGuerra;
  final String celularDeAcesso;
  final String email;
  final String foto;
  final DateTime? dataCadastro;
  final String status;
  final bool ativo;

  factory ColaboradorUsuarioResumo.fromJson(Map<String, dynamic> json) {
    final String status = json['status']?.toString() ?? 'ATIVO';
    return ColaboradorUsuarioResumo(
      idUnicoPessoal: json['idUnicoPessoal']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      nomeDeGuerra: json['nomeDeGuerra']?.toString() ?? '',
      celularDeAcesso: json['celularDeAcesso']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      foto: json['foto']?.toString() ?? '',
      dataCadastro: DateTime.tryParse(json['dataCadastro']?.toString() ?? ''),
      status: status,
      ativo: _toBool(json['ativo'], fallback: status.toUpperCase() == 'ATIVO'),
    );
  }

  ColaboradorUsuarioResumo copyWith({
    String? nome,
    String? nomeDeGuerra,
    String? celularDeAcesso,
    String? email,
    String? foto,
    String? status,
    bool? ativo,
  }) {
    return ColaboradorUsuarioResumo(
      idUnicoPessoal: idUnicoPessoal,
      nome: nome ?? this.nome,
      nomeDeGuerra: nomeDeGuerra ?? this.nomeDeGuerra,
      celularDeAcesso: celularDeAcesso ?? this.celularDeAcesso,
      email: email ?? this.email,
      foto: foto ?? this.foto,
      dataCadastro: dataCadastro,
      status: status ?? this.status,
      ativo: ativo ?? this.ativo,
    );
  }

  static bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized == 'true' || normalized == '1' || normalized == 'sim') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'nao' || normalized == 'não') {
      return false;
    }
    return fallback;
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
