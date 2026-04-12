class ClienteUsuarioListResponse {
  ClienteUsuarioListResponse({
    required this.idUnicoDaEmpresa,
    required this.total,
    required this.clientes,
  });

  final String idUnicoDaEmpresa;
  final int total;
  final List<ClienteUsuario> clientes;

  factory ClienteUsuarioListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawClientes =
        (json['clientes'] as List<dynamic>?) ?? <dynamic>[];

    return ClienteUsuarioListResponse(
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? rawClientes.length,
      clientes: rawClientes
          .whereType<Map<String, dynamic>>()
          .map(ClienteUsuario.fromJson)
          .toList(growable: false),
    );
  }
}

class ClienteUsuario {
  ClienteUsuario({
    required this.id,
    required this.idUsuario,
    required this.idUnicoDaEmpresa,
    required this.ativo,
    required this.tipoPessoa,
    required this.documento,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.observacoes,
    required this.origemAutoCadastro,
    required this.enviadoEm,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.foto,
  });

  final String id;
  final String idUsuario;
  final String idUnicoDaEmpresa;
  final bool ativo;
  final String tipoPessoa;
  final String documento;
  final String nome;
  final String telefone;
  final String email;
  final String observacoes;
  final bool origemAutoCadastro;
  final DateTime? enviadoEm;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final String foto;

  factory ClienteUsuario.fromJson(Map<String, dynamic> json) {
    return ClienteUsuario(
      id: json['id']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      ativo: _parseBool(json['ativo']),
      tipoPessoa: json['tipoPessoa']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      observacoes: json['observacoes']?.toString() ?? '',
      origemAutoCadastro: _parseBool(json['origemAutoCadastro']),
      enviadoEm: _parseDateTime(json['enviadoEm']),
      criadoEm: _parseDateTime(json['criadoEm']),
      atualizadoEm: _parseDateTime(json['atualizadoEm']),
      foto: json['foto']?.toString() ?? '',
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().toLowerCase().trim() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'sim';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
