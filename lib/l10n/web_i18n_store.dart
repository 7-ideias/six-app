/// Armazena, em memória, as traduções de UI carregadas do backend.
///
/// É um singleton síncrono lido durante o `build` dos widgets via
/// [WebRootL10n]. O carregamento remoto (assíncrono) acontece no
/// `LocaleSettingsProvider`, que escreve aqui via [setMessages] e dispara
/// `notifyListeners()` para reconstruir a árvore com os textos novos.
///
/// Não há fallback embutido no app: o backend é a única fonte de conteúdo. As
/// telas que dependem destas mensagens só são construídas depois que o locale
/// corrente está carregado — o `WebI18nGate` exibe carregamento/erro enquanto
/// [hasLanguage] for falso. Por isso os getters retornam `null` quando a chave
/// ainda não chegou, e [WebRootL10n] traduz isso em vazio (`''` / `[]`).
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

  bool hasLanguage(String code) => _byCode.containsKey(_lang(code));

  /// String simples para [key], ou `null` se ausente/tipo inesperado.
  String? string(String code, String key) {
    final value = _byCode[_lang(code)]?[key];
    return value is String ? value : null;
  }

  /// Lista de strings para [key], ou `null` se ausente/tipo inesperado.
  List<String>? stringList(String code, String key) {
    final value = _byCode[_lang(code)]?[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Lista de objetos para [key] (ex.: plans, featureCards), ou `null`.
  List<Map<String, dynamic>>? objectList(String code, String key) {
    final value = _byCode[_lang(code)]?[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return null;
  }

  String _lang(String code) {
    final normalized = code.toLowerCase();
    final sep = normalized.indexOf(RegExp('[-_]'));
    return sep > 0 ? normalized.substring(0, sep) : normalized;
  }
}
