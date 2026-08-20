enum TipoDocumentoPdf {
  relatorioProdutos('RELATORIO_PRODUTOS'),
  comprovanteOperacao('COMPROVANTE_OPERACAO');

  const TipoDocumentoPdf(this.codigoApi);
  final String codigoApi;

  static TipoDocumentoPdf fromApi(dynamic value) => values.firstWhere(
    (TipoDocumentoPdf item) => item.codigoApi == value?.toString(),
    orElse: () => TipoDocumentoPdf.relatorioProdutos,
  );
}

enum PerfilPaginaDocumento {
  a4Retrato('A4_RETRATO', 193.1, 277.1),
  a4Paisagem('A4_PAISAGEM', 280.1, 190.1),
  cupomTermico80mm('CUPOM_TERMICO_80MM', 72, 150);

  const PerfilPaginaDocumento(
    this.codigoApi,
    this.larguraUtilMm,
    this.alturaPreviewMm,
  );

  final String codigoApi;
  final double larguraUtilMm;
  final double alturaPreviewMm;

  bool get termico => this == PerfilPaginaDocumento.cupomTermico80mm;

  static PerfilPaginaDocumento fromApi(dynamic value) => values.firstWhere(
    (PerfilPaginaDocumento item) => item.codigoApi == value?.toString(),
    orElse: () => PerfilPaginaDocumento.a4Retrato,
  );
}

enum TipoElementoDocumento {
  texto('TEXTO'),
  logo('LOGO'),
  linha('LINHA'),
  qrCode('QRCODE'),
  paginacao('PAGINACAO');

  const TipoElementoDocumento(this.codigoApi);
  final String codigoApi;

  static TipoElementoDocumento fromApi(dynamic value) => values.firstWhere(
    (TipoElementoDocumento item) => item.codigoApi == value?.toString(),
    orElse: () => TipoElementoDocumento.texto,
  );
}

enum ChaveVinculoDocumento {
  textoLivre('TEXTO_LIVRE'),
  nomeFantasiaEmpresa('NOME_FANTASIA_EMPRESA'),
  razaoSocialEmpresa('RAZAO_SOCIAL_EMPRESA'),
  documentoEmpresa('DOCUMENTO_EMPRESA'),
  telefoneEmpresa('TELEFONE_EMPRESA'),
  emailEmpresa('EMAIL_EMPRESA'),
  enderecoEmpresa('ENDERECO_EMPRESA'),
  siteEmpresa('SITE_EMPRESA'),
  tituloDocumento('TITULO_DOCUMENTO'),
  numeroDocumento('NUMERO_DOCUMENTO'),
  dataGeracao('DATA_GERACAO'),
  paginacao('PAGINACAO'),
  urlValidacao('URL_VALIDACAO');

  const ChaveVinculoDocumento(this.codigoApi);
  final String codigoApi;

  static ChaveVinculoDocumento fromApi(dynamic value) => values.firstWhere(
    (ChaveVinculoDocumento item) => item.codigoApi == value?.toString(),
    orElse: () => ChaveVinculoDocumento.textoLivre,
  );
}

