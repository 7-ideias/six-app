enum CatalogoPublicoEstilo {
  classico('CLASSICO'),
  minimalista('MINIMALISTA'),
  expressivo('EXPRESSIVO');

  const CatalogoPublicoEstilo(this.apiValue);

  final String apiValue;

  static CatalogoPublicoEstilo fromApi(dynamic value) {
    final String normalized = value?.toString().trim().toUpperCase() ?? '';
    return CatalogoPublicoEstilo.values.firstWhere(
      (CatalogoPublicoEstilo item) => item.apiValue == normalized,
      orElse: () => CatalogoPublicoEstilo.classico,
    );
  }
}

enum CatalogoPublicoDensidade {
  confortavel('CONFORTAVEL'),
  compacta('COMPACTA');

  const CatalogoPublicoDensidade(this.apiValue);

  final String apiValue;

  static CatalogoPublicoDensidade fromApi(dynamic value) {
    final String normalized = value?.toString().trim().toUpperCase() ?? '';
    return CatalogoPublicoDensidade.values.firstWhere(
      (CatalogoPublicoDensidade item) => item.apiValue == normalized,
      orElse: () => CatalogoPublicoDensidade.confortavel,
    );
  }
}

class CatalogoPublicoPersonalizacaoModel {
  const CatalogoPublicoPersonalizacaoModel({
    this.titulo = '',
    this.descricao = '',
    this.corPrincipal = '#126BFF',
    this.estilo = CatalogoPublicoEstilo.classico,
    this.densidade = CatalogoPublicoDensidade.confortavel,
    this.exibirPrecos = true,
    this.exibirContato = true,
    this.exibirEndereco = true,
  });

  final String titulo;
  final String descricao;
  final String corPrincipal;
  final CatalogoPublicoEstilo estilo;
  final CatalogoPublicoDensidade densidade;
  final bool exibirPrecos;
  final bool exibirContato;
  final bool exibirEndereco;

  factory CatalogoPublicoPersonalizacaoModel.fromJson(dynamic json) {
    final Map<String, dynamic> map = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    return CatalogoPublicoPersonalizacaoModel(
      titulo: map['titulo']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      corPrincipal: _normalizeHexColor(map['corPrincipal']?.toString()),
      estilo: CatalogoPublicoEstilo.fromApi(map['estilo']),
      densidade: CatalogoPublicoDensidade.fromApi(map['densidade']),
      exibirPrecos: map['exibirPrecos'] != false,
      exibirContato: map['exibirContato'] != false,
      exibirEndereco: map['exibirEndereco'] != false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'titulo': titulo.trim(),
    'descricao': descricao.trim(),
    'corPrincipal': _normalizeHexColor(corPrincipal),
    'estilo': estilo.apiValue,
    'densidade': densidade.apiValue,
    'exibirPrecos': exibirPrecos,
    'exibirContato': exibirContato,
    'exibirEndereco': exibirEndereco,
  };

  CatalogoPublicoPersonalizacaoModel copyWith({
    String? titulo,
    String? descricao,
    String? corPrincipal,
    CatalogoPublicoEstilo? estilo,
    CatalogoPublicoDensidade? densidade,
    bool? exibirPrecos,
    bool? exibirContato,
    bool? exibirEndereco,
  }) {
    return CatalogoPublicoPersonalizacaoModel(
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      corPrincipal: corPrincipal ?? this.corPrincipal,
      estilo: estilo ?? this.estilo,
      densidade: densidade ?? this.densidade,
      exibirPrecos: exibirPrecos ?? this.exibirPrecos,
      exibirContato: exibirContato ?? this.exibirContato,
      exibirEndereco: exibirEndereco ?? this.exibirEndereco,
    );
  }

  bool sameValuesAs(CatalogoPublicoPersonalizacaoModel other) {
    return titulo.trim() == other.titulo.trim() &&
        descricao.trim() == other.descricao.trim() &&
        _normalizeHexColor(corPrincipal) ==
            _normalizeHexColor(other.corPrincipal) &&
        estilo == other.estilo &&
        densidade == other.densidade &&
        exibirPrecos == other.exibirPrecos &&
        exibirContato == other.exibirContato &&
        exibirEndereco == other.exibirEndereco;
  }

  static String _normalizeHexColor(String? value) {
    final String normalized = value?.trim().toUpperCase() ?? '';
    return RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized)
        ? normalized
        : '#126BFF';
  }
}

