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
  static const String _logoItau =
      'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60701190.svg';

  /// Associação revisada por ISPB. Usada também enquanto o cache do backend
  /// ainda estiver servindo URLs incorretas de parceiros do Open Finance.
  static String? logoRevisado(String nome) {
    switch (normalizarNome(nome)) {
      case 'nubank':
        return _logoNubank;
      case 'itau':
      case 'itaucard':
      case 'bancoitaucard':
      case 'bancoitaucardsa':
      case 'itauunibanco':
      case 'itauunibancosa':
      case 'bancoitauunibanco':
      case 'bancoitauunibancosa':
        return _logoItau;
      default:
        return null;
    }
  }

  static String normalizarNome(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  static InstituicaoOpenFinance? fromJson(Map<String, dynamic> json) {
    final nome = json['nome'];
    if (nome is! String || nome.trim().isEmpty) return null;
    final logo = json['logotipoUrl'];
    final url = logoRevisado(nome) ?? (logo is String ? logo : null);
    if (url == null) return null;
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
    if (!habilitado || instituicao.trim().isEmpty) return null;
    // Nunca usamos uma URI errada do diretório para uma marca auditada.
    final logoRevisado = InstituicaoOpenFinance.logoRevisado(instituicao);
    if (logoRevisado != null) return logoRevisado;
    final nome = InstituicaoOpenFinance.normalizarNome(instituicao);
    if (marcaOpenFinanceId != null && marcaOpenFinanceId.isNotEmpty) {
      for (final item in instituicoes) {
        if (item.marcaOpenFinanceId == marcaOpenFinanceId &&
            InstituicaoOpenFinance.normalizarNome(item.nome) == nome) {
          return item.logotipoUrl;
        }
      }
    }
    for (final item in instituicoes) {
      if (InstituicaoOpenFinance.normalizarNome(item.nome) == nome) {
        return item.logotipoUrl;
      }
    }

    // Compatibilidade com os registros antigos que só guardavam "Nu".
    if (nome == 'nu' || nome == 'nupagamentos') {
      for (final item in instituicoes) {
        if (InstituicaoOpenFinance.normalizarNome(item.nome) == 'nubank') return item.logotipoUrl;
      }
    }
    return null;
  }

}
