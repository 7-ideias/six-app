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

class ClienteUsuarioRequest {
  ClienteUsuarioRequest({
    required this.ativo,
    required this.tipoPessoa,
    required this.documento,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.observacoes,
    required this.foto,
    required this.permiteCompraFiado,
    required this.limiteFiado,
    required this.prazoPagamentoDias,
    required this.bloqueadoFiado,
  });

  final bool ativo;
  final String tipoPessoa;
  final String documento;
  final String nome;
  final String telefone;
  final String email;
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String observacoes;
  final String foto;
  final bool permiteCompraFiado;
  final double limiteFiado;
  final int prazoPagamentoDias;
  final bool bloqueadoFiado;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ativo': ativo,
      'tipoPessoa': tipoPessoa,
      'documento': documento,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
      'observacoes': observacoes,
      'foto': foto,
      'permiteCompraFiado': permiteCompraFiado,
      'limiteFiado': limiteFiado,
      'prazoPagamentoDias': prazoPagamentoDias,
      'bloqueadoFiado': bloqueadoFiado,
    };
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
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.observacoes,
    required this.origemAutoCadastro,
    required this.enviadoEm,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.foto,
    required this.permiteCompraFiado,
    required this.limiteFiado,
    required this.saldoFiado,
    required this.prazoPagamentoDias,
    required this.bloqueadoFiado,
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
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String observacoes;
  final String origemAutoCadastro;
  final DateTime? enviadoEm;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final String foto;
  final bool permiteCompraFiado;
  final double limiteFiado;
  final double saldoFiado;
  final int prazoPagamentoDias;
  final bool bloqueadoFiado;

  factory ClienteUsuario.fromJson(Map<String, dynamic> json) {
    return ClienteUsuario(
      id: json['id']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      ativo: _parseBool(json['ativo'], fallback: true),
      tipoPessoa: json['tipoPessoa']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cep: json['cep']?.toString() ?? '',
      logradouro: json['logradouro']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      complemento: json['complemento']?.toString() ?? '',
      bairro: json['bairro']?.toString() ?? '',
      cidade: json['cidade']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
      observacoes: json['observacoes']?.toString() ?? '',
      origemAutoCadastro: json['origemAutoCadastro']?.toString() ?? '',
      enviadoEm: _parseDateTime(json['enviadoEm']),
      criadoEm: _parseDateTime(json['criadoEm']),
      atualizadoEm: _parseDateTime(json['atualizadoEm']),
      foto: json['foto']?.toString() ?? '',
      permiteCompraFiado: _parseBool(json['permiteCompraFiado']),
      limiteFiado: _parseDouble(json['limiteFiado']),
      saldoFiado: _parseDouble(json['saldoFiado']),
      prazoPagamentoDias: _parseInt(json['prazoPagamentoDias']),
      bloqueadoFiado: _parseBool(json['bloqueadoFiado']),
    );
  }

  ClienteUsuarioRequest toRequest() {
    return ClienteUsuarioRequest(
      ativo: ativo,
      tipoPessoa: tipoPessoa.isEmpty ? 'PF' : tipoPessoa,
      documento: documento,
      nome: nome,
      telefone: telefone,
      email: email,
      cep: cep,
      logradouro: logradouro,
      numero: numero,
      complemento: complemento,
      bairro: bairro,
      cidade: cidade,
      uf: uf,
      observacoes: observacoes,
      foto: foto,
      permiteCompraFiado: permiteCompraFiado,
      limiteFiado: limiteFiado,
      prazoPagamentoDias: prazoPagamentoDias,
      bloqueadoFiado: bloqueadoFiado,
    );
  }

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().toLowerCase().trim() ?? '';
    if (normalized == 'true' || normalized == '1' || normalized == 'sim') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'nao' || normalized == 'não') {
      return false;
    }
    return fallback;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
