class PaletaSistemaDto {
  final String primaria;
  final String secundaria;
  final String destaque;
  final String alerta;
  final String fundo;
  final String superficie;
  final String textoPrimario;
  final String textoSecundario;

  PaletaSistemaDto({
    required this.primaria,
    required this.secundaria,
    required this.destaque,
    required this.alerta,
    required this.fundo,
    required this.superficie,
    required this.textoPrimario,
    required this.textoSecundario,
  });

  factory PaletaSistemaDto.fromJson(Map<String, dynamic> json) {
    return PaletaSistemaDto(
      primaria: json['primaria'],
      secundaria: json['secundaria'],
      destaque: json['destaque'],
      alerta: json['alerta'],
      fundo: json['fundo'],
      superficie: json['superficie'],
      textoPrimario: json['textoPrimario'],
      textoSecundario: json['textoSecundario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaria': primaria,
      'secundaria': secundaria,
      'destaque': destaque,
      'alerta': alerta,
      'fundo': fundo,
      'superficie': superficie,
      'textoPrimario': textoPrimario,
      'textoSecundario': textoSecundario,
    };
  }
}

class ConfiguracaoAparenciaResponse {
  final String id;
  final String idEmpresa;
  final String tema;
  final PaletaSistemaDto paleta;

  ConfiguracaoAparenciaResponse({
    required this.id,
    required this.idEmpresa,
    required this.tema,
    required this.paleta,
  });

  factory ConfiguracaoAparenciaResponse.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoAparenciaResponse(
      id: json['id'],
      idEmpresa: json['idEmpresa'],
      tema: json['tema'],
      paleta: PaletaSistemaDto.fromJson(json['paleta']),
    );
  }
}

class SalvarConfiguracaoAparenciaRequest {
  final String? idEmpresa;
  final String tema;
  final PaletaSistemaDto paleta;

  SalvarConfiguracaoAparenciaRequest({
    this.idEmpresa,
    required this.tema,
    required this.paleta,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'tema': tema,
      'paleta': paleta.toJson(),
    };
    if (idEmpresa != null) {
      data['idEmpresa'] = idEmpresa;
    }
    return data;
  }
}
