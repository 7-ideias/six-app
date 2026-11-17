class InstituicaoOpenFinance {
  const InstituicaoOpenFinance({
    required this.nome,
    required this.logotipoUrl,
    this.idParticipante,
  });

  final String nome;
  final String logotipoUrl;
  final String? idParticipante;

  static InstituicaoOpenFinance? fromJson(Map<String, dynamic> json) {
    final nome = json['nome'];
    final url = json['logotipoUrl'];
    if (nome is! String || nome.trim().isEmpty || url is! String) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return InstituicaoOpenFinance(
      nome: nome.trim(),
      logotipoUrl: uri.toString(),
      idParticipante: json['idParticipante'] as String?,
    );
  }
}

/// A elegibilidade vem da regionalização persistida da empresa no backend,
/// nunca do idioma do usuário nem da seleção PESSOAL / EMPRESA.
class CatalogoInstituicoesBrasil {
  const CatalogoInstituicoesBrasil({
    required this.habilitado,
    required this.instituicoes,
  });

  static const vazio = CatalogoInstituicoesBrasil(
    habilitado: false,
    instituicoes: <InstituicaoOpenFinance>[],
  );

  final bool habilitado;
  final List<InstituicaoOpenFinance> instituicoes;

  factory CatalogoInstituicoesBrasil.fromJson(Map<String, dynamic> json) {
    if (json['habilitado'] != true) return vazio;
    final raw = json['instituicoes'];
    if (raw is! List) throw const FormatException('Invalid institution catalog');
    return CatalogoInstituicoesBrasil(
      habilitado: true,
      instituicoes: raw
          .whereType<Map>()
          .map((e) => InstituicaoOpenFinance.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .whereType<InstituicaoOpenFinance>()
          .toList(growable: false),
    );
  }

  String? logotipoDe(String instituicao) {
    if (!habilitado || instituicao.trim().isEmpty) return null;
    final nome = _normalizar(instituicao);
    for (final item in instituicoes) {
      if (_normalizar(item.nome) == nome) return item.logotipoUrl;
    }

    // Compatibilidade exclusiva com um nome antigo já usado no Sixo.
    // Não se faz busca parcial entre bancos para evitar atribuir marca errada.
    if (nome == 'nu' || nome == 'nu pagamentos') {
      for (final item in instituicoes) {
        if (_normalizar(item.nome) == 'nubank') return item.logotipoUrl;
      }
    }
    return null;
  }

  static String _normalizar(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}
