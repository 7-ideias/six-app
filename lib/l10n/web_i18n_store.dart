/// Armazena, em memória, as traduções de UI carregadas do backend.
///
/// É um singleton síncrono lido durante o `build` dos widgets. O carregamento
/// remoto assíncrono acontece no `LocaleSettingsProvider`, que escreve aqui via
/// [setMessages] e dispara `notifyListeners()` para reconstruir a árvore.
class WebI18nStore {
  WebI18nStore._();

  static final WebI18nStore instance = WebI18nStore._();

  /// languageCode ('pt' | 'en' | 'es') -> árvore de mensagens (key -> valor).
  final Map<String, Map<String, dynamic>> _byCode = {};

  /// Guarda as mensagens de um idioma. [code] pode ser um locale completo
  /// ('pt-BR') ou só o idioma ('pt'); apenas o idioma é usado como chave.
  void setMessages(String code, Map<String, dynamic> messages) {
    _byCode[_lang(code)] = messages;
  }

  /// Mantém em memória somente o idioma ativo.
  ///
  /// O objetivo é manter o mesmo comportamento do cache local persistido:
  /// quando o usuário troca de idioma, o pacote anterior deixa de ocupar espaço
  /// e o app passa a usar somente o pacote recém-baixado.
  void keepOnly(String code) {
    final active = _lang(code);
    _byCode.removeWhere((key, _) => key != active);
  }

  bool hasLanguage(String code) => _byCode.containsKey(_lang(code));

  /// String simples para [key], ou `null` se ausente/tipo inesperado.
  ///
  /// Suporta os dois formatos:
  /// - chave plana: `configuracoes.pageTitle`;
  /// - mapa aninhado vindo do Mongo: `{ "configuracoes": { "pageTitle": "..." } }`.
  String? string(String code, String key) {
    final value = _resolve(code, key);
    return value is String ? value : null;
  }

  /// Lista de strings para [key], ou `null` se ausente/tipo inesperado.
  List<String>? stringList(String code, String key) {
    final value = _resolve(code, key);
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Lista de objetos para [key] (ex.: plans, featureCards), ou `null`.
  List<Map<String, dynamic>>? objectList(String code, String key) {
    final value = _resolve(code, key);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return null;
  }

  Object? _resolve(String code, String key) {
    final messages = _byCode[_lang(code)];
    if (messages == null) return null;

    final flatValue = messages[key];
    if (flatValue != null) return flatValue;

    Object? current = messages;
    for (final part in key.split('.')) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  String _lang(String code) {
    final normalized = code.toLowerCase();
    final sep = normalized.indexOf(RegExp('[-_]'));
    return sep > 0 ? normalized.substring(0, sep) : normalized;
  }
}
