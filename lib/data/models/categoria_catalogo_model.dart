class CategoriaCatalogoModel {
  const CategoriaCatalogoModel({
    required this.id,
    required this.idUnicoDaEmpresa,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.ativo,
    required this.itensVinculados,
    this.criadoEm,
    this.atualizadoEm,
  });
  final String id;
  final String idUnicoDaEmpresa;
  final String nome;
  final String descricao;
  final String tipo;
  final bool ativo;
  final int itensVinculados;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  factory CategoriaCatalogoModel.fromJson(Map<String, dynamic> json) {
    return CategoriaCatalogoModel(
      id: json['id']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      tipo: _normalizarTipo(json['tipo']?.toString() ?? 'PRODUTO'),
      ativo: json['ativo'] != false,
      itensVinculados: (json['itensVinculados'] as num?)?.toInt() ?? 0,
      criadoEm: _dateFromJson(json['criadoEm']),
      atualizadoEm: _dateFromJson(json['atualizadoEm']),
    );
  }
  Map<String, dynamic> toRequestJson() {
    return <String, dynamic>{
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'ativo': ativo,
    };
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _normalizarTipo(String value) {
    final String normalizado = value.trim().toUpperCase();
    if (normalizado == 'SERVIÇO' ||
        normalizado == 'SERVIÇOS' ||
        normalizado == 'SERVICOS') {
      return 'SERVICO';
    }
    if (normalizado == 'PRODUTOS') return 'PRODUTO';
    if (normalizado == 'AMBOS') return 'AMBOS';
    if (normalizado == 'SERVICO') return 'SERVICO';
    return 'PRODUTO';
  }
}

class CategoriaCatalogoListResponse {
  const CategoriaCatalogoListResponse({
    required this.idUnicoDaEmpresa,
    required this.total,
    required this.categorias,
  });
  final String idUnicoDaEmpresa;
  final int total;
  final List<CategoriaCatalogoModel> categorias;
  factory CategoriaCatalogoListResponse.fromJson(Map<String, dynamic> json) {
    final dynamic categoriasJson = json['categorias'];
    return CategoriaCatalogoListResponse(
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      categorias:
          categoriasJson is List
              ? categoriasJson
                  .whereType<Map>()
                  .map(
                    (item) => CategoriaCatalogoModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList(growable: false)
              : const <CategoriaCatalogoModel>[],
    );
  }
}

class CategoriaCatalogoRequest {
  const CategoriaCatalogoRequest({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.ativo,
  });
  final String nome;
  final String descricao;
  final String tipo;
  final bool ativo;
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'ativo': ativo,
    };
  }
}
