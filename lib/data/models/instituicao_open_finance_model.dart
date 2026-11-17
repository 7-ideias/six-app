class InstituicaoOpenFinance {
  const InstituicaoOpenFinance({
    required this.nome,
    required this.logotipoUrl,
    this.idParticipante,
    this.marcaOpenFinanceId,
  });

  // O catálogo oficial identifica uma marca pelo AuthorizationServerId.
  // O ID da organização é outro identificador e não substitui o da marca.
  final String nome;
  final String logotipoUrl;
  final String? idParticipante;
  final String? marcaOpenFinanceId;

  static const String _logoNubank =
      'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg';

  static InstituicaoOpenFinance? fromJson(Map<String, dynamic> json) {
    final nome = json['nome'];
    final logo = json['logotipoUrl'];
    if (nome is! String || nome.trim().isEmpty || logo is! String) {
      return null;
    }
    // Proteção contra versões antigas da API e inconsistências de catálogo:
    // jamais mostrar a marca de outro banco no lugar de Nubank.
    final url = _normalizar(nome) == 'nubank' ? _logoNubank : logo;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }
    return InstituicaoOpenFinance(
      nome: nome.trim(),
      logotipoUrl: uri.toString(),
      idParticipante: json['idParticipante'] as String?,
      marcaOpenFinanceId: json['marcaOpenFinanceId'] as String?,
    );
  }

  static String _normalizar(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  String? logotipoDe(String instituicao, {String? marcaOpenFinanceId}) {
    if (!habilitado) return null;
    if (marcaOpenFinanceId != null && marcaOpenFinanceId.isNotEmpty) {
      for (final item in instituicoes) {
        if (item.marcaOpenFinanceId == marcaOpenFinanceId) {
          return item.logotipoUrl;
        }
      }
    }
    if (instituicao.trim().isEmpty) return null;
    final nome = _normalizar(instituicao);
    for (final item in instituicoes) {
      if (_normalizar(item.nome) == nome) return item.logotipoUrl;
    }

    // Compatibilidade com os registros antigos que só guardavam "Nu".
    if (nome == 'nu' || nome == 'nupagamentos') {
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