class CatalogoPublicoEmpresaPreviewModel {
  const CatalogoPublicoEmpresaPreviewModel({
    this.nome = '',
    this.endereco = '',
    this.telefone = '',
    this.whatsapp = '',
    this.email = '',
    this.logoBase64 = '',
  });

  final String nome;
  final String endereco;
  final String telefone;
  final String whatsapp;
  final String email;
  final String logoBase64;

  factory CatalogoPublicoEmpresaPreviewModel.fromJson(dynamic json) {
    final Map<String, dynamic> map = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    return CatalogoPublicoEmpresaPreviewModel(
      nome: map['nomeFantasia']?.toString().trim().isNotEmpty == true
          ? map['nomeFantasia'].toString().trim()
          : map['nomeEmpresa']?.toString().trim() ?? '',
      endereco: map['endereco']?.toString().trim() ?? '',
      telefone: map['telefone']?.toString().trim() ?? '',
      whatsapp: map['whatsapp']?.toString().trim() ?? '',
      email: map['email']?.toString().trim() ?? '',
      logoBase64: map['logoBase64']?.toString().trim() ?? '',
    );
  }
}

class CatalogoPublicoProdutoPreviewModel {
  const CatalogoPublicoProdutoPreviewModel({
    required this.id,
    required this.nome,
    required this.preco,
    this.modelo = '',
    this.imagemUrl = '',
    this.imagemBase64 = '',
  });

  final String id;
  final String nome;
  final String modelo;
  final double preco;
  final String imagemUrl;
  final String imagemBase64;

  factory CatalogoPublicoProdutoPreviewModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CatalogoPublicoProdutoPreviewModel(
      id: json['id']?.toString() ?? '',
      nome: json['nomeProduto']?.toString().trim() ?? '',
      modelo: json['modeloProduto']?.toString().trim() ?? '',
      preco: (json['precoVenda'] as num?)?.toDouble() ?? 0,
      imagemUrl: json['imagemUrl']?.toString().trim() ?? '',
      imagemBase64: json['imagemBase64']?.toString().trim() ?? '',
    );
  }
}

class CatalogoPublicoConfiguracaoModel {
  const CatalogoPublicoConfiguracaoModel({
    required this.ativo,
    required this.token,
    required this.url,
    required this.personalizacao,
    required this.empresa,
    required this.produtos,
    this.locale = 'pt-BR',
    this.currencyCode = 'BRL',
    this.criadoEm,
    this.atualizadoEm,
  });

  final bool ativo;
  final String token;
  final String url;
  final String locale;
  final String currencyCode;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final CatalogoPublicoPersonalizacaoModel personalizacao;
  final CatalogoPublicoEmpresaPreviewModel empresa;
  final List<CatalogoPublicoProdutoPreviewModel> produtos;

  factory CatalogoPublicoConfiguracaoModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawProducts = json['produtos'] is List<dynamic>
        ? json['produtos'] as List<dynamic>
        : const <dynamic>[];
    return CatalogoPublicoConfiguracaoModel(
      ativo: json['ativo'] == true,
      token: json['token']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      locale: json['locale']?.toString() ?? 'pt-BR',
      currencyCode: json['currencyCode']?.toString().toUpperCase() ?? 'BRL',
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? ''),
      atualizadoEm: DateTime.tryParse(json['atualizadoEm']?.toString() ?? ''),
      personalizacao: CatalogoPublicoPersonalizacaoModel.fromJson(
        json['personalizacao'],
      ),
      empresa: CatalogoPublicoEmpresaPreviewModel.fromJson(json['empresa']),
      produtos: rawProducts
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (Map<dynamic, dynamic> item) =>
                CatalogoPublicoProdutoPreviewModel.fromJson(
                  item.map(
                    (dynamic key, dynamic value) =>
                        MapEntry<String, dynamic>(key.toString(), value),
                  ),
                ),
          )
          .toList(growable: false),
    );
  }

  CatalogoPublicoConfiguracaoModel copyWith({
    bool? ativo,
    CatalogoPublicoPersonalizacaoModel? personalizacao,
  }) {
    return CatalogoPublicoConfiguracaoModel(
      ativo: ativo ?? this.ativo,
      token: token,
      url: url,
      locale: locale,
      currencyCode: currencyCode,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm,
      personalizacao: personalizacao ?? this.personalizacao,
      empresa: empresa,
      produtos: produtos,
    );
  }
}
