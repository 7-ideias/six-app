class EmpresaModel {
  final String nomeEmpresa;
  final String nomeFantasia;
  final String documentoNoBrasilCNPJ;
  final String? telefone;
  final String? whatsapp;
  final String? emailPrincipal;
  final String? siteEmpresa;
  final String? endereco;
  final String? logoBase64;
  final List<HorarioAtendimentoModel> horariosAtendimento;
  final bool? realizaVendas;
  final bool? prestaServicosTecnicos;

  const EmpresaModel({
    required this.nomeEmpresa,
    required this.nomeFantasia,
    required this.documentoNoBrasilCNPJ,
    this.telefone,
    this.whatsapp,
    this.emailPrincipal,
    this.siteEmpresa,
    this.endereco,
    this.logoBase64,
    this.horariosAtendimento = const <HorarioAtendimentoModel>[],
    this.realizaVendas,
    this.prestaServicosTecnicos,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      nomeEmpresa: json['nomeEmpresa'] ?? '',
      nomeFantasia: json['nomeFantasia'] ?? '',
      documentoNoBrasilCNPJ: json['documentoNoBrasilCNPJ'] ?? '',
      telefone: _optionalString(json['telefone']),
      whatsapp: _optionalString(json['whatsapp']),
      emailPrincipal: _optionalString(json['emailPrincipal']),
      siteEmpresa: _optionalString(json['siteEmpresa']),
      endereco: _optionalString(json['endereco']),
      logoBase64: _optionalString(json['logoBase64']),
      horariosAtendimento: _parseHorariosAtendimento(
        json['horariosAtendimento'],
      ),
      realizaVendas: json['realizaVendas'] as bool?,
      prestaServicosTecnicos: json['prestaServicosTecnicos'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'nomeEmpresa': nomeEmpresa,
      'nomeFantasia': nomeFantasia,
      'documentoNoBrasilCNPJ': documentoNoBrasilCNPJ,
    };

    if (realizaVendas != null) {
      json['realizaVendas'] = realizaVendas;
    }
    if (prestaServicosTecnicos != null) {
      json['prestaServicosTecnicos'] = prestaServicosTecnicos;
    }

    if (telefone != null) {
      json['telefone'] = telefone;
    }
    if (whatsapp != null) {
      json['whatsapp'] = whatsapp;
    }
    if (emailPrincipal != null) {
      json['emailPrincipal'] = emailPrincipal;
    }
    if (siteEmpresa != null) {
      json['siteEmpresa'] = siteEmpresa;
    }
    if (endereco != null) {
      json['endereco'] = endereco;
    }
    if (logoBase64 != null) {
      json['logoBase64'] = logoBase64;
    }
    if (horariosAtendimento.isNotEmpty) {
      json['horariosAtendimento'] =
          horariosAtendimento.map((horario) => horario.toJson()).toList();
    }

    return json;
  }

  static List<HorarioAtendimentoModel> _parseHorariosAtendimento(
    dynamic value,
  ) {
    if (value is! List) return const <HorarioAtendimentoModel>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(HorarioAtendimentoModel.fromJson)
        .toList(growable: false);
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}

class HorarioAtendimentoModel {
  const HorarioAtendimentoModel({
    required this.diaSemana,
    required this.fechado,
    this.inicio,
    this.fim,
  });

  final String diaSemana;
  final bool fechado;
  final String? inicio;
  final String? fim;

  factory HorarioAtendimentoModel.fromJson(Map<String, dynamic> json) {
    return HorarioAtendimentoModel(
      diaSemana: json['diaSemana']?.toString() ?? '',
      fechado: json['fechado'] == true,
      inicio: _optionalString(json['inicio']),
      fim: _optionalString(json['fim']),
    );
  }

  HorarioAtendimentoModel copyWith({
    String? diaSemana,
    bool? fechado,
    String? inicio,
    String? fim,
  }) {
    return HorarioAtendimentoModel(
      diaSemana: diaSemana ?? this.diaSemana,
      fechado: fechado ?? this.fechado,
      inicio: inicio ?? this.inicio,
      fim: fim ?? this.fim,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'diaSemana': diaSemana,
      'fechado': fechado,
    };

    if (!fechado) {
      json['inicio'] = inicio;
      json['fim'] = fim;
    }

    return json;
  }

  static String? _optionalString(dynamic value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