class ModeloDocumento {
  const ModeloDocumento({
    this.id,
    required this.nome,
    this.descricao = '',
    this.ativo = true,
    required this.perfilPagina,
    required this.cabecalho,
    required this.rodape,
    this.versaoEsquema = 1,
    this.revisao,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String? id;
  final String nome;
  final String descricao;
  final bool ativo;
  final PerfilPaginaDocumento perfilPagina;
  final ZonaDocumento cabecalho;
  final ZonaDocumento rodape;
  final int versaoEsquema;
  final int? revisao;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  factory ModeloDocumento.fromJson(Map<String, dynamic> json) =>
      ModeloDocumento(
        id: _textoNulo(json['id']),
        nome: _texto(json['nome']),
        descricao: _texto(json['descricao']),
        ativo: _booleano(json['ativo'], true),
        perfilPagina: PerfilPaginaDocumento.fromApi(json['perfilPagina']),
        cabecalho: ZonaDocumento.fromJson(_mapa(json['cabecalho'])),
        rodape: ZonaDocumento.fromJson(_mapa(json['rodape'])),
        versaoEsquema: _inteiro(json['versaoEsquema'], 1),
        revisao: json['revisao'] == null ? null : _inteiro(json['revisao'], 1),
        criadoEm: _data(json['criadoEm']),
        atualizadoEm: _data(json['atualizadoEm']),
      );

  Map<String, dynamic> toJson({bool incluirCamposServidor = true}) =>
      <String, dynamic>{
        if (incluirCamposServidor && id != null) 'id': id,
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
        'perfilPagina': perfilPagina.codigoApi,
        'cabecalho': cabecalho.toJson(),
        'rodape': rodape.toJson(),
        'versaoEsquema': versaoEsquema,
        if (incluirCamposServidor && revisao != null) 'revisao': revisao,
      };

  ModeloDocumento copyWith({
    String? id,
    bool limparId = false,
    String? nome,
    String? descricao,
    bool? ativo,
    PerfilPaginaDocumento? perfilPagina,
    ZonaDocumento? cabecalho,
    ZonaDocumento? rodape,
    int? versaoEsquema,
    int? revisao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) => ModeloDocumento(
    id: limparId ? null : id ?? this.id,
    nome: nome ?? this.nome,
    descricao: descricao ?? this.descricao,
    ativo: ativo ?? this.ativo,
    perfilPagina: perfilPagina ?? this.perfilPagina,
    cabecalho: cabecalho ?? this.cabecalho,
    rodape: rodape ?? this.rodape,
    versaoEsquema: versaoEsquema ?? this.versaoEsquema,
    revisao: revisao ?? this.revisao,
    criadoEm: criadoEm ?? this.criadoEm,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
  );

  factory ModeloDocumento.novo(
    PerfilPaginaDocumento perfil, {
    String nomeA4 = 'Documento personalizado',
    String nomeCupom = 'Cupom personalizado 80 mm',
    String textoRodape = 'Obrigado pela preferência.',
  }) {
    final bool termico = perfil.termico;
    final double largura = perfil.larguraUtilMm;
    return ModeloDocumento(
      nome: termico ? nomeCupom : nomeA4,
      perfilPagina: perfil,
      cabecalho: ZonaDocumento(
        alturaMm: termico ? 32 : 28,
        elementos: <ElementoDocumento>[
          ElementoDocumento(
            id: 'logo-${DateTime.now().microsecondsSinceEpoch}',
            tipo: TipoElementoDocumento.logo,
            chaveVinculo: ChaveVinculoDocumento.nomeFantasiaEmpresa,
            xMm: 0,
            yMm: 1,
            larguraMm: termico ? 18 : 28,
            alturaMm: termico ? 13 : 18,
          ),
          ElementoDocumento(
            id: 'empresa-${DateTime.now().microsecondsSinceEpoch + 1}',
            tipo: TipoElementoDocumento.texto,
            chaveVinculo: ChaveVinculoDocumento.nomeFantasiaEmpresa,
            xMm: termico ? 0 : 32,
            yMm: termico ? 15 : 2,
            larguraMm: termico ? largura : largura - 32,
            alturaMm: 7,
            propriedades: <String, dynamic>{
              'tamanhoFonte': 12,
              'negrito': true,
              'alinhamento': 'ESQUERDA',
              'cor': '#1F3A8A',
            },
          ),
          ElementoDocumento(
            id: 'titulo-${DateTime.now().microsecondsSinceEpoch + 2}',
            tipo: TipoElementoDocumento.texto,
            chaveVinculo: ChaveVinculoDocumento.tituloDocumento,
            xMm: termico ? 0 : 32,
            yMm: termico ? 22 : 10,
            larguraMm: termico ? largura : largura - 32,
            alturaMm: 7,
            propriedades: <String, dynamic>{
              'tamanhoFonte': termico ? 9 : 11,
              'negrito': true,
              'alinhamento': termico ? 'CENTRO' : 'ESQUERDA',
              'cor': '#334155',
            },
          ),
          ElementoDocumento(
            id: 'linha-${DateTime.now().microsecondsSinceEpoch + 3}',
            tipo: TipoElementoDocumento.linha,
            chaveVinculo: ChaveVinculoDocumento.textoLivre,
            xMm: 0,
            yMm: termico ? 30 : 25,
            larguraMm: largura,
            alturaMm: 1,
            propriedades: const <String, dynamic>{
              'cor': '#CBD5E1',
              'espessura': 0.8,
            },
          ),
        ],
      ),
      rodape: ZonaDocumento(
        alturaMm: termico ? 24 : 18,
        elementos: <ElementoDocumento>[
          ElementoDocumento(
            id: 'rodape-${DateTime.now().microsecondsSinceEpoch + 4}',
            tipo: TipoElementoDocumento.texto,
            chaveVinculo: ChaveVinculoDocumento.textoLivre,
            xMm: 0,
            yMm: 2,
            larguraMm: termico ? largura : largura - 42,
            alturaMm: termico ? 12 : 8,
            propriedades: <String, dynamic>{
              'texto': textoRodape,
              'tamanhoFonte': 8,
              'alinhamento': 'ESQUERDA',
              'cor': '#64748B',
            },
          ),
          if (!termico)
            ElementoDocumento(
              id: 'pagina-${DateTime.now().microsecondsSinceEpoch + 5}',
              tipo: TipoElementoDocumento.paginacao,
              chaveVinculo: ChaveVinculoDocumento.paginacao,
              xMm: largura - 40,
              yMm: 2,
              larguraMm: 40,
              alturaMm: 7,
              propriedades: const <String, dynamic>{
                'tamanhoFonte': 8,
                'alinhamento': 'DIREITA',
                'cor': '#64748B',
              },
            ),
          ElementoDocumento(
            id: 'data-${DateTime.now().microsecondsSinceEpoch + 6}',
            tipo: TipoElementoDocumento.texto,
            chaveVinculo: ChaveVinculoDocumento.dataGeracao,
            xMm: 0,
            yMm: termico ? 15 : 10,
            larguraMm: largura,
            alturaMm: 6,
            propriedades: const <String, dynamic>{
              'tamanhoFonte': 7,
              'alinhamento': 'CENTRO',
              'cor': '#94A3B8',
            },
          ),
        ],
      ),
    );
  }
}

class ZonaDocumento {
  const ZonaDocumento({
    this.exibir = true,
    required this.alturaMm,
    this.repetirEmTodasPaginas = true,
    this.elementos = const <ElementoDocumento>[],
  });

  final bool exibir;
  final double alturaMm;
  final bool repetirEmTodasPaginas;
  final List<ElementoDocumento> elementos;

  factory ZonaDocumento.fromJson(Map<String, dynamic> json) => ZonaDocumento(
    exibir: _booleano(json['exibir'], true),
    alturaMm: _numero(json['alturaMm'], 20),
    repetirEmTodasPaginas: _booleano(json['repetirEmTodasPaginas'], true),
    elementos: _lista(json['elementos'])
        .whereType<Map>()
        .map(
          (Map item) => ElementoDocumento.fromJson(
            item.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exibir': exibir,
    'alturaMm': alturaMm,
    'repetirEmTodasPaginas': repetirEmTodasPaginas,
    'elementos': elementos
        .map((ElementoDocumento item) => item.toJson())
        .toList(growable: false),
  };

  ZonaDocumento copyWith({
    bool? exibir,
    double? alturaMm,
    bool? repetirEmTodasPaginas,
    List<ElementoDocumento>? elementos,
  }) => ZonaDocumento(
    exibir: exibir ?? this.exibir,
    alturaMm: alturaMm ?? this.alturaMm,
    repetirEmTodasPaginas: repetirEmTodasPaginas ?? this.repetirEmTodasPaginas,
    elementos: elementos ?? this.elementos,
  );
}

class ElementoDocumento {
  const ElementoDocumento({
    required this.id,
    required this.tipo,
    required this.chaveVinculo,
    required this.xMm,
    required this.yMm,
    required this.larguraMm,
    required this.alturaMm,
    this.indiceCamada = 0,
    this.propriedades = const <String, dynamic>{},
  });

  final String id;
  final TipoElementoDocumento tipo;
  final ChaveVinculoDocumento chaveVinculo;
  final double xMm;
  final double yMm;
  final double larguraMm;
  final double alturaMm;
  final int indiceCamada;
  final Map<String, dynamic> propriedades;

  factory ElementoDocumento.fromJson(Map<String, dynamic> json) =>
      ElementoDocumento(
        id: _texto(json['id']),
        tipo: TipoElementoDocumento.fromApi(json['tipo']),
        chaveVinculo: ChaveVinculoDocumento.fromApi(json['chaveVinculo']),
        xMm: _numero(json['xMm'], 0),
        yMm: _numero(json['yMm'], 0),
        larguraMm: _numero(json['larguraMm'], 20),
        alturaMm: _numero(json['alturaMm'], 8),
        indiceCamada: _inteiro(json['indiceCamada'], 0),
        propriedades: _mapa(json['propriedades']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tipo': tipo.codigoApi,
    'chaveVinculo': chaveVinculo.codigoApi,
    'xMm': xMm,
    'yMm': yMm,
    'larguraMm': larguraMm,
    'alturaMm': alturaMm,
    'indiceCamada': indiceCamada,
    'propriedades': propriedades,
  };

  ElementoDocumento copyWith({
    String? id,
    TipoElementoDocumento? tipo,
    ChaveVinculoDocumento? chaveVinculo,
    double? xMm,
    double? yMm,
    double? larguraMm,
    double? alturaMm,
    int? indiceCamada,
    Map<String, dynamic>? propriedades,
  }) => ElementoDocumento(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    chaveVinculo: chaveVinculo ?? this.chaveVinculo,
    xMm: xMm ?? this.xMm,
    yMm: yMm ?? this.yMm,
    larguraMm: larguraMm ?? this.larguraMm,
    alturaMm: alturaMm ?? this.alturaMm,
    indiceCamada: indiceCamada ?? this.indiceCamada,
    propriedades: propriedades ?? this.propriedades,
  );
}

class ModeloPadraoDocumento {
  const ModeloPadraoDocumento({
    required this.tipoDocumento,
    required this.perfilPagina,
    required this.idModeloDocumento,
  });

  final TipoDocumentoPdf tipoDocumento;
  final PerfilPaginaDocumento perfilPagina;
  final String idModeloDocumento;

  factory ModeloPadraoDocumento.fromJson(Map<String, dynamic> json) =>
      ModeloPadraoDocumento(
        tipoDocumento: TipoDocumentoPdf.fromApi(json['tipoDocumento']),
        perfilPagina: PerfilPaginaDocumento.fromApi(json['perfilPagina']),
        idModeloDocumento: _texto(json['idModeloDocumento']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'tipoDocumento': tipoDocumento.codigoApi,
    'perfilPagina': perfilPagina.codigoApi,
    'idModeloDocumento': idModeloDocumento,
  };
}

class DocumentoPdfResponse {
  const DocumentoPdfResponse({
    required this.arquivoBase64,
    required this.nomeArquivo,
    required this.mimeType,
    required this.tamanhoBytes,
    this.geradoEm,
  });

  final String arquivoBase64;
  final String nomeArquivo;
  final String mimeType;
  final int tamanhoBytes;
  final DateTime? geradoEm;

  factory DocumentoPdfResponse.fromJson(Map<String, dynamic> json) =>
      DocumentoPdfResponse(
        arquivoBase64: _texto(json['arquivoBase64']),
        nomeArquivo: _texto(
          json['nomeArquivo'],
          fallback: 'previa-documento.pdf',
        ),
        mimeType: _texto(json['mimeType'], fallback: 'application/pdf'),
        tamanhoBytes: _inteiro(json['tamanhoBytes'], 0),
        geradoEm: _data(json['geradoEm']),
      );
}

String _texto(dynamic value, {String fallback = ''}) {
  final String texto = value?.toString().trim() ?? '';
  return texto.isEmpty ? fallback : texto;
}

String? _textoNulo(dynamic value) {
  final String texto = _texto(value);
  return texto.isEmpty ? null : texto;
}

double _numero(dynamic value, double fallback) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

int _inteiro(dynamic value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

bool _booleano(dynamic value, bool fallback) => value is bool
    ? value
    : value == null
    ? fallback
    : '$value' == 'true';

Map<String, dynamic> _mapa(dynamic value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map(
    (dynamic key, dynamic item) =>
        MapEntry<String, dynamic>(key.toString(), item),
  );
}

List<dynamic> _lista(dynamic value) => value is List ? value : <dynamic>[];

DateTime? _data(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
